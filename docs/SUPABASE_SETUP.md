# Connect GET IT NOW to Supabase

Your supplied project URL and publishable key are now saved in `config/supabase.json`. The connection check on September 10, 2026 succeeded. The latest check found eight products and the protected orders table. Do not rerun already-applied migrations. You do not need to insert users manually: Supabase Auth stores each email and a securely hashed password in its database.

Normal launches now automatically load the bundled `config/supabase.json`, even without build flags. If an installed app shows the red demo message, install the new APK or fully stop and restart Flutter. Demo mode now requires `--dart-define=DEMO_MODE=true`. Configuration failures never silently switch a normal launch into demo mode.

## 1. Create a project and copy its public configuration

In the Supabase dashboard, create or open your project. Use its **Connect** panel (or Project Settings → API) to copy the project URL and **publishable** key. A legacy **anon** key also works. Never use the secret/service-role key in Flutter.

Copy `config/supabase.example.json` to `config/supabase.json`, then replace the placeholders:

```json
{
  "SUPABASE_URL": "https://your-project-ref.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_your_actual_key"
}
```

The older `SUPABASE_ANON_KEY` name remains supported. The local config file is ignored by Git and bundled through pubspec.yaml, so recreate it from the example in fresh checkouts. Public client keys are part of the compiled app; row-level security protects the data. Explicit build flags override the bundled values.

## 2. Create the tables and sample inventory

Run these files in Supabase **SQL Editor**, in order:

1. `supabase/migrations/202609100001_products.sql` — products, read policies, and eight sample products.
2. `supabase/migrations/202609100002_orders.sql` — private orders/items, validation, atomic stock changes, and checkout RPC.

Run each migration once. If you already applied the products migration, run only the new orders migration. Keep these migrations in source control for future environments.

You can add products or change their stock, price, image, or category in Table Editor → products. Use integer paise: ₹149 is `14900`. Set `active = false` to hide a product. The client cannot edit inventory or prices.

## 3. Enable password-only email login

In **Authentication → Sign In / Providers**, enable Email and turn **Confirm email** off. A new account then receives a session immediately: the only form fields are email and password, with no OTP or email-link step.

If your project does not allow that setting to change, run `supabase/migrations/202609170003_auto_confirm_email.sql` once in SQL Editor after the first two migrations. It confirms every new email address, including any already-created unconfirmed accounts, and the app immediately signs in with the submitted password. This has the same security trade-off as disabling Confirm email: email ownership is not verified.

New signups have `onboarding_complete: false` in Auth user metadata. The onboarding completion action sets it to `true` in Supabase. Existing accounts without that flag skip onboarding.

## 4. Fully restart the app with the configuration

Stop the old run completely, then run normally with `flutter run -d chrome --web-port=8081`. The project configuration is loaded automatically. You can also supply explicit build overrides:

```powershell
flutter run -d chrome --web-port=8081 --dart-define-from-file=config/supabase.json
```

Open the app at `http://localhost:8081`. For Android:

```powershell
flutter devices
flutter run -d YOUR_DEVICE_ID --dart-define-from-file=config/supabase.json
```

Or use the helper (PowerShell):

```powershell
powershell -ExecutionPolicy Bypass -File tool/run.ps1 -Device chrome
```

To build a connected Android APK:

```powershell
flutter build apk --debug --dart-define-from-file=config/supabase.json
```

To rebuild the local static preview at port 8080 with real accounts, run `flutter build web --release --no-web-resources-cdn --dart-define-from-file=config/supabase.json`, and set the web Site URL/redirect allowlist to the actual origin you use. Normal APK/web builds now include the saved project configuration without flags. Editing the JSON does not change an existing installed build; rebuild and reinstall it.

## 5. Verify the live flow

1. Launch → animated GET IT NOW name → Sign in / Create account.
2. Create a new account with only email and password; it should receive a session immediately.
3. Finish or skip the one-time onboarding tour → Home.
4. Sign out and sign back in → Home directly, with no onboarding.
5. Save an address in Account, add products, and check out with cash on delivery.
6. Verify the order in Table Editor → orders/order_items, and verify stock decreased.
7. Change the order status in the dashboard, then pull to refresh Orders in the app.
8. Sign in as another test customer and verify they cannot see the first customer's orders.

## 6. Add the admin and delivery operations panels

Run `supabase/migrations/202609170004_delivery_operations.sql` once in the SQL Editor after the first two migrations. It creates role profiles, secure product-management policies, delivery assignment, and delivery-completion functions. Then promote exactly one staff account by UUID:

```sql
update public.profiles
set role = 'admin', is_active = true
where id = 'PASTE_ADMIN_AUTH_USER_UUID_HERE';
```

The Vercel-ready panels are in `ops-console/`. Follow `ops-console/README.md` to deploy `/admin` and `/delivery` with the same project URL and publishable key. Never add the service-role key to a browser app.

## Checkout and current boundaries

Home, Categories, Bag, Orders, and Account are functional. Checkout supports an Indian delivery address and cash on delivery. Delivery is ₹25, free from ₹299; the database recalculates it and rejects changed prices. Checkout retries with the same request ID return the existing receipt. Keep the same checkout open after a network error and retry there; closing/restarting creates a new attempt, so check order history first if the result was uncertain.

The store must fulfill orders and update status through its dashboard. There is no automatic courier dispatch, live GPS tracking, online payment provider, cancellation/refund workflow, password reset, or account deletion in this version. A PIN code validates format only; it does not prove service coverage. Add actual coverage/fulfillment operations before accepting customer orders. Dashboard cancellations do not automatically restock products.

The demo lets you explore onboarding and create clearly labelled local preview orders, without creating accounts, taking payments, or requesting delivery. Demo orders/bag/address reset when the app restarts. A live user's saved address is kept in their Supabase Auth metadata; order history is stored in Postgres.

## Troubleshooting

- **Preview message:** an older demo build or explicit DEMO_MODE=true. Fully stop Flutter and run again, refresh the rebuilt web preview, or install the new APK.
- **Invalid login credentials:** check the email and password; verify the user exists in this project’s Authentication → Users.
- **Email confirmation is enabled:** turn off **Confirm email** in Authentication → Sign In / Providers so sign-up stays password-only.
- **Empty/error catalog:** apply the first migration; verify active products and read policies.
- **Checkout unavailable:** apply the second migration and sign in. Do not weaken RLS to fix it.
- **Changed price/unavailable stock:** close checkout, refresh Home, and review the bag before trying again.
- **iOS build:** requires a Mac, Xcode, and your signing team. Open `ios/Runner.xcworkspace`.

References: [official Flutter quickstart](https://supabase.com/docs/guides/getting-started/quickstarts/flutter), [email sign-up](https://supabase.com/docs/reference/dart/auth-signup), [updating user metadata](https://supabase.com/docs/reference/dart/auth-updateuser), [database functions](https://supabase.com/docs/guides/database/functions), [row-level security](https://supabase.com/docs/guides/database/postgres/row-level-security).
