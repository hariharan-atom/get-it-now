# Get It Now operations console

One responsive Next.js deployment serves both panels:

- `/admin` — admin product CRUD, order queue, status updates, and delivery assignment.
- `/delivery` — mobile-first partner sign-up, activation, assigned-order address/call/map actions, and delivery confirmation.

## First-time Supabase setup

1. In Supabase SQL Editor, run `../supabase/migrations/202609170004_delivery_operations.sql` once, after the existing products and orders migrations.
2. Create or sign in to the account that will administer the store, then run this query with its UUID from **Authentication → Users**:

```sql
update public.profiles
set role = 'admin', is_active = true
where id = 'PASTE_ADMIN_AUTH_USER_UUID_HERE';
```

Delivery partners create an account at `/delivery`, then tap **Activate delivery account**. Their active name becomes selectable on `/admin`.

## Local run

Copy `.env.local.example` to `.env.local`, then add the same project URL and **publishable** key used by the Flutter app. Do not put a Supabase service-role key here.

```powershell
npm install
npm run dev
```

Open `http://localhost:3000/admin` or `http://localhost:3000/delivery`.

## Vercel deployment

Push this repository to GitHub, then import it into Vercel. Set the Vercel project **Root Directory** to `ops-console`, choose the Next.js preset, and set these environment variables for Production, Preview, and Development:

```text
NEXT_PUBLIC_SUPABASE_URL=https://your-project-ref.supabase.co
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=sb_publishable_your_key
```

Deploy once to use both paths. If you need separate domains, create two Vercel projects from the same repository and root directory, then give one team the `/admin` URL and delivery partners the `/delivery` URL. The same Supabase RLS policies protect both.
