import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device storage for small settings (theme, language, last factory date).
///
/// Loaded once in `main()` before the first frame and injected with
/// `sharedPreferencesProvider.overrideWithValue(prefs)`.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main()',
  ),
);
