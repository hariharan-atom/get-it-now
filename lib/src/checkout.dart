import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth.dart';
import 'orders.dart';
import 'store.dart';
import 'theme.dart';

class CheckoutSheet extends StatefulWidget {
  const CheckoutSheet({super.key, required this.store, required this.onOrders});
  final ShopStore store;
  final VoidCallback onOrders;
  @override
  State<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<CheckoutSheet> {
  final requestId = newRequestId();
  ShopOrder? order;
  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    if (order != null) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppColors.mint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.check,
                  size: 42,
                  color: AppColors.forest,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                order!.demo ? 'Demo order placed!' : 'Order placed!',
                style: headline(32),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Order #${order!.shortId} · ${money(order!.total)}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.paleGreen,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(LucideIcons.clock3, color: AppColors.forest),
                    const SizedBox(height: 8),
                    Text(
                      order!.deliveryEstimate,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.forest,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (!order!.demo) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'Pay cash when it arrives. Track every update in Orders.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onOrders();
                  },
                  child: const Text('View my orders'),
                ),
              ),
            ],
          ).enter(context),
        ),
      );
    }
    return AddressEditor(
      store: store,
      title: 'The last little step.',
      buttonLabel: store.isDemo
          ? 'Place demo order'
          : 'Place order · Pay on delivery',
      introduction: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SummaryLine('Items (${store.count})', money(store.total)),
          SummaryLine(
            'Delivery',
            deliveryFee(store.total) == 0
                ? 'FREE'
                : money(deliveryFee(store.total)),
          ),
          const Divider(color: AppColors.line),
          SummaryLine(
            'Total · Cash on delivery',
            money(store.total + deliveryFee(store.total)),
            bold: true,
          ),
          const SizedBox(height: 16),
          Text(
            store.isDemo ? 'Demo checkout · No real payment or delivery.' : 'Delivery is free on orders of ₹299 or more. Your store updates the order status.',
            style: const TextStyle(color: AppColors.forest, fontSize: 13),
          ),
          const SizedBox(height: 24),
        ],
      ),
      onSubmit: (address) async {
        if (!store.signedIn && !store.isDemo) {
          await showAuth(context, store);
          return;
        }
        await store.saveAddress(address.toJson());
        final result = await store.placeOrder(address, requestId);
        if (mounted) setState(() => order = result);
      },
    );
  }
}

class SummaryLine extends StatelessWidget {
  const SummaryLine(this.label, this.value, {super.key, this.bold = false});
  final String label, value;
  final bool bold;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: bold ? AppColors.forest : AppColors.ink,
            ),
          ),
        ),
      ],
    ),
  );
}

class AddressEditor extends StatefulWidget {
  const AddressEditor({
    super.key,
    required this.store,
    required this.title,
    required this.buttonLabel,
    required this.onSubmit,
    this.introduction,
  });
  final ShopStore store;
  final String title, buttonLabel;
  final Widget? introduction;
  final Future<void> Function(DeliveryAddress) onSubmit;
  @override
  State<AddressEditor> createState() => _AddressEditorState();
}

class _AddressEditorState extends State<AddressEditor> {
  final form = GlobalKey<FormState>();
  late final initial = DeliveryAddress.fromJson(
    widget.store.savedAddress ?? {},
  );
  late final name = TextEditingController(text: initial.name);
  late final phone = TextEditingController(text: initial.phone);
  late final line1 = TextEditingController(text: initial.line1);
  late final city = TextEditingController(text: initial.city);
  late final pincode = TextEditingController(text: initial.pincode);
  late String addressLabel;
  bool busy = false, locating = false;
  String? error, locationError;
  @override
  void initState() {
    super.initState();
    addressLabel = initial.label;
  }

  @override
  void dispose() {
    for (final c in [name, phone, line1, city, pincode]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.onSubmit(
        DeliveryAddress(
          label: addressLabel,
          name: name.text,
          phone: phone.text,
          line1: line1.text,
          city: city.text,
          pincode: pincode.text,
        ),
      );
    } on PostgrestException catch (e) {
      if (mounted) {
        setState(
          () => error = e.code == 'P0001'
              ? e.message
              : 'Checkout is unavailable right now. Please try again.',
        );
      }
    } on StateError catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'The connection was interrupted. Retry here to safely check the same order.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void useSavedAddress(DeliveryAddress address) {
    setState(() {
      addressLabel = address.label;
      name.text = address.name;
      phone.text = address.phone;
      line1.text = address.line1;
      city.text = address.city;
      pincode.text = address.pincode;
      locationError = null;
    });
  }

  Future<void> useCurrentLocation() async {
    setState(() {
      locating = true;
      locationError = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('Turn on Location, then tap “Use my location” again.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw StateError(
          'Location permission was not allowed. Enter your address instead.',
        );
      }
      if (permission == LocationPermission.deniedForever) {
        throw StateError('Allow location in Settings, then try again.');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      final places = await Geocoding().placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (places.isEmpty) {
        throw StateError('We could not find an address here.');
      }
      final place = places.first;
      final street = [
        place.subThoroughfare,
        place.thoroughfare,
        place.subLocality,
      ].whereType<String>().where((part) => part.trim().isNotEmpty).join(', ');
      setState(() {
        line1.text = street.isEmpty ? (place.name ?? '') : street;
        city.text = place.locality ?? place.subAdministrativeArea ?? '';
        pincode.text = place.postalCode ?? '';
      });
    } on StateError catch (e) {
      if (mounted) setState(() => locationError = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => locationError = 'We could not find a complete address. Please fill the remaining fields.',
        );
      }
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Form(
          key: form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: Text(widget.title, style: headline(27))),
                  IconButton(
                    onPressed: busy ? null : () => Navigator.pop(context),
                    tooltip: 'Close address form',
                    icon: const Icon(LucideIcons.x),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (widget.introduction != null) widget.introduction!,
              const Text(
                'DELIVERY ADDRESS',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.5,
                  color: AppColors.forest,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              if (widget.store.savedAddresses.isNotEmpty) ...[
                const Text(
                  'SAVED ADDRESSES',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.5,
                    color: AppColors.forest,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.store.savedAddresses
                      .map(
                        (saved) => ChoiceChip(
                          label: Text(saved['label'] as String? ?? 'Home'),
                          selected:
                              addressLabel ==
                              (saved['label'] as String? ?? 'Home'),
                          onSelected: busy
                              ? null
                              : (_) => useSavedAddress(
                                  DeliveryAddress.fromJson(saved),
                                ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 20),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: busy || locating ? null : useCurrentLocation,
                  icon: locating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(LucideIcons.locateFixed, size: 19),
                  label: Text(
                    locating ? 'Finding your address…' : 'Use my location',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (locationError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      locationError!,
                      style: const TextStyle(color: Color(0xFF8C3028)),
                    ),
                  ),
                ),
              field(name, 'Full name', maxLength: 100),
              field(
                phone,
                'Mobile number',
                keyboard: TextInputType.phone,
                maxLength: 10,
                validator: (s) => RegExp(r'^[6-9][0-9]{9}$').hasMatch(s ?? '')
                    ? null
                    : 'Enter a valid 10-digit Indian mobile number.',
              ),
              field(
                line1,
                'Flat, building and street',
                minLength: 5,
                maxLength: 300,
              ),
              field(city, 'City', maxLength: 100),
              field(
                pincode,
                'PIN code',
                keyboard: TextInputType.number,
                maxLength: 6,
                validator: (s) => RegExp(r'^[1-9][0-9]{5}$').hasMatch(s ?? '')
                    ? null
                    : 'Enter a valid 6-digit PIN code.',
              ),
              const Text(
                'SAVE ADDRESS AS',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.5,
                  color: AppColors.forest,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Home', 'Office', 'Other']
                    .map(
                      (label) => ChoiceChip(
                        label: Text(label),
                        selected: addressLabel == label,
                        onSelected: busy
                            ? null
                            : (_) => setState(() => addressLabel = label),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      error!,
                      style: const TextStyle(color: Color(0xFF8C3028)),
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: busy ? null : submit,
                  child: busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.buttonLabel, textAlign: TextAlign.center),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  Widget field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboard,
    int minLength = 2,
    required int maxLength,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      enabled: !busy,
      keyboardType: keyboard,
      textInputAction: TextInputAction.next,
      maxLength: maxLength,
      decoration: InputDecoration(labelText: label, counterText: ''),
      validator:
          validator ??
          (s) => (s?.trim().length ?? 0) < minLength
              ? 'Enter your ${label.toLowerCase()}.'
              : null,
    ),
  );
}
