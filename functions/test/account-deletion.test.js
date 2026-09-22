const {test, before, after, beforeEach} = require('node:test');
const assert = require('node:assert/strict');
const {initializeApp, deleteApp} = require('firebase-admin/app');
const {getFirestore, Timestamp} = require('firebase-admin/firestore');
let app, db, deletion, checkout;
const calls = [];
const auth = {updateUser: async uid => calls.push(`disable:${uid}`),
  deleteUser: async uid => calls.push(`delete:${uid}`)};
const request = () => ({auth: {uid: 'customer', token: {auth_time: Math.floor(Date.now() / 1000)}},
  data: {uid: 'other'}});
before(() => {
  if (!process.env.FIRESTORE_EMULATOR_HOST) throw new Error('Emulator required');
  app = initializeApp({projectId: 'demo-azharna'}); db = getFirestore();
  deletion = require('../account-deletion'); checkout = require('../orders').createCashOrder;
});
after(async () => { await deleteApp(app); });
beforeEach(async () => {
  calls.length = 0;
  for (const name of ['users', 'orders', 'accountDeletionRequests', 'refundRequests', 'paymentTransactions', 'customerRequests']) {
    await db.recursiveDelete(db.collection(name));
  }
  await db.doc('users/customer').set({role: 'customer', active: true, phone: 'private', fcmTokens: ['secret']});
  await db.doc('users/other').set({role: 'customer', active: true});
});
test('request uses authenticated identity, requires recent sign-in and is idempotent', async () => {
  await assert.rejects(deletion.requestAccountDeletion.run({data: {}}), {code: 'unauthenticated'});
  const stale = request(); stale.auth.token.auth_time -= 301;
  await assert.rejects(deletion.requestAccountDeletion.run(stale), {code: 'unauthenticated'});
  await deletion.requestAccountDeletion.run(request());
  await deletion.requestAccountDeletion.run(request());
  assert.equal((await db.collection('accountDeletionRequests').get()).size, 1);
  assert.equal((await db.doc('users/customer').get()).data().deletionRequested, true);
  assert.equal((await db.doc('users/other').get()).data().deletionRequested, undefined);
  await assert.rejects(checkout.run({auth: {uid: 'customer'}, data: {
    items: [{productId: 'rose', quantity: 1}], address: 'Baghdad', expectedTotal: 15000,
    requestId: 'request_123456789'}}), {code: 'failed-precondition'});
});
test('business accounts cannot enter the customer deletion worker', async () => {
  await db.doc('users/customer').update({role: 'store'});
  await assert.rejects(deletion.requestAccountDeletion.run(request()), {code: 'permission-denied'});
});
test('open orders defer deletion without disabling the customer', async () => {
  await db.doc('orders/order').set({customerId: 'customer', status: 'preparing'});
  await deletion.requestAccountDeletion.run(request());
  assert.equal(await deletion.processDeletion('customer', db, auth), false);
  assert.deepEqual(calls, []);
  assert.equal((await db.doc('users/customer').get()).exists, true);
});
test('open refunds also defer deletion', async () => {
  await db.doc('refundRequests/refund').set({customerId: 'customer', status: 'approved'});
  await deletion.requestAccountDeletion.run(request());
  assert.equal(await deletion.processDeletion('customer', db, auth), false);
  assert.deepEqual(calls, []);
});
test('completed orders are redacted, messages/profile removed, and retry is harmless', async () => {
  await db.doc('orders/order').set({customerId: 'customer', status: 'delivered', address: 'private',
    requestFingerprint: 'private', total: 15000});
  await db.doc('orders/order/messages/msg').set({senderId: 'customer', text: 'private'});
  await db.doc('users/customer/addresses/home').set({address: 'private'});
  await db.doc('users/customer/account/profile').set({name: 'private'});
  await db.doc('customerRequests/customerRequest').set({ownerId: 'customer', fields: {details: 'private'}});
  await db.doc('refundRequests/refund').set({customerId: 'customer', status: 'completed', reason: 'private', note: 'private'});
  await db.doc('paymentTransactions/pay').set({customerId: 'customer', amount: 15000});
  await deletion.requestAccountDeletion.run(request());
  assert.equal(await deletion.processDeletion('customer', db, auth), true);
  const order = (await db.doc('orders/order').get()).data();
  assert.equal(order.customerId, 'deleted'); assert.equal(order.total, 15000);
  assert.equal(order.requestFingerprint, undefined); assert.notEqual(order.address, 'private');
  assert.equal((await db.collection('orders/order/messages').get()).size, 0);
  assert.equal((await db.doc('users/customer').get()).exists, false);
  assert.equal((await db.doc('users/customer/account/profile').get()).exists, false);
  assert.equal((await db.doc('customerRequests/customerRequest').get()).exists, false);
  assert.equal((await db.collection('users/customer/addresses').get()).size, 0);
  assert.equal((await db.doc('users/other').get()).exists, true);
  assert.deepEqual(calls, ['disable:customer', 'delete:customer']);
  assert.equal(await deletion.processDeletion('customer', db, auth), false);
});
test('Auth failure preserves retry task and a later run completes cleanup', async () => {
  await deletion.requestAccountDeletion.run(request());
  await assert.rejects(deletion.processDeletion('customer', db, {
    updateUser: auth.updateUser, deleteUser: async () => { throw new Error('temporary'); }}));
  assert.equal((await db.doc('accountDeletionRequests/customer').get()).data().status, 'pending');
  await db.doc('accountDeletionRequests/customer').update({nextAttemptAt: Timestamp.fromMillis(0)});
  assert.equal(await deletion.processDeletion('customer', db, auth), true);
});


test('positive wallet balance prevents deletion until it is settled', async () => {
  await db.doc('users/customer/account/benefits').set({balance:5000});
  await assert.rejects(deletion.requestAccountDeletion.run(request()), {code:'failed-precondition'});
  assert.equal((await db.doc('users/customer').get()).exists,true);
});
