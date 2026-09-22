'use strict';
const {onCall,HttpsError} = require('firebase-functions/v2/https');
const {onDocumentUpdated} = require('firebase-functions/v2/firestore');
const {getFirestore,FieldValue} = require('firebase-admin/firestore');
const tier = total => total >= 1500 ? 'ذهبية' : total >= 500 ? 'فضية' : 'أساسية';
const integer = v => Number.isSafeInteger(v) && v >= 0;
function account(data = {}) {
  const value = {...data, points:data.points ?? 0, lifetimePoints:data.lifetimePoints ?? 0, balance:data.balance ?? 0,
    coupons:data.coupons ?? [], transactions:data.transactions ?? []};
  if (![value.points,value.lifetimePoints,value.balance].every(integer) || !Array.isArray(value.coupons) || !Array.isArray(value.transactions)) throw new HttpsError('failed-precondition','Invalid account balance');
  return value;
}
function log(a,type,description,amount=0,points=0,orderId=null) {
  a.transactions = [{type,description,amount,points,orderId,createdAt:new Date().toISOString()},...a.transactions].slice(0,100);
  a.membership = tier(a.lifetimePoints);
}
function purchase(a,{subtotal,deliveryFee,couponId,walletAmount,orderId}) {
  if (!integer(walletAmount)) throw new HttpsError('invalid-argument','Invalid wallet amount');
  const coupon = couponId ? a.coupons.find(c=>c.id===couponId) : null;
  if (couponId && (!coupon || coupon.value !== 1000 || subtotal < 1000)) throw new HttpsError('failed-precondition','Coupon unavailable');
  const discount = coupon ? 1000 : 0;
  const total = subtotal + deliveryFee - discount;
  if (walletAmount > Math.min(a.balance,total)) throw new HttpsError('failed-precondition','Wallet balance changed');
  a.balance -= walletAmount;
  if (coupon) { a.coupons = a.coupons.filter(c=>c.id!==couponId); log(a,'coupon','استخدام كوبون خصم',-discount,0,orderId); }
  if (walletAmount) log(a,'debit','خصم من المحفظة للطلب',-walletAmount,0,orderId);
  return {discount,total,cashDue:total-walletAmount};
}
function requestId(data) {
  if (typeof data.requestId !== 'string' || !/^[A-Za-z0-9_-]{16,80}$/.test(data.requestId)) throw new HttpsError('invalid-argument','Invalid request ID');
  return data.requestId;
}
exports.redeemRewardPoints = onCall({enforceAppCheck:true},async request=>{
  if (!request.auth) throw new HttpsError('unauthenticated','Sign in');
  const id=requestId(request.data||{}), uid=request.auth.uid, db=getFirestore();
  const ref=db.doc(`users/${uid}/account/benefits`), marker=db.doc(`users/${uid}/rewardActions/redeem_${id}`);
  return db.runTransaction(async tx=>{
    const [profile,done,snapshot]=await tx.getAll(db.doc(`users/${uid}`),marker,ref);
    if (profile.data()?.role!=='customer' || profile.data()?.active!==true || profile.data()?.deletionRequested) throw new HttpsError('permission-denied','Active customer required');
    if(done.exists) return done.data();
    const a=account(snapshot.data());
    if(a.points<100) throw new HttpsError('failed-precondition','تحتاج إلى 100 نقطة للاستبدال');
    if(a.coupons.length>=50) throw new HttpsError('failed-precondition','استخدم أحد كوبوناتك أولًا');
    a.points-=100;
    a.coupons.push({id,code:id,value:1000});
    log(a,'redeem','استبدال 100 نقطة بكوبون 1,000 د.ع',0,-100);
    tx.set(ref,{...a,ownerId:uid}); tx.create(marker,{couponId:id});
    return {couponId:id};
  });
});
exports.creditCustomerWallet=onCall({enforceAppCheck:true},async request=>{
  const auth=request.auth,data=request.data||{};
  if(!auth) throw new HttpsError('unauthenticated','Sign in');
  const id=requestId(data);
  if(auth.token.role!=='superAdmin'||!auth.token.firebase?.sign_in_second_factor) throw new HttpsError('permission-denied','Admin MFA required');
  if(typeof data.customerId!=='string'||!data.customerId||data.customerId.includes('/')||!Number.isSafeInteger(data.amount)||data.amount<=0||data.amount>100000000||typeof data.reason!=='string'||!data.reason.trim()||data.reason.length>300) throw new HttpsError('invalid-argument','Invalid credit');
  const db=getFirestore(),uid=data.customerId,ref=db.doc(`users/${uid}/account/benefits`),marker=db.doc(`users/${uid}/rewardActions/credit_${auth.uid}_${id}`);
  return db.runTransaction(async tx=>{
    const [admin,customer,done,snapshot]=await tx.getAll(db.doc(`users/${auth.uid}`),db.doc(`users/${uid}`),marker,ref);
    if(admin.data()?.role!=='superAdmin'||admin.data()?.active!==true||customer.data()?.role!=='customer'||customer.data()?.active!==true||customer.data()?.deletionRequested) throw new HttpsError('permission-denied','Account unavailable');
    if(done.exists) {
      if(done.data().amount!==data.amount || done.data().reason!==data.reason.trim()) throw new HttpsError('already-exists','Request already used');
      return {credited:true};
    }
    const a=account(snapshot.data());
    if(a.balance+data.amount>100000000) throw new HttpsError('failed-precondition','Balance limit');
    a.balance+=data.amount; log(a,'credit',`${data.reason.trim()} • الإدارة: ${auth.uid}`,data.amount);
    tx.set(ref,{...a,ownerId:uid}); tx.create(marker,{amount:data.amount,reason:data.reason.trim(),actor:auth.uid,createdAt:FieldValue.serverTimestamp()});
    return {credited:true};
  });
});
async function settle(orderId,db=getFirestore()) {
  return db.runTransaction(async tx=>{
    const orderRef=db.doc(`orders/${orderId}`),snap=await tx.get(orderRef),o=snap.data();
    if(!o||!['delivered','cancelled'].includes(o.status)||typeof o.customerId!=='string'||o.customerId==='deleted') return;
    const ref=db.doc(`users/${o.customerId}/account/benefits`);
    const walletRef=db.doc(`paymentTransactions/${orderId}_wallet`);
    const [profile,snapshot,walletPayment]=await tx.getAll(db.doc(`users/${o.customerId}`),ref,walletRef);
    if(!profile.exists) return;
    const a=account(snapshot.data());
    if(o.status==='delivered'&&!o.rewardsGranted) {
      const points=Math.floor(Math.max(0,o.subtotal-(o.discount||0))/1000);
      if(!integer(points)) throw new Error('Invalid subtotal');
      a.points+=points;a.lifetimePoints+=points;
      log(a,'earned','نقاط طلب تم تسليمه',0,points,orderId);
      tx.set(ref,{...a,ownerId:o.customerId});tx.update(orderRef,{rewardsGranted:true});
    }
    if(o.status==='cancelled'&&!o.benefitsRestored&&!o.rewardsGranted) {
      const wallet=o.walletUsed||0;
      a.balance+=wallet;
      if(walletPayment.exists)tx.update(walletRef,{status:'refunded'});
      if(wallet) log(a,'credit','إرجاع رصيد طلب ملغى',wallet,0,orderId);
      if(o.couponId&&!a.coupons.some(c=>c.id===o.couponId)) a.coupons.push({id:o.couponId,code:o.couponId,value:1000});
      tx.set(ref,{...a,ownerId:o.customerId});tx.update(orderRef,{benefitsRestored:true});
    }
  });
}
exports.settleOrderRewards=onDocumentUpdated('orders/{orderId}',async event=>{if(event.data.before.data().status!==event.data.after.data().status) await settle(event.params.orderId);});
exports.account=account;exports.purchase=purchase;exports.settle=settle;exports.tier=tier;

exports.syncRewardPoints=onCall({enforceAppCheck:true},async request=>{
  if(!request.auth)throw new HttpsError('unauthenticated','Sign in');
  const uid=request.auth.uid,db=getFirestore(),profile=await db.doc(`users/${uid}`).get();
  if(profile.data()?.role!=='customer'||profile.data()?.active!==true)throw new HttpsError('permission-denied','Active customer required');
  let query=db.collection('orders').where('customerId','==',uid).orderBy('__name__').limit(100);
  const cursor=request.data?.cursor;
  if(cursor!=null){if(typeof cursor!=='string'||!cursor||cursor.includes('/'))throw new HttpsError('invalid-argument','Invalid cursor');query=query.startAfter(db.doc(`orders/${cursor}`));}
  const docs=await query.get();
  for(const order of docs.docs)if(order.data().status==='delivered'&&!order.data().rewardsGranted)await settle(order.id,db);
  return {cursor:docs.size===100?docs.docs.at(-1).id:null};
});
