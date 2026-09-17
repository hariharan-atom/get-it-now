import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'art.dart';
import 'auth.dart';
import 'onboarding.dart';
import 'shell.dart';
import 'store.dart';
import 'theme.dart';

class GetItNowApp extends StatelessWidget {
  const GetItNowApp({super.key, required this.store});
  final ShopStore store;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'GET IT NOW',
    debugShowCheckedModeBanner: false,
    theme: appTheme(),
    builder: (context, child) => ColoredBox(
      color: AppColors.blue,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: child,
        ),
      ),
    ),
    home: LaunchGate(store: store),
  );
}

class LaunchGate extends StatefulWidget {
  const LaunchGate({super.key, required this.store});
  final ShopStore store;
  @override
  State<LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends State<LaunchGate> {
  bool launched = false;
  Timer? timer;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    timer ??= Timer(
      MediaQuery.disableAnimationsOf(context)
          ? const Duration(milliseconds: 100)
          : const Duration(milliseconds: 450),
      () {
        if (mounted) setState(() => launched = true);
      },
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) {
      final store = widget.store;
      final Widget screen = !launched || store.connecting
          ? const AnimatedLaunchScreen()
          : store.needsOnboarding
          ? OnboardingScreen(store: store)
          : store.signedIn || store.browsing
          ? AppShell(store: store)
          : WelcomeScreen(store: store);
      return AnimatedSwitcher(duration: motionDuration(context), child: screen);
    },
  );
}

class AnimatedLaunchScreen extends StatelessWidget {
  const AnimatedLaunchScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    Widget animate(Widget child, int delay) => reduced
        ? child
        : child
              .animate()
              .fadeIn(delay: delay.ms, duration: 450.ms)
              .slideY(
                begin: .35,
                end: 0,
                duration: 600.ms,
                curve: Curves.easeOutBack,
              );
    return Scaffold(
      backgroundColor: AppColors.forest,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  animate(
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.mint,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Icon(
                        LucideIcons.zap,
                        size: 52,
                        color: AppColors.forest,
                      ),
                    ),
                    0,
                  ),
                  const SizedBox(height: 32),
                  FittedBox(
                    child: Column(
                      children: [
                        animate(
                          Text(
                            'GET IT',
                            style: headline(68, color: AppColors.mint),
                          ),
                          180,
                        ),
                        animate(
                          Text(
                            'NOW.',
                            style: headline(82, color: Colors.white),
                          ),
                          350,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  animate(
                    const Text(
                      'Fresh finds. Everyday happiness.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.mint, fontSize: 15),
                    ),
                    550,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.store});
  final ShopStore store;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Align(
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Brand(),
                      ),
                      const SizedBox(height: 24),
                      const SizedBox(
                        width: 230,
                        child: GroceryArt(),
                      ).enter(context),
                      const SizedBox(height: 24),
                      Text(
                        'Your everyday.\nDelivered.',
                        textAlign: TextAlign.center,
                        style: headline(40),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Fresh groceries and little essentials.\nLet’s get you started.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted),
                      ),
                      const SizedBox(height: 32),
                      if (store.startupError != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            store.startupError!,
                            style: const TextStyle(color: AppColors.forest),
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => showAuth(context, store),
                          child: const Text('Sign in'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () =>
                              showAuth(context, store, signup: true),
                          child: const Text('Create account'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: store.browse,
                        child: Text(
                          store.isDemo ? 'Explore demo' : 'Browse as guest',
                        ),
                      ),
                    ],
                  ).enter(context, delay: 100),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
