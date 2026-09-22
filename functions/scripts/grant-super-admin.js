const {initializeApp, applicationDefault} = require('firebase-admin/app');
const {getAuth} = require('firebase-admin/auth');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');
async function main() {
  const [projectId, uid, expectedEmail] = process.argv.slice(2);
  if (!projectId || !uid || !expectedEmail) throw new Error('Usage: node scripts/grant-super-admin.js PROJECT UID VERIFIED_EMAIL');
  initializeApp({credential:applicationDefault(),projectId});
  const auth = getAuth();
  const account = await auth.getUser(uid);
  if (account.disabled || !account.emailVerified || account.email !== expectedEmail ||
      !account.providerData.some(provider => provider.providerId === 'password')) {
    throw new Error('Requires an enabled account with a matching verified email and password provider.');
  }
  await auth.setCustomUserClaims(uid,{...account.customClaims,role:'superAdmin'});
  await getFirestore().collection('users').doc(uid).set({
    role:'superAdmin',active:true,name:account.displayName || 'Azharna Admin',
    updatedAt:FieldValue.serverTimestamp(),
  },{merge:true});
  await auth.revokeRefreshTokens(uid);
  console.log('Role granted. Sign in again and enroll TOTP; administrative access requires MFA.');
}
main().catch(error => {console.error(error.message);process.exitCode=1;});
