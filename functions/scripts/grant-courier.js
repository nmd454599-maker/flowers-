const {initializeApp,applicationDefault} = require('firebase-admin/app');
const {getAuth} = require('firebase-admin/auth');
const {getFirestore,FieldValue} = require('firebase-admin/firestore');
async function main() {
  const [projectId,uid,phone] = process.argv.slice(2);
  if (!projectId || !uid || !phone) throw new Error('Usage: node scripts/grant-courier.js PROJECT UID PHONE_E164');
  initializeApp({credential:applicationDefault(),projectId});
  const auth=getAuth(), user=await auth.getUser(uid);
  if(user.disabled || user.phoneNumber!==phone || ['admin','superAdmin'].includes(user.customClaims?.role)) throw new Error('Enabled phone account required; cannot replace an admin role');
  await auth.setCustomUserClaims(uid,{...user.customClaims,role:'courier'});
  await getFirestore().collection('users').doc(uid).set({role:'courier',active:true,phone,updatedAt:FieldValue.serverTimestamp()},{merge:true});
  await auth.revokeRefreshTokens(uid);
  console.log('Courier granted. Sign in again to refresh claims.');
}
main().catch(error=>{console.error(error.message);process.exitCode=1;});
