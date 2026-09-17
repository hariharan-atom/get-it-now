import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src/app.dart';
import 'src/store.dart';

Future<({String url, String key})> loadSupabaseConfiguration() async {
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
  // Explicit build configuration overrides the bundled public configuration.
  if (url.isNotEmpty || key.isNotEmpty) return (url: url, key: key);
  final config = jsonDecode(
    await rootBundle.loadString('config/supabase.json'),
  ) as Map<String, dynamic>;
  return (
    url: config['SUPABASE_URL'] as String,
    key:
        (config['SUPABASE_PUBLISHABLE_KEY'] ?? config['SUPABASE_ANON_KEY'])
            as String,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = ShopStore();
  if (!const bool.fromEnvironment('DEMO_MODE')) {
    try {
      final config = await loadSupabaseConfiguration();
      unawaited(store.connect(config.url, config.key));
    } catch (_) {
      store.startupError = 'The store configuration could not load. Please reopen the app or install the latest version.';
    }
  }
  runApp(GetItNowApp(store: store));
}