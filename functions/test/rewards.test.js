const {test,before,after,beforeEach}=require('node:test');
const assert=require('node:assert/strict');
const {initializeApp,deleteApp}=require('firebase-admin/app');
const {getFirestore}=require('firebase-admin/firestore');
let app,db,rewards,checkout;
const uid='customer';
before(()=>{if(!process.env.FIRESTORE_EMULATOR_HOST)throw Error('Emulator required');app=initializeApp({projectId:'demo-azharna'});db=getFirestore();rewards=require('../rewards');checkout=require('../orders').createCashOrder;});
after(async()=>{await deleteApp(app);});
beforeEach(async()=>{
  for(const name of ['orders','users','products','stores','paymentTransactions'])await db.recursiveDelete(db.collection(name));
  await db.doc('users/customer').set({role:'customer',active:true});
  await db.doc('users/admin').set({role:'superAdmin',active:true});
  await db.doc('stores/shop').set({active:true});
  await db.doc('products/rose').set({active:true,approvalStatus:'approved',price:100000,stock:10,storeId:'shop',name:'Rose'});
});
const order=(extra={})=>({auth:{uid},data:{requestId:'order_request_123456',items:[{productId:'rose',quantity:1}],address:'Baghdad',expectedTotal:105000,...extra}});
const balance=async()=>(await db.doc('users/customer/account/benefits').get()).data();
test('delivered orders earn once, then points redeem into a usable coupon',async()=>{
 const {orderId}=await checkout.run(order());
 await rewards.settle(orderId,db);assert.equal(await balance(),undefined);
 await db.doc(`orders/${orderId}`).update({status:'delivered'});
 await Promise.all([rewards.settle(orderId,db),rewards.settle(orderId,db)]);
 assert.equal((await balance()).points,100);
 const req={auth:{uid},data:{requestId:'redeem_request_123456'}};
 await rewards.redeemRewardPoints.run(req);await rewards.redeemRewardPoints.run(req);
 assert.equal((await balance()).points,0);assert.equal((await balance()).coupons.length,1);
 const couponId=(await balance()).coupons[0].id;
 const second=await checkout.run(order({requestId:'second_order_123456',couponId,expectedTotal:104000}));
 assert.equal((await db.doc(`orders/${second.orderId}`).get()).data().discount,1000);
 assert.equal((await balance()).coupons.length,0);
 await assert.rejects(checkout.run(order({requestId:'third_order_1234567',couponId,expectedTotal:104000})),{code:'failed-precondition'});
});
test('concurrent redemptions cannot spend the same points twice',async()=>{
 await db.doc('users/customer/account/benefits').set({points:100,lifetimePoints:500,balance:0});
 const results=await Promise.allSettled(['redeem_request_11111','redeem_request_22222'].map(requestId=>rewards.redeemRewardPoints.run({auth:{uid},data:{requestId}})));
 assert.equal(results.filter(r=>r.status==='fulfilled').length,1);assert.equal((await balance()).membership,'فضية');
});
test('wallet credit requires admin MFA and retries never double-credit',async()=>{
 const data={customerId:uid,amount:5000,reason:'Cash received',requestId:'credit_request_123456'};
 await assert.rejects(rewards.creditCustomerWallet.run({auth:{uid,token:{}},data}),{code:'permission-denied'});
 const auth={uid:'admin',token:{role:'superAdmin',firebase:{sign_in_second_factor:'totp'}}};
 await rewards.creditCustomerWallet.run({auth,data});await rewards.creditCustomerWallet.run({auth,data});
 assert.equal((await balance()).balance,5000);
 await assert.rejects(rewards.creditCustomerWallet.run({auth,data:{...data,amount:6000}}),{code:'already-exists'});
});
test('concurrent orders cannot overspend wallet; cancelled order restores it once',async()=>{
 await db.doc('users/customer/account/benefits').set({balance:5000});
 const results=await Promise.allSettled(['wallet_order_111111','wallet_order_222222'].map(requestId=>checkout.run(order({requestId,walletAmount:5000}))));
 assert.equal(results.filter(r=>r.status==='fulfilled').length,1);assert.equal((await balance()).balance,0);
 const id=results.find(r=>r.status==='fulfilled').value.orderId;
 assert.equal((await db.doc(`orders/${id}`).get()).data().cashDue,100000);
 await db.doc(`orders/${id}`).update({status:'cancelled'});await rewards.settle(id,db);await rewards.settle(id,db);
 assert.equal((await balance()).balance,5000);
 assert.equal((await db.doc(`paymentTransactions/${id}_wallet`).get()).data().status,'refunded');
});
test('sync counts historical delivered orders once and upgrades membership',async()=>{
 await db.doc('orders/history').set({customerId:uid,status:'delivered',subtotal:1500000});
 await rewards.syncRewardPoints.run({auth:{uid},data:{}});await rewards.syncRewardPoints.run({auth:{uid},data:{}});
 assert.equal((await balance()).points,1500);assert.equal((await balance()).membership,'ذهبية');
});
