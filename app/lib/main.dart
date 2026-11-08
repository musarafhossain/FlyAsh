import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/config/preferences.dart';
import 'core/network/session.dart';

Future<void> main() async {
  // Web: clean URLs (/expenses instead of /#/expenses). No effect on other platforms.
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicenses();

  // Loaded before the first frame so the saved theme is used immediately.
  final prefs = await SharedPreferences.getInstance();
  // Token in memory before the first request.
  final tokens = TokenStore(const FlutterSecureStorage());
  await tokens.load();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        tokenStoreProvider.overrideWithValue(tokens),
      ],
      child: const FlyAshApp(),
    ),
  );
}

/// Bundled fonts are SIL Open Font License; show them on the licenses page.
void _registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final (name, file) in [
      ('Inter', 'OFL-Inter.txt'),
      ('Hind Siliguri', 'OFL-HindSiliguri.txt'),
    ]) {
      final text = await rootBundle.loadString('assets/fonts/$file');
      yield LicenseEntryWithLineBreaks([name], text);
    }
  });
}
