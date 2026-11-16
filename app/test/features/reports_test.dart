import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flyash/app.dart';
import 'package:flyash/core/l10n/locale_controller.dart';
import 'package:flyash/core/router/app_router.dart';
import 'package:flyash/core/widgets/cards.dart';
import 'package:flyash/features/reports/presentation/report_export.dart';
import 'package:flyash/features/reports/presentation/widgets/report_view.dart';

import '../fake_api.dart';
import '../helpers.dart';

Reply _ok(Object? data) => (200, envelope(200, 'ok', data), {});

/// The six report endpoints (07-API §14), with what was asked recorded.
class FakeReports {
  final requests = <RequestOptions>[];

  FakeRoutes get routes => {
    'GET /reports/sales': (o) => _ok({
      'from': o.queryParameters['from'],
      'to': o.queryParameters['to'],
      'count': 3,
      'amount': '19500.50',
      'by_product': [
        {
          'product_name': 'Fly Ash Brick',
          'quantity': '3000.00',
          'amount': '19500.50',
        },
      ],
      'daily': [
        {'date': '2026-11-02', 'amount': '6500.00'},
        {'date': '2026-11-05', 'amount': '13000.50'},
      ],
    }),
    'GET /reports/expenses': (o) => _ok({
      'from': o.queryParameters['from'],
      'to': o.queryParameters['to'],
      'total': '1350.00',
      'by_category': [
        {'name': 'Diesel', 'amount': '850.00', 'percent': 63.0},
        {'name': 'Labour Tiffin', 'amount': '500.00', 'percent': 37.0},
      ],
    }),
    'GET /reports/net-profit': (o) => _ok({
      'from': o.queryParameters['from'],
      'to': o.queryParameters['to'],
      'sales': '19500.00',
      'expenses': '1350.00',
      'wages': '20000.00',
      'net_profit': '-1850.00',
      'monthly': [
        {
          'month': '2026-10',
          'sales': '9000.00',
          'expenses': '350.00',
          'wages': '8000.00',
          'net_profit': '650.00',
        },
        {
          'month': '2026-11',
          'sales': '10500.00',
          'expenses': '1000.00',
          'wages': '12000.00',
          'net_profit': '-2500.00',
        },
      ],
    }),
    'GET /reports/collections': (o) => _ok({
      'from': o.queryParameters['from'],
      'to': o.queryParameters['to'],
      'total': '7000.00',
      'by_method': [
        {'method': 'cash', 'amount': '5000.00'},
        {'method': 'upi', 'amount': '2000.00'},
      ],
      'daily': [
        {'date': '2026-11-03', 'amount': '7000.00'},
      ],
    }),
    'GET /reports/wages': (o) => _ok({
      'month': o.queryParameters['month'],
      'earned': '4050.00',
      'paid': '1000.00',
      'balance': '3050.00',
      'rows': [
        {
          'labour_id': '9',
          'name': 'Abdul Karim',
          'wage_type': 'daily',
          'wage_amount': '450.00',
          'is_active': true,
          'present_days': 9,
          'absent_days': 6,
          'earned': '4050.00',
          'paid': '1000.00',
          'balance': '3050.00',
          'status': 'partial',
        },
      ],
    }),
    'GET /reports/dues': (o) => _ok({
      'items': [
        {
          'customer_id': '1',
          'name': 'Rahim Traders',
          'phone': '9830000000',
          'total_due': '64965.00',
          'oldest_due_date': '2026-10-16',
          'sales_count': 2,
        },
      ],
      'page': 1,
      'limit': 100,
      'total': 1,
      'last_page': 1,
      'grand_total': '64965.00',
    }),
  };
}

late FakeReports api;

Future<void> openAt(
  WidgetTester tester,
  String location, {
  Size size = const Size(400, 900),
  bool dark = false,
  bool bengali = false,
}) async {
  api = FakeReports();
  setScreenSize(tester, size);
  await tester.pumpWidget(
    await testApp(
      const FlyAshApp(),
      prefs: {
        'business.date': '2026-11-16',
        if (dark) 'theme.mode': 'dark',
        if (bengali) 'app.locale': 'bn',
      },
      token: 'oat_saved',
      api: signedInRoutes(api.routes),
      requests: api.requests,
    ),
  );
  await tester.pumpAndSettle();
  testContainer.read(routerProvider).go(location);
  await tester.pumpAndSettle();
}

String path() =>
    testContainer.read(routerProvider).routeInformationProvider.value.uri.path;

RequestOptions last(String p) => api.requests.lastWhere((r) => r.path == p);

void main() {
  testWidgets('grid: six reports; a tile opens its report', (tester) async {
    await openAt(tester, '/reports');
    for (final t in [
      'sales',
      'dues',
      'expenses',
      'wages',
      'net-profit',
      'collections',
    ]) {
      expect(find.byKey(Key('reportTile-$t')), findsOneWidget);
    }
    await tester.tap(find.byKey(const Key('reportTile-sales')));
    await tester.pumpAndSettle();
    expect(path(), '/reports/sales');
  });

  testWidgets('sales: this month by default; stat cards, chart, tables', (
    tester,
  ) async {
    await openAt(tester, '/reports/sales');
    expect(last('/reports/sales').queryParameters, {
      'from': '2026-11-01',
      'to': '2026-11-16',
    });
    expect(find.text('₹19,500.50'), findsWidgets, reason: 'paise kept');
    expect(find.text('3'), findsWidgets);
    expect(find.byKey(const Key('reportChart')), findsOneWidget);
    expect(find.byType(ReportBarChart), findsOneWidget);
    expect(find.text('Fly Ash Brick'), findsOneWidget);
    expect(find.text('3,000'), findsOneWidget, reason: 'quantity');
  });

  testWidgets('period chips ask the server for that range', (tester) async {
    await openAt(tester, '/reports/sales');
    await tester.tap(find.byKey(const Key('period-today')));
    await tester.pumpAndSettle();
    expect(last('/reports/sales').queryParameters, {
      'from': '2026-11-16',
      'to': '2026-11-16',
    });
    await tester.tap(find.byKey(const Key('period-thisYear')));
    await tester.pumpAndSettle();
    expect(last('/reports/sales').queryParameters['from'], '2026-01-01');
    await tester.tap(find.byKey(const Key('period-lastMonth')));
    await tester.pumpAndSettle();
    expect(last('/reports/sales').queryParameters, {
      'from': '2026-10-01',
      'to': '2026-10-31',
    });
    expect(find.text('01 Oct 2026 – 31 Oct 2026'), findsOneWidget);
  });

  testWidgets('expenses: horizontal bars by category with the amounts', (
    tester,
  ) async {
    await openAt(tester, '/reports/expenses');
    expect(find.byType(ReportHorizontalBars), findsOneWidget);
    // Chart, table and the "Top category" card.
    expect(find.text('Diesel'), findsNWidgets(3));
    expect(find.text('Top category'), findsOneWidget);
    expect(find.text('By category'), findsOneWidget, reason: 'said once');
    expect(find.text('63.0%'), findsOneWidget);
  });

  testWidgets('net profit: 4 stat cards, a loss shown below the axis', (
    tester,
  ) async {
    await openAt(tester, '/reports/net-profit');
    expect(find.byType(KpiChip), findsNWidgets(4));
    expect(find.text('-₹1,850'), findsWidgets);
    expect(find.byType(ReportBarChart), findsOneWidget);
  });

  testWidgets('collections: by method uses the method names', (tester) async {
    await openAt(tester, '/reports/collections');
    expect(find.text('Cash'), findsOneWidget);
    expect(find.text('UPI'), findsOneWidget);
  });

  testWidgets('wages: month selector, no future months', (tester) async {
    await openAt(tester, '/reports/wages');
    expect(last('/reports/wages').queryParameters['month'], '2026-11');
    expect(find.byKey(const Key('reportPeriods')), findsNothing);
    await tester.tap(find.byTooltip('Previous'));
    await tester.pumpAndSettle();
    expect(last('/reports/wages').queryParameters['month'], '2026-10');
    expect(find.text('Abdul Karim'), findsWidgets);
  });

  testWidgets('dues: no period; a row opens the customer', (tester) async {
    await openAt(tester, '/reports/dues');
    expect(find.byKey(const Key('reportPeriods')), findsNothing);
    expect(find.text('₹64,965'), findsWidgets);
    await tester.tap(find.textContaining('Rahim Traders'));
    await tester.pumpAndSettle();
    expect(path(), '/customers/1');
  });

  testWidgets('⋮ offers Export PDF and Export Excel', (tester) async {
    await openAt(tester, '/reports/sales');
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    expect(find.text('Export PDF'), findsOneWidget);
    expect(find.text('Export Excel'), findsOneWidget);
  });

  testWidgets('a language change shows at once (no reload)', (tester) async {
    await openAt(tester, '/reports/expenses');
    final asked = api.requests.length;
    await testContainer.read(localeProvider.notifier).setLocale('bn');
    await tester.pumpAndSettle();
    expect(find.text('Top category'), findsNothing);
    expect(find.text('সবচেয়ে বেশি খরচ'), findsOneWidget);
    expect(
      api.requests.where((r) => r.path.startsWith('/reports')),
      hasLength(
        api.requests
            .take(asked)
            .where((r) => r.path.startsWith('/reports'))
            .length,
      ),
    );
  });

  testWidgets('an unknown report goes back to the grid', (tester) async {
    await openAt(tester, '/reports/nope');
    expect(path(), '/reports');
  });

  for (final size in const [Size(360, 800), Size(800, 1000), Size(1440, 900)]) {
    for (final dark in [false, true]) {
      testWidgets('no overflow at ${size.width.toInt()} px '
          '(${dark ? 'dark' : 'light'}, Bengali)', (tester) async {
        await openAt(tester, '/reports', size: size, dark: dark, bengali: true);
        for (final p in [
          '/reports/sales',
          '/reports/dues',
          '/reports/expenses',
          '/reports/wages',
          '/reports/net-profit',
          '/reports/collections',
        ]) {
          testContainer.read(routerProvider).go(p);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: p);
        }
      });
    }
  }

  group('export files', () {
    const view = ReportView(
      title: 'Sales',
      period: '01 Nov 2026 – 16 Nov 2026',
      summary: [
        ReportFigure(
          'Sales amount',
          '₹19,500.50',
          Icons.trending_up,
          KpiTint.sky,
        ),
      ],
      tables: [
        ReportTable(
          title: 'By product',
          columns: [
            ReportColumn('Product'),
            ReportColumn('Amount', numeric: true),
          ],
          rows: [
            ['ফ্লাই অ্যাশ ইট', '₹19,500.50'],
          ],
        ),
      ],
    );

    testWidgets('PDF (with a Bengali name) is a real PDF file', (tester) async {
      final bytes = await tester.runAsync(
        () => buildReportPdf(view, generatedOn: 'Generated on 16 Nov 2026'),
      );
      expect(String.fromCharCodes(bytes!.take(5)), '%PDF-');
      expect(bytes.length, greaterThan(1000));
    });

    test('Excel is a real .xlsx (zip) file', () {
      final bytes = buildReportExcel(
        view,
        generatedOn: 'Generated on 16 Nov 2026',
      );
      expect(String.fromCharCodes(bytes.take(2)), 'PK');
    });

    test('file names carry the report and the period', () {
      expect(
        reportFileName('sales', '2026-11-01_2026-11-16'),
        'flyash-sales-2026-11-01_2026-11-16',
      );
    });
  });
}
