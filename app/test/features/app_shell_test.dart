import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flyash/app.dart';
import 'package:flyash/core/router/app_router.dart';
import 'package:flyash/core/router/nav_items.dart';
import 'package:flyash/core/theme/app_colors.dart';
import 'package:flyash/core/theme/app_tokens.dart';
import 'package:flyash/core/theme/theme_controller.dart';

import '../helpers.dart';

Finder appBarTitle(String title) =>
    find.descendant(of: find.byType(AppBar), matching: find.text(title));

/// Starts the app logged in; it opens on Home.
Future<void> openApp(
  WidgetTester tester,
  Size size, {
  String mode = 'light',
}) async {
  setScreenSize(tester, size);
  await tester.pumpWidget(
    await testApp(
      const FlyAshApp(),
      prefs: {'theme.mode': mode},
      token: 'oat_test',
      api: signedInRoutes(),
    ),
  );
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

  group('desktop sidebar', () {
    testWidgets('collapse button at the top, group captions, user + logout '
        'at the bottom', (tester) async {
      await openApp(tester, const Size(1440, 900));
      for (final caption in ['DAILY WORK', 'BUSINESS', 'ADMIN']) {
        expect(find.text(caption), findsOneWidget);
      }
      final toggleY = tester.getCenter(find.byTooltip('Collapse menu')).dy;
      final logoutY = tester.getCenter(find.byTooltip('Log out')).dy;
      final homeY = tester.getCenter(find.text('Home').first).dy;
      expect(toggleY, lessThan(homeY), reason: 'collapse button on top');
      expect(logoutY, greaterThan(800), reason: 'logout at the bottom');
      expect(find.text('Test Owner'), findsOneWidget);

      // Collapsed: icons only, but profile and logout stay reachable.
      await tester.tap(find.byTooltip('Collapse menu'));
      await tester.pumpAndSettle();
      expect(find.text('DAILY WORK'), findsNothing);
      expect(find.byTooltip('Log out'), findsOneWidget);
      expect(find.byTooltip('My profile'), findsOneWidget);
    });

    testWidgets('user card opens My profile', (tester) async {
      await openApp(tester, const Size(1440, 900));
      await tester.tap(find.text('Test Owner'));
      await tester.pumpAndSettle();
      expect(
        testContainer
            .read(routerProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        '/profile',
      );
    });

    testWidgets('logout button asks first', (tester) async {
      await openApp(tester, const Size(1440, 900));
      await tester.tap(find.byTooltip('Log out'));
      await tester.pumpAndSettle();
      expect(find.text('Log out?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
      await tester.pumpAndSettle();
      expect(find.text('Sign in'), findsWidgets);
    });

    // A short laptop window (like 1536×738): the list scrolls, nothing
    // overlaps or overflows, also mid-animation and in Bengali.
    for (final locale in ['en', 'bn']) {
      testWidgets('short window, $locale: no overflow while toggling', (
        tester,
      ) async {
        setScreenSize(tester, const Size(1536, 738));
        await tester.pumpWidget(
          await testApp(
            const FlyAshApp(),
            prefs: {'app.locale': locale},
            token: 'oat_test',
            api: signedInRoutes(),
          ),
        );
        await tester.pumpAndSettle();
        final toggle = find.byIcon(Icons.keyboard_double_arrow_left);
        await tester.tap(toggle);
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 20));
          expect(tester.takeException(), isNull, reason: 'frame $i');
        }
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.keyboard_double_arrow_right));
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 20));
          expect(tester.takeException(), isNull, reason: 'frame $i');
        }
        await tester.pumpAndSettle();
      });
    }
  });

  // Bug: clicking a sidebar item with the mouse painted it black while the
  // pointer stayed on it. Reads the real rendered pixels after a mouse click.
  for (final dark in [false, true]) {
    testWidgets('mouse click keeps the selected item tinted, not black '
        '(${dark ? 'dark' : 'light'})', (tester) async {
      setScreenSize(tester, const Size(1440, 900));
      final key = GlobalKey();
      await tester.pumpWidget(
        await testApp(
          RepaintBoundary(key: key, child: const FlyAshApp()),
          prefs: {'theme.mode': dark ? 'dark' : 'light'},
          token: 'oat_test',
          api: signedInRoutes(),
        ),
      );
      await tester.pumpAndSettle();
      // The account's saved theme is applied at login, so set it after.
      await testContainer
          .read(themeControllerProvider.notifier)
          .setMode(dark ? ThemeMode.dark : ThemeMode.light);
      await tester.pumpAndSettle();

      // An empty part of the "Sales" row (right of the label).
      final spot = Offset(220, tester.getCenter(find.text('Sales').first).dy);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(spot);
      await tester.pumpAndSettle();
      await mouse.down(spot);
      await tester.pump(const Duration(milliseconds: 50));
      await mouse.up();
      await tester.pumpAndSettle();
      expect(appBarTitle('Sales'), findsOneWidget);

      final pixel = await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final bytes = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final i = (spot.dy.round() * image.width + spot.dx.round()) * 4;
        return Color.fromARGB(
          255,
          bytes.getUint8(i),
          bytes.getUint8(i + 1),
          bytes.getUint8(i + 2),
        );
      });

      // Close to the selected tint (primaryContainer), far from black.
      final expected = AppTokens.of(
        AccentColor.blue,
        dark ? Brightness.dark : Brightness.light,
      ).primaryContainer;
      double diff(Color a, Color b) =>
          ((a.r - b.r).abs() + (a.g - b.g).abs() + (a.b - b.b).abs()) * 255;
      expect(diff(pixel!, expected), lessThan(40), reason: 'pixel $pixel');
      expect(diff(pixel, const Color(0xFF000000)), greaterThan(60));
    });
  }
}
