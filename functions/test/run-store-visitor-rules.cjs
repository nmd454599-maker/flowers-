const {spawnSync} = require('node:child_process');
const result = spawnSync(process.execPath, [
  '--test', '--test-name-pattern=public store reviews|direct store messages',
  'test/rules.test.js',
], {stdio: 'inherit'});
process.exit(result.status ?? 1);
