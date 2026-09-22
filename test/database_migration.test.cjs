const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const {DatabaseSync}=require('node:sqlite');
const root=path.resolve(__dirname,'..');
const source=fs.readFileSync(path.join(root,'lib/data/local/database_schema.dart'),'utf8');
const section=source.split('version6Statements = <String>[')[1].split('];')[0];
const upgrade=[...section.matchAll(/['"]((?:ALTER TABLE|CREATE INDEX)[^'"\r\n]*)['"]/g)].map(m=>m[1]);
test('SQLite v5 to v6 preserves accounts, points, order links and images',()=>{
 const db=new DatabaseSync(':memory:');
 db.exec(fs.readFileSync(path.join(root,'test/fixtures/schema_v5.sql'),'utf8'));
 db.exec("INSERT INTO users VALUES('legacy','Name','07700000000','customer','customer',950,'2025-01-01'); INSERT INTO stores VALUES('s1','Store','Baghdad',5,'',0,30,NULL,NULL); INSERT INTO products VALUES('p1','s1','Rose','Flowers',12000,'',5,'','photo.png'); INSERT INTO orders VALUES('o1','legacy','Address',5000,'newOrder','2025-01-01'); INSERT INTO order_items VALUES('o1','p1',2,12000);");
 const before=db.prepare('SELECT * FROM users').get();
 db.exec('BEGIN'); for(const sql of upgrade)db.exec(sql); db.exec('COMMIT');
 const after=db.prepare('SELECT * FROM users').get();
 for(const key of Object.keys(before))assert.equal(after[key],before[key]);
 assert.equal(after.active,1);assert.equal(after.store_id,null);
 assert.equal(db.prepare('SELECT o.user_id, p.image_url FROM orders o JOIN order_items i ON i.order_id=o.id JOIN products p ON p.id=i.product_id').get().image_url,'photo.png');
 assert.equal(db.prepare("SELECT count(*) n FROM sqlite_master WHERE type='index' AND name LIKE 'idx_%'").get().n,12);
 assert.equal(db.prepare('PRAGMA integrity_check').get().integrity_check,'ok'); db.close();
});
test('fresh schema and upgrade produce equivalent table definitions',()=>{
 const fresh=new DatabaseSync(':memory:'); const legacy=new DatabaseSync(':memory:');
 for(const match of source.matchAll(/'''(CREATE TABLE[\s\S]*?)'''/g))fresh.exec(match[1]);
 legacy.exec(fs.readFileSync(path.join(root,'test/fixtures/schema_v5.sql'),'utf8'));
 for(const sql of upgrade){fresh.exec(sql);legacy.exec(sql);}
 const tables=fresh.prepare("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name").all();
 for(const {name} of tables)assert.deepEqual(fresh.prepare(`PRAGMA table_info(${name})`).all(),legacy.prepare(`PRAGMA table_info(${name})`).all());
 fresh.close();legacy.close();
});
