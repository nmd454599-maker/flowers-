const { DatabaseSync } = require('node:sqlite');
const readline = require('node:readline');
const db = new DatabaseSync(process.argv[2]);
readline.createInterface({input: process.stdin}).on('line', line => {
  try {
    const r = JSON.parse(line);
    let value;
    if (r.kind === 'execute') { db.exec(r.sql); value = null; }
    else if (r.kind === 'query') value = db.prepare(r.sql).all(...r.args);
    else { const x = db.prepare(r.sql).run(...r.args); value = Number(r.kind === 'insert' ? x.lastInsertRowid : x.changes); }
    process.stdout.write(JSON.stringify({value}) + '\n');
  } catch(e) { process.stdout.write(JSON.stringify({error: e.message}) + '\n'); }
});
