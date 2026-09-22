const {test,before,after,beforeEach} = require('node:test');
const assert = require('node:assert/strict');
const {initializeApp,deleteApp} = require('firebase-admin/app');
const {getFirestore} = require('firebase-admin/firestore');
let app,db,checkout;
before(() => {
  if (!process.env.FIRESTORE_EMULATOR_HOST) throw new Error('Emulator required');
  app=initializeApp({projectId:'demo-azharna'});db=getFirestore();
  checkout=require('../orders').createCashOrder;
});
after(async () => {await deleteApp(app);});
beforeEach(async () => {
  for (const name of ['orders','users','products','stores','paymentTransactions']) {
    await db.recursiveDelete(db.collection(name));
  }
  await db.doc('users/customer').set({role:'customer',active:true});
  await db.doc('stores/shop').set({active:true});
  await db.doc('products/rose').set({active:true,approvalStatus:'approved',price:10000,stock:2,storeId:'shop',name:'Rose'});
});
const request = (data = {}) => ({auth:{uid:'customer'},data:{
  requestId:'request_123456789',items:[{productId:'rose',quantity:1}],address:'Baghdad',expectedTotal:15000,...data,
}});
test('server sets totals and retry creates one order and one reservation', async () => {
  const first=await checkout.run(request());
  const retry=await checkout.run(request());
  assert.equal(first.orderId,retry.orderId);
  assert.equal((await db.doc(`orders/${first.orderId}`).get()).data().total,15000);
  assert.equal((await db.doc('products/rose').get()).data().stock,1);
  assert.equal((await db.collection('paymentTransactions').get()).size,1);
});
test('stale total and invalid quantity do not reserve stock', async () => {
  await assert.rejects(checkout.run(request({expectedTotal:1})),{code:'failed-precondition'});
  await assert.rejects(checkout.run(request({items:[{productId:'rose',quantity:-1}]})),{code:'invalid-argument'});
  assert.equal((await db.doc('products/rose').get()).data().stock,2);
});
test('concurrent checkouts cannot oversell inventory', async () => {
  const results=await Promise.allSettled([
    checkout.run(request({requestId:'request_concurrent1',items:[{productId:'rose',quantity:2}],expectedTotal:25000})),
    checkout.run(request({requestId:'request_concurrent2',items:[{productId:'rose',quantity:2}],expectedTotal:25000})),
  ]);
  assert.equal(results.filter(item=>item.status==='fulfilled').length,1);
  assert.equal((await db.doc('products/rose').get()).data().stock,0);
});
