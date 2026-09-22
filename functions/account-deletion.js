const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {onSchedule} = require('firebase-functions/v2/scheduler');
const {getFirestore, FieldValue, Timestamp} = require('firebase-admin/firestore');
const {getAuth} = require('firebase-admin/auth');
const logger = require('firebase-functions/logger');

// Only the authenticated customer can enqueue their own deletion. No client UID.
exports.requestAccountDeletion = onCall({enforceAppCheck: true}, async request => {
  const now = Math.floor(Date.now() / 1000);
  const authTime = request.auth?.token?.auth_time;
  if (!request.auth || !Number.isFinite(authTime) || now - authTime > 300 || authTime > now + 60) {
    throw new HttpsError('unauthenticated', 'Recent sign-in required');
  }
  const db = getFirestore();
  const uid = request.auth.uid;
  const profile = db.doc(`users/${uid}`);
  const task = db.doc(`accountDeletionRequests/${uid}`);
  await db.runTransaction(async tx => {
    const user = await tx.get(profile);
    const existing = await tx.get(task);
    if (user.data()?.role !== 'customer') {
      throw new HttpsError('permission-denied', 'Customer account required');
    }
    if (existing.exists) return;
    const benefits = await tx.get(db.doc(`users/${uid}/account/benefits`));
    if ((benefits.data()?.balance || 0) > 0) throw new HttpsError('failed-precondition', 'Settle wallet balance before deleting account');
    tx.create(task, {status: 'pending', requestedAt: FieldValue.serverTimestamp(),
      nextAttemptAt: Timestamp.now()});
    tx.update(profile, {deletionRequested: true, updatedAt: FieldValue.serverTimestamp()});
  });
  return {status: 'requested'};
});

async function ignoreMissingAuth(action) {
  try { await action(); } catch (error) {
    if (error.code !== 'auth/user-not-found') throw error;
  }
}

// A lease plus repeatable redaction makes retries safe after partial failure.
async function processDeletion(uid, db = getFirestore(), auth = getAuth()) {
  const task = db.doc(`accountDeletionRequests/${uid}`);
  const claimed = await db.runTransaction(async tx => {
    const snapshot = await tx.get(task);
    if (!snapshot.exists || snapshot.data().status === 'completed' ||
        snapshot.data().nextAttemptAt.toMillis() > Date.now()) return false;
    tx.update(task, {status: 'processing', nextAttemptAt: Timestamp.fromMillis(Date.now() + 15 * 60000)});
    return true;
  });
  if (!claimed) return false;
  try {
    const orders = await db.collection('orders').where('customerId', '==', uid).get();
    const refunds = await db.collection('refundRequests').where('customerId', '==', uid).get();
    const benefits = await db.doc(`users/${uid}/account/benefits`).get();
    if ((benefits.data()?.balance || 0) > 0 || orders.docs.some(doc => !['delivered', 'cancelled'].includes(doc.data().status)) ||
        refunds.docs.some(doc => !['completed', 'rejected'].includes(doc.data().status))) {
      await task.update({status: 'pending', nextAttemptAt: Timestamp.fromMillis(Date.now() + 3600000)});
      return false;
    }
    await ignoreMissingAuth(() => auth.updateUser(uid, {disabled: true}));
    const profile = db.doc(`users/${uid}`);
    if ((await profile.get()).exists) await profile.update({active: false});
    // Keep transaction amounts/items; remove contact details and free text.
    for (const order of orders.docs) {
      await db.recursiveDelete(order.ref.collection('messages'));
      await order.ref.update({address: 'تم حذف بيانات العميل',
        requestFingerprint: FieldValue.delete(), customerId: 'deleted'});
    }
    for (const refund of refunds.docs) {
      await refund.ref.update({customerId: 'deleted', reason: 'تم حذف بيانات العميل', note: FieldValue.delete()});
    }
    const payments = await db.collection('paymentTransactions').where('customerId', '==', uid).get();
    for (const payment of payments.docs) await payment.ref.update({customerId: 'deleted'});
    const customerRequests = await db.collection('customerRequests').where('ownerId', '==', uid).get();
    for (const request of customerRequests.docs) await request.ref.delete();
    await ignoreMissingAuth(() => auth.deleteUser(uid));
    await db.recursiveDelete(profile);
    await task.update({status: 'completed', completedAt: FieldValue.serverTimestamp(),
      nextAttemptAt: FieldValue.delete()});
    return true;
  } catch (error) {
    await task.update({status: 'pending', nextAttemptAt: Timestamp.fromMillis(Date.now() + 3600000)});
    throw error;
  }
}
exports.processDeletion = processDeletion;

exports.processAccountDeletions = onSchedule({schedule: 'every 60 minutes',
  timeoutSeconds: 540, maxInstances: 1}, async () => {
  const tasks = await getFirestore().collection('accountDeletionRequests')
      .where('nextAttemptAt', '<=', Timestamp.now()).orderBy('nextAttemptAt').limit(20).get();
  for (const task of tasks.docs) {
    try { await processDeletion(task.id); } catch (error) {
      logger.error('account_deletion_failed', {code: error.code || 'unknown'});
    }
  }
});

