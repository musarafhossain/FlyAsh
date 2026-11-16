import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flyash/app.dart';
import 'package:flyash/core/router/app_router.dart';

import '../helpers.dart';
import 'attendance_test.dart' show FakeAttendance;
import 'dashboard_test.dart' show FakeHome;
import 'expenses_test.dart' show FakeExpenses;
import 'labours_test.dart' show FakeLabours;
import 'reports_test.dart' show FakeReports;
import 'sale_form_test.dart' show FakeSalesBackend;
import 'wages_test.dart' show FakeWages;

/// Accessibility pass (04-UI-UX §13, F19): on every main screen, in light
/// and dark, every tap target is at least 48×48 dp and has a label for
/// screen readers, and text has enough contrast.
const screens = [
  '/home',
  '/sales',
  '/sales/104',
  '/sales/new',
  '/customers',
  '/attendance',
  '/labours',
  '/expenses',
  '/expenses/new',
  '/reports',
  '/reports/sales',
  '/settings',
  '/settings/about',
];

Future<void> openApp(
  WidgetTester tester, {
  required bool dark,
  double fontScale = 1,
  Size size = const Size(400, 900),
}) async {
  setScreenSize(tester, size);
  final routes = {
    ...FakeHome().routes,
    ...FakeLabours().routes,
    ...FakeWages().routes,
    ...FakeAttendance().routes,
    ...FakeExpenses().routes,
    ...FakeReports().routes,
    ...FakeSalesBackend().routes,
  };
  await tester.pumpWidget(
    await testApp(
      const FlyAshApp(),
      prefs: {
        'business.date': '2026-11-09',
        'theme.mode': dark ? 'dark' : 'light',
        'theme.font_scale': fontScale,
      },
      token: 'oat_saved',
      api: signedInRoutes(routes),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';
    for (final path in screens) {
      testWidgets('$path ($mode): tap targets, labels, contrast', (
        tester,
      ) async {
        if (dark) {
          tester.platformDispatcher.platformBrightnessTestValue =
              Brightness.dark;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
        }
        final handle = tester.ensureSemantics();
        await openApp(tester, dark: dark);
        testContainer.read(routerProvider).go(path);
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }
  }

  for (final width in [360.0, 1280.0]) {
    testWidgets('1.3× text at ${width.toInt()} px: no overflow anywhere', (
      tester,
    ) async {
      await openApp(
        tester,
        dark: false,
        fontScale: 1.3,
        size: Size(width, 800),
      );
      for (final path in screens) {
        testContainer.read(routerProvider).go(path);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: path);
      }
    });
  }

  testWidgets('login (signed out): tap targets, labels, contrast', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    setScreenSize(tester, const Size(400, 900));
    await tester.pumpWidget(await testApp(const FlyAshApp()));
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
