import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get_it_now/src/app.dart';
import 'package:get_it_now/src/art.dart';
import 'package:get_it_now/src/auth.dart';
import 'package:get_it_now/src/checkout.dart';
import 'package:get_it_now/src/onboarding.dart';
import 'package:get_it_now/src/orders.dart';
import 'package:get_it_now/src/shell.dart';
import 'package:get_it_now/src/store.dart';
import 'package:get_it_now/src/theme.dart';

class TestAuthStorage extends GotrueAsyncStorage {
  final values = <String, String>{};
  @override
  Future<String?> getItem({required String key}) async => values[key];
  @override
  Future<void> setItem({required String key, required String value}) async {
    values[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    values.remove(key);
  }
}

class AuthServer extends http.BaseClient {
  AuthServer({this.signupReturnsNoSession = false});
  final bool signupReturnsNoSession;
  Map<String, dynamic> metadata = {
    'display_name': 'Hari',
    'onboarding_complete': true,
  };
  Map<String, dynamic> get user => {
    'id': '11111111-1111-4111-8111-111111111111',
    'aud': 'authenticated',
    'role': 'authenticated',
    'email': 'test@example.com',
    'created_at': '2026-09-10T00:00:00Z',
    'app_metadata': {'provider': 'email'},
    'user_metadata': metadata,
  };
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = await request.finalize().bytesToString();
    final data = body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(body) as Map<String, dynamic>;
    final path = request.url.path;
    Object result;
    if (path.endsWith('/signup') || path.endsWith('/token')) {
      if (path.endsWith('/signup')) {
        metadata = Map<String, dynamic>.from(data['data'] as Map);
      }
      final expiry = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600;
      final payload = base64Url
          .encode(utf8.encode(jsonEncode({'exp': expiry, 'sub': user['id']})))
          .replaceAll('=', '');
      result = path.endsWith('/signup') && signupReturnsNoSession
          ? user
          : {
              'access_token': 'eyJhbGciOiJIUzI1NiJ9.$payload.signature',
              'refresh_token': 'test-refresh',
              'expires_in': 3600,
              'token_type': 'bearer',
              'user': user,
            };
    } else if (path.endsWith('/user')) {
      if (data['data'] != null) {
        metadata = {
          ...metadata,
          ...Map<String, dynamic>.from(data['data'] as Map),
        };
      }
      result = user;
    } else if (path.endsWith('/products')) {
      result = demoProducts
          .map(
            (p) => {
              'id': p.id,
              'name': p.name,
              'category': p.category,
              'unit': p.unit,
              'price_paise': p.price,
              'original_price_paise': p.originalPrice,
              'image': p.image,
              'badge': p.badge,
              'stock': p.stock,
            },
          )
          .toList();
    } else {
      result = [];
    }
    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(result))),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}

void size(WidgetTester tester, Size value) {
  tester.view.physicalSize = value;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> launch(WidgetTester tester, ShopStore store) async {
  await tester.pumpWidget(GetItNowApp(store: store));
  await tester.pump(const Duration(milliseconds: 1800));
  await tester.pumpAndSettle();
}

Future<ShopStore> liveStore(
  WidgetTester tester, {
  bool signupReturnsNoSession = false,
}) async {
  final client = (await tester.runAsync(
    () async => SupabaseClient(
      'https://test.supabase.co',
      'test-public-key',
      httpClient: AuthServer(signupReturnsNoSession: signupReturnsNoSession),
      authOptions: AuthClientOptions(
        autoRefreshToken: false,
        pkceAsyncStorage: TestAuthStorage(),
      ),
    ),
  ))!;
  final store = ShopStore(client: client)..products = demoProducts;
  addTearDown(() async {
    store.dispose();
    await tester.runAsync(client.dispose);
  });
  return store;
}

Future<void> enterAuth(WidgetTester tester, {required bool signup}) async {
  await tester.tap(find.text(signup ? 'Create account' : 'Sign in').first);
  await tester.pumpAndSettle();
  final fields = find.byType(TextFormField);
  if (signup) await tester.enterText(fields.at(0), 'Hari Kumar');
  await tester.enterText(fields.at(signup ? 1 : 0), 'test@example.com');
  await tester.enterText(fields.at(signup ? 2 : 1), 'Password123');
  final submit = find.descendant(
    of: find.byType(AuthSheet),
    matching: find.widgetWithText(
      FilledButton,
      signup ? 'Create account' : 'Sign in',
    ),
  );
  await tester.ensureVisible(submit);
  await tester.tap(submit);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final font in [
      ('Epilogue', 'assets/fonts/Epilogue.ttf'),
      ('DM Sans', 'assets/fonts/DMSans.ttf'),
    ]) {
      await (FontLoader(font.$1)..addFont(rootBundle.load(font.$2))).load();
    }
  });
  test(
    'money, delivery thresholds, stock limits and demo checkout retry',
    () async {
      final store = ShopStore();
      addTearDown(store.dispose);
      await store.loadProducts();
      final product = store.products.first;
      store.changeQuantity(product, 2);
      expect(store.total, 29800);
      expect(store.savings, 10000);
      expect(deliveryFee(29800), 2500);
      expect(deliveryFee(29900), 0);
      expect(money(12550), '₹125.50');
      const address = DeliveryAddress(
        name: 'Hari',
        phone: '9876543210',
        line1: '10 Garden Street',
        city: 'Bengaluru',
        pincode: '560001',
      );
      final id = newRequestId();
      final order = await store.placeOrder(address, id);
      expect(order.total, 32300);
      expect(store.count, 0);
      expect(order.demo, isTrue);
      expect(order.deliveryEstimate, contains('preview order'));
      await store.saveAddress(address.toJson());
      await store.saveAddress(
        const DeliveryAddress(
          label: 'Office',
          name: 'Hari',
          phone: '9876543210',
          line1: '10 Garden Street',
          city: 'Bengaluru',
          pincode: '560001',
        ).toJson(),
      );
      expect(store.savedAddresses.map((saved) => saved['label']), [
        'Office',
        'Home',
      ]);
      expect((await store.placeOrder(address, id)).id, order.id);
      expect(store.orders.length, 1);
      store.changeQuantity(product, 1000);
      expect(store.quantity(product), product.stock);
      store.changeQuantity(product, -1000);
      expect(store.count, 0);
    },
  );
  test('invalid live config cannot silently become a demo catalog', () async {
    final store = ShopStore(startupError: 'No connection');
    addTearDown(store.dispose);
    await store.loadProducts();
    expect(store.isDemo, isFalse);
    expect(store.catalogError, isNotNull);
    expect(store.products, isEmpty);
  });
  testWidgets('animated name then account choice, without onboarding', (
    tester,
  ) async {
    final store = ShopStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(GetItNowApp(store: store));
    expect(find.byType(AnimatedLaunchScreen), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
  });
  testWidgets('existing account signs in directly to five-tab shop', (
    tester,
  ) async {
    size(tester, const Size(390, 844));
    final store = await liveStore(tester);
    await launch(tester, store);
    await enterAuth(tester, signup: false);
    expect(store.signedIn, isTrue);
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
    expect(tester.takeException(), isNull);
  });
  testWidgets('new signup gets onboarding once and saves completion', (
    tester,
  ) async {
    size(tester, const Size(390, 844));
    final store = await liveStore(tester, signupReturnsNoSession: true);
    await launch(tester, store);
    await enterAuth(tester, signup: true);
    expect(store.needsOnboarding, isTrue);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    await tester.tap(find.text('Skip tour'));
    await tester.pumpAndSettle();
    expect(store.needsOnboarding, isFalse);
    expect(
      store.client!.auth.currentUser!.userMetadata!['onboarding_complete'],
      isTrue,
    );
    expect(
      store.client!.auth.currentUser!.userMetadata!['display_name'],
      'Hari Kumar',
    );
    expect(find.byType(AppShell), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final viewport in [
    const Size(320, 740),
    const Size(375, 812),
    const Size(812, 375),
    const Size(1200, 850),
  ]) {
    testWidgets('welcome and navigation fit $viewport', (tester) async {
      size(tester, viewport);
      final store = ShopStore();
      addTearDown(store.dispose);
      await launch(tester, store);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Explore demo'));
      await tester.tap(find.text('Explore demo'));
      await tester.pumpAndSettle();
      expect(find.byType(AppShell), findsOneWidget);
      for (final label in ['Categories', 'Bag', 'Orders', 'Account', 'Home']) {
        await tester.tap(
          find
              .descendant(
                of: find.byType(NavigationBar),
                matching: find.text(label),
              )
              .last,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }
  testWidgets('search to bag to demo order to history', (tester) async {
    size(tester, const Size(390, 844));
    final store = ShopStore()..browse();
    addTearDown(store.dispose);
    await launch(tester, store);
    await tester.enterText(find.byType(TextField), 'Avocado');
    await tester.pumpAndSettle();
    expect(find.text('1 fresh find'), findsOneWidget);
    tester.testTextInput.hide();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ADD').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('View bag'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue to checkout'));
    await tester.pumpAndSettle();
    expect(find.byType(CheckoutSheet), findsOneWidget);
    final fields = find.byType(TextFormField);
    final values = [
      'Hari',
      '9876543210',
      '10 Garden Street',
      'Bengaluru',
      '560001',
    ];
    for (var i = 0; i < values.length; i++) {
      await tester.enterText(fields.at(i), values[i]);
    }
    tester.testTextInput.hide();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Place demo order'));
    await tester.tap(find.text('Place demo order'));
    await tester.pumpAndSettle();
    expect(find.text('Demo order placed!'), findsOneWidget);
    expect(store.count, 0);
    expect(store.orders.length, 1);
    await tester.tap(find.text('View my orders'));
    await tester.pumpAndSettle();
    expect(find.text('DEMO ORDER'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('large text and reduced motion fit onboarding and navigation', (
    tester,
  ) async {
    size(tester, const Size(375, 812));
    final store = ShopStore();
    addTearDown(store.dispose);
    Widget frame(Widget child) => MaterialApp(
      theme: appTheme(),
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(375, 812),
          textScaler: TextScaler.linear(2),
          disableAnimations: true,
        ),
        child: child,
      ),
    );
    await tester.pumpWidget(frame(OnboardingScreen(store: store)));
    await tester.pumpAndSettle();
    expect(find.byType(Brand), findsNothing);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Skip tour'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      frame(
        Scaffold(
          body: CheckoutSheet(store: store, onOrders: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Use my location'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(frame(AppShell(store: store)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('saved addresses fit checkout in phone landscape', (
    tester,
  ) async {
    size(tester, const Size(812, 375));
    final store = ShopStore();
    addTearDown(store.dispose);
    const base = DeliveryAddress(
      name: 'Hari',
      phone: '9876543210',
      line1: '10 Garden Street',
      city: 'Bengaluru',
      pincode: '560001',
    );
    await store.saveAddress(base.toJson());
    await store.saveAddress(
      const DeliveryAddress(
        label: 'Office',
        name: 'Hari',
        phone: '9876543210',
        line1: '99 Market Street',
        city: 'Bengaluru',
        pincode: '560001',
      ).toJson(),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(),
        home: Scaffold(
          body: CheckoutSheet(store: store, onOrders: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsNWidgets(2));
    expect(find.text('Office'), findsNWidgets(2));
    expect(find.text('Use my location'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
