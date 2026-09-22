const path = require('node:path');
const auth = require(path.join(process.env.APPDATA, 'npm/node_modules/firebase-tools/lib/auth.js'));
async function main() {
  const account = auth.getGlobalDefaultAccount();
  if (!account) throw new Error('Firebase login required');
  const token = await auth.getAccessToken(account.tokens.refresh_token, account.tokens.scopes);
  const headers = {Authorization: `Bearer ${token.access_token}`};
  const base = 'https://firestore.googleapis.com/v1/projects/azharna-production/databases/(default)/documents';
  for (const collection of ['products', 'stores']) {
    const response = await fetch(`${base}/${collection}?pageSize=100`, {headers});
    if (!response.ok) throw new Error(`${collection}: HTTP ${response.status}`);
    const data = await response.json();
    console.log(JSON.stringify({collection, more: !!data.nextPageToken, documents: (data.documents || []).map(d => ({id:d.name.split('/').pop(), fields:Object.fromEntries(Object.entries(d.fields || {}).filter(([k]) => ['name','storeId','active','price','category','imageUrl','imageUrls'].includes(k)))}))}));
  }
  const response = await fetch('https://storage.googleapis.com/storage/v1/b/azharna-production.firebasestorage.app/o?maxResults=1', {headers});
  console.log(JSON.stringify({storageStatus:response.status}));
  const buckets = await fetch('https://storage.googleapis.com/storage/v1/b?project=azharna-production', {headers});
  const bucketData = await buckets.json();
  console.log(JSON.stringify({bucketListStatus:buckets.status, buckets:(bucketData.items || []).map(b=>({name:b.name,location:b.location})), error:bucketData.error?.message}));
  const billing = await fetch('https://cloudbilling.googleapis.com/v1/projects/azharna-production/billingInfo', {headers});
  const billingData = await billing.json();
  console.log(JSON.stringify({billingStatus:billing.status,billingEnabled:billingData.billingEnabled,error:billingData.error?.message}));
}
main().catch(e => { console.error(e.message); process.exitCode=1; });
