begin;

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references auth.users(id) on delete cascade,
  request_id text not null check (request_id ~ '^[a-f0-9]{32}$'),
  address jsonb not null,
  subtotal_paise integer not null check (subtotal_paise >= 0),
  delivery_fee_paise integer not null check (delivery_fee_paise >= 0),
  total_paise integer not null check (total_paise = subtotal_paise + delivery_fee_paise),
  payment_method text not null default 'cash_on_delivery' check (payment_method = 'cash_on_delivery'),
  status text not null default 'placed' check (status in ('placed', 'preparing', 'out_for_delivery', 'delivered', 'cancelled')),
  created_at timestamptz not null default now(),
  unique (customer_id, request_id)
);
create index orders_customer_created on public.orders(customer_id, created_at desc);

create table public.order_items (
  id bigint generated always as identity primary key,
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id text references public.products(id) on delete set null,
  name text not null,
  unit text not null,
  image text not null,
  quantity integer not null check (quantity between 1 and 99),
  price_paise integer not null check (price_paise >= 0)
);
create index order_items_order on public.order_items(order_id);
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
revoke all on public.orders, public.order_items from anon, authenticated;
grant select on public.orders, public.order_items to authenticated;
create policy "Customers read their orders" on public.orders for select to authenticated
  using (customer_id = (select auth.uid()));
create policy "Customers read their order items" on public.order_items for select to authenticated
  using (exists (select 1 from public.orders o where o.id = order_items.order_id and o.customer_id = (select auth.uid())));

-- This function alone may write orders/decrement inventory. Prices come from
-- products, never the caller. The caller must own the authenticated session.
create function public.place_order(p_request_id text, p_address jsonb, p_items jsonb, p_expected_total integer)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  customer uuid := auth.uid();
  v_order_id uuid;
  product record;
  item jsonb;
  qty integer;
  locked_count integer := 0;
  subtotal bigint := 0;
  fee integer;
  result jsonb;
  field text;
begin
  if customer is null then raise exception 'Please sign in to place your order.'; end if;
  if p_request_id is null or p_request_id !~ '^[a-f0-9]{32}$' then raise exception 'Invalid order request.'; end if;
  -- Serialize retries for this customer/request, including simultaneous taps.
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(customer::text || p_request_id, 0));
  select o.id into v_order_id from public.orders o where o.customer_id = customer and o.request_id = p_request_id;
  if v_order_id is not null then
    select to_jsonb(o) || jsonb_build_object('order_items',
      (select coalesce(jsonb_agg(to_jsonb(i)), '[]'::jsonb) from public.order_items i where i.order_id = o.id))
      into result from public.orders o where o.id = v_order_id;
    return result;
  end if;
  if p_address is null or jsonb_typeof(p_address) <> 'object' then raise exception 'Enter a delivery address.'; end if;
  foreach field in array array['name', 'phone', 'line1', 'city', 'pincode'] loop
    if coalesce(jsonb_typeof(p_address->field), '') <> 'string' then raise exception 'Complete every delivery address field.'; end if;
  end loop;
  if length(trim(p_address->>'name')) not between 2 and 100 or
     length(trim(p_address->>'line1')) not between 5 and 300 or
     length(trim(p_address->>'city')) not between 2 and 100 or
     (p_address->>'phone') !~ '^[6-9][0-9]{9}$' or
     (p_address->>'pincode') !~ '^[1-9][0-9]{5}$' then raise exception 'Enter a valid delivery address and mobile number.'; end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' then raise exception 'Your bag is empty.'; end if;
  if jsonb_array_length(p_items) not between 1 and 100 then raise exception 'Choose between 1 and 100 products.'; end if;
  for item in select value from jsonb_array_elements(p_items) loop
    if coalesce(jsonb_typeof(item->'product_id'), '') <> 'string' or
       coalesce(jsonb_typeof(item->'quantity'), '') <> 'number' or
       (item->>'quantity') !~ '^[1-9][0-9]?$' then raise exception 'Each product needs a quantity from 1 to 99.'; end if;
  end loop;
  if (select count(distinct x->>'product_id') from jsonb_array_elements(p_items) x) <> jsonb_array_length(p_items)
    then raise exception 'A product appears more than once in your bag.'; end if;
  if (select count(*) from public.products p where p.id in
      (select x->>'product_id' from jsonb_array_elements(p_items) x)) <> jsonb_array_length(p_items)
    then raise exception 'One of these products is no longer available.'; end if;
  -- Lock in a stable order so concurrent orders cannot oversell or deadlock.
  for product in select p.* from public.products p where p.id in
    (select x->>'product_id' from jsonb_array_elements(p_items) x) order by p.id for update loop
    select (x->>'quantity')::integer into qty from jsonb_array_elements(p_items) x where x->>'product_id' = product.id;
    if not product.active or product.stock < qty then raise exception '% is unavailable in that quantity. Refresh your bag.', product.name; end if;
    subtotal := subtotal + product.price_paise::bigint * qty;
    locked_count := locked_count + 1;
  end loop;
  if locked_count <> jsonb_array_length(p_items) then raise exception 'The inventory changed. Refresh your bag.'; end if;
  fee := case when subtotal >= 29900 then 0 else 2500 end;
  if subtotal + fee > 2147483647 or p_expected_total is null or subtotal + fee <> p_expected_total
    then raise exception 'Prices have changed. Refresh your bag before checking out.'; end if;
  insert into public.orders(customer_id, request_id, address, subtotal_paise, delivery_fee_paise, total_paise)
    values(customer, p_request_id, jsonb_build_object('name', trim(p_address->>'name'), 'phone', p_address->>'phone',
      'line1', trim(p_address->>'line1'), 'city', trim(p_address->>'city'), 'pincode', p_address->>'pincode'), subtotal, fee, subtotal + fee)
    returning id into v_order_id;
  for item in select value from jsonb_array_elements(p_items) loop
    qty := (item->>'quantity')::integer;
    insert into public.order_items(order_id, product_id, name, unit, image, quantity, price_paise)
      select v_order_id, p.id, p.name, p.unit, p.image, qty, p.price_paise from public.products p where p.id = item->>'product_id';
    update public.products set stock = stock - qty where id = item->>'product_id';
  end loop;
  select to_jsonb(o) || jsonb_build_object('order_items',
    (select jsonb_agg(to_jsonb(i)) from public.order_items i where i.order_id = o.id)) into result from public.orders o where o.id = v_order_id;
  return result;
end;
$$;
revoke all on function public.place_order(text, jsonb, jsonb, integer) from public, anon;
grant execute on function public.place_order(text, jsonb, jsonb, integer) to authenticated;
commit;
