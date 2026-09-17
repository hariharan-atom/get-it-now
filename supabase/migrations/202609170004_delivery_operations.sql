-- Operations roles, delivery assignment, and browser-safe management actions.
-- Run once in the Supabase SQL Editor after the products and orders migrations.
begin;

do $$ begin
  create type public.app_role as enum ('customer', 'admin', 'delivery_partner');
exception when duplicate_object then null;
end $$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '' check (char_length(full_name) <= 120),
  role public.app_role not null default 'customer',
  is_active boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Create profiles for accounts that already exist before this migration.
insert into public.profiles (id, full_name)
select u.id, coalesce(nullif(trim(u.raw_user_meta_data ->> 'display_name'), ''), '')
from auth.users u
on conflict (id) do nothing;

create or replace function public.create_profile_for_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name)
  values (
    new.id,
    coalesce(nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''), '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

revoke all on function public.create_profile_for_new_user() from public, anon, authenticated;
drop trigger if exists create_profile_for_new_user on auth.users;
create trigger create_profile_for_new_user
after insert on auth.users
for each row execute function public.create_profile_for_new_user();

create or replace function public.touch_profile_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists touch_profile_updated_at on public.profiles;
create trigger touch_profile_updated_at
before update on public.profiles
for each row execute function public.touch_profile_updated_at();

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'::public.app_role and p.is_active
  );
$$;

create or replace function public.is_active_delivery_partner()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and p.role = 'delivery_partner'::public.app_role
      and p.is_active
  );
$$;

revoke all on function public.is_admin(), public.is_active_delivery_partner() from public, anon;
grant execute on function public.is_admin(), public.is_active_delivery_partner() to authenticated;

alter table public.profiles enable row level security;
revoke all on public.profiles from anon, authenticated;
grant select on public.profiles to authenticated;
drop policy if exists "Profiles are visible to owner or admin" on public.profiles;
create policy "Profiles are visible to owner or admin" on public.profiles
  for select to authenticated
  using (id = (select auth.uid()) or (select public.is_admin()));

alter table public.orders
  add column if not exists delivery_partner_id uuid references public.profiles(id) on delete set null,
  add column if not exists assigned_at timestamptz,
  add column if not exists delivered_at timestamptz;
create index if not exists orders_delivery_partner_created
  on public.orders(delivery_partner_id, created_at desc);

-- Add operations visibility without replacing the existing customer-only policies.
drop policy if exists "Operations read orders" on public.orders;
create policy "Operations read orders" on public.orders for select to authenticated
  using (
    (select public.is_admin())
    or delivery_partner_id = (select auth.uid())
  );

drop policy if exists "Operations read order items" on public.order_items;
create policy "Operations read order items" on public.order_items for select to authenticated
  using (exists (
    select 1 from public.orders o
    where o.id = order_items.order_id
      and ((select public.is_admin()) or o.delivery_partner_id = (select auth.uid()))
  ));

-- Admin-only product policies. Existing "Read active products" remains public.
grant insert, update, delete on public.products to authenticated;
drop policy if exists "Admins read all products" on public.products;
create policy "Admins read all products" on public.products for select to authenticated
  using ((select public.is_admin()));
drop policy if exists "Admins insert products" on public.products;
create policy "Admins insert products" on public.products for insert to authenticated
  with check ((select public.is_admin()));
drop policy if exists "Admins update products" on public.products;
create policy "Admins update products" on public.products for update to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));
drop policy if exists "Admins delete products" on public.products;
create policy "Admins delete products" on public.products for delete to authenticated
  using ((select public.is_admin()));

-- A signed-in account may opt in as a delivery partner. This is an activation,
-- not a background/admin approval workflow, matching the requested process.
create or replace function public.activate_delivery_partner()
returns public.profiles
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_profile public.profiles;
begin
  if auth.uid() is null then
    raise exception 'Please sign in first.';
  end if;
  update public.profiles
  set role = 'delivery_partner', is_active = true
  where id = auth.uid()
  returning * into v_profile;
  if v_profile.id is null then
    raise exception 'Your account profile is not ready. Sign out and sign in again.';
  end if;
  return v_profile;
end;
$$;

create or replace function public.assign_delivery_partner(p_order_id uuid, p_partner_id uuid)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_order public.orders;
begin
  if not public.is_admin() then
    raise exception 'Only an active admin can assign delivery partners.';
  end if;
  if not exists (
    select 1 from public.profiles p
    where p.id = p_partner_id
      and p.role = 'delivery_partner'::public.app_role
      and p.is_active
  ) then
    raise exception 'Choose an active delivery partner.';
  end if;
  update public.orders
  set delivery_partner_id = p_partner_id,
      assigned_at = now(),
      status = 'out_for_delivery'
  where id = p_order_id
    and status not in ('delivered', 'cancelled')
  returning * into v_order;
  if v_order.id is null then
    raise exception 'This order cannot be assigned.';
  end if;
  return v_order;
end;
$$;

create or replace function public.update_order_status(p_order_id uuid, p_status text)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_order public.orders;
begin
  if not public.is_admin() then
    raise exception 'Only an active admin can update orders.';
  end if;
  if p_status not in ('placed', 'preparing', 'cancelled') then
    raise exception 'Use delivery assignment or the partner delivery action for that status.';
  end if;
  update public.orders
  set status = p_status
  where id = p_order_id
    and status not in ('delivered', 'cancelled')
  returning * into v_order;
  if v_order.id is null then
    raise exception 'This order cannot be updated.';
  end if;
  return v_order;
end;
$$;

create or replace function public.mark_order_delivered(p_order_id uuid)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_order public.orders;
begin
  if not public.is_active_delivery_partner() then
    raise exception 'Activate your delivery account before delivering orders.';
  end if;
  update public.orders
  set status = 'delivered', delivered_at = now()
  where id = p_order_id
    and delivery_partner_id = auth.uid()
    and status = 'out_for_delivery'
  returning * into v_order;
  if v_order.id is null then
    raise exception 'This order is no longer available to deliver.';
  end if;
  return v_order;
end;
$$;

revoke all on function public.activate_delivery_partner() from public, anon;
revoke all on function public.assign_delivery_partner(uuid, uuid) from public, anon;
revoke all on function public.update_order_status(uuid, text) from public, anon;
revoke all on function public.mark_order_delivered(uuid) from public, anon;
grant execute on function public.activate_delivery_partner() to authenticated;
grant execute on function public.assign_delivery_partner(uuid, uuid) to authenticated;
grant execute on function public.update_order_status(uuid, text) to authenticated;
grant execute on function public.mark_order_delivered(uuid) to authenticated;

commit;
