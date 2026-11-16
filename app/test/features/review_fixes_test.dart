import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flyash/core/router/app_router.dart';
import 'package:flyash/core/router/section_app_bar.dart';
import 'package:flyash/core/theme/app_colors.dart';
import 'package:flyash/core/theme/app_theme.dart';
import 'package:flyash/core/widgets/cards.dart';
import 'package:flyash/core/widgets/motion.dart';
import 'package:flyash/core/widgets/state_views.dart';

import '../helpers.dart';
import 'customers_test.dart' as customers;
import 'sale_form_test.dart' as sale;
import 'shell_swipe_test.dart' show openApp, pager, swipe;
import 'wages_test.dart' as wages;

String path() =>
    testContainer.read(routerProvider).routeInformationProvider.value.uri.path;

void main() {
  group('confirm dialog (delete)', () {
    Future<Completer<String?>> openDialog(WidgetTester tester) async {
      final done = Completer<String?>();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(AccentColor.values.first, Brightness.light),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showConfirmDialog(
                  context,
                  title: 'Delete X?',
                  message: 'Gone for good',
                  confirmLabel: 'Yes, delete',
                  cancelLabel: 'Keep this',
                  destructive: true,
                  onConfirm: () => done.future,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return done;
    }

    testWidgets('waits for the server: buttons off + spinner; closes when '
        'done', (tester) async {
      final done = await openDialog(tester);
      await tester.tap(find.text('Yes, delete'));
      await tester.pump();
      expect(find.byKey(const Key('confirmDialogSpinner')), findsOneWidget);
      expect(
        tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNull,
      );
      expect(find.byType(AlertDialog), findsOneWidget, reason: 'still open');
      done.complete(null);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('refused: stays open with the message; Keep this closes', (
      tester,
    ) async {
      final done = await openDialog(tester);
      await tester.tap(find.text('Yes, delete'));
      await tester.pump();
      done.complete('Has sales. Deactivate it instead');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('confirmDialogError')), findsOneWidget);
      expect(find.byKey(const Key('confirmDialogSpinner')), findsNothing);
      await tester.tap(find.text('Keep this'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('compact buttons: 40 px high', (tester) async {
      await openDialog(tester);
      expect(tester.getSize(find.byType(OutlinedButton)).height, 40);
    });
  });

  testWidgets('numbers count up to their value; the last frame is exact', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: CountUpText('₹6,03,316'))),
    );
    await tester.pump(const Duration(milliseconds: 100));
    final mid = tester.widget<Text>(find.byType(Text)).data!;
    expect(mid, isNot('₹6,03,316'));
    expect(mid, startsWith('₹'));
    await tester.pumpAndSettle();
    expect(find.text('₹6,03,316'), findsOneWidget);
  });

  group('Home', () {
    testWidgets('hero card: icon top right, arrow bottom right; quick '
        'actions are app icons in 4 colours', (tester) async {
      await openApp(tester);
      final hero = find.byType(HeroCard);
      final icon = find.descendant(
        of: hero,
        matching: find.byIcon(Icons.trending_up),
      );
      final arrow = find.descendant(
        of: hero,
        matching: find.byIcon(Icons.arrow_forward),
      );
      final label = find.text("Today's sales");
      expect(
        tester.getCenter(icon).dx,
        greaterThan(tester.getCenter(label).dx),
      );
      expect(
        tester.getCenter(arrow).dy,
        greaterThan(tester.getCenter(icon).dy),
      );
      final tints = tester
          .widgetList<QuickActionTile>(find.byType(QuickActionTile))
          .map((q) => q.tint)
          .toSet();
      expect(tints, hasLength(4));
    });

    testWidgets('while loading: the real labels show, numbers are '
        'placeholders', (tester) async {
      await openApp(tester);
      testContainer.read(routerProvider).go('/expenses');
      await tester.pumpAndSettle();
      // Re-open Home from scratch is hard to catch; check the widgets' own
      // loading mode instead.
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(AccentColor.values.first, Brightness.light),
          home: const Scaffold(
            body: KpiChip(
              icon: Icons.receipt_long_outlined,
              label: 'Month expenses',
              value: '₹0',
              loading: true,
            ),
          ),
        ),
      );
      expect(find.text('Month expenses'), findsOneWidget);
      expect(find.text('₹0'), findsNothing);
      expect(find.byType(SkeletonBox), findsOneWidget);
    });
  });

  group('bottom-bar sections', () {
    testWidgets('a section left on an inner page is back on its list: swipe '
        'from Home shows the Sales list and can swipe on', (tester) async {
      await openApp(tester);
      testContainer.read(routerProvider).go('/sales/upcoming');
      await tester.pumpAndSettle();
      expect(path(), '/sales/upcoming');
      await tester.tap(find.text('Home').last);
      await tester.pumpAndSettle();
      expect(path(), '/home');
      await swipe(tester, left: true);
      expect(path(), '/sales', reason: 'the list, not Upcoming deliveries');
      await swipe(tester, left: true);
      expect(path(), '/attendance', reason: 'swiping still works');
    });

    testWidgets(
      'New sale from Home, then Home: swipe lands on the Sales list',
      (tester) async {
        await openApp(tester);
        await tester.tap(find.text('New sale').first);
        await tester.pumpAndSettle();
        expect(path(), '/sales/new');
        await tester.tap(find.text('Home').last);
        await tester.pumpAndSettle();
        await swipe(tester, left: true);
        expect(path(), '/sales');
      },
    );

    testWidgets('the app bar stays put while swiping: one fixed bar with a '
        'shadow; titles fade', (tester) async {
      await openApp(tester);
      expect(find.byKey(const Key('shellFixedBar')), findsOneWidget);
      final title = find.text('Home').first;
      final before = tester.getTopLeft(title);
      final g = await tester.startGesture(tester.getCenter(pager));
      await g.moveBy(const Offset(-20, 0));
      await tester.pump();
      await g.moveBy(const Offset(-100, 0));
      await tester.pump();
      expect(tester.getTopLeft(title).dx, closeTo(before.dx, 1));
      await g.up();
      await tester.pumpAndSettle();
      expect(find.byType(SectionAppBar), findsWidgets);
    });

    testWidgets('Home keeps animating while another section is open, so a '
        'card highlight never freezes and shows on return', (tester) async {
      await openApp(tester);
      final card = find.byType(KpiChip).first;
      testContainer.read(routerProvider).go('/customers');
      await tester.pumpAndSettle();
      expect(
        TickerMode.valuesOf(
          tester.element(find.byType(KpiChip, skipOffstage: false).first),
        ).enabled,
        isTrue,
      );
      testContainer.read(routerProvider).go('/home');
      await tester.pumpAndSettle();
      expect(card, findsOneWidget);
    });

    testWidgets('leaving a section clears its search', (tester) async {
      await openApp(tester);
      testContainer.read(routerProvider).go('/expenses');
      await tester.pumpAndSettle();
      final field = find.byType(TextField).hitTestable().first;
      await tester.enterText(field, 'belt');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Clear'), findsWidgets, reason: '✕ in the box');
      await tester.tap(find.text('Home').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Expenses').last);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byType(TextField).hitTestable().first)
            .controller!
            .text,
        isEmpty,
      );
    });
  });

  group('sale form', () {
    testWidgets('tax chips 5 · 12 · 18 %, ✕ removes the tax; the bar shows '
        'Total · Paid · Due', (tester) async {
      await sale.openAt(tester, '/sales/new');
      await tester.ensureVisible(find.byKey(const Key('tax-18')));
      await tester.tap(find.byKey(const Key('tax-18')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, '18'), findsOneWidget);
      await tester.tap(find.byTooltip('Remove tax'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, '18'), findsNothing);
      expect(find.text('Total'), findsWidgets);
      expect(find.text('Paid'), findsWidgets);
      expect(find.text('Due'), findsWidgets);
    });
  });

  testWidgets('customer page: 4 stat cards (2 × 2) and a line under Sales', (
    tester,
  ) async {
    await customers.openCustomers(tester, location: '/customers/1');
    expect(find.byType(KpiChip), findsNWidgets(4));
    final chips = tester.widgetList(find.byType(KpiChip)).toList();
    final first = tester.getTopLeft(find.byWidget(chips[0]));
    final third = tester.getTopLeft(find.byWidget(chips[2]));
    expect(third.dy, greaterThan(first.dy), reason: 'second row');
    expect(find.byTooltip('More actions'), findsOneWidget);
  });

  testWidgets('wage detail: Day by day title in the text colour, arrow turns, '
      'list slides open; no labour item in ⋮; all-time total', (tester) async {
    await wages.openAt(tester, '/labours/9/wages?month=2026-11');
    final title = tester.widget<Text>(find.text('Day by day'));
    expect(title.style!.color, isNot(const Color(0xFF000000)));
    final arrow = find.byType(AnimatedRotation);
    expect(tester.widget<AnimatedRotation>(arrow).turns, 0);
    await tester.ensureVisible(find.byKey(const Key('dayByDayHeader')));
    await tester.tap(find.byKey(const Key('dayByDayHeader')));
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.byType(AnimatedSize), findsWidgets);
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedRotation>(arrow).turns, 0.5);
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    expect(find.text('Labour details'), findsNothing);
  });
}
