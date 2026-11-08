import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flyash/core/config/preferences.dart';
import 'package:flyash/core/config/preferences_sync.dart';
import 'package:flyash/core/l10n/locale_controller.dart';
import 'package:flyash/core/network/api_client.dart';
import 'package:flyash/core/theme/app_colors.dart';
import 'package:flyash/core/theme/theme_controller.dart';
import 'package:flyash/core/network/session.dart';

import '../fake_api.dart';

/// Container with the sync active; records every request body.
Future<(ProviderContainer, List<(String, Object?)>)> setup({
  String? token,
  int status = 200,
}) async {
  SharedPreferences.setMockInitialValues({});
  FlutterSecureStorage.setMockInitialValues({'auth.token': ?token});
  final prefs = await SharedPreferences.getInstance();
  final tokens = TokenStore(const FlutterSecureStorage());
  await tokens.load();
  final c = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      tokenStoreProvider.overrideWithValue(tokens),
    ],
  );
  addTearDown(c.dispose);

  final requests = <(String, Object?)>[];
  c.read(dioProvider).httpClientAdapter = FakeAdapter((o) {
    requests.add((
      '${o.method} ${o.path}',
      o.data is String ? jsonDecode(o.data as String) : o.data,
    ));
    return (status, envelope(status, 'Preferences saved', {}), {});
  });
  c.read(preferencesSyncProvider); // activate listeners
  return (c, requests);
}

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 10));

void main() {
  test('logged in: each change sends only the changed field', () async {
    final (c, requests) = await setup(token: 'oat_x');

    await c.read(themeControllerProvider.notifier).setAccent(AccentColor.brick);
    await c.read(themeControllerProvider.notifier).setMode(ThemeMode.dark);
    await c.read(localeProvider.notifier).setLocale('bn');
    await settle();

    expect(requests.map((r) => r.$1).toSet(), {'PUT /auth/preferences'});
    expect(requests.map((r) => r.$2).toList(), [
      {'accent_color': 'brick'},
      {'theme_mode': 'dark'},
      {'locale': 'bn'},
    ]);
  });

  test('font size is a device setting and is never sent', () async {
    final (c, requests) = await setup(token: 'oat_x');
    await c.read(themeControllerProvider.notifier).setFontScale(1.15);
    await settle();
    expect(requests, isEmpty);
  });

  test('logged out: nothing is sent, the change stays on the device', () async {
    final (c, requests) = await setup();
    await c
        .read(themeControllerProvider.notifier)
        .setAccent(AccentColor.violet);
    await settle();
    expect(requests, isEmpty);
    expect(
      c.read(sharedPreferencesProvider).getString('theme.accent'),
      'violet',
    );
  });

  test('values from the account are applied without being sent back', () async {
    final (c, requests) = await setup(token: 'oat_x');
    await c.read(preferencesSyncProvider).applyFromAccount({
      'locale': 'bn',
      'theme_mode': 'light',
      'accent_color': 'emerald',
    });
    await settle();

    expect(c.read(localeProvider), 'bn');
    expect(c.read(themeControllerProvider).mode, ThemeMode.light);
    expect(c.read(themeControllerProvider).accent, AccentColor.emerald);
    expect(requests, isEmpty);
  });

  test('a server error does not throw', () async {
    final (c, requests) = await setup(token: 'oat_x', status: 500);
    await c.read(localeProvider.notifier).setLocale('bn');
    await settle();
    expect(requests, hasLength(1));
    expect(c.read(localeProvider), 'bn');
  });
}
