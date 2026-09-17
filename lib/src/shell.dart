import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'art.dart';
import 'auth.dart';
import 'checkout.dart';
import 'orders.dart';
import 'shop.dart';
import 'store.dart';
import 'theme.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.store});
  final ShopStore store;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int tab = 0, catalogVersion = 0;
  String category = 'All';
  void select(int index) {
    setState(() => tab = index);
    if (index == 3) widget.store.loadOrders();
  }

  void checkout() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    useSafeArea: true,
    backgroundColor: AppColors.lavender,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (_) =>
        CheckoutSheet(store: widget.store, onOrders: () => select(3)),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) {
      final store = widget.store;
      return PopScope(
        canPop: tab == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) select(0);
        },
        child: Scaffold(
          body: IndexedStack(
            index: tab,
            children: [
              ShopScreen(
                key: ValueKey(catalogVersion),
                store: store,
                initialCategory: category,
                onBag: () => select(2),
                onAccount: () => select(4),
              ),
              SafeArea(
                child: CategoriesScreen(
                  store: store,
                  onCategory: (value) => setState(() {
                    category = value;
                    catalogVersion++;
                    tab = 0;
                  }),
                ),
              ),
              SafeArea(
                child: BagSheet(
                  store: store,
                  embedded: true,
                  onContinue: () => select(0),
                  onCheckout: checkout,
                ),
              ),
              SafeArea(
                child: OrdersScreen(store: store, onShop: () => select(0)),
              ),
              SafeArea(child: AccountScreen(store: store)),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: select,
            animationDuration: motionDuration(context),
            backgroundColor: Colors.white,
            indicatorColor: AppColors.mint,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              const NavigationDestination(
                icon: Icon(LucideIcons.house, size: 21),
                label: 'Home',
              ),
              const NavigationDestination(
                icon: Icon(LucideIcons.layoutGrid, size: 21),
                label: 'Categories',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: store.count > 0,
                  label: Text('${store.count}'),
                  child: const Icon(LucideIcons.shoppingBag, size: 21),
                ),
                label: 'Bag',
              ),
              const NavigationDestination(
                icon: Icon(LucideIcons.receiptText, size: 21),
                label: 'Orders',
              ),
              const NavigationDestination(
                icon: Icon(LucideIcons.user, size: 21),
                label: 'Account',
              ),
            ],
          ),
        ),
      );
    },
  );
}

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({
    super.key,
    required this.store,
    required this.onCategory,
  });
  final ShopStore store;
  final ValueChanged<String> onCategory;
  @override
  Widget build(BuildContext context) {
    final categories = store.products.map((p) => p.category).toSet();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Brand(small: true),
        const SizedBox(height: 28),
        Text('Find your favourites.', style: headline(32)),
        const SizedBox(height: 12),
        const Text(
          'A little something for every part of your day.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 28),
        if (store.loading)
          const Center(child: CircularProgressIndicator())
        else if (categories.isEmpty)
          EmptyPanel(
            icon: LucideIcons.layoutGrid,
            title: 'The shelves are waiting.',
            body: store.catalogError ?? 'There are no categories yet.',
            action: 'Refresh',
            onPressed: store.loadProducts,
          ),
        ...categories.map((category) {
          final products = store.products
              .where((p) => p.category == category)
              .toList();
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onCategory(category),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child: ProductPhoto(product: products.first),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(category, style: headline(24)),
                            const SizedBox(height: 8),
                            Text(
                              '${products.length} fresh finds',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        LucideIcons.arrowUpRight,
                        color: AppColors.forest,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key, required this.store, required this.onShop});
  final ShopStore store;
  final VoidCallback onShop;
  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: store.loadOrders,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Expanded(child: Text('Your orders', style: headline(32))),
            IconButton(
              onPressed: store.loadOrders,
              tooltip: 'Refresh orders',
              icon: const Icon(LucideIcons.refreshCw),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'All your happy deliveries, in one place.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 24),
        if (store.ordersLoading)
          const Center(child: CircularProgressIndicator())
        else if (store.ordersError != null)
          EmptyPanel(
            icon: LucideIcons.cloudOff,
            title: 'Couldn’t load your orders.',
            body: store.ordersError!,
            action: 'Try again',
            onPressed: store.loadOrders,
          )
        else if (!store.signedIn && !store.isDemo)
          EmptyPanel(
            icon: LucideIcons.user,
            title: 'Your orders are waiting.',
            body: 'Sign in to see your order history.',
            action: 'Sign in',
            onPressed: () => showAuth(context, store),
          )
        else if (store.orders.isEmpty)
          EmptyPanel(
            icon: LucideIcons.receiptText,
            title: 'Your first fresh start.',
            body: 'Once you check out, your orders will appear here.',
            action: 'Find something good',
            onPressed: onShop,
          )
        else
          ...store.orders.map(
            (order) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    constraints: const BoxConstraints(maxWidth: 560),
                    builder: (_) => OrderDetails(order: order),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            Text(
                              '#${order.shortId}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              order.demo ? 'DEMO ORDER' : order.statusLabel,
                              style: const TextStyle(
                                color: AppColors.forest,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          order.items
                              .map((i) => '${i['quantity']} × ${i['name']}')
                              .join(', '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          order.deliveryEstimate,
                          style: const TextStyle(
                            color: AppColors.forest,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SummaryLine(
                          '${order.createdAt.toLocal().day}/${order.createdAt.toLocal().month}/${order.createdAt.toLocal().year}',
                          money(order.total),
                          bold: true,
                        ),
                        const Text(
                          'View order details →',
                          style: TextStyle(
                            color: AppColors.forest,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class OrderDetails extends StatelessWidget {
  const OrderDetails({super.key, required this.order});
  final ShopOrder order;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Order #${order.shortId}', style: headline(26)),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                tooltip: 'Close order',
                icon: const Icon(LucideIcons.x),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            order.demo ? 'Demo · No real delivery' : order.statusLabel,
            style: const TextStyle(
              color: AppColors.forest,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          ...order.items.map(
            (item) => SummaryLine(
              '${item['quantity']} × ${item['name']}',
              money(
                (item['quantity'] as num).toInt() *
                    (item['price_paise'] as num).toInt(),
              ),
            ),
          ),
          const Divider(),
          SummaryLine('Delivery', money(order.deliveryFee)),
          SummaryLine(
            'Total · Cash on delivery',
            money(order.total),
            bold: true,
          ),
          const SizedBox(height: 24),
          Text(
            order.deliveryEstimate,
            style: const TextStyle(color: AppColors.forest),
          ),
          const SizedBox(height: 16),
          Text('Delivering to', style: headline(21)),
          const SizedBox(height: 12),
          Text(
            '${order.address.name}\n${order.address.line1}\n${order.address.city} · ${order.address.pincode}\n${order.address.phone}',
          ),
          const SizedBox(height: 24),
          const Text(
            'Order progress updates when the store changes its status. Pull to refresh your order list.',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ],
      ),
    ),
  );
}

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key, required this.store});
  final ShopStore store;
  Future<void> address(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (sheet) => AddressEditor(
      store: store,
      title: 'Your doorstep.',
      buttonLabel: 'Save address',
      onSubmit: (address) async {
        await store.saveAddress(address.toJson());
        if (sheet.mounted) Navigator.pop(sheet);
      },
    ),
  );
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const Brand(small: true),
      const SizedBox(height: 28),
      Text(
        'Hello, ${store.displayName.split(' ').first}.',
        style: headline(34),
      ),
      const SizedBox(height: 12),
      Text(
        store.client?.auth.currentUser?.email ??
            'A little more fresh in your everyday.',
        style: const TextStyle(color: AppColors.muted),
      ),
      const SizedBox(height: 24),
      if (!store.signedIn) ...[
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.paleGreen,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                store.isDemo
                    ? 'You’re exploring the demo.'
                    : 'Make yourself at home.',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              const Text(
                'Sign in to keep your address and see your orders across devices.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton(
                    onPressed: () => showAuth(context, store),
                    child: const Text('Sign in'),
                  ),
                  OutlinedButton(
                    onPressed: () => showAuth(context, store, signup: true),
                    child: const Text('Sign up'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
      ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        leading: const Icon(LucideIcons.mapPin, color: AppColors.forest),
        title: Text(
          store.savedAddresses.length > 1
              ? 'Delivery addresses'
              : 'Delivery address',
        ),
        subtitle: Text(
          store.savedAddresses.isEmpty
              ? 'Add your favourite doorstep'
              : store.savedAddresses
                    .map(
                      (address) =>
                          '${address['label'] as String? ?? 'Home'} · ${address['line1']}, ${address['city']}',
                    )
                    .join('\n'),
        ),
        isThreeLine: store.savedAddresses.length > 1,
        trailing: const Icon(LucideIcons.chevronRight),
        onTap: () => address(context),
      ),
      const Divider(color: AppColors.line),
      ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        leading: const Icon(LucideIcons.info, color: AppColors.forest),
        title: const Text('About GET IT NOW'),
        subtitle: const Text('Fresh finds. Everyday happiness.\nVersion 1.1.0'),
      ),
      const SizedBox(height: 24),
      OutlinedButton(
        onPressed: () async {
          try {
            await store.signOut();
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not sign out. Try again.')),
              );
            }
          }
        },
        child: Text(store.signedIn ? 'Sign out' : 'Back to sign in'),
      ),
    ],
  );
}

class EmptyPanel extends StatelessWidget {
  const EmptyPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    required this.onPressed,
  });
  final IconData icon;
  final String title, body, action;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Column(
      children: [
        Icon(icon, size: 44, color: AppColors.forest),
        const SizedBox(height: 20),
        Text(title, style: headline(25), textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 24),
        OutlinedButton(onPressed: onPressed, child: Text(action)),
      ],
    ),
  );
}
