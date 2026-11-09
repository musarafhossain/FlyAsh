import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flyash/app.dart';
import 'package:flyash/core/router/app_router.dart';
import 'package:flyash/features/sales/presentation/widgets/sale_list_items.dart';

import '../fake_api.dart';
import '../helpers.dart';
import 'sales_test.dart' show saleJson;

Reply _page(List<Object?> items) => (
  200,
  envelope(200, 'ok', {
    'items': items,
    'page': 1,
    'limit': 20,
    'total': items.length,
    'last_page': 1,
  }),
  {},
);

class FakeHome {
  final requests = <RequestOptions>[];
  bool fail = false;

  Map<String, Object?> get dashboard => {
    'date': '2026-11-09',
    'today_sales': {'amount': '313800.00', 'count': 11},
    'today_profit': '116400.00',
    'total_due': '828316.00',
    'deliveries_today': 3,
    'overdue_deliveries': 2,
    'present_today': 14,
    'labours_total': 17,
    'month_expenses': '12900.00',
    'recent_sales': [
      saleJson(
        105,
        type: 'booking',
        status: 'booked',
        customer: 'Nazrul Islam',
      ),
      saleJson(104),
    ],
  };

  FakeRoutes get routes => {
    'GET /dashboard': (_) => fail
        ? (500, envelope(500, 'Something went wrong', null), {})
        : (200, envelope(200, 'ok', dashboard), {}),
    'GET /sales': (_) => _page(const []),
    'GET /customers': (_) => _page(const []),
    'GET /sales/upcoming-deliveries': (_) => _page(const []),
    'GET /expenses': (_) => (
      200,
      envelope(200, 'ok', {
        'items': const [],
        'page': 1,
        'limit': 20,
        'total': 0,
        'last_page': 1,
        'period_total': '0.00',
      }),
      {},
    ),
    'GET /expense-categories': (_) => (200, envelope(200, 'ok', const []), {}),
    'GET /attendance': (_) => (
      200,
      envelope(200, 'ok', {'date': '2026-11-09', 'items': const []}),
      {},
    ),
    'GET /settings/factory': (_) => (
      200,
      envelope(200, 'ok', {'factory_name': 'Maa Tara Fly Ash Bricks'}),
      {},
    ),
  };
}

late FakeHome api;

Future<void> openHome(
  WidgetTester tester, {
  Size size = const Size(400, 1000),
  bool fail = false,
}) async {
  api = FakeHome()..fail = fail;
  setScreenSize(tester, size);
  await tester.pumpWidget(
    await testApp(
      const FlyAshApp(),
      prefs: {'business.date': '2026-11-09'},
      token: 'oat_saved',
      api: signedInRoutes(api.routes),
      requests: api.requests,
    ),
  );
  await tester.pumpAndSettle();
}

String currentLocation() => testContainer
    .read(routerProvider)
    .routeInformationProvider
    .value
    .uri
    .toString();

int dashboardCalls() =>
    api.requests.where((r) => r.path == '/dashboard').length;

Future<void> tapVisible(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows greeting, today, KPIs, quick actions, recent sales', (
    tester,
  ) async {
    await openHome(tester);
    expect(currentLocation(), '/home');
    expect(find.text('Test Owner'), findsWidgets);
    expect(find.text('Maa Tara Fly Ash Bricks · 09 Nov 2026'), findsOneWidget);
    expect(find.text("Today's sales"), findsOneWidget);
    expect(find.text('₹3,13,800'), findsOneWidget);
    expect(find.text('11 sales · profit ₹1,16,400'), findsOneWidget);
    expect(find.text('₹8,28,316'), findsOneWidget);
    expect(find.text('Deliveries · 2 late'), findsOneWidget);
    expect(find.text('14/17'), findsOneWidget);
    expect(find.text('₹12,900'), findsOneWidget);
    expect(find.text('2'), findsWidgets); // bell badge
    await tester.ensureVisible(find.byType(SaleTile).last);
    expect(find.byType(SaleTile), findsNWidgets(2));
  });

  testWidgets("Today's sales opens the sales list filtered to today", (
    tester,
  ) async {
    await openHome(tester);
    await tester.tap(find.text("Today's sales"));
    await tester.pumpAndSettle();
    expect(currentLocation(), '/sales?period=today');
    final q = api.requests.lastWhere((r) => r.path == '/sales').queryParameters;
    expect(q['from'], '2026-11-09');
    expect(q['to'], '2026-11-09');
    expect(find.widgetWithText(InputChip, 'Today'), findsOneWidget);
  });

  testWidgets('Total due opens customers with dues', (tester) async {
    await openHome(tester);
    await tester.tap(find.text('Total due'));
    await tester.pumpAndSettle();
    expect(currentLocation(), '/customers?filter=due');
    expect(
      api.requests
          .lastWhere((r) => r.path == '/customers')
          .queryParameters['has_due'],
      'true',
    );
  });

  for (final (label, location) in [
    ('Deliveries · 2 late', '/sales/upcoming'),
    ('Present today', '/attendance'),
    ('Month expenses', '/expenses'),
  ]) {
    testWidgets('"$label" opens $location', (tester) async {
      await openHome(tester);
      await tapVisible(tester, find.text(label));
      expect(currentLocation(), location);
    });
  }

  for (final (label, location) in [
    ('New sale', '/sales/new?type=instant'),
    ('New booking', '/sales/new?type=booking'),
    ('Add expense', '/expenses/new'),
  ]) {
    testWidgets('quick action "$label" opens $location', (tester) async {
      await openHome(tester);
      await tapVisible(tester, find.text(label));
      expect(currentLocation(), location);
    });
  }

  testWidgets('recent sale and View all; the bell opens deliveries', (
    tester,
  ) async {
    await openHome(tester);
    await tapVisible(tester, find.text('Rahim Biswas Traders'));
    expect(currentLocation(), '/sales/104');

    testContainer.read(routerProvider).go('/home');
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('View all'));
    expect(currentLocation(), '/sales');

    testContainer.read(routerProvider).go('/home');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Upcoming deliveries'));
    await tester.pumpAndSettle();
    expect(currentLocation(), '/sales/upcoming');
  });

  testWidgets('coming back to Home reloads the numbers', (tester) async {
    await openHome(tester);
    final before = dashboardCalls();
    testContainer.read(routerProvider).go('/expenses');
    await tester.pumpAndSettle();
    expect(dashboardCalls(), before, reason: 'not while away');
    testContainer.read(routerProvider).go('/home');
    await tester.pumpAndSettle();
    expect(dashboardCalls(), before + 1);
  });

  testWidgets('an error shows Retry', (tester) async {
    await openHome(tester, fail: true);
    expect(find.text('Something went wrong'), findsOneWidget);
    api.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('₹3,13,800'), findsOneWidget);
  });

  for (final size in const [Size(360, 800), Size(800, 1000), Size(1440, 900)]) {
    for (final dark in [false, true]) {
      testWidgets('no overflow at ${size.width.toInt()} px '
          '(${dark ? 'dark' : 'light'}, Bengali)', (tester) async {
        api = FakeHome();
        setScreenSize(tester, size);
        await tester.pumpWidget(
          await testApp(
            const FlyAshApp(),
            prefs: {
              'app.locale': 'bn',
              'theme.mode': dark ? 'dark' : 'light',
              'business.date': '2026-11-09',
            },
            token: 'oat_saved',
            api: signedInRoutes(api.routes),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
