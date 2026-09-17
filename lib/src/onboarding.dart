import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'store.dart';
import 'theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.store});
  final ShopStore store;
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int page = 0;
  static const pages = [
    (
      'FRESH IN A FEW TAPS',
      'Groceries,\nright now.',
      'From avocados to milk, your everyday essentials\nare ready when you are.',
    ),
    (
      'FAST FROM STORE TO DOOR',
      'At your door.\nBefore you blink.',
      'Your fresh finds are packed locally and on the\nmove in just a few minutes.',
    ),
    (
      'YOUR BASKET, SORTED',
      'Tap. Bag.\nDone.',
      'Build your list, check out quickly, and make\nmore room for your day.',
    ),
  ];

  bool saving = false;
  Future<void> finish() async {
    setState(() => saving = true);
    try {
      await widget.store.completeOnboarding();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save your progress. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1000;
          final compact = constraints.maxWidth < 380;
          final art = GestureDetector(
            onHorizontalDragEnd: (details) {
              final speed = details.primaryVelocity ?? 0;
              if (speed.abs() > 60) {
                setState(
                  () => page = (page + (speed < 0 ? 1 : -1)).clamp(0, 2),
                );
              }
            },
            child: AnimatedSwitcher(
              duration: motionDuration(context),
              child: _OnboardingArt(key: ValueKey(page), page: page),
            ),
          ).enter(context, delay: 80);
          final content = Column(
            crossAxisAlignment: wide
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: motionDuration(context),
                child: Column(
                  key: ValueKey(page),
                  crossAxisAlignment: wide
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    Text(
                      pages[page].$1,
                      textAlign: wide ? TextAlign.start : TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.forest,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      pages[page].$2,
                      textAlign: wide ? TextAlign.start : TextAlign.center,
                      style: headline(
                        wide
                            ? 56
                            : compact
                            ? 37
                            : 42,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      pages[page].$3,
                      textAlign: wide ? TextAlign.start : TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: wide
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (index) => Semantics(
                    selected: page == index,
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: TextButton(
                        onPressed: () => setState(() => page = index),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        child: Semantics(
                          label: 'Onboarding page ${index + 1}',
                          child: AnimatedContainer(
                            duration: motionDuration(context),
                            width: page == index ? 28 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: page == index
                                  ? AppColors.forest
                                  : const Color(0xFFC6C1D5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: saving
                      ? null
                      : () {
                          if (page < 2) {
                            setState(() => page++);
                          } else {
                            finish();
                          }
                        },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          saving
                              ? 'Getting ready…'
                              : page == 2
                              ? 'Let’s shop'
                              : 'Continue',
                        ),
                      ),
                      SizedBox(width: 16),
                      Icon(LucideIcons.arrowUpRight, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.shoppingBag,
                    size: 14,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      'A little less planning. A lot more living.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ).enter(context, delay: 160);
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: wide ? 48 : 24,
                  vertical: wide ? 32 : 16,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: saving ? null : finish,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Skip tour',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(width: 7),
                            Icon(
                              LucideIcons.arrowRight,
                              size: 16,
                              color: AppColors.muted,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (wide) ...[
                      const SizedBox(height: 40),
                      Row(
                        children: [
                          Expanded(
                            flex: 6,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 48),
                              child: art,
                            ),
                          ),
                          Expanded(flex: 5, child: content),
                        ],
                      ),
                      const SizedBox(height: 48),
                      Container(
                        padding: const EdgeInsets.only(top: 24),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: AppColors.line),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _Benefit(LucideIcons.leaf, 'Freshness comes first'),
                            _Benefit(LucideIcons.heart, 'Everyday favourites'),
                            _Benefit(
                              LucideIcons.truck,
                              'Straight to your door',
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 14),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: art,
                      ),
                      const SizedBox(height: 8),
                      content,
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _OnboardingArt extends StatelessWidget {
  const _OnboardingArt({super.key, required this.page});

  final int page;

  static const assets = [
    'assets/onboarding/fresh-groceries.png',
    'assets/onboarding/delivery-scooter.png',
    'assets/onboarding/easy-checkout.png',
  ];

  static const labels = [
    'Fresh groceries in a reusable shopping bag',
    'A quick grocery delivery scooter',
    'A simple grocery checkout on a phone',
  ];

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: labels[page],
    child: ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: 1,
        child: Image.asset(
          assets[page],
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    ),
  );
}

class _Benefit extends StatelessWidget {
  const _Benefit(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: AppColors.forest, size: 19),
      const SizedBox(width: 10),
      Text(label, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
    ],
  );
}
