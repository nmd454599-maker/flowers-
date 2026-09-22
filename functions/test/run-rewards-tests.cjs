const {spawnSync}=require('node:child_process');
const result=spawnSync(process.execPath,['--test','--test-concurrency=1','test/rewards.test.js','test/orders.test.js','test/account-deletion.test.js'],{stdio:'inherit'});
process.exit(result.status??1);
