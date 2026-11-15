import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flyash/app.dart';
import 'package:flyash/core/router/app_router.dart';

import '../helpers.dart';
import 'attendance_test.dart' show FakeAttendance;
import 'dashboard_test.dart' show FakeHome;
import 'expenses_test.dart' show FakeExpenses;
import 'sales_test.dart' show salesRoutes;

String path() =>
    testContainer.read(routerProvider).routeInformationProvider.value.uri.path;

Future<void> openApp(
  WidgetTester tester, {
  Size size = const Size(400, 800),
}) async {
  setScreenSize(tester, size);
  await tester.pumpWidget(
    await testApp(
      const FlyAshApp(),
      token: 'oat_saved',
      prefs: {'business.date': '2026-11-09'},
      api: signedInRoutes({
        ...FakeHome().routes,
        ...salesRoutes(),
        ...FakeAttendance().routes,
        ...FakeExpenses().routes,
      }),
    ),
  );
  await tester.pumpAndSettle();
  testContainer.read(routerProvider).go('/home');
  await tester.pumpAndSettle();
}

final pager = find.byKey(const Key('shellPager'));

Future<void> swipe(WidgetTester tester, {required bool left}) async {
  await tester.fling(pager, Offset(left ? -300 : 300, 0), 1500);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('phone: swipe left / right moves between the bottom-bar '
      'sections, like WhatsApp', (tester) async {
    await openApp(tester);
    expect(path(), '/home');

    await swipe(tester, left: true);
    expect(path(), '/sales');
    await swipe(tester, left: true);
    expect(path(), '/attendance');
    await swipe(tester, left: true);
    expect(path(), '/expenses');
    await swipe(tester, left: true);
    expect(path(), '/expenses', reason: 'last section: nothing further');

    await swipe(tester, left: false);
    expect(path(), '/attendance');
    await swipe(tester, left: false);
    await swipe(tester, left: false);
    expect(path(), '/home');
    expect(tester.takeException(), isNull);
  });

  testWidgets('the page follows the finger; a short drag springs back', (
    tester,
  ) async {
    await openApp(tester);
    final gesture = await tester.startGesture(tester.getCenter(pager));
    await gesture.moveBy(const Offset(-20, 0)); // past the touch slop
    await tester.pump();
    await gesture.moveBy(const Offset(-80, 0));
    await tester.pump();
    final controller = tester.widget<PageView>(pager).controller!;
    expect(controller.page, greaterThan(0), reason: 'moving with the finger');
    expect(controller.page, lessThan(0.5));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.page, 0);
    expect(path(), '/home');
  });

  testWidgets('a bottom-bar tap slides the pager to that section', (
    tester,
  ) async {
    await openApp(tester);
    await tester.tap(find.text('Expenses').last);
    await tester.pumpAndSettle();
    expect(path(), '/expenses');
    expect(tester.widget<PageView>(pager).controller!.page, 3);
    await swipe(tester, left: false);
    expect(path(), '/attendance', reason: 'swipe works after a tap too');
  });

  testWidgets('no swipe on a detail page or form (only on section lists)', (
    tester,
  ) async {
    await openApp(tester);
    await swipe(tester, left: true);
    expect(path(), '/sales');
    unawaited(testContainer.read(routerProvider).push('/sales/104'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<PageView>(pager).physics,
      isA<NeverScrollableScrollPhysics>(),
    );
  });

  testWidgets('desktop: no pager, one section at a time', (tester) async {
    await openApp(tester, size: const Size(1440, 900));
    expect(pager, findsNothing);
    expect(path(), '/home');
  });
}
