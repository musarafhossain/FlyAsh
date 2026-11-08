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
    testWidgets(
      'bottom bar with 4 sections; the app bar menu opens the drawer',
      (tester) async {
        await openApp(tester, const Size(360, 800));

        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.byType(NavigationDestination), findsNWidgets(4));
        expect(find.text('More'), findsNothing);
        expect(find.byType(NavigationRail), findsNothing);

        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text('Sales'),
          ),
        );
        await tester.pumpAndSettle();
        expect(appBarTitle('Sales'), findsOneWidget);

        await tester.tap(find.byTooltip('Menu'));
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
        // A drawer section is open: no bottom item looks selected.
        expect(
          find.byIcon(Icons.home),
          findsNothing,
          reason: 'Home not filled',
        );
        final barTheme = tester.widget<NavigationBarTheme>(
          find
              .ancestor(
                of: find.byType(NavigationBar),
                matching: find.byType(NavigationBarTheme),
              )
              .first,
        );
        expect(barTheme.data.indicatorColor, Colors.transparent);
      },
    );

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

    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(Drawer), matching: find.text('Products')),
    );
    await tester.pumpAndSettle();
    expect(appBarTitle('Products'), findsOneWidget);
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
      isNull,
    );
    expect(
      tester
          .widget<NavigationRail>(find.byType(NavigationRail))
          .destinations
          .length,
      4,
    );
  });

  testWidgets('desktop (1440 px): sidebar with every section, collapsible', (
    tester,
  ) async {
    await openApp(tester, const Size(1440, 900));
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsNothing);
    expect(
      find.byTooltip('Menu'),
      findsNothing,
      reason: 'sidebar is always visible',
    );
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

  testWidgets('desktop sidebar: no overflow during collapse/expand animation', (
    tester,
  ) async {
    await openApp(tester, const Size(1440, 900));
    for (final tooltip in ['Collapse menu', 'Expand menu', 'Collapse menu']) {
      await tester.tap(find.byTooltip(tooltip));
      // Step through the 200 ms animation frame by frame.
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 20));
        expect(tester.takeException(), isNull, reason: '$tooltip frame $i');
      }
      await tester.pumpAndSettle();
    }
  });

  for (final size in const [Size(360, 800), Size(800, 1000), Size(1440, 900)]) {
    for (final mode in ['light', 'dark']) {
      testWidgets(
        'no overflow at ${size.width.toInt()}px ($mode), with the menu open',
        (tester) async {
          await openApp(tester, size, mode: mode);
          if (size.width < 1024) {
            await tester.tap(find.byTooltip('Menu'));
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
