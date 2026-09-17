process.on('uncaughtException', e => { console.error(e.message, e.detail ?? '', e.where ?? ''); process.exit(1); });
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { PGlite } from '@electric-sql/pglite';

const db = new PGlite();
await db.exec(`
  create role anon; create role authenticated;
  create schema auth;
  create table auth.users(
    id uuid primary key,
    raw_user_meta_data jsonb not null default '{}'::jsonb
  );
  create function auth.uid() returns uuid language sql stable as
    'select nullif(current_setting(''request.jwt.claim.sub'', true), '''')::uuid';
  grant usage on schema auth, public to anon, authenticated;
  grant execute on function auth.uid() to anon, authenticated;
  insert into auth.users values ('11111111-1111-4111-8111-111111111111'), ('22222222-2222-4222-8222-222222222222');
`);
for (const migration of [
  '202609100001_products.sql',
  '202609100002_orders.sql',
  '202609170004_delivery_operations.sql',
]) {
  await db.exec((await readFile(new URL(`../../supabase/migrations/${migration}`, import.meta.url), 'utf8')).replace(/^\uFEFF/, ''));
}
const a = '11111111-1111-4111-8111-111111111111';
const b = '22222222-2222-4222-8222-222222222222';
const address = { name:'Test Customer',phone:'9876543210',line1:'10 Garden Street',city:'Bengaluru',pincode:'560001' };
async function customer(id) {
  await db.exec('reset role');
  await db.query("select set_config('request.jwt.claim.sub', $1, false)",[id]);
  await db.exec('set role authenticated');
}
async function order(key, items, total, addr = address) {
  return (await db.query('select public.place_order($1, $2::jsonb, $3::jsonb, $4) as receipt',
    [key, JSON.stringify(addr), JSON.stringify(items),total])).rows[0].receipt;
}
await db.exec('set role anon');
assert.equal((await db.query('select * from public.products')).rows.length, 8);
await assert.rejects(db.query('select * from public.orders'), /permission denied/);
await assert.rejects(order('a'.repeat(32), [{product_id:'avocado',quantity:2}],32300), /permission denied/);
await customer(a);
const first = await order('a'.repeat(32), [{product_id:'avocado',quantity:2}],32300);
assert.equal(first.total_paise,32300);
assert.equal(first.order_items[0].quantity,2);
assert.equal(first.customer_id,a);
assert.equal((await db.query("select stock from public.products where id='avocado'")).rows[0].stock,28);
const retry = await order('a'.repeat(32), [{product_id:'avocado',quantity:2}],32300);
assert.equal(retry.id, first.id);
assert.equal((await db.query("select stock from public.products where id='avocado'")).rows[0].stock,28);
await db.query("update public.products set price_paise = 1 where id='avocado'");
assert.equal((await db.query("select price_paise from public.products where id='avocado'")).rows[0].price_paise,14900);
await assert.rejects(db.query("update public.orders set status = 'delivered'"), /permission denied/);
await assert.rejects(order('b'.repeat(32), [{product_id:'avocado',quantity:2}],1), /Prices have changed/);
await assert.rejects(order('c'.repeat(32), [{product_id:'avocado',quantity:99}],1475100), /unavailable in that quantity/);
await assert.rejects(order('d'.repeat(32), [{product_id:'avocado',quantity:-1}],0), /quantity from 1 to 99/);
await assert.rejects(order('e'.repeat(32), [{product_id:'avocado',quantity:1},{product_id:'avocado',quantity:1}],32300), /more than once/);
await assert.rejects(order('f'.repeat(32), [{product_id:'missing',quantity:1}],100), /no longer available/);
await assert.rejects(order('1'.repeat(32), [{product_id:'avocado',quantity:1}],17400,{...address,phone:'bad'}), /valid delivery address/);
assert.equal((await db.query('select * from public.orders')).rows.length,1);
await customer(b);
assert.equal((await db.query('select * from public.orders')).rows.length,0);
assert.equal((await db.query('select * from public.order_items')).rows.length,0);
const second = await order('a'.repeat(32), [{product_id:'avocado',quantity:3}],44700);
assert.notEqual(first.id,second.id);
assert.equal(second.delivery_fee_paise,0);
await db.exec("reset role; update public.products set active = false where id = 'milk'; set role anon;");
assert.equal((await db.query("select * from public.products where id='milk'")).rows.length,0);
await db.exec(`reset role;
  update public.profiles set role = 'admin', is_active = true where id = '${a}';`);
await customer(b);
assert.equal((await db.query('select * from public.orders')).rows.length,1);
await db.query('select public.activate_delivery_partner()');
await customer(a);
assert.equal((await db.query('select * from public.products')).rows.length,8);
await db.query("select public.assign_delivery_partner($1, $2)", [first.id, b]);
await customer(b);
assert.equal((await db.query('select * from public.orders')).rows.length,2);
await db.query('select public.mark_order_delivered($1)', [first.id]);
assert.equal((await db.query("select status from public.orders where id = $1", [first.id])).rows[0].status, 'delivered');
await db.close();
console.log('PASS: migrations, authenticated checkout, server totals, delivery fees, inventory, retry deduplication, operations roles, secure delivery assignment, and per-user RLS.');
