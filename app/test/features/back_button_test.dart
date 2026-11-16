import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flyash/core/router/app_router.dart';
import 'package:flyash/core/router/back_guard.dart';

import '../helpers.dart';
import 'shell_swipe_test.dart' show openApp;

String path() =>
    testContainer.read(routerProvider).routeInformationProvider.value.uri.path;

bool drawerOpen(WidgetTester t) =>
    t.state<ScaffoldState>(find.byType(Scaffold).first).isDrawerOpen;

Future<void> openAt(WidgetTester tester, String location) async {
  await openApp(tester);
  testContainer.read(routerProvider).go(location);
  await tester.pumpAndSettle();
}

Future<void> openDrawer(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Menu').hitTestable());
  await tester.pumpAndSettle();
  expect(drawerOpen(tester), isTrue);
}

Future<void> openDeleteDialog(WidgetTester tester) async {
  await tester.tap(find.byTooltip('More actions'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Delete sale'));
  await tester.pumpAndSettle();
  expect(find.byType(AlertDialog), findsOneWidget);
}

/// The browser's back button: the engine sends the previous URL.
Future<void> browserBack(WidgetTester tester, String previous) async {
  const codec = JSONMethodCodec();
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/navigation',
    codec.encodeMethodCall(
      MethodCall('pushRouteInformation', {'location': previous, 'state': null}),
    ),
    (_) {},
  );
  await tester.pumpAndSettle();
  // Past BackGuard's safety timer.
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  group('Android / app back', () {
    testWidgets('drawer open on Sales: back closes it and stays on Sales', (
      tester,
    ) async {
      await openAt(tester, '/sales');
      await openDrawer(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(drawerOpen(tester), isFalse);
      expect(path(), '/sales');

      // Drawer closed: back now goes Home, as before
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(path(), '/home');
    });

    testWidgets('drawer open on Home: back closes it (the app stays open)', (
      tester,
    ) async {
      await openAt(tester, '/home');
      await openDrawer(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(drawerOpen(tester), isFalse);
      expect(path(), '/home');
    });

    testWidgets('dialog open: back closes the dialog, the page stays', (
      tester,
    ) async {
      await openAt(tester, '/sales/104');
      await openDeleteDialog(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(path(), '/sales/104');
    });
  });

  group('web: the browser back button', () {
    var forwardSteps = 0;

    setUp(() {
      BackGuard.webOverride = true;
      forwardSteps = 0;
      BackGuard.instance
        ..resetForTest()
        ..stepForward = () => forwardSteps++;
    });
    tearDown(() => BackGuard.webOverride = false);

    testWidgets('drawer open: closes it, keeps the page, and steps forward '
        'to the entry it was on (no new entry)', (tester) async {
      await openAt(tester, '/sales');
      await openDrawer(tester);
      await browserBack(tester, '/home');
      expect(drawerOpen(tester), isFalse);
      expect(path(), '/sales');
      expect(forwardSteps, 1);
      // The step forward arrives as a history event: it changes nothing
      await browserBack(tester, '/sales');
      expect(path(), '/sales');
      expect(drawerOpen(tester), isFalse);
    });

    testWidgets('dialog open: closes it, keeps the page', (tester) async {
      await openAt(tester, '/sales/104');
      await openDeleteDialog(tester);
      await browserBack(tester, '/sales');
      expect(find.byType(AlertDialog), findsNothing);
      expect(path(), '/sales/104');
    });

    testWidgets('⋮ menu open: closes it, keeps the page', (tester) async {
      await openAt(tester, '/sales/104');
      await tester.tap(find.byTooltip('More actions'));
      await tester.pumpAndSettle();
      expect(find.text('Delete sale'), findsOneWidget);
      await browserBack(tester, '/sales');
      expect(find.text('Delete sale'), findsNothing);
      expect(path(), '/sales/104');
    });

    testWidgets('nothing open: back changes the page as usual', (tester) async {
      await openAt(tester, '/sales/104');
      await browserBack(tester, '/sales');
      expect(path(), '/sales');
    });
  });
}
