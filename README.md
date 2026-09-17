# GET IT NOW

Flutter grocery app for Android and iOS, with a responsive web preview. Epilogue Black headlines, DM Sans body text, lavender backgrounds, mint actions, and dark green accents.

## App flow

Animated **GET IT NOW** launch → Sign in / Create account.

- Existing account: sign in → Home directly.
- New account: sign up → email confirmation when enabled → onboarding → Home. Tour completion is saved in Supabase Auth metadata.
- Restored sessions: launch → Home, or resume an unfinished new-account tour.
- Demo: explore without an account, preview the new-user tour, and place explicitly labelled preview orders.

The bottom navigation has **Home, Categories, Bag, Orders, Account**. Includes product search/filtering, details, quantities, stock limits, savings, delivery-address entry, cash-on-delivery checkout, order receipts/history, saved addresses, and sign-out.

## Run and connect

Requires Flutter 3.47.2 / Dart 3.13.2 or a compatible newer stable version.

```powershell
flutter pub get
flutter run -d chrome --web-port=8081
```

Normal launches now load the bundled public configuration from `config/supabase.json` automatically, including Android Studio runs and APK builds. In a fresh checkout, copy `config/supabase.example.json` to that path and fill in your public configuration before building. To explicitly override the bundled project for a build, use:

```powershell
flutter run -d chrome --web-port=8081 --dart-define-from-file=config/supabase.json
```

This workspace now has the supplied project URL and publishable key in the Git-ignored `config/supabase.json`. A read-only connection check on September 10, 2026 confirmed that the key works, email signup is enabled, and email confirmation is required. The latest read-only check found eight products and an orders table that correctly denies anonymous reads. Email confirmation is still enabled in the hosted project; disable Confirm email under Authentication ? Sign In / Providers ? Email for the requested immediate-signup flow. Live account creation and checkout have not yet been tested against the hosted project. The JSON is bundled as an app asset. Updating it requires a full restart/rebuild; an already-installed APK does not update automatically. To intentionally run the demo, use `flutter run --dart-define=DEMO_MODE=true`. Configuration failures show a connection error instead of silently entering demo mode.

For Android, connect a phone/emulator and select it with `flutter run -d DEVICE_ID`. iOS builds require a Mac, Xcode, and signing; open `ios/Runner.xcworkspace` there.

## Backend and order behavior

The first SQL migration creates eight products and read-only client policies. The second creates private orders/items and a `place_order` RPC. The RPC authenticates the caller, validates the address and quantities, locks inventory in product-ID order, computes totals from current server prices, rejects price changes, decrements stock atomically, and returns the receipt. A request key deduplicates retries within the same checkout attempt. Customers cannot edit inventory, prices, or order status, and can read only their own orders.

Cash on delivery: ₹25 delivery, free from ₹299. PIN validation checks format, not actual service coverage. Store staff fulfill orders and update status through the dashboard; the app refreshes status on demand. Online payments, automatic dispatch/GPS tracking, cancellations/refunds, password recovery, and account deletion are not implemented. Dashboard cancellation does not restock automatically. Configure actual service coverage and fulfillment before taking customer orders.

Demo orders, bags, and guest addresses are in memory and reset on restart/sign-out. Live addresses are saved in Auth metadata and order history in Postgres. If an order response is interrupted, retry within the same checkout; if you close/restart it, check order history before creating another attempt.

## Verify

```powershell
flutter analyze
flutter test
flutter build web --release --no-web-resources-cdn --no-wasm-dry-run
flutter build apk --debug
```

Auth-flow tests use a mocked HTTP service with the real Supabase Dart client; they do not contact a hosted project. Layout/interaction tests cover launch, login versus signup, email confirmation, onboarding, navigation at phone/landscape/desktop sizes, enlarged text/reduced motion, and demo checkout through order history.

SQL tests run the real migrations in an embedded PostgreSQL runtime with local Supabase-role/Auth stubs:

```powershell
npm.cmd ci --prefix tool/db-tests
node tool/db-tests/orders.mjs
```

These verify RLS, server pricing, fees, inventory, invalid input, rollback, and retry deduplication. They do not simulate independent concurrent production database connections.

## Previews and assets

Screenshots are in `previews/`. Serve the built app with `python -m http.server 8080 --bind 127.0.0.1 --directory build/web`; open http://127.0.0.1:8080. The Android APK is `build/app/outputs/flutter-apk/app-debug.apk`.

`tool/preview.py` uses Python Playwright and local Chrome for screenshots; `tool/make_icons.py` uses Pillow to regenerate launcher icons. Neither is required to run Flutter. `tool/run.ps1` validates public configuration and starts a connected run (use `-Demo` for preview).

Fonts/photos are bundled locally. Font licenses live in `assets/fonts/`; photo sources are recorded in `tool/download_assets.py` (illustrative Unsplash images). The grocery artwork is Flutter canvas code in `lib/src/art.dart`. Tokens are in `lib/src/theme.dart`.

Android incremental Kotlin compilation is disabled because the project and package cache are on different Windows drives. Remove that setting when both live on the same drive.
