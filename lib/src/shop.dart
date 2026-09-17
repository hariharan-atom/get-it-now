import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'art.dart';
import 'auth.dart';
import 'store.dart';
import 'theme.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({
    super.key,
    required this.store,
    this.initialCategory = 'All',
    this.onBag,
    this.onAccount,
  });
  final ShopStore store;
  final String initialCategory;
  final VoidCallback? onBag, onAccount;
  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final search = TextEditingController();
  late String category = widget.initialCategory;
  @override
  void initState() {
    super.initState();
    if (widget.store.products.isEmpty) {
      Future.microtask(widget.store.loadProducts);
    }
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void bag() {
    if (widget.onBag != null) {
      widget.onBag!();
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.lavender,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (_) => BagSheet(store: widget.store),
    );
  }

  Future<void> account() async {
    if (widget.onAccount != null) {
      widget.onAccount!();
      return;
    }
    if (!widget.store.signedIn) {
      await showAuth(context, widget.store);
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 520),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your account', style: headline(28)),
            const SizedBox(height: 16),
            Text(widget.store.client!.auth.currentUser!.email ?? 'Signed in'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  Navigator.pop(sheetContext);
                  try {
                    await widget.store.signOut();
                  } catch (_) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not sign out. Try again.'),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Sign out'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) {
      final store = widget.store;
      final categories = [
        'All',
        ...store.products.map((p) => p.category).toSet(),
      ];
      if (!categories.contains(category)) category = 'All';
      final products = store.products
          .where(
            (p) =>
                (category == 'All' || p.category == category) &&
                '${p.name} ${p.category}'.toLowerCase().contains(
                  search.text.trim().toLowerCase(),
                ),
          )
          .toList();
      return Scaffold(
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: store.loadProducts,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Brand(small: true),
                            const Spacer(),
                            IconButton(
                              onPressed: account,
                              tooltip: 'Your account',
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white,
                              ),
                              icon: const Icon(LucideIcons.user, size: 21),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: bag,
                              tooltip: 'Open shopping bag',
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.mint,
                              ),
                              icon: Badge(
                                isLabelVisible: store.count > 0,
                                label: Text('${store.count}'),
                                child: const Icon(
                                  LucideIcons.shoppingBag,
                                  size: 21,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'A FRESH START TO YOUR DAY',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.7,
                            fontWeight: FontWeight.w700,
                            color: AppColors.forest,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text('What’s on your list?', style: headline(30)),
                        const SizedBox(height: 20),
                        TextField(
                          controller: search,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Search milk, bread, and happy things',
                            hintStyle: const TextStyle(
                              fontSize: 14,
                              color: AppColors.muted,
                            ),
                            prefixIcon: const Icon(
                              LucideIcons.search,
                              size: 20,
                            ),
                            suffixIcon: search.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear search',
                                    onPressed: () => setState(search.clear),
                                    icon: const Icon(LucideIcons.x, size: 18),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.mint,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) => Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'THE EVERYDAY EDIT',
                                        style: TextStyle(
                                          color: AppColors.forest,
                                          letterSpacing: 1.5,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Fresh picks.\nFull of good.',
                                        style: headline(
                                          28,
                                          color: AppColors.forest,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Little essentials. Big day energy.',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.forest,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (constraints.maxWidth > 300)
                                  const SizedBox(
                                    width: 130,
                                    child: GroceryArt(),
                                  ),
                              ],
                            ),
                          ),
                        ).enter(context),
                        const SizedBox(height: 24),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: categories
                                .map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: ChoiceChip(
                                      label: Text(item),
                                      selected: category == item,
                                      showCheckmark: false,
                                      avatar: Icon(
                                        switch (item) {
                                          'Fresh' => LucideIcons.leaf,
                                          'Dairy' => LucideIcons.milk,
                                          'Bakery' => LucideIcons.croissant,
                                          _ => LucideIcons.layoutGrid,
                                        },
                                        size: 17,
                                        color: category == item
                                            ? Colors.white
                                            : AppColors.forest,
                                      ),
                                      selectedColor: AppColors.forest,
                                      backgroundColor: Colors.white,
                                      labelStyle: TextStyle(
                                        color: category == item
                                            ? Colors.white
                                            : AppColors.ink,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 13,
                                        vertical: 13,
                                      ),
                                      side: BorderSide.none,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      onSelected: (_) =>
                                          setState(() => category = item),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            Text(
                              search.text.isEmpty
                                  ? 'Your everyday favourites'
                                  : 'Search results',
                              style: headline(21),
                            ),
                            Text(
                              '${products.length} fresh ${products.length == 1 ? 'find' : 'finds'}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (store.isDemo)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.info,
                                  size: 15,
                                  color: AppColors.muted,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Demo catalog · Browse and build your bag',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (store.loading)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                else if (store.catalogError != null)
                  SliverToBoxAdapter(
                    child: _EmptyState(
                      icon: LucideIcons.cloudOff,
                      title: 'A little connection hiccup',
                      body: store.catalogError!,
                      action: 'Try again',
                      onPressed: store.loadProducts,
                    ),
                  )
                else if (products.isEmpty)
                  SliverToBoxAdapter(
                    child: _EmptyState(
                      icon: LucideIcons.search,
                      title: 'Nothing on this shelf yet',
                      body:
                          'Try another search or explore all the fresh finds.',
                      action: 'Reset filters',
                      onPressed: () => setState(() {
                        search.clear();
                        category = 'All';
                      }),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverLayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.crossAxisExtent;
                        final scale =
                            MediaQuery.textScalerOf(context).scale(14) / 14;
                        final columns = width > 850
                            ? 4
                            : width > 600
                            ? 3
                            : width < 310 || scale > 1.5
                            ? 1
                            : 2;
                        return SliverGrid(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => ProductCard(
                              product: products[index],
                              store: store,
                            ),
                            childCount: products.length,
                          ),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 16,
                                mainAxisExtent: 295 + (scale - 1) * 110,
                              ),
                        );
                      },
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good food.\nGood mood.',
                          style: TextStyle(
                            fontFamily: 'Epilogue',
                            fontWeight: FontWeight.w900,
                            fontSize: 34,
                            letterSpacing: -1.8,
                            height: 1.1,
                            color: AppColors.forest,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'A little more fresh in your everyday.',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: store.count == 0
            ? null
            : SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: FilledButton(
                    onPressed: bag,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.forest,
                      foregroundColor: Colors.white,
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.shoppingBag, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${store.count} ${store.count == 1 ? 'item' : 'items'} · ${money(store.total)}',
                          ),
                        ),
                        const Text('View bag'),
                        const SizedBox(width: 8),
                        const Icon(LucideIcons.arrowRight, size: 19),
                      ],
                    ),
                  ).enter(context),
                ),
              ),
      );
    },
  );
}

class ProductPhoto extends StatelessWidget {
  const ProductPhoto({super.key, required this.product});
  final Product product;
  @override
  Widget build(BuildContext context) {
    Widget fallback(BuildContext context, Object error, StackTrace? stack) =>
        const ColoredBox(
          color: AppColors.paleGreen,
          child: Center(
            child: Icon(
              LucideIcons.shoppingBag,
              size: 40,
              color: AppColors.forest,
            ),
          ),
        );
    return product.image.startsWith('https://')
        ? Image.network(
            product.image,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: fallback,
            semanticLabel: product.name,
          )
        : Image.asset(
            product.image,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: fallback,
            semanticLabel: product.name,
          );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.store});
  final Product product;
  final ShopStore store;
  void details(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 520),
    builder: (_) => ListenableBuilder(
      listenable: store,
      builder: (context, _) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                tooltip: 'Close product details',
                icon: const Icon(LucideIcons.x),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                height: 250,
                width: double.infinity,
                child: ProductPhoto(product: product),
              ),
            ),
            const SizedBox(height: 24),
            Text(product.name, style: headline(28)),
            const SizedBox(height: 8),
            Text(
              '${product.unit} · ${product.category}',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text(money(product.price), style: headline(25)),
                const Spacer(),
                QuantityControl(product: product, store: store),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              product.stock > 0
                  ? 'In stock · Picked for your everyday'
                  : 'Currently out of stock',
              style: const TextStyle(color: AppColors.forest),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: InkWell(
            onTap: () => details(context),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ProductPhoto(product: product),
                if (product.badge.isNotEmpty)
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 10,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.paleGreen,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          product.badge,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.forest,
                            letterSpacing: .5,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.unit,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 3),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 4, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      money(product.price),
                      style: const TextStyle(
                        fontFamily: 'Epilogue',
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    if (product.originalPrice > product.price)
                      Text(
                        money(product.originalPrice),
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              QuantityControl(product: product, store: store),
            ],
          ),
        ),
      ],
    ),
  );
}

class QuantityControl extends StatelessWidget {
  const QuantityControl({
    super.key,
    required this.product,
    required this.store,
  });
  final Product product;
  final ShopStore store;
  void change(int delta) {
    HapticFeedback.selectionClick();
    store.changeQuantity(product, delta);
  }

  @override
  Widget build(BuildContext context) {
    final quantity = store.quantity(product);
    if (quantity == 0) {
      return TextButton(
        onPressed: product.stock == 0 ? null : () => change(1),
        style: TextButton.styleFrom(
          backgroundColor: AppColors.paleGreen,
          foregroundColor: AppColors.forest,
          minimumSize: const Size(56, 48),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        child: Semantics(
          label: 'Add ${product.name} to bag',
          child: Text(
            product.stock == 0 ? 'Sold out' : 'ADD',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => change(-1),
            tooltip: 'Remove one ${product.name}',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            padding: EdgeInsets.zero,
            icon: const Icon(LucideIcons.minus, size: 14),
          ),
          AnimatedSwitcher(
            duration: motionDuration(context),
            child: Text(
              '$quantity',
              key: ValueKey(quantity),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            onPressed: quantity >= product.stock.clamp(0, 99)
                ? null
                : () => change(1),
            tooltip: 'Add one ${product.name}',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            padding: EdgeInsets.zero,
            icon: const Icon(LucideIcons.plus, size: 14),
          ),
        ],
      ),
    );
  }
}

class BagSheet extends StatelessWidget {
  const BagSheet({
    super.key,
    required this.store,
    this.embedded = false,
    this.onContinue,
    this.onCheckout,
  });
  final ShopStore store;
  final bool embedded;
  final VoidCallback? onContinue, onCheckout;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      void continueShopping() {
        if (onContinue != null) {
          onContinue!();
        } else {
          Navigator.pop(context);
        }
      }

      Widget content(ScrollController? controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              Expanded(child: Text('Your happy bag', style: headline(28))),
              if (!embedded)
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close bag',
                  icon: const Icon(LucideIcons.x),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (store.count == 0)
            _EmptyState(
              icon: LucideIcons.shoppingBag,
              title: 'Good things belong here.',
              body: 'Your bag is empty. Let’s find you something fresh.',
              action: 'Explore products',
              onPressed: continueShopping,
            )
          else ...[
            ...store.products
                .where((p) => store.quantity(p) > 0)
                .map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: SizedBox(
                                width: 64,
                                height: 64,
                                child: ProductPhoto(product: p),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    p.unit,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              money(p.price * store.quantity(p)),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            QuantityControl(product: p, store: store),
                          ],
                        ),
                        const Divider(color: AppColors.line),
                      ],
                    ),
                  ),
                ),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.paleGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.partyPopper,
                    size: 20,
                    color: AppColors.forest,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You’re saving ${money(store.savings)} on these picks.',
                      style: const TextStyle(
                        color: AppColors.forest,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 16,
              runSpacing: 12,
              children: [
                const Text('Item subtotal'),
                Text(money(store.total), style: headline(24)),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Free delivery from ₹299. Otherwise ₹25. Pay cash on delivery.',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            if (store.isDemo)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Demo bag · Checkout creates a preview order only.',
                  style: TextStyle(fontSize: 13, color: AppColors.forest),
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onCheckout,
              child: const Text('Continue to checkout'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: continueShopping,
              child: const Text('Keep exploring'),
            ),
          ],
        ],
      );
      return embedded
          ? content(null)
          : DraggableScrollableSheet(
              initialChildSize: .8,
              minChildSize: .4,
              maxChildSize: .95,
              expand: false,
              builder: (context, controller) => content(controller),
            );
    },
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
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
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        Icon(icon, size: 40, color: AppColors.forest),
        const SizedBox(height: 20),
        Text(title, style: headline(23), textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 20),
        OutlinedButton(onPressed: onPressed, child: Text(action)),
      ],
    ),
  );
}
