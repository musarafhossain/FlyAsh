import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flyash/app.dart';
import 'package:flyash/core/router/app_router.dart';
import 'package:flyash/core/router/nav_items.dart';
import 'package:flyash/core/widgets/controls.dart';

import '../helpers.dart';

Future<void> open(WidgetTester tester, Size size, String location) async {
  setScreenSize(tester, size);
  await tester.pumpWidget(
    await testApp(const FlyAshApp(), token: 'oat_test', api: signedInRoutes()),
  );
  await tester.pumpAndSettle();
  testContainer.read(routerProvider).go(location);
  await tester.pumpAndSettle();
}

String currentPath() =>
    testContainer.read(routerProvider).routeInformationProvider.value.uri.path;

/// The Labours section is the labour list only (2026-11-16): no Wages tab.
/// A labour's wages: their page → ⋮ → Wage details (/labours/:id/wages);
/// everyone's month: Reports → Wages.
void main() {
  test('Wages is not a section', () {
    expect(kNavItems.map((i) => i.path), isNot(contains('/wages')));
    expect(kNavItems.length, 10);
  });

  testWidgets('Labours shows the labour list only, without tabs', (
    tester,
  ) async {
    await open(tester, const Size(1440, 900), '/labours');
    expect(find.byType(SegmentedTabs<Object?>), findsNothing);
    expect(find.byWidgetPredicate((w) => w is SegmentedTabs), findsNothing);
    expect(find.text('Wages'), findsNothing);
    expect(find.text('Add labour'), findsWidgets); // the real list
  });

  testWidgets('an old /labours/wages link opens the labour list', (
    tester,
  ) async {
    await open(tester, const Size(360, 800), '/labours/wages');
    expect(currentPath(), '/labours');
    expect(tester.takeException(), isNull);
  });

  testWidgets('sidebar keeps Labours selected', (tester) async {
    await open(tester, const Size(1440, 900), '/labours');
    expect(find.byIcon(Icons.engineering), findsWidgets);
  });

  for (final size in const [Size(360, 800), Size(800, 1000), Size(1440, 900)]) {
    testWidgets('no overflow on Labours at ${size.width.toInt()} px '
        '(Bengali)', (tester) async {
      setScreenSize(tester, size);
      await tester.pumpWidget(
        await testApp(
          const FlyAshApp(),
          prefs: {'app.locale': 'bn'},
          token: 'oat_test',
          api: signedInRoutes(),
        ),
      );
      await tester.pumpAndSettle();
      testContainer.read(routerProvider).go('/labours');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
