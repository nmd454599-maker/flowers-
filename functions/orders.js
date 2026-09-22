const rewards = require('./rewards');
﻿const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');

// Prices and stock always come from Firestore, never from the client.
exports.createCashOrder = onCall({enforceAppCheck: true}, async request => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first');
  const {items, address, requestId, expectedTotal, couponId = null, walletAmount = 0} = request.data || {};
  if (!Array.isArray(items) || !items.length || items.length > 50 ||
      typeof address !== 'string' || !address.trim() || address.length > 2000 ||
      typeof requestId !== 'string' || !/^[a-zA-Z0-9_-]{16,80}$/.test(requestId)) {
    throw new HttpsError('invalid-argument', 'Invalid order');
  }
  if ((couponId !== null && (typeof couponId !== 'string' || !/^[A-Za-z0-9_-]{1,80}$/.test(couponId))) || !Number.isSafeInteger(walletAmount) || walletAmount < 0) throw new HttpsError('invalid-argument','Invalid benefits');
  const seen = new Set();
  for (const item of items) {
    if (!item || typeof item.productId !== 'string' || !/^[a-zA-Z0-9_-]{1,128}$/.test(item.productId) ||
        seen.has(item.productId) || !Number.isSafeInteger(item.quantity) || item.quantity < 1 || item.quantity > 100) {
      throw new HttpsError('invalid-argument', 'Invalid item');
    }
    seen.add(item.productId);
  }
  const db = getFirestore();
  const uid = request.auth.uid;
  const orderRef = db.collection('orders').doc(`${uid}_${requestId}`);
  const fingerprint = JSON.stringify({items, address:address.trim(), expectedTotal, couponId, walletAmount});
  return db.runTransaction(async transaction => {
    const profile = await transaction.get(db.collection('users').doc(uid));
    if (profile.data()?.active !== true || profile.data()?.role !== 'customer') {
      throw new HttpsError('permission-denied', 'Active customer required');
    }
    const existing = await transaction.get(orderRef);
    if (existing.exists) {
      if (existing.data().requestFingerprint !== fingerprint) throw new HttpsError('already-exists', 'Request ID already used');
      return {orderId:orderRef.id};
    }
    if (profile.data().deletionRequested === true) {
      throw new HttpsError('failed-precondition', 'Account deletion requested');
    }
    const products = await transaction.getAll(...items.map(item => db.collection('products').doc(item.productId)));
    const orderItems = products.map((snapshot,index) => {
      const product = snapshot.data();
      const quantity = items[index].quantity;
      if (!product || product.active !== true || product.approvalStatus !== 'approved' ||
          !Number.isSafeInteger(product.price) || product.price <= 0 ||
          !Number.isSafeInteger(product.stock) || product.stock < quantity ||
          typeof product.storeId !== 'string' || !/^[a-zA-Z0-9_-]{1,128}$/.test(product.storeId)) {
        throw new HttpsError('failed-precondition', 'Product unavailable');
      }
      return {productId:snapshot.id,storeId:product.storeId,name:product.name || '',unitPrice:product.price,quantity};
    });
    const storeIds = [...new Set(orderItems.map(item => item.storeId))];
    const stores = await transaction.getAll(...storeIds.map(id => db.collection('stores').doc(id)));
    if (stores.some(store => store.data()?.active !== true)) throw new HttpsError('failed-precondition', 'Store unavailable');
    const subtotal = orderItems.reduce((sum,item) => sum + item.unitPrice * item.quantity,0);
    const deliveryFee = 5000;
    const benefitsRef = db.doc(`users/${uid}/account/benefits`);
    const benefits = rewards.account((await transaction.get(benefitsRef)).data());
    const {total, discount, cashDue} = rewards.purchase(benefits,{subtotal,deliveryFee,couponId,walletAmount,orderId:orderRef.id});
    if (!Number.isSafeInteger(total) || total > 100000000) throw new HttpsError('invalid-argument','Invalid total');
    if (expectedTotal !== total) throw new HttpsError('failed-precondition', 'Prices changed; refresh the cart');
    if (couponId || walletAmount) transaction.set(benefitsRef,{...benefits,ownerId:uid});
    transaction.create(orderRef, {customerId:uid,address:address.trim(),items:orderItems,storeIds,
      subtotal,deliveryFee,total,discount,couponId,walletUsed:walletAmount,cashDue,paymentMethod:'cash',paymentStatus:cashDue===0?'paid':'pending',status:'newOrder',
      requestFingerprint:fingerprint,createdAt:FieldValue.serverTimestamp()});
    if (cashDue > 0) transaction.create(db.collection('paymentTransactions').doc(orderRef.id), {
      orderId:orderRef.id,customerId:uid,amount:cashDue,method:'cash',provider:'cash',status:'pending',createdAt:FieldValue.serverTimestamp(),
    });
    if (walletAmount) transaction.create(db.collection('paymentTransactions').doc(orderRef.id+'_wallet'), {
      orderId:orderRef.id,customerId:uid,amount:walletAmount,method:'wallet',provider:'internal_credit',status:'paid',createdAt:FieldValue.serverTimestamp(),
    });
    products.forEach((product,index) => transaction.update(product.ref,{stock:product.data().stock-items[index].quantity}));
    return {orderId:orderRef.id};
  });
});
