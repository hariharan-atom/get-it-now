-- Delivery availability is a delivery-partner setting, never a role change.
-- This prevents visiting the delivery workspace from turning an admin/customer
-- into a delivery partner or changing their availability without a button tap.

begin;

create or replace function public.lock_profile_role_and_availability()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  -- The Supabase dashboard (where auth.uid() is null) can still be used for
  -- deliberate admin setup. App users cannot change either protected field
  -- directly; availability changes must use set_delivery_availability().
  if auth.uid() is not null
     and (new.role is distinct from old.role or new.is_active is distinct from old.is_active)
     and coalesce(current_setting('app.getitnow_availability_change', true), '') <> 'allowed' then
    raise exception 'Role and delivery availability can only be changed by an authorised action';
  end if;

  return new;
end;
$$;

drop trigger if exists lock_profile_role_and_availability on public.profiles;
create trigger lock_profile_role_and_availability
before update on public.profiles
for each row execute function public.lock_profile_role_and_availability();

-- Keep the old function name harmless in case an older deployed page calls it.
-- It must never promote a user or silently set them active.
create or replace function public.activate_delivery_partner()
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  return;
end;
$$;

create or replace function public.set_delivery_availability(p_is_active boolean)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if not exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'delivery_partner'
  ) then
    raise exception 'Only a delivery partner can change delivery availability';
  end if;

  perform set_config('app.getitnow_availability_change', 'allowed', true);

  update public.profiles
  set is_active = p_is_active,
      updated_at = now()
  where id = auth.uid();
end;
$$;

create or replace function public.delivery_my_orders()
returns setof jsonb
language sql
security definer
set search_path = public, pg_temp
as $$
  select to_jsonb(o)
  from public.orders o
  where o.delivery_partner_id = auth.uid()
    and o.status in ('assigned', 'out_for_delivery')
  order by o.created_at desc;
$$;

create or replace function public.delivery_complete_order(p_order_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  update public.orders
  set status = 'delivered',
      delivered_at = now(),
      updated_at = now()
  where id = p_order_id
    and delivery_partner_id = auth.uid()
    and status in ('assigned', 'out_for_delivery');

  if not found then
    raise exception 'This order is not assigned to your account';
  end if;
end;
$$;

grant execute on function public.set_delivery_availability(boolean) to authenticated;
grant execute on function public.delivery_my_orders() to authenticated;
grant execute on function public.delivery_complete_order(uuid) to authenticated;

commit;
