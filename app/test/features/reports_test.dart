import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flyash/app.dart';
import 'package:flyash/core/l10n/locale_controller.dart';
import 'package:flyash/core/router/app_router.dart';
import 'package:flyash/core/widgets/cards.dart';
import 'package:flyash/core/widgets/state_views.dart';
import 'package:flyash/features/reports/presentation/report_export.dart';
import 'package:flyash/features/reports/presentation/widgets/report_view.dart';

import '../fake_api.dart';
import '../helpers.dart';

Reply _ok(Object? data) => (200, envelope(200, 'ok', data), {});

/// `GET /reports/net-profit` (07-API §14): sales with tax − expenses −
/// wages paid, with a row per month.
class FakeReports {
  final requests = <RequestOptions>[];

  FakeRoutes get routes => {
    'GET /reports/net-profit': (o) => _ok({
      'from': o.queryParameters['from'],
      'to': o.queryParameters['to'],
      'sales': '19500.00',
      'expenses': '1350.00',
      'wages_paid': '20000.00',
      'net_profit': '-1850.00',
      'monthly': [
        {
          'month': '2026-10',
          'sales': '9000.00',
          'expenses': '350.00',
          'wages_paid': '8000.00',
          'net_profit': '650.00',
        },
        {
          'month': '2026-11',
          'sales': '10500.00',
          'expenses': '1000.00',
          'wages_paid': '12000.00',
          'net_profit': '-2500.00',
        },
      ],
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
  bool settle = true,
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
  if (settle) await tester.pumpAndSettle();
}

String path() =>
    testContainer.read(routerProvider).routeInformationProvider.value.uri.path;

RequestOptions last(String p) => api.requests.lastWhere((r) => r.path == p);

void main() {
  testWidgets('Reports opens net profit directly (no list of reports)', (
    tester,
  ) async {
    await openAt(tester, '/reports');
    expect(path(), '/reports');
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Reports')),
      findsOneWidget,
    );
    expect(find.text('Net profit'), findsOneWidget); // the card
    expect(find.byKey(const Key('reportTile-sales')), findsNothing);
    expect(api.requests.where((r) => r.path.startsWith('/reports')), [
      isA<RequestOptions>().having(
        (r) => r.path,
        'path',
        '/reports/net-profit',
      ),
    ]);
  });

  testWidgets('4 cards: Sales (with tax), Expenses, Wages paid, Net profit', (
    tester,
  ) async {
    await openAt(tester, '/reports');
    expect(last('/reports/net-profit').queryParameters, {
      'from': '2026-11-01',
      'to': '2026-11-16',
    });
    expect(find.byType(KpiChip), findsNWidgets(4));
    for (final label in [
      'Sales (with tax)',
      'Expenses',
      'Wages paid',
      'Net profit',
    ]) {
      expect(
        find.descendant(of: find.byType(KpiChip), matching: find.text(label)),
        findsOneWidget,
        reason: label,
      );
    }
    expect(find.text('₹19,500'), findsOneWidget);
    expect(find.text('₹20,000'), findsOneWidget);
    expect(find.text('-₹1,850'), findsOneWidget);
    expect(find.text('Sales (without tax)'), findsNothing);
  });

  testWidgets('by month: chart + a card per month, newest first', (
    tester,
  ) async {
    await openAt(tester, '/reports');
    expect(find.byType(ReportBarChart), findsOneWidget);
    final nov = find.byKey(const Key('month-2026-11'));
    final oct = find.byKey(const Key('month-2026-10'));
    expect(nov, findsOneWidget);
    expect(oct, findsOneWidget);
    expect(
      tester.getTopLeft(nov).dy,
      lessThan(tester.getTopLeft(oct).dy),
      reason: 'newest first',
    );
    expect(
      find.descendant(of: nov, matching: find.text('-₹2,500')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: nov, matching: find.text('₹12,000')),
      findsOneWidget,
    );
  });

  testWidgets('"Last 7 days" asks for today and the 6 days before', (
    tester,
  ) async {
    await openAt(tester, '/reports');
    await tester.tap(find.byKey(const Key('period-last7Days')));
    await tester.pumpAndSettle();
    expect(last('/reports/net-profit').queryParameters, {
      'from': '2026-11-10',
      'to': '2026-11-16',
    });
    expect(find.text('10 Nov 2026 – 16 Nov 2026'), findsOneWidget);
    await tester.tap(find.byKey(const Key('period-today')));
    await tester.pumpAndSettle();
    expect(last('/reports/net-profit').queryParameters, {
      'from': '2026-11-16',
      'to': '2026-11-16',
    });
    await tester.tap(find.byKey(const Key('period-lastMonth')));
    await tester.pumpAndSettle();
    expect(last('/reports/net-profit').queryParameters, {
      'from': '2026-10-01',
      'to': '2026-10-31',
    });
  });

  testWidgets('loading: the same cards with placeholders (no layout jump)', (
    tester,
  ) async {
    await openAt(tester, '/reports', settle: false);
    await tester.pump();
    await tester.pump();
    // Real cards and labels, values pulsing.
    expect(find.byType(KpiChip), findsNWidgets(4));
    expect(find.text('Wages paid'), findsWidgets);
    expect(find.byType(SkeletonBox), findsWidgets);
    expect(find.byKey(const Key('reportChart')), findsOneWidget);
    final chartBefore = tester.getRect(find.byKey(const Key('reportChart')));
    await tester.pumpAndSettle();
    final chartAfter = tester.getRect(find.byKey(const Key('reportChart')));
    expect(chartAfter.top, chartBefore.top, reason: 'chart stays in place');
    expect(chartAfter.height, chartBefore.height);
  });

  testWidgets('language change shows at once', (tester) async {
    await openAt(tester, '/reports');
    await testContainer.read(localeProvider.notifier).setLocale('bn');
    await tester.pumpAndSettle();
    expect(find.text('মজুরি দেওয়া'), findsWidgets);
    expect(find.text('বিক্রি (ট্যাক্স সহ)'), findsWidgets);
  });

  testWidgets('Export (next to the dates) offers PDF and Excel', (
    tester,
  ) async {
    await openAt(tester, '/reports');
    await tester.tap(find.byKey(const Key('reportExport')));
    await tester.pumpAndSettle();
    expect(find.text('Export PDF'), findsOneWidget);
    expect(find.text('Export Excel'), findsOneWidget);
  });

  testWidgets('old report links open /reports', (tester) async {
    await openAt(tester, '/reports/sales');
    expect(path(), '/reports');
  });

  for (final size in const [Size(320, 700), Size(360, 800), Size(1440, 900)]) {
    for (final dark in [false, true]) {
      testWidgets('no overflow at ${size.width.toInt()} px '
          '(${dark ? 'dark' : 'light'}, Bengali)', (tester) async {
        await openAt(tester, '/reports', size: size, dark: dark, bengali: true);
        expect(tester.takeException(), isNull);
      });
    }
  }

  group('export files', () {
    const view = ReportView(
      title: 'Net profit',
      period: '01 Nov 2026 – 16 Nov 2026',
      summary: [
        ReportFigure(
          'Sales (with tax)',
          '₹19,500',
          Icons.trending_up,
          KpiTint.sky,
        ),
      ],
      tables: [
        ReportTable(
          title: 'By month',
          columns: [
            ReportColumn('Month'),
            ReportColumn('Net profit', numeric: true),
          ],
          rows: [
            ['নভেম্বর', '₹-2,500'],
          ],
        ),
      ],
    );

    testWidgets('PDF (with Bengali) is a real PDF file', (tester) async {
      final bytes = await tester.runAsync(
        () => buildReportPdf(view, generatedOn: 'Generated on 16 Nov 2026'),
      );
      expect(String.fromCharCodes(bytes!.take(5)), '%PDF-');
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
        reportFileName('net-profit', '2026-11-01_2026-11-16'),
        'flyash-net-profit-2026-11-01_2026-11-16',
      );
    });
  });
}
