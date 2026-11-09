import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flyash/app.dart';
import 'package:flyash/core/router/app_router.dart';
import 'package:flyash/core/router/nav_items.dart';

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

Finder tab(String label) =>
    find.descendant(of: find.byType(TabBar), matching: find.text(label));

void main() {
  test('Wages is not a separate section any more', () {
    expect(kNavItems.map((i) => i.path), isNot(contains('/wages')));
    expect(kNavItems.length, 10);
  });

  testWidgets('Labours has two tabs; each tab has its own URL', (tester) async {
    await open(tester, const Size(1440, 900), '/labours');
    expect(tab('Labours'), findsOneWidget);
    expect(tab('Wages'), findsOneWidget);
    expect(find.text('Add labour'), findsWidgets); // the real list

    await tester.tap(tab('Wages'));
    await tester.pumpAndSettle();
    expect(currentPath(), '/labours/wages');
    expect(find.text('This screen is built in step F13.'), findsOneWidget);

    await tester.tap(tab('Labours'));
    await tester.pumpAndSettle();
    expect(currentPath(), '/labours');
  });

  testWidgets('opening /labours/wages directly selects the Wages tab', (
    tester,
  ) async {
    await open(tester, const Size(360, 800), '/labours/wages');
    final controller = DefaultTabController.of(
      tester.element(find.byType(TabBar)),
    );
    expect(controller.index, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sidebar keeps Labours selected on the Wages tab', (
    tester,
  ) async {
    await open(tester, const Size(1440, 900), '/labours/wages');
    final selected = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .where((s) => s.properties.selected == true)
        .map((s) => s.properties.label)
        .whereType<String>();
    // The expanded sidebar tile has no semantics label, so check the
    // icon instead: Labours shows its filled (selected) icon.
    expect(selected, isNot(contains('Wages')));
    expect(find.byIcon(Icons.engineering), findsWidgets);
  });

  for (final size in const [Size(360, 800), Size(800, 1000), Size(1440, 900)]) {
    testWidgets('no overflow on the Wages tab at ${size.width.toInt()} px '
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
      testContainer.read(routerProvider).go('/labours/wages');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
