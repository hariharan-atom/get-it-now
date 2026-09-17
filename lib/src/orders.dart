import 'dart:math';

class DeliveryAddress {
  const DeliveryAddress({
    this.label = 'Home',
    required this.name,
    required this.phone,
    required this.line1,
    required this.city,
    required this.pincode,
  });
  final String label, name, phone, line1, city, pincode;
  Map<String, dynamic> toJson() => {
    'label': label,
    'name': name.trim(),
    'phone': phone.trim(),
    'line1': line1.trim(),
    'city': city.trim(),
    'pincode': pincode.trim(),
  };
  factory DeliveryAddress.fromJson(Map<String, dynamic> json) =>
      DeliveryAddress(
        label: json['label'] as String? ?? 'Home',
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        line1: json['line1'] as String? ?? '',
        city: json['city'] as String? ?? '',
        pincode: json['pincode'] as String? ?? '',
      );
}

class ShopOrder {
  const ShopOrder({
    required this.id,
    required this.createdAt,
    required this.status,
    required this.total,
    required this.deliveryFee,
    required this.address,
    required this.items,
    this.demo = false,
  });
  final String id, status;
  final DateTime createdAt;
  final int total, deliveryFee;
  final DeliveryAddress address;
  final List<Map<String, dynamic>> items;
  final bool demo;
  String get shortId => id.substring(0, min(8, id.length)).toUpperCase();
  String get statusLabel => switch (status) {
    'placed' => 'Order placed',
    'preparing' => 'Being prepared',
    'out_for_delivery' => 'Out for delivery',
    'delivered' => 'Delivered',
    'cancelled' => 'Cancelled',
    _ => 'Order received',
  };
  String get deliveryEstimate => demo
      ? 'This is a preview order. No delivery will take place.'
      : switch (status) {
          'placed' => 'Estimated delivery: about 30 minutes.',
          'preparing' => 'Your bag is being packed now.',
          'out_for_delivery' => 'Your rider is on the way.',
          'delivered' => 'Delivered. Enjoy your fresh finds!',
          'cancelled' => 'This order was cancelled.',
          _ => 'We will update you when your order is on the way.',
        };
  factory ShopOrder.fromJson(Map<String, dynamic> json) => ShopOrder(
    id: json['id'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    status: json['status'] as String,
    total: (json['total_paise'] as num).toInt(),
    deliveryFee: (json['delivery_fee_paise'] as num).toInt(),
    address: DeliveryAddress.fromJson(
      Map<String, dynamic>.from(json['address'] as Map),
    ),
    items: (json['order_items'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(),
  );
}

int deliveryFee(int subtotal) => subtotal >= 29900 ? 0 : 2500;
String newRequestId() {
  final random = Random.secure();
  return List.generate(
    16,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}
