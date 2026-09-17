-- The first version of this function returned a profile row. Remove that
-- legacy signature before the availability-safe version is installed.

drop function if exists public.activate_delivery_partner();

create function public.activate_delivery_partner()
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  -- Compatibility no-op: activation is now only changed with
  -- set_delivery_availability(true/false).
  return;
end;
$$;
