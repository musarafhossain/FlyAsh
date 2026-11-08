import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/preferences.dart';

/// The app language: 'en' or 'bn'. Sent as `Accept-Language` on every
/// request so API messages come back in the same language.
/// F5 adds the translated UI (ARB files) and the account sync.
class LocaleController extends Notifier<String> {
  static const _key = 'app.locale';
  static const supported = ['en', 'bn'];

  @override
  String build() {
    final saved = ref.read(sharedPreferencesProvider).getString(_key);
    return supported.contains(saved) ? saved! : 'en';
  }

  Future<void> setLocale(String code) async {
    if (!supported.contains(code)) return;
    state = code;
    await ref.read(sharedPreferencesProvider).setString(_key, code);
  }
}

final localeProvider = NotifierProvider<LocaleController, String>(
  LocaleController.new,
);
