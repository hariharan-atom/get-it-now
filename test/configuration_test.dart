import 'package:flutter_test/flutter_test.dart';
import 'package:get_it_now/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'normal launches load the bundled Supabase project without build flags',
    () async {
      final config = await loadSupabaseConfiguration();
      expect(config.url, matches(r'^https://[a-z0-9]+\.supabase\.co$'));
      expect(config.key, startsWith('sb_publishable_'));
    },
  );
}
