import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flyash/app.dart';

import '../fake_api.dart';
import '../helpers.dart';

Map<String, Object?> arb(String locale) =>
    jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
        as Map<String, Object?>;

Iterable<String> keys(Map<String, Object?> m) =>
    m.keys.where((k) => !k.startsWith('@'));

void main() {
  test('English and Bengali ARB files have the same keys', () {
    final en = keys(arb('en')).toSet();
    final bn = keys(arb('bn')).toSet();
    expect(bn.difference(en), isEmpty, reason: 'only in bn');
    expect(en.difference(bn), isEmpty, reason: 'missing in bn');
  });

  testWidgets('saved Bengali shows Bengali navigation after login', (
    tester,
  ) async {
    setScreenSize(tester, const Size(360, 800));
    await tester.pumpWidget(
      await testApp(
        const FlyAshApp(),
        prefs: {'app.locale': 'bn'},
        token: 'oat_test',
        api: signedInRoutes({
          'GET /auth/me': (_) =>
              (200, envelope(200, 'ok', {...sampleUser, 'locale': 'bn'}), {}),
        }),
      ),
    );
    await tester.pumpAndSettle();

    for (final label in ['হোম', 'বিক্রি', 'হাজিরা', 'খরচ']) {
      expect(find.text(label), findsWidgets, reason: label);
    }
  });

  testWidgets('the language switch changes the UI immediately', (tester) async {
    setScreenSize(tester, const Size(800, 900));
    await tester.pumpWidget(await testApp(const FlyAshApp()));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsWidgets);

    await tester.tap(find.byTooltip('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('বাংলা').last);
    await tester.pumpAndSettle();

    expect(find.text('সাইন ইন'), findsWidgets);
    expect(find.text('Sign in'), findsNothing);
  });

  // Bengali strings are longer; check every width with the menu open.
  for (final size in const [Size(360, 800), Size(800, 1000), Size(1440, 900)]) {
    testWidgets('Bengali: no overflow at ${size.width.toInt()}px', (
      tester,
    ) async {
      setScreenSize(tester, size);
      await tester.pumpWidget(
        await testApp(
          const FlyAshApp(),
          prefs: {'app.locale': 'bn', 'theme.font_scale': 1.15},
          token: 'oat_test',
          api: signedInRoutes({
            'GET /auth/me': (_) =>
                (200, envelope(200, 'ok', {...sampleUser, 'locale': 'bn'}), {}),
          }),
        ),
      );
      await tester.pumpAndSettle();
      if (size.width < 1024) {
        await tester.tap(find.byTooltip('মেনু'));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });
  }
}
