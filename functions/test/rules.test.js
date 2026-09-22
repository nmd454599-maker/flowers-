const {before, after, beforeEach, test} = require('node:test');
const {readFileSync} = require('node:fs');
const {initializeTestEnvironment, assertFails, assertSucceeds} = require('@firebase/rules-unit-testing');
const {doc, setDoc, getDoc, getDocs, collection, query, where, updateDoc, deleteDoc, serverTimestamp} = require('firebase/firestore');
const {ref, uploadBytes, deleteObject} = require('firebase/storage');
let env;
test('store owner may change photo only; customers, other stores and blocked owners cannot', async () => {
  await env.withSecurityRulesDisabled(async context => {
    await setDoc(doc(context.firestore(), 'stores', 'shop'), {active: false, name: 'Shop'});
    await setDoc(doc(context.firestore(), 'stores', 'another'), {active: true, name: 'Another'});
  });
  const image = {photoUrl: 'https://example.test/store.png', updatedAt: serverTimestamp()};
  await assertSucceeds(getDoc(doc(user('merchant').firestore(), 'stores', 'shop')));
  await assertSucceeds(updateDoc(doc(user('merchant').firestore(), 'stores', 'shop'), image));
  await assertFails(updateDoc(doc(user('merchant').firestore(), 'stores', 'another'), image));
  await assertFails(updateDoc(doc(user('customer').firestore(), 'stores', 'shop'), image));
  await assertFails(updateDoc(doc(user('blocked').firestore(), 'stores', 'shop'), image));
  await assertFails(updateDoc(doc(user('merchant').firestore(), 'stores', 'shop'), {...image, active: true}));
  await assertFails(updateDoc(doc(user('merchant').firestore(), 'stores', 'shop'), {...image, name: 'Changed'}));
});
const adminClaims = {role: 'superAdmin', firebase: {sign_in_second_factor: 'totp'}};
const user = (uid, claims = {}) => env.authenticatedContext(uid, claims);
test('public store reviews protect customer authorship and store access', async () => {
  await env.withSecurityRulesDisabled(async context => {
    await setDoc(doc(context.firestore(),'stores','shop'), {active:true});
    await setDoc(doc(context.firestore(),'stores','hidden'), {active:false});
  });
  const review = {storeId:'shop',customerId:'customer',customerName:'',rating:5,comment:'Nice flowers',createdAt:'2026-09-13'};
  const path = ['stores','shop','reviews','customer'];
  await assertSucceeds(setDoc(doc(user('customer').firestore(),...path), review));
  await assertSucceeds(getDoc(doc(env.unauthenticatedContext().firestore(),...path)));
  await assertSucceeds(updateDoc(doc(user('customer').firestore(),...path), {rating:4,comment:'Updated'}));
  await assertFails(setDoc(doc(user('other').firestore(),...path), review));
  await assertFails(setDoc(doc(user('merchant').firestore(),'stores','shop','reviews','merchant'), {...review,customerId:'merchant'}));
  await assertFails(updateDoc(doc(user('customer').firestore(),...path), {rating:6}));
  await assertFails(updateDoc(doc(user('customer').firestore(),...path), {customerName:'Impersonated'}));
  await assertFails(setDoc(doc(user('customer').firestore(),'stores','hidden','reviews','customer'), {...review,storeId:'hidden'}));
});
test('direct store messages are visible only to their customer and store', async () => {
  await env.withSecurityRulesDisabled(async context => {
    await setDoc(doc(context.firestore(),'stores','shop'), {active:true});
    await setDoc(doc(context.firestore(),'stores','another'), {active:true});
  });
  const message = {storeId:'shop',storeName:'Shop',customerId:'customer',customerName:'Customer',threadId:'shop-customer',senderId:'customer',text:'Hello',createdAt:'2026-09-13'};
  const path = ['storeDirectMessages','first'];
  await assertSucceeds(setDoc(doc(user('customer').firestore(),...path), message));
  await assertSucceeds(getDoc(doc(user('merchant').firestore(),...path)));
  await assertSucceeds(getDocs(query(collection(user('merchant').firestore(),'storeDirectMessages'),where('storeId','==','shop'))));
  await assertSucceeds(getDocs(query(collection(user('customer').firestore(),'storeDirectMessages'),where('customerId','==','customer'))));
  await assertFails(getDocs(collection(user('customer').firestore(),'storeDirectMessages')));
  await assertFails(getDoc(doc(user('other').firestore(),...path)));
  await assertFails(getDoc(doc(user('blocked').firestore(),...path)));
  await assertSucceeds(setDoc(doc(user('merchant').firestore(),'storeDirectMessages','reply'), {...message,senderId:'merchant'}));
  await assertFails(setDoc(doc(user('other').firestore(),'storeDirectMessages','spoof'), {...message,senderId:'other'}));
  await assertFails(setDoc(doc(user('merchant').firestore(),'storeDirectMessages','wrong-store'), {...message,senderId:'merchant',storeId:'another'}));
  await assertFails(updateDoc(doc(user('customer').firestore(),...path), {text:'Changed'}));
  const imagePath = ['storeDirectMessages', 'with-image'];
  await assertSucceeds(setDoc(doc(user('customer').firestore(), ...imagePath),
      {...message, image:'data:image/png;base64,aGVsbG8='}));
  await assertSucceeds(getDoc(doc(user('merchant').firestore(), ...imagePath)));
  await assertFails(getDoc(doc(user('other').firestore(), ...imagePath)));
  await assertFails(setDoc(doc(user('customer').firestore(), 'storeDirectMessages', 'oversized-image'),
      {...message, image:'data:image/png;base64,' + 'a'.repeat(700001)}));
  await assertFails(setDoc(doc(user('customer').firestore(), 'storeDirectMessages', 'invalid-image'),
      {...message, image:'data:text/html;base64,aGVsbG8='}));
});
test('store videos and public profiles enforce owner and media limits', async () => {
  await env.withSecurityRulesDisabled(async context => {
    await setDoc(doc(context.firestore(), 'stores', 'shop'), {active: true});
    await setDoc(doc(context.firestore(), 'stores', 'another'), {active: true});
  });
  const video = {storeId:'shop', title:'Our flowers', url:'https://firebasestorage.googleapis.com/video.mp4',
    durationMs:12000, createdAt:'2026-09-13T00:00:00.000Z', extension:'mp4', active:true, thumbnail:''};
  const path = ['stores', 'shop', 'videos', 'clip'];
  await assertSucceeds(setDoc(doc(user('merchant').firestore(), ...path), video));
  await assertSucceeds(getDoc(doc(user('customer').firestore(), ...path)));
  await assertFails(setDoc(doc(user('customer').firestore(), ...path), video));
  await assertFails(setDoc(doc(user('blocked').firestore(), 'stores','shop','videos','blocked'), video));
  await assertFails(setDoc(doc(user('merchant').firestore(), 'stores','another','videos','clip'), {...video,storeId:'another'}));
  await assertFails(setDoc(doc(user('merchant').firestore(), 'stores','shop','videos','long'), {...video,durationMs:180001}));
  await assertFails(deleteDoc(doc(user('customer').firestore(), ...path)));
  await assertSucceeds(deleteDoc(doc(user('merchant').firestore(), ...path)));
  const profile = {description:'Store bio',address:'Baghdad',hours:'9–5',phone:'07700000000'};
  await assertSucceeds(setDoc(doc(user('merchant').firestore(),'storeProfiles','shop'),profile));
  await assertFails(setDoc(doc(user('merchant').firestore(),'storeProfiles','another'),profile));
  await assertFails(setDoc(doc(user('customer').firestore(),'storeProfiles','shop'),profile));
  await assertSucceeds(getDoc(doc(user('customer').firestore(),'storeProfiles','shop')));
  const bytes = new Uint8Array([0,0,0,12,102,116,121,112,109,112,52,50]);
  const media = ref(user('merchant').storage(), 'store-videos/shop/test.mp4');
  await assertSucceeds(uploadBytes(media, bytes, {contentType:'video/mp4'}));
  await assertFails(uploadBytes(ref(user('customer').storage(),'store-videos/shop/customer.mp4'),bytes,{contentType:'video/mp4'}));
  await assertFails(uploadBytes(ref(user('merchant').storage(),'store-videos/another/clip.mp4'),bytes,{contentType:'video/mp4'}));
  await assertFails(uploadBytes(ref(user('merchant').storage(),'store-videos/shop/invalid.txt'),bytes,{contentType:'text/plain'}));
  await assertSucceeds(deleteObject(media));
});
before(async () => { env = await initializeTestEnvironment({
  projectId: 'demo-azharna',
  firestore: {rules: readFileSync('../firestore.rules', 'utf8')},
  storage: {rules: readFileSync('../storage.rules', 'utf8')},
}); });
after(async () => { if (env) await env.cleanup(); });
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async context => {
    const db = context.firestore();
    for (const [id, data] of Object.entries({
      customer: {role:'customer', active:true},
      other: {role:'customer', active:true},
      courier: {role:'courier',active:true},
      courier2: {role:'courier',active:true},
      merchant: {role:'store', active:true, storeId:'shop'},
      blocked: {role:'store', active:false, storeId:'shop'},
      admin: {role:'superAdmin', active:true},
    })) await setDoc(doc(db, 'users', id), data);
    await setDoc(doc(db,'orders','order'), {customerId:'customer', storeIds:['shop'],status:'preparing',assignedCourierId:'courier'});
    await setDoc(doc(db,'adminData','security'), {enabled:true});
  });
});
test('new account cannot assign its own store', async () => {
  await assertFails(setDoc(doc(user('attacker').firestore(),'users','attacker'),
    {role:'store',active:true,storeId:'shop'}));
});
test('new customer may create a minimal profile', async () => {
  await assertSucceeds(setDoc(doc(user('new').firestore(),'users','new'),{role:'customer',active:true,name:'Customer'}));
});
test('profile cannot escalate role or reactivate a blocked account', async () => {
  await assertFails(updateDoc(doc(user('customer').firestore(),'users','customer'),{role:'superAdmin'}));
  await assertFails(updateDoc(doc(user('blocked').firestore(),'users','blocked'),{active:true}));
});
test('admin document alone and claim without MFA grant no admin access', async () => {
  await assertFails(getDoc(doc(user('admin').firestore(),'adminData','security')));
  await assertFails(getDoc(doc(user('admin',{role:'superAdmin'}).firestore(),'adminData','security')));
  await assertSucceeds(getDoc(doc(user('admin',adminClaims).firestore(),'adminData','security')));
});
test('unrelated customer and blocked store cannot read the order', async () => {
  await assertFails(getDoc(doc(user('other').firestore(),'orders','order')));
  await assertFails(getDoc(doc(user('blocked').firestore(),'orders','order')));
  await assertSucceeds(getDoc(doc(user('merchant').firestore(),'orders','order')));
});
test('customer, store, and MFA support may send messages', async () => {
  for(const [uid,claims] of [['customer',{}],['merchant',{}],['admin',adminClaims]]) {
    await assertSucceeds(setDoc(doc(user(uid,claims).firestore(),'orders','order','messages',uid),
      {senderId:uid,text:'Hello',createdAt:serverTimestamp()}));
  }
});
test('messages deny outsiders, forged senders and edits', async () => {
  const db = user('customer').firestore();
  await assertFails(setDoc(doc(user('other').firestore(),'orders','order','messages','x'),
    {senderId:'other',text:'Hello',createdAt:serverTimestamp()}));
  await assertFails(setDoc(doc(db,'orders','order','messages','x'),
    {senderId:'admin',text:'Hello',createdAt:serverTimestamp()}));
  await assertSucceeds(setDoc(doc(db,'orders','order','messages','x'),
    {senderId:'customer',text:'Hello',createdAt:serverTimestamp()}));
  await assertFails(updateDoc(doc(db,'orders','order','messages','x'),{text:'Changed'}));
  await assertFails(getDoc(doc(user('other').firestore(),'orders','order','messages','x')));
});
test('product images require active store ownership and image content type', async () => {
  const data = new Uint8Array([1,2,3]);
  await assertSucceeds(uploadBytes(ref(user('merchant').storage(),'products/shop/test.png'),data,{contentType:'image/png'}));
  await assertFails(uploadBytes(ref(user('merchant').storage(),'products/another/test.png'),data,{contentType:'image/png'}));
  await assertFails(uploadBytes(ref(user('blocked').storage(),'products/shop/test.png'),data,{contentType:'image/png'}));
  await assertFails(uploadBytes(ref(user('merchant').storage(),'products/shop/test.html'),data,{contentType:'text/html'}));
});

test('courier sees only assigned orders and follows delivery transitions', async () => {
  const db = user('courier',{role:'courier'}).firestore();
  await assertSucceeds(getDoc(doc(db,'orders','order')));
  await assertFails(getDoc(doc(user('courier2',{role:'courier'}).firestore(),'orders','order')));
  await assertFails(updateDoc(doc(db,'orders','order'),{status:'delivered',updatedAt:serverTimestamp()}));
  await assertSucceeds(updateDoc(doc(db,'orders','order'),{status:'delivering',updatedAt:serverTimestamp()}));
  await assertSucceeds(updateDoc(doc(db,'orders','order'),{status:'delivered',updatedAt:serverTimestamp()}));
  await assertFails(updateDoc(doc(db,'orders','order'),{total:1}));
});

test('store products enter review and cannot self-publish', async () => {
  const pending = {
    storeId: 'shop', name: 'Flowers', category: 'flowers', price: 100,
    emoji: 'flower', rating: 0, description: '', imageUrl: null, stock: 2,
    approvalStatus: 'pending', active: false, updatedAt: serverTimestamp(),
  };
  await assertSucceeds(setDoc(doc(user('merchant').firestore(), 'products', 'pending'), pending));
  await assertFails(setDoc(doc(user('merchant').firestore(), 'products', 'published'),
    {...pending, approvalStatus: 'approved', active: true}));
  await assertFails(setDoc(doc(user('customer').firestore(), 'products', 'forged'), pending));
});

test('store submits its own application and only approved applications are public', async () => {
  const path = ['adminData', 'store_applications', 'records'];
  const pending = {ownerId: 'merchant', status: 'pending', name: 'Shop'};
  await assertSucceeds(setDoc(doc(user('merchant').firestore(), ...path, 'merchant'), pending));
  await assertFails(setDoc(doc(user('merchant').firestore(), ...path, 'another'), pending));
  await assertFails(getDoc(doc(user('customer').firestore(), ...path, 'merchant')));
  await assertSucceeds(updateDoc(doc(user('admin',adminClaims).firestore(), ...path, 'merchant'),
    {status: 'approved'}));
  await assertSucceeds(getDoc(doc(user('customer').firestore(), ...path, 'merchant')));
});
test('clients cannot bypass server checkout or forge payment records', async () => {
  await assertFails(setDoc(doc(user('customer').firestore(),'orders','forged'),
    {customerId:'customer',status:'newOrder',paymentMethod:'cash',paymentStatus:'pending',items:[{}],total:1}));
  await assertFails(setDoc(doc(user('customer').firestore(),'paymentTransactions','forged'),
    {customerId:'customer',status:'pending',method:'cash',amount:1}));
});

test('merchant status changes follow sequence and cannot reopen terminal orders', async () => {
  const db = user('merchant').firestore();
  await assertFails(updateDoc(doc(db,'orders','order'),{status:'delivered',updatedAt:serverTimestamp()}));
  await assertFails(updateDoc(doc(db,'orders','order'),{status:'newOrder',updatedAt:serverTimestamp()}));
  await assertFails(updateDoc(doc(db,'orders','order'),{status:'cancelled',updatedAt:serverTimestamp()}));
  await assertFails(updateDoc(doc(db,'orders','order'),{status:'delivering'}));
  await assertSucceeds(updateDoc(doc(db,'orders','order'),{status:'delivering',updatedAt:serverTimestamp()}));
  await assertSucceeds(updateDoc(doc(db,'orders','order'),{status:'delivered',updatedAt:serverTimestamp()}));
  await assertFails(updateDoc(doc(db,'orders','order'),{status:'preparing',updatedAt:serverTimestamp()}));
});

test('admin cannot bypass normal order sequence with a direct document update', async () => {
  const db = user('admin',adminClaims).firestore();
  await assertFails(updateDoc(doc(db,'orders','order'),{status:'delivered',updatedAt:serverTimestamp()}));
  await assertFails(updateDoc(doc(db,'orders','order'),{status:'cancelled',updatedAt:serverTimestamp()}));
  await assertSucceeds(updateDoc(doc(db,'orders','order'),{status:'delivering',updatedAt:serverTimestamp()}));
});

test('customer account data is private and financial benefits are server managed', async () => {
  const path = ['users', 'customer', 'account', 'profile'];
  await assertSucceeds(setDoc(doc(user('customer').firestore(), ...path), {ownerId: 'customer', name: 'New name'}));
  await assertSucceeds(getDoc(doc(user('customer').firestore(), ...path)));
  await assertFails(getDoc(doc(user('other').firestore(), ...path)));
  await assertFails(setDoc(doc(user('other').firestore(), ...path), {ownerId: 'customer', name: 'Attack'}));
  await assertFails(setDoc(doc(user('customer').firestore(), 'users/customer/account/benefits'), {ownerId: 'customer', balance: 1000}));
  await assertFails(setDoc(doc(user('blocked').firestore(), 'users/blocked/account/addresses'), {ownerId: 'blocked', items: []}));
  await assertSucceeds(setDoc(doc(user('customer').firestore(), 'users/customer/account/addresses'), {ownerId: 'customer', items: []}));
});

test('customer requests reach admins without exposing them to other customers', async () => {
  await env.withSecurityRulesDisabled(async context => {
    await updateDoc(doc(context.firestore(), 'users/customer'), {phone: '07701234567'});
  });
  const path = ['customerRequests', 'request1'];
  const data = {ownerId: 'customer', name: 'Customer', phone: '07701234567', kind: 'support',
    fields: {subject: 'Help'}, status: 'pending', createdAt: '2026-09-14'};
  await assertSucceeds(setDoc(doc(user('customer').firestore(), ...path), data));
  await assertSucceeds(getDocs(query(collection(user('customer').firestore(), 'customerRequests'), where('ownerId', '==', 'customer'))));
  await assertFails(getDoc(doc(user('other').firestore(), ...path)));
  await assertFails(updateDoc(doc(user('customer').firestore(), ...path), {status: 'approved'}));
  await assertSucceeds(updateDoc(doc(user('admin', adminClaims).firestore(), ...path), {reply: 'Reply', status: 'replied'}));
  await assertSucceeds(getDoc(doc(user('customer').firestore(), ...path)));
});
