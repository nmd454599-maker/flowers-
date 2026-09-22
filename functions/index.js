const logger = require('firebase-functions/logger');
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {setGlobalOptions} = require("firebase-functions/v2");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {getFirestore, FieldValue, Timestamp} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();
setGlobalOptions({region: "me-central1", maxInstances: 4});

const db = getFirestore();

exports.processAdminAction = onDocumentCreated(
  "adminData/{scope}/records/{recordId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;
    const data = snapshot.data();
    const scope = event.params.scope;
    if (!["pendingBackend", "requested"].includes(data.status)) return;

    try {
      let result = {};
      if (scope === "notifications") result = await sendNotification(data);
      if (scope === "security") result = await revokeSessions(data);
      if (scope === "support") result = await processSupportAction(data);
      if (scope === "analytics" || scope === "finance") {
        result = await buildReport(scope);
      }
      await snapshot.ref.update({
        status: "completed",
        result,
        processedAt: FieldValue.serverTimestamp(),
      });
    } catch (error) {
      await snapshot.ref.update({
        status: "failed",
        error: String(error.message || error),
        processedAt: FieldValue.serverTimestamp(),
      });
      throw error;
    }
  },
);

exports.sendScheduledNotifications = onSchedule("every 5 minutes", async () => {
  const scheduled = await db
    .collection("adminData")
    .doc("notifications")
    .collection("records")
    .where("status", "==", "scheduled")
    .where("scheduledFor", "<=", Timestamp.now())
    .limit(100)
    .get();
  for (const item of scheduled.docs) {
    try {
      const result = await sendNotification(item.data());
      await item.ref.update({
        status: "completed",
        result,
        processedAt: FieldValue.serverTimestamp(),
      });
    } catch (error) {
      logger.error('scheduled_admin_notification_failed', {recordId: item.id, code: error.code || 'unknown'});
      await item.ref.update({
        status: "failed",
        error: String(error.message || error),
        processedAt: FieldValue.serverTimestamp(),
      });
    }
  }
});

async function sendNotification(data) {
  const topicByTarget = {
    "الكل": "all",
    "العملاء": "customers",
    "المتاجر": "stores",
  };
  const topic = topicByTarget[data.target];
  const notification = {title: String(data.title), body: String(data.body)};
  if (topic) {
    const messageId = await getMessaging().send({
      topic,
      notification,
      data: {source: "azharna-admin"},
    });
    return {messageId, topic};
  }

  const users = await db.collection("users").limit(10000).get();
  const inactiveBefore = Date.now() - 30 * 24 * 60 * 60 * 1000;
  const tokens = users.docs.flatMap((user) => {
    const value = user.data();
    const matchesCity = data.target === "مدينة محددة" && value.city === data.city;
    const lastActive = value.lastActiveAt?.toMillis?.() || 0;
    const matchesInactive = data.target === "غير النشطين" &&
      value.active !== false && lastActive < inactiveBefore;
    return matchesCity || matchesInactive ? (value.fcmTokens || []) : [];
  });
  let sent = 0;
  let failed = 0;
  for (let index = 0; index < tokens.length; index += 500) {
    const response = await getMessaging().sendEachForMulticast({
      tokens: tokens.slice(index, index + 500),
      notification,
      data: {source: "azharna-admin"},
    });
    sent += response.successCount;
    failed += response.failureCount;
  }
  return {sent, failed, audience: data.target};
}

async function revokeSessions(data) {
  const uid = data.updatedBy;
  if (!uid) throw new Error("معرف المستخدم غير موجود");
  await getAuth().revokeRefreshTokens(uid);
  return {uid};
}

async function processSupportAction(data) {
  const title = String(data.title || "");
  const value = String(data.value || "");
  if (title.includes("حظر حساب")) {
    const users = await db.collection("users").where("phone", "==", value).limit(1).get();
    if (users.empty) throw new Error("الحساب غير موجود");
    const user = users.docs[0];
    await Promise.all([
      user.ref.update({active: false, updatedAt: FieldValue.serverTimestamp()}),
      getAuth().updateUser(user.id, {disabled: true}),
    ]);
    return {userId: user.id, disabled: true};
  }
  if (title.includes("قسيمة تعويض")) {
    const coupon = await db.collection("coupons").add({
      value,
      active: true,
      source: "supportCompensation",
      createdBy: data.updatedBy,
      createdAt: FieldValue.serverTimestamp(),
    });
    return {couponId: coupon.id};
  }
  return {recorded: true};
}

async function buildReport(scope) {
  const orders = await db.collection("orders").limit(5000).get();
  let grossSales = 0;
  let cancelled = 0;
  for (const order of orders.docs) {
    const data = order.data();
    grossSales += Number(data.total || 0);
    if (data.status === "cancelled") cancelled += 1;
  }
  return {scope, orders: orders.size, grossSales, cancelled};
}

exports.createCashOrder = require('./orders').createCashOrder;
exports.requestAccountDeletion = require('./account-deletion').requestAccountDeletion;
exports.processAccountDeletions = require('./account-deletion').processAccountDeletions;

exports.redeemRewardPoints = require('./rewards').redeemRewardPoints;
exports.creditCustomerWallet = require('./rewards').creditCustomerWallet;
exports.settleOrderRewards = require('./rewards').settleOrderRewards;
exports.syncRewardPoints = require('./rewards').syncRewardPoints;
