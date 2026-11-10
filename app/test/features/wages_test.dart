import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flyash/app.dart';
import 'package:flyash/core/router/app_router.dart';
import 'package:flyash/core/widgets/data_table_card.dart';

import '../fake_api.dart';
import '../helpers.dart';
import 'labours_test.dart' show FakeLabours;

Map<String, Object?> body(RequestOptions o) =>
    (o.data is String ? jsonDecode(o.data as String) : o.data)
        as Map<String, Object?>;

Decimal d(Object? v) => Decimal.parse('${v ?? 0}');
String m(Decimal v) => v.toStringAsFixed(2);

/// In-memory wages for two labours; balance = earned − advances − paid.
class FakeWages {
  final requests = <RequestOptions>[];
  int _next = 100;

  final labours = {
    9: {
      'name': 'Abdul Karim',
      'type': 'daily',
      'amount': '450.00',
      'earned': '3150.00',
      'p': 7,
      'a': 1,
    },
    1: {
      'name': 'Kartik Mondal',
      'type': 'monthly',
      'amount': '15000.00',
      'earned': '4000.00',
      'p': 8,
      'a': 0,
    },
  };

  /// labourId → advances / payments (each with month "YYYY-MM").
  final advances = <int, List<Map<String, Object?>>>{
    9: [],
    1: [
      {
        'id': 2,
        'amount': '500.00',
        'advance_date': '2026-11-03',
        'note': 'Medical',
      },
    ],
  };
  final payments = <int, List<Map<String, Object?>>>{9: [], 1: []};

  Map<String, Object?> row(int id, String month) {
    final l = labours[id]!;
    final earned = month == '2026-11' ? d(l['earned']) : Decimal.fromInt(9000);
    final adv = advances[id]!
        .where((a) => (a['advance_date']! as String).startsWith(month))
        .fold(Decimal.zero, (s, a) => s + d(a['amount']));
    final paid = payments[id]!
        .where((p) => p['wage_month'] == '$month-01')
        .fold(Decimal.zero, (s, p) => s + d(p['amount']));
    final balance = earned - adv - paid;
    return {
      'labour_id': id,
      'name': l['name'],
      'wage_type': l['type'],
      'wage_amount': l['amount'],
      'is_active': true,
      'present_days': l['p'],
      'absent_days': l['a'],
      'earned': m(earned),
      'advances': m(adv),
      'paid': m(paid),
      'balance': m(balance),
      'status': paid == Decimal.zero
          ? 'due'
          : (balance <= Decimal.zero ? 'paid' : 'partial'),
    };
  }

  Reply _ok(Object? data, [String msg = 'ok', int code = 200]) =>
      (code, envelope(code, msg, data), {});

  FakeRoutes get routes => {
    'GET /wages': (o) {
      final month = o.queryParameters['month'] as String;
      final rows = [row(9, month), row(1, month)];
      Decimal sum(String k) => rows.fold(Decimal.zero, (s, r) => s + d(r[k]));
      return _ok({
        'items': rows,
        'page': 1,
        'limit': 20,
        'total': 2,
        'last_page': 1,
        'month': month,
        'totals': {
          'earned': m(sum('earned')),
          'advances': m(sum('advances')),
          'paid': m(sum('paid')),
          'balance': m(sum('balance')),
        },
      });
    },
    for (final id in [9, 1]) ...{
      'GET /labours/$id/wages': (o) {
        final month = o.queryParameters['month'] as String;
        return _ok({
          ...row(id, month),
          'month': month,
          'advances': [
            for (final a in advances[id]!)
              if ((a['advance_date']! as String).startsWith(month)) a,
          ],
          'payments': [
            for (final p in payments[id]!)
              if (p['wage_month'] == '$month-01') p,
          ],
          'days': [
            {'date': '$month-01', 'earned': '450.00'},
            {'date': '$month-02', 'earned': '450.00'},
          ],
        });
      },
      'POST /labours/$id/advances': (o) {
        final b = body(o);
        advances[id]!.add({
          'id': _next++,
          'amount': m(d(b['amount'])),
          'advance_date': b['advance_date'],
          'note': b['note'],
        });
        return _ok(null, 'Advance recorded', 201);
      },
      'POST /labours/$id/wage-payments': (o) {
        final b = body(o);
        payments[id]!.add({
          'id': _next++,
          'wage_month': '${b['wage_month']}-01',
          'amount': m(d(b['amount'])),
          'payment_date': b['payment_date'],
          'method': b['method'],
          'note': b['note'],
          'created_by': {'id': 1, 'name': 'Test Owner'},
        });
        return _ok(null, 'Wage payment recorded', 201);
      },
    },
    for (final aid in [2, 100, 101, 102])
      'DELETE /advances/$aid': (_) {
        for (final list in advances.values) {
          list.removeWhere((a) => a['id'] == aid);
        }
        return _ok(null, 'Advance deleted');
      },
    for (final pid in [100, 101, 102])
      'DELETE /wage-payments/$pid': (_) {
        for (final list in payments.values) {
          list.removeWhere((p) => p['id'] == pid);
        }
        return _ok(null, 'Wage payment deleted');
      },
  };
}

late FakeWages api;

Future<void> openAt(
  WidgetTester tester,
  String location, {
  Size size = const Size(400, 900),
}) async {
  api = FakeWages();
  setScreenSize(tester, size);
  await tester.pumpWidget(
    await testApp(
      const FlyAshApp(),
      prefs: {'business.date': '2026-11-09'},
      token: 'oat_saved',
      api: signedInRoutes({...FakeLabours().routes, ...api.routes}),
      requests: api.requests,
    ),
  );
  await tester.pumpAndSettle();
  testContainer.read(routerProvider).go(location);
  await tester.pumpAndSettle();
}

String currentLocation() => testContainer
    .read(routerProvider)
    .routeInformationProvider
    .value
    .uri
    .toString();

Future<void> tapVisible(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

RequestOptions last(String method, String path) =>
    api.requests.lastWhere((r) => r.method == method && r.path == path);

void main() {
  testWidgets('wage sheet: month, totals, rows; no future months', (
    tester,
  ) async {
    await openAt(tester, '/labours/wages');
    expect(last('GET', '/wages').queryParameters['month'], '2026-11');
    expect(find.text('Nov 2026'), findsOneWidget);
    expect(find.text('Earned in Nov 2026'), findsOneWidget);
    expect(find.text('₹7,150'), findsOneWidget); // 3,150 + 4,000
    expect(find.text('₹500'), findsWidgets); // advances
    expect(find.text('₹6,650'), findsOneWidget); // balance
    expect(find.text('7 days · earned ₹3,150'), findsOneWidget);
    expect(find.text('₹3,500'), findsOneWidget); // Kartik's balance
    expect(find.text('Due'), findsNWidgets(2));

    final next = find.ancestor(
      of: find.byIcon(Icons.chevron_right),
      matching: find.byType(IconButton),
    );
    expect(tester.widget<IconButton>(next.first).onPressed, isNull);
    await tester.tap(find.byTooltip('Previous').first);
    await tester.pumpAndSettle();
    expect(last('GET', '/wages').queryParameters['month'], '2026-10');
    expect(find.text('Oct 2026'), findsOneWidget);
  });

  testWidgets('desktop: the sheet is a table', (tester) async {
    await openAt(tester, '/labours/wages', size: const Size(1440, 900));
    expect(find.byType(DataTableCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('?month= opens that month; a row opens the labour for it', (
    tester,
  ) async {
    await openAt(tester, '/labours/wages?month=2026-10');
    expect(last('GET', '/wages').queryParameters['month'], '2026-10');
    await tester.tap(find.text('Kartik Mondal'));
    await tester.pumpAndSettle();
    expect(currentLocation(), '/labours/wages/1?month=2026-10');
    expect(last('GET', '/labours/1/wages').queryParameters['month'], '2026-10');
  });

  testWidgets('detail: breakdown, pay wage prefilled with the balance', (
    tester,
  ) async {
    await openAt(tester, '/labours/wages/1?month=2026-11');
    expect(find.text('Present 8 · Absent 0'), findsOneWidget);
    expect(find.text('₹4,000.00'), findsOneWidget); // earned
    expect(find.text('− ₹500.00'), findsOneWidget); // advance
    expect(find.text('₹3,500.00'), findsOneWidget); // balance
    expect(find.text('Medical'), findsOneWidget);

    await tapVisible(tester, find.widgetWithText(FilledButton, 'Pay wage'));
    expect(find.text('Pay Kartik Mondal for Nov 2026'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '3500'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Amount'),
      '2000',
    );
    await tester.tap(find.widgetWithText(ChoiceChip, 'UPI'));
    await tester.tap(find.widgetWithText(FilledButton, 'Pay wage').last);
    await tester.pumpAndSettle();

    expect(body(last('POST', '/labours/1/wage-payments')), {
      'wage_month': '2026-11',
      'amount': '2000',
      'payment_date': '2026-11-09',
      'method': 'upi',
      'note': null,
    });
    expect(find.text('Wage payment recorded'), findsOneWidget);
    expect(find.text('₹1,500.00'), findsOneWidget); // new balance
    expect(find.text('Partial'), findsOneWidget);
    expect(find.text('09 Nov 2026 · UPI'), findsOneWidget);
  });

  testWidgets('give advance: today in this month, month end in a past one', (
    tester,
  ) async {
    await openAt(tester, '/labours/wages/9?month=2026-11');
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Give advance'));
    expect(find.text('Advance to Abdul Karim'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '0');
    await tester.tap(find.widgetWithText(FilledButton, 'Give advance').last);
    await tester.pumpAndSettle();
    expect(find.text('Enter an amount, e.g. 4.50'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Amount'),
      '1000',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Give advance').last);
    await tester.pumpAndSettle();
    expect(body(last('POST', '/labours/9/advances')), {
      'amount': '1000',
      'advance_date': '2026-11-09',
      'note': null,
    });
    expect(find.text('Advance recorded'), findsOneWidget);
    expect(find.text('₹2,150.00'), findsOneWidget); // 3,150 − 1,000

    await tapVisible(tester, find.byTooltip('Previous'));
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Give advance'));
    expect(find.text('31 Oct 2026'), findsOneWidget);
  });

  testWidgets('delete an advance asks first, then the balance goes up', (
    tester,
  ) async {
    await openAt(tester, '/labours/wages/1?month=2026-11');
    await tapVisible(tester, find.byTooltip('Delete advance'));
    await tester.tap(find.text('Delete advance').last);
    await tester.pumpAndSettle();
    expect(find.text('Delete advance of ₹500.00?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(last('DELETE', '/advances/2'), isNotNull);
    expect(find.text('Advance deleted'), findsOneWidget);
    expect(find.text('No advance this month'), findsOneWidget);
    expect(find.text('₹4,000.00'), findsNWidgets(2)); // earned = balance
  });

  testWidgets('day by day opens on tap', (tester) async {
    await openAt(tester, '/labours/wages/9?month=2026-11');
    expect(find.text('01 Nov 2026'), findsNothing);
    await tapVisible(tester, find.text('Day by day'));
    expect(find.text('01 Nov 2026'), findsOneWidget);
    expect(find.text('02 Nov 2026'), findsOneWidget);
    expect(find.text('Present'), findsNWidgets(2));
    expect(find.text('₹450.00'), findsNWidgets(2));
  });

  testWidgets('labour page shows this month\'s wage and opens the detail', (
    tester,
  ) async {
    await openAt(tester, '/labours/1');
    expect(find.text('Wage this month'), findsOneWidget);
    expect(find.text('₹3,500'), findsOneWidget); // balance tile
    await tapVisible(tester, find.text('Advance / pay'));
    expect(currentLocation(), '/labours/wages/1?month=2026-11');
  });

  for (final size in const [Size(360, 800), Size(800, 1000), Size(1440, 900)]) {
    for (final dark in [false, true]) {
      testWidgets('no overflow at ${size.width.toInt()} px '
          '(${dark ? 'dark' : 'light'}, Bengali)', (tester) async {
        api = FakeWages();
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
            api: signedInRoutes({...FakeLabours().routes, ...api.routes}),
          ),
        );
        await tester.pumpAndSettle();
        for (final path in [
          '/labours/wages',
          '/labours/wages/1?month=2026-11',
          '/labours/1',
        ]) {
          testContainer.read(routerProvider).go(path);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: path);
        }
        // Let the last page's requests finish.
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();
      });
    }
  }
}
