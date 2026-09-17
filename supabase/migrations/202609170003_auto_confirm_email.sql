-- Password-only sign-up fallback when the hosted Auth confirmation setting
-- cannot be changed. It deliberately treats every submitted email as valid.
begin;

create or replace function public.auto_confirm_email_on_signup()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.email_confirmed_at = coalesce(new.email_confirmed_at, now());
  return new;
end;
$$;

revoke all on function public.auto_confirm_email_on_signup() from public, anon, authenticated;

drop trigger if exists auto_confirm_email_on_signup on auth.users;
create trigger auto_confirm_email_on_signup
before insert on auth.users
for each row execute function public.auto_confirm_email_on_signup();

-- Confirm accounts created before this fallback was installed too.
update auth.users
set email_confirmed_at = now()
where email is not null and email_confirmed_at is null;

commit;
