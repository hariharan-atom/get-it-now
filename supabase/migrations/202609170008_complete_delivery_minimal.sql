-- Keep completion compatible with the existing orders table: status is the
-- only field needed to mark a hand-off as delivered.

create or replace function public.delivery_complete_order(p_order_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  update public.orders
  set status = 'delivered'
  where id = p_order_id
    and delivery_partner_id = auth.uid()
    and status in ('assigned', 'out_for_delivery');

  if not found then
    raise exception 'This order is not assigned to your account';
  end if;
end;
$$;
