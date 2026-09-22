const {spawnSync} = require('node:child_process');
for (const args of [
  ['--test', '--test-name-pattern=customer account data|customer requests', 'test/rules.test.js'],
  ['--test', 'test/account-deletion.test.js'],
]) {
  const result = spawnSync(process.execPath, args, {stdio: 'inherit'});
  if (result.status !== 0) process.exit(result.status ?? 1);
}
