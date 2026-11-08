import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flyash/app.dart';
import 'package:flyash/core/router/nav_items.dart';

import '../helpers.dart';

Finder appBarTitle(String title) =>
    find.descendant(of: find.byType(AppBar), matching: find.text(title));

/// Starts the app and opens the shell (Home).
Future<void> openApp(
  WidgetTester tester,
  Size size, {
  String mode = 'light',
}) async {
  setScreenSize(tester, size);
  await tester.pumpWidget(
    await testApp(const FlyAshApp(), prefs: {'theme.mode': mode}),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open app'));
  await tester.pumpAndSettle();
  expect(appBarTitle('Home'), findsOneWidget);
}

void main() {
  group('phone (360 px)', () {
    testWidgets('bottom bar with 4 sections + More; More opens the drawer', (
      tester,
    ) async {
      await openApp(tester, const Size(360, 800));

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNWidgets(5));
      expect(find.byType(NavigationRail), findsNothing);

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Sales'),
        ),
      );
      await tester.pumpAndSettle();
      expect(appBarTitle('Sales'), findsOneWidget);

      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      expect(find.byType(Drawer), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(Drawer),
          matching: find.text('Customers'),
        ),
      );
      await tester.pumpAndSettle();
      expect(appBarTitle('Customers'), findsOneWidget);
      expect(find.byType(Drawer), findsNothing);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        4,
        reason: 'More is highlighted',
      );
    });

    testWidgets('Android back on a section goes Home', (tester) async {
      await openApp(tester, const Size(360, 800));
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Expenses'),
        ),
      );
      await tester.pumpAndSettle();
      expect(appBarTitle('Expenses'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(appBarTitle('Home'), findsOneWidget);
    });
  });

  testWidgets('tablet (800 px): navigation rail, no bottom bar', (
    tester,
  ) async {
    await openApp(tester, const Size(800, 1000));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationRail),
        matching: find.text('Attendance'),
      ),
    );
    await tester.pumpAndSettle();
    expect(appBarTitle('Attendance'), findsOneWidget);
  });

  testWidgets('desktop (1440 px): sidebar with every section, collapsible', (
    tester,
  ) async {
    await openApp(tester, const Size(1440, 900));
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsNothing);
    for (final item in kNavItems) {
      expect(find.text(item.label), findsWidgets, reason: item.label);
    }

    await tester.tap(find.text('Reports'));
    await tester.pumpAndSettle();
    expect(appBarTitle('Reports'), findsOneWidget);

    await tester.tap(find.byTooltip('Collapse menu'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Expand menu'), findsOneWidget);
    expect(
      find.text('Wages'),
      findsNothing,
      reason: 'labels hidden when collapsed',
    );
    expect(tester.takeException(), isNull);
  });

  for (final size in const [Size(360, 800), Size(800, 1000), Size(1440, 900)]) {
    for (final mode in ['light', 'dark']) {
      testWidgets(
        'no overflow at ${size.width.toInt()}px ($mode), with the menu open',
        (tester) async {
          await openApp(tester, size, mode: mode);
          if (size.width < 1024) {
            await tester.tap(find.text('More'));
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
