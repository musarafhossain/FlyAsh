import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error/failure.dart';
import '../l10n/locale_controller.dart';
import '../network/api_client.dart';
import '../network/api_response.dart';
import '../network/session.dart';
import '../theme/theme_controller.dart';

/// Keeps language, theme mode and accent color in sync with the user's
/// account (`users.locale`, `users.theme_mode`, `users.accent_color`):
///
/// - a change made in the app is sent with `PUT /auth/preferences`
///   (only the changed fields, and only while logged in)
/// - after login / `/auth/me`, [applyFromAccount] applies the account values
///   without sending them back
///
/// Font size is a device setting and is never sent. Failures are ignored:
/// the value is already saved on the device and is sent again with the next change.
class PreferencesSync {
  PreferencesSync(this._ref);

  final Ref _ref;
  bool _applying = false;

  Future<void> applyFromAccount(Json user) async {
    _applying = true;
    try {
      final locale = user['locale'] as String?;
      if (locale != null) {
        await _ref.read(localeProvider.notifier).setLocale(locale);
      }
      await _ref
          .read(themeControllerProvider.notifier)
          .applyFromAccount(
            themeMode: user['theme_mode'] as String?,
            accentColor: user['accent_color'] as String?,
          );
    } finally {
      _applying = false;
    }
  }

  void _onLocaleChanged(String? previous, String next) {
    if (previous == null || previous == next) return;
    _push({'locale': next});
  }

  void _onThemeChanged(ThemeSettings? previous, ThemeSettings next) {
    if (previous == null) return;
    _push({
      if (previous.mode != next.mode) 'theme_mode': next.mode.name,
      if (previous.accent != next.accent) 'accent_color': next.accent.name,
    });
  }

  Future<void> _push(Json body) async {
    final loggedIn = _ref.read(tokenStoreProvider).hasToken;
    if (_applying || body.isEmpty || !loggedIn) return;
    try {
      await _ref
          .read(apiClientProvider)
          .put('/auth/preferences', body: body, parse: (d) => d);
    } on Failure catch (e) {
      debugPrint('Preferences not saved to the account yet: $e');
    }
  }
}

/// Watch this once (in the app root) so the listeners stay active.
final preferencesSyncProvider = Provider<PreferencesSync>((ref) {
  final sync = PreferencesSync(ref);
  ref.listen<String>(localeProvider, sync._onLocaleChanged);
  ref.listen<ThemeSettings>(themeControllerProvider, sync._onThemeChanged);
  return sync;
});
