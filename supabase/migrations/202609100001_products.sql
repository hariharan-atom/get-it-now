-- Run in the Supabase SQL editor, or apply with `supabase db push`.
-- Prices use integer paise, never floating point currency.
begin;
create table public.products (
  id text primary key,
  name text not null check (char_length(name) between 1 and 120),
  category text not null check (char_length(category) between 1 and 60),
  unit text not null,
  price_paise integer not null check (price_paise >= 0),
  original_price_paise integer not null check (original_price_paise >= price_paise),
  image text not null check (image like 'assets/products/%' or image like 'https://%'),
  badge text not null default '',
  stock integer not null default 0 check (stock >= 0),
  active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

alter table public.products enable row level security;
revoke all on public.products from anon, authenticated;
grant select on public.products to anon, authenticated;
create policy "Read active products" on public.products for select
  to anon, authenticated using (active = true);
-- Only trusted dashboard/SQL operations can add or change products.
-- No client insert/update/delete policies are granted.

insert into public.products
  (id, name, category, unit, price_paise, original_price_paise, image, badge, stock, sort_order)
values
  ('avocado', 'Hass Avocados', 'Fresh', '2 pieces', 14900, 19900, 'assets/products/avocado.jpg', 'BESTSELLER', 30, 1),
  ('strawberries', 'Sweet Strawberries', 'Fresh', '200 g', 9900, 12900, 'assets/products/strawberries.jpg', 'FARM FRESH', 24, 2),
  ('bananas', 'Yelakki Bananas', 'Fresh', '500 g', 4900, 6500, 'assets/products/bananas.jpg', '', 40, 3),
  ('bread', 'Sourdough Loaf', 'Bakery', '400 g', 12900, 15900, 'assets/products/bread.jpg', 'BAKED TODAY', 18, 4),
  ('milk', 'Fresh Whole Milk', 'Dairy', '1 litre', 6800, 7500, 'assets/products/milk.jpg', '', 50, 5),
  ('eggs', 'Free-range Eggs', 'Dairy', '6 pieces', 8900, 10500, 'assets/products/eggs.jpg', '', 30, 6),
  ('tomatoes', 'Vine Tomatoes', 'Fresh', '500 g', 3900, 5500, 'assets/products/tomatoes.jpg', '', 35, 7),
  ('oranges', 'Juicy Oranges', 'Fresh', '4 pieces', 7900, 9900, 'assets/products/oranges.jpg', 'VITAMIN C', 25, 8);
commit;

