import 'dart:async';

import 'orders.dart';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.price,
    required this.originalPrice,
    required this.image,
    this.badge = '',
    this.stock = 30,
  });
  final String id, name, category, unit, image, badge;
  final int price, originalPrice, stock;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as String,
    name: json['name'] as String,
    category: json['category'] as String,
    unit: json['unit'] as String,
    price: (json['price_paise'] as num).toInt(),
    originalPrice: (json['original_price_paise'] as num).toInt(),
    image: json['image'] as String,
    badge: json['badge'] as String? ?? '',
    stock: (json['stock'] as num).toInt(),
  );
}

String money(int paise) =>
    '₹${paise % 100 == 0 ? paise ~/ 100 : (paise / 100).toStringAsFixed(2)}';

const demoProducts = [
  Product(
    id: 'avocado',
    name: 'Hass Avocados',
    category: 'Fresh',
    unit: '2 pieces',
    price: 14900,
    originalPrice: 19900,
    image: 'assets/products/avocado.jpg',
    badge: 'BESTSELLER',
  ),
  Product(
    id: 'strawberries',
    name: 'Sweet Strawberries',
    category: 'Fresh',
    unit: '200 g',
    price: 9900,
    originalPrice: 12900,
    image: 'assets/products/strawberries.jpg',
    badge: 'FARM FRESH',
  ),
  Product(
    id: 'bananas',
    name: 'Yelakki Bananas',
    category: 'Fresh',
    unit: '500 g',
    price: 4900,
    originalPrice: 6500,
    image: 'assets/products/bananas.jpg',
  ),
  Product(
    id: 'bread',
    name: 'Sourdough Loaf',
    category: 'Bakery',
    unit: '400 g',
    price: 12900,
    originalPrice: 15900,
    image: 'assets/products/bread.jpg',
    badge: 'BAKED TODAY',
  ),
  Product(
    id: 'milk',
    name: 'Fresh Whole Milk',
    category: 'Dairy',
    unit: '1 litre',
    price: 6800,
    originalPrice: 7500,
    image: 'assets/products/milk.jpg',
  ),
  Product(
    id: 'eggs',
    name: 'Free-range Eggs',
    category: 'Dairy',
    unit: '6 pieces',
    price: 8900,
    originalPrice: 10500,
    image: 'assets/products/eggs.jpg',
  ),
  Product(
    id: 'tomatoes',
    name: 'Vine Tomatoes',
    category: 'Fresh',
    unit: '500 g',
    price: 3900,
    originalPrice: 5500,
    image: 'assets/products/tomatoes.jpg',
  ),
  Product(
    id: 'oranges',
    name: 'Juicy Oranges',
    category: 'Fresh',
    unit: '4 pieces',
    price: 7900,
    originalPrice: 9900,
    image: 'assets/products/oranges.jpg',
    badge: 'VITAMIN C',
  ),
];

class ShopStore extends ChangeNotifier {
  ShopStore({this.client, this.startupError}) {
    _listenToAuth();
  }
  void _listenToAuth() {
    _authSubscription?.cancel();
    _authSubscription = client?.auth.onAuthStateChange.listen((_) {
      if (client?.auth.currentSession == null) {
        bag.clear();
        orders.clear();
        demoAddress = null;
      }
      notifyListeners();
    });
  }

  SupabaseClient? client;
  String? startupError;
  bool connecting = false;
  Future<void> connect(String url, String key) async {
    connecting = true;
    notifyListeners();
    try {
      if (!url.startsWith('https://') || key.isEmpty) {
        throw const FormatException('Missing backend configuration');
      }
      await Supabase.initialize(url: url, publishableKey: key);
      client = Supabase.instance.client;
      _listenToAuth();
    } catch (_) {
      startupError = 'We couldn’t connect to the store. Check the connection and reopen the app.';
    } finally {
      connecting = false;
      notifyListeners();
    }
  }

  StreamSubscription<AuthState>? _authSubscription;
  bool get isDemo => client == null && startupError == null;
  bool get signedIn => client?.auth.currentSession != null;
  bool browsing = false;
  bool demoTour = false;
  bool get needsOnboarding =>
      demoTour ||
      (signedIn &&
          client!.auth.currentUser?.userMetadata?['onboarding_complete'] ==
              false);
  String get displayName {
    final name =
        client?.auth.currentUser?.userMetadata?['display_name'] as String?;
    if (name != null && name.trim().isNotEmpty) return name.trim();
    final localPart = client?.auth.currentUser?.email?.split('@').first ?? '';
    if (localPart.isEmpty) return 'there';
    return localPart
        .split(RegExp(r'[._-]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  List<Map<String, dynamic>> get savedAddresses {
    final stored =
        client?.auth.currentUser?.userMetadata?['delivery_addresses'];
    if (stored is List) {
      return stored
          .whereType<Map>()
          .map((address) => Map<String, dynamic>.from(address))
          .toList();
    }
    final legacy = client?.auth.currentUser?.userMetadata?['delivery_address'];
    if (legacy is Map) return [Map<String, dynamic>.from(legacy)];
    if (demoAddresses.isNotEmpty) return demoAddresses;
    return demoAddress == null ? [] : [demoAddress!];
  }

  Map<String, dynamic>? get savedAddress {
    final addresses = savedAddresses;
    return addresses.isEmpty ? null : addresses.first;
  }

  Map<String, dynamic>? demoAddress;
  List<Map<String, dynamic>> demoAddresses = [];
  void previewOnboarding() {
    demoTour = true;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    if (signedIn) {
      await client!.auth.updateUser(
        UserAttributes(data: {'onboarding_complete': true}),
      );
    }
    demoTour = false;
    browsing = true;
    notifyListeners();
  }

  Future<void> saveAddress(Map<String, dynamic> address) async {
    final label = address['label'] as String? ?? 'Home';
    final addresses = [
      address,
      ...savedAddresses.where(
        (saved) => (saved['label'] as String? ?? 'Home') != label,
      ),
    ];
    if (signedIn) {
      await client!.auth.updateUser(
        UserAttributes(
          data: {'delivery_address': address, 'delivery_addresses': addresses},
        ),
      );
    } else {
      demoAddress = address;
      demoAddresses = addresses;
    }
    notifyListeners();
  }

  bool loading = false;
  String? catalogError;
  List<Product> products = [];
  final Map<String, int> bag = {};
  int get count => bag.values.fold(0, (a, b) => a + b);
  int get total => products.fold(0, (sum, p) => sum + p.price * quantity(p));
  int get savings => products.fold(
    0,
    (sum, p) => sum + (p.originalPrice - p.price) * quantity(p),
  );
  int quantity(Product product) => bag[product.id] ?? 0;

  Future<void> loadProducts() async {
    loading = true;
    catalogError = null;
    notifyListeners();
    try {
      if (startupError != null) throw StateError(startupError!);
      products = client == null
          ? demoProducts
          : (await client!
                    .from('products')
                    .select()
                    .eq('active', true)
                    .order('sort_order'))
                .map(Product.fromJson)
                .toList();
      final available = {for (final p in products) p.id: p.stock};
      bag.removeWhere(
        (id, _) => !available.containsKey(id) || available[id]! <= 0,
      );
      bag.updateAll((id, count) => count.clamp(0, available[id]!));
    } catch (_) {
      catalogError =
          'The shelves could not load. Check your connection and try again.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void browse() {
    browsing = true;
    notifyListeners();
  }

  void changeQuantity(Product product, int delta) {
    final next = (quantity(product) + delta).clamp(
      0,
      product.stock.clamp(0, 99),
    );
    if (next == 0) {
      bag.remove(product.id);
    } else {
      bag[product.id] = next;
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    await client?.auth.signOut();
    browsing = false;
    demoTour = false;
    demoAddress = null;
    demoAddresses = [];
    orders.clear();
    bag.clear();
    notifyListeners();
  }

  List<ShopOrder> orders = [];
  bool ordersLoading = false;
  String? ordersError;
  final Map<String, ShopOrder> _demoRequests = {};
  Future<void> loadOrders() async {
    if (!signedIn) return;
    ordersLoading = true;
    ordersError = null;
    notifyListeners();
    try {
      final rows = await client!
          .from('orders')
          .select('*, order_items(*)')
          .order('created_at', ascending: false);
      orders = rows.map(ShopOrder.fromJson).toList();
    } catch (_) {
      ordersError = 'Your orders could not load. Please try again.';
    } finally {
      ordersLoading = false;
      notifyListeners();
    }
  }

  Future<ShopOrder> placeOrder(
    DeliveryAddress address,
    String requestId,
  ) async {
    if (isDemo && _demoRequests.containsKey(requestId)) {
      return _demoRequests[requestId]!;
    }
    if (count == 0) throw StateError('Your bag is empty.');
    if (!signedIn && !isDemo) {
      throw StateError('Please sign in to place your order.');
    }
    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(address.phone.trim()) ||
        !RegExp(r'^[1-9][0-9]{5}$').hasMatch(address.pincode.trim()) ||
        address.line1.trim().length < 5 ||
        address.name.trim().length < 2 ||
        address.city.trim().length < 2) {
      throw StateError('Please enter a complete delivery address.');
    }
    final fee = deliveryFee(total);
    late final ShopOrder order;
    if (isDemo) {
      order = ShopOrder(
        id: requestId,
        createdAt: DateTime.now(),
        status: 'placed',
        total: total + fee,
        deliveryFee: fee,
        address: address,
        demo: true,
        items: products
            .where((p) => quantity(p) > 0)
            .map(
              (p) => <String, dynamic>{
                'product_id': p.id,
                'name': p.name,
                'unit': p.unit,
                'image': p.image,
                'quantity': quantity(p),
                'price_paise': p.price,
              },
            )
            .toList(),
      );
      _demoRequests[requestId] = order;
    } else {
      final result = await client!.rpc(
        'place_order',
        params: {
          'p_request_id': requestId,
          'p_address': address.toJson(),
          'p_items': bag.entries
              .map((e) => {'product_id': e.key, 'quantity': e.value})
              .toList(),
          'p_expected_total': total + fee,
        },
      );
      order = ShopOrder.fromJson(Map<String, dynamic>.from(result as Map));
    }
    orders.removeWhere((o) => o.id == order.id);
    orders.insert(0, order);
    bag.clear();
    notifyListeners();
    if (signedIn) unawaited(loadProducts());
    return order;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
