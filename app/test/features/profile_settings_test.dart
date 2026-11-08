import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:flyash/app.dart';
import 'package:flyash/core/l10n/locale_controller.dart';
import 'package:flyash/core/router/app_router.dart';
import 'package:flyash/core/theme/app_colors.dart';
import 'package:flyash/core/theme/theme_controller.dart';
import 'package:flyash/features/auth/presentation/auth_controller.dart';

import '../fake_api.dart';
import '../helpers.dart';

Map<String, Object?> body(RequestOptions o) =>
    (o.data is String ? jsonDecode(o.data as String) : o.data)
        as Map<String, Object?>;

final factoryJson = <String, Object?>{
  'id': 1,
  'factory_name': 'Maa Tara Fly Ash Bricks',
  'owner_name': 'Rahim Sheikh',
  'phone': '9833333333',
  'email': null,
  'address': 'Barasat, WB',
  'invoice_prefix': 'INV-',
};

FakeRoutes settingsRoutes() {
  final me = Map<String, Object?>.of(sampleUser)
    ..['last_login_at'] = '2026-11-08T14:55:46.000Z';
  return signedInRoutes({
    'GET /auth/me': (_) => (200, envelope(200, 'ok', me), {}),
    'PUT /auth/me': (o) {
      me.addAll(body(o));
      return (200, envelope(200, 'Profile updated successfully', me), {});
    },
    'PUT /auth/password': (o) => body(o)['current_password'] == 'secret123'
        ? (
            200,
            envelope(
              200,
              'Password changed. Other devices were logged out',
              null,
            ),
            {},
          )
        : (
            422,
            envelope(422, 'Validation failed', {
              'errors': [
                {
                  'field': 'current_password',
                  'message': 'Current password is incorrect',
                },
              ],
            }),
            {},
          ),
    'PUT /auth/preferences': (o) =>
        (200, envelope(200, 'Preferences saved', me..addAll(body(o))), {}),
    'GET /settings/factory': (_) => (200, envelope(200, 'ok', factoryJson), {}),
    'PUT /settings/factory': (o) {
      factoryJson.addAll(body(o));
      return (200, envelope(200, 'Factory profile updated', factoryJson), {});
    },
  });
}

Future<List<RequestOptions>> open(
  WidgetTester tester,
  String location, {
  Size size = const Size(360, 800),
}) async {
  final requests = <RequestOptions>[];
  setScreenSize(tester, size);
  await tester.pumpWidget(
    await testApp(
      const FlyAshApp(),
      token: 'oat_saved',
      api: settingsRoutes(),
      requests: requests,
    ),
  );
  await tester.pumpAndSettle();
  testContainer.read(routerProvider).go(location);
  await tester.pumpAndSettle();
  return requests;
}

String currentPath() =>
    testContainer.read(routerProvider).routeInformationProvider.value.uri.path;

void main() {
  setUp(
    () => PackageInfo.setMockInitialValues(
      appName: 'FlyAsh',
      packageName: 'com.flyash.app',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    ),
  );

  testWidgets('settings lists every group and opens each page', (tester) async {
    await open(tester, '/settings');
    expect(find.text('Test Owner'), findsOneWidget);
    expect(find.text('Maa Tara Fly Ash Bricks'), findsOneWidget);

    for (final (label, path) in [
      ('My profile', '/profile'),
      ('Factory profile', '/settings/factory'),
      ('Appearance', '/settings/appearance'),
      ('Language', '/settings/language'),
      ('About', '/settings/about'),
    ]) {
      await tester.scrollUntilVisible(find.text(label).last, 100);
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      expect(currentPath(), path, reason: label);
      testContainer.read(routerProvider).pop();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('my profile shows details; edit saves to /auth/me', (
    tester,
  ) async {
    final requests = await open(tester, '/profile');
    expect(find.text('owner@test.com'), findsOneWidget);
    expect(find.textContaining('Nov 2026'), findsOneWidget); // last login

    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();
    expect(currentPath(), '/profile/edit');
    await tester.enterText(find.byType(TextFormField).first, 'Rahim Owner');
    await tester.enterText(find.byType(TextFormField).at(2), '');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    final put = requests.lastWhere((r) => r.path == '/auth/me');
    expect(body(put), {
      'name': 'Rahim Owner',
      'phone': '9876543210',
      'email': null,
    });
    expect(currentPath(), '/profile');
    expect(find.text('Rahim Owner'), findsOneWidget);
    expect(find.text('Profile updated'), findsOneWidget);
    expect(
      testContainer.read(authControllerProvider).user!.name,
      'Rahim Owner',
    );
  });

  testWidgets('change password: wrong current password, then success', (
    tester,
  ) async {
    await open(tester, '/profile/password');
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'nope');
    await tester.enterText(fields.at(1), 'newpass1');
    await tester.enterText(fields.at(2), 'newpass1');
    await tester.tap(find.widgetWithText(FilledButton, 'Change password'));
    await tester.pumpAndSettle();
    expect(find.text('Current password is incorrect'), findsOneWidget);

    await tester.enterText(fields.at(0), 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, 'Change password'));
    await tester.pumpAndSettle();
    expect(
      find.text('Password changed. Other devices were logged out'),
      findsOneWidget,
    );
    expect(currentPath(), '/profile');
  });

  testWidgets('factory profile: prefix is checked and upper-cased', (
    tester,
  ) async {
    final requests = await open(tester, '/settings/factory');
    expect(find.text('Maa Tara Fly Ash Bricks'), findsOneWidget);

    final prefix = find.byType(TextFormField).last;
    await tester.enterText(prefix, 'mt/26');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('1–10 characters: A–Z, 0–9 and -'), findsOneWidget);

    await tester.enterText(prefix, 'mt-26');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    final put = requests.lastWhere(
      (r) => r.method == 'PUT' && r.path == '/settings/factory',
    );
    expect(body(put)['invoice_prefix'], 'MT-26');
    expect(body(put)['email'], isNull);
    expect(find.text('Factory profile updated'), findsOneWidget);
  });

  testWidgets('appearance applies instantly and saves to the account', (
    tester,
  ) async {
    final requests = await open(tester, '/settings/appearance');

    await tester.tap(find.bySemanticsLabel('Dark'));
    await tester.pumpAndSettle();
    expect(testContainer.read(themeControllerProvider).mode, ThemeMode.dark);
    expect(
      Theme.of(tester.element(find.byType(Scaffold).last)).brightness,
      Brightness.dark,
    );

    await tester.tap(find.bySemanticsLabel('Emerald'));
    await tester.pumpAndSettle();
    expect(
      testContainer.read(themeControllerProvider).accent,
      AccentColor.emerald,
    );

    await tester.tap(find.text('Large'));
    await tester.pumpAndSettle();
    expect(testContainer.read(themeControllerProvider).fontScale, 1.15);

    final prefs = requests
        .where((r) => r.path == '/auth/preferences')
        .map(body)
        .toList();
    expect(prefs, [
      {'theme_mode': 'dark'},
      {'accent_color': 'emerald'},
    ]); // font size stays on the device

    await tester.scrollUntilVisible(find.text('Reset to default'), 100);
    await tester.tap(find.text('Reset to default'));
    await tester.pumpAndSettle();
    expect(testContainer.read(themeControllerProvider), const ThemeSettings());
  });

  testWidgets('language switches the whole app to Bengali', (tester) async {
    final requests = await open(tester, '/settings/language');
    await tester.tap(find.text('বাংলা'));
    await tester.pumpAndSettle();
    expect(testContainer.read(localeProvider), 'bn');
    expect(find.text('ভাষা'), findsOneWidget); // app bar title
    expect(body(requests.lastWhere((r) => r.path == '/auth/preferences')), {
      'locale': 'bn',
    });
  });

  testWidgets('about shows the installed version', (tester) async {
    await open(tester, '/settings/about');
    expect(find.text('1.0.0'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('drawer header opens My profile; sun/moon toggles dark', (
    tester,
  ) async {
    await open(tester, '/home');
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Dark'));
    await tester.pumpAndSettle();
    expect(testContainer.read(themeControllerProvider).mode, ThemeMode.dark);

    await tester.tap(find.text('Test Owner · 9876543210'));
    await tester.pumpAndSettle();
    expect(currentPath(), '/profile');
  });

  // Definition of done: every new screen at 360 / 800 / 1440 px, light and
  // dark, Bengali, without overflow (a layout overflow fails the test).
  for (final size in const [Size(360, 800), Size(800, 1000), Size(1440, 900)]) {
    for (final dark in [false, true]) {
      testWidgets('no overflow at ${size.width.toInt()} px, '
          '${dark ? 'dark' : 'light'}', (tester) async {
        await open(tester, '/settings', size: size);
        await testContainer
            .read(themeControllerProvider.notifier)
            .setMode(dark ? ThemeMode.dark : ThemeMode.light);
        await testContainer.read(localeProvider.notifier).setLocale('bn');
        for (final path in [
          '/settings',
          '/settings/factory',
          '/settings/appearance',
          '/settings/language',
          '/settings/about',
          '/profile',
          '/profile/edit',
          '/profile/password',
          '/users',
          '/users/new',
        ]) {
          testContainer.read(routerProvider).go(path);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: path);
        }
      });
    }
  }
}
