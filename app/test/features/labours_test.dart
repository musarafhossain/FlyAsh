import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flyash/app.dart';
import 'package:flyash/core/router/app_router.dart';
import 'package:flyash/core/utils/contact_launcher.dart';
import 'package:flyash/core/widgets/data_table_card.dart';
import 'package:flyash/features/labours/presentation/widgets/labours_tab.dart';

import '../fake_api.dart';
import '../helpers.dart';

Map<String, Object?> body(RequestOptions o) =>
    (o.data is String ? jsonDecode(o.data as String) : o.data)
        as Map<String, Object?>;

Map<String, Object?> labour(
  int id,
  String name, {
  String type = 'daily',
  String amount = '450.00',
  String? phone,
  bool active = true,
  String? today,
  String joined = '2026-08-25',
  String? left,
}) => {
  'id': id,
  'name': name,
  'phone': phone,
  'address': null,
  'wage_type': type,
  'wage_amount': amount,
  'joining_date': joined,
  'left_date': left,
  'is_active': active,
  'today_status': today,
};

/// In-memory Labours API (07-API §10).
class FakeLabours {
  FakeLabours()
    : labours = [
        labour(9, 'Abdul Karim', phone: '9120837832', today: 'present'),
        labour(1, 'Kartik Mondal', type: 'monthly', amount: '15000.00'),
        labour(5, 'Old Worker', active: false, left: '2026-10-31'),
      ];

  final List<Map<String, Object?>> labours;
  final requests = <RequestOptions>[];

  Reply _ok(Object? d, [String m = 'ok', int c = 200]) =>
      (c, envelope(c, m, d), {});

  Map<String, Object?> _clean(Map<String, Object?> b) => {
    ...b,
    'wage_amount': double.parse('${b['wage_amount']}').toStringAsFixed(2),
  };

  FakeRoutes get routes => {
    'GET /labours': (o) {
      final a = o.queryParameters['active'];
      final items = [
        for (final lb in labours)
          if (a == null || '${lb['is_active']}' == '$a') lb,
      ];
      return _ok({
        'items': items,
        'page': 1,
        'limit': 20,
        'total': items.length,
        'last_page': 1,
      });
    },
    'POST /labours': (o) {
      final created = {...labour(30, ''), ..._clean(body(o)), 'id': 30};
      labours.add(created);
      return _ok(created, 'Labour added successfully', 201);
    },
    'GET /labours/30': (_) => _ok(labours.firstWhere((l) => l['id'] == 30)),
    'GET /labours/30/attendance': (_) => _ok({
      'labour_id': 30,
      'month': '2026-11',
      'days': const [],
      'summary': {'present': 0, 'half_day': 0, 'absent': 0},
    }),
    for (final lb in labours) ...{
      'GET /labours/${lb['id']}': (_) => _ok(lb),
      'PUT /labours/${lb['id']}': (o) {
        lb.addAll(_clean(body(o)));
        return _ok(lb, 'Labour updated successfully');
      },
      'PATCH /labours/${lb['id']}/status': (o) {
        final b = body(o);
        final active = b['is_active']! as bool;
        lb['is_active'] = active;
        lb['left_date'] = active ? null : b['left_date'];
        return _ok(lb, active ? 'Labour activated' : 'Labour deactivated');
      },
      'GET /labours/${lb['id']}/attendance': (o) {
        final month = o.queryParameters['month'] as String;
        return _ok({
          'labour_id': lb['id'],
          'month': month,
          'days': [
            {'date': '$month-03', 'status': 'present'},
            {'date': '$month-04', 'status': 'half_day'},
            {'date': '$month-05', 'status': 'absent'},
            {'date': '$month-06', 'status': 'present'},
          ],
          'summary': {'present': 2, 'half_day': 1, 'absent': 1},
        });
      },
    },
  };
}

late FakeLabours api;

Future<void> openLabours(
  WidgetTester tester, {
  Size size = const Size(360, 800),
  String location = '/labours',
}) async {
  api = FakeLabours();
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
  testContainer.read(routerProvider).go(location);
  await tester.pumpAndSettle();
}

String currentPath() =>
    testContainer.read(routerProvider).routeInformationProvider.value.uri.path;

Future<void> tapVisible(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

RequestOptions last(String method, String path) =>
    api.requests.lastWhere((r) => r.method == method && r.path == path);

void main() {
  late List<Uri> launched;
  setUp(() {
    launched = [];
    ContactLauncher.launch = (uri) async {
      launched.add(uri);
      return true;
    };
  });

  testWidgets('phone: active labours with wage and today\'s attendance', (
    tester,
  ) async {
    await openLabours(tester);
    expect(api.requests.last.queryParameters['active'], 'true');
    expect(find.byType(LabourTile), findsNWidgets(2));
    expect(find.text('₹450 / day'), findsOneWidget);
    expect(find.text('₹15,000 / month'), findsOneWidget);
    expect(find.text('Present'), findsOneWidget);
    expect(find.text('Not marked'), findsOneWidget);
    expect(find.byType(DataTableCard), findsNothing);
  });

  testWidgets('filters: Inactive and All', (tester) async {
    await openLabours(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Inactive'));
    await tester.pumpAndSettle();
    expect(api.requests.last.queryParameters['active'], 'false');
    expect(find.text('Old Worker'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await tester.pumpAndSettle();
    expect(api.requests.last.queryParameters.containsKey('active'), isFalse);
    expect(find.byType(LabourTile), findsNWidgets(3));
  });

  testWidgets('desktop: a table with wage, joined and today', (tester) async {
    await openLabours(tester, size: const Size(1440, 900));
    expect(find.byType(DataTableCard), findsOneWidget);
    expect(find.text('25 Aug 2026'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('add: wage type + amount required, monthly, then the new '
      'labour opens', (tester) async {
    await openLabours(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(currentPath(), '/labours/new');

    await tapVisible(tester, find.widgetWithText(FilledButton, 'Add labour'));
    expect(find.text('This field is required'), findsNWidgets(2)); // name, wage

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Motiur',
    );
    await tester.tap(find.text('Monthly'));
    await tester.pumpAndSettle();
    expect(find.text('Wage per month'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Wage per month'),
      '0',
    );
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Add labour'));
    expect(find.text('Enter an amount, e.g. 4.50'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Wage per month'),
      '12000',
    );
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Add labour'));
    expect(body(last('POST', '/labours')), {
      'name': 'Motiur',
      'phone': null,
      'address': null,
      'wage_type': 'monthly',
      'wage_amount': '12000',
      'joining_date': '2026-11-09',
    });
    expect(currentPath(), '/labours/30');
    expect(find.text('Labour added'), findsOneWidget);
    expect(find.text('₹12,000 / month'), findsOneWidget);
  });

  testWidgets('detail: calendar with colours and totals, months, Call', (
    tester,
  ) async {
    await openLabours(tester);
    await tester.tap(find.text('Abdul Karim'));
    await tester.pumpAndSettle();
    expect(currentPath(), '/labours/9');
    expect(
      last('GET', '/labours/9/attendance').queryParameters['month'],
      '2026-11',
    );
    expect(find.text('Nov 2026'), findsOneWidget);
    expect(find.text('Present 2'), findsOneWidget);
    expect(find.text('Half day 1'), findsOneWidget);
    expect(find.text('Absent 1'), findsOneWidget);
    expect(find.bySemanticsLabel('03 Nov 2026: Present'), findsOneWidget);
    expect(find.bySemanticsLabel('05 Nov 2026: Absent'), findsOneWidget);

    // No future months; the previous month loads
    final next = find.ancestor(
      of: find.byIcon(Icons.chevron_right),
      matching: find.byType(IconButton),
    );
    expect(tester.widget<IconButton>(next).onPressed, isNull);
    await tester.tap(find.byTooltip('Previous'));
    await tester.pumpAndSettle();
    expect(
      last('GET', '/labours/9/attendance').queryParameters['month'],
      '2026-10',
    );
    expect(find.text('Oct 2026'), findsOneWidget);

    await tapVisible(tester, find.text('Call'));
    expect(launched.single, Uri.parse('tel:+919120837832'));
  });

  testWidgets('edit: a new wage explains it applies from now on', (
    tester,
  ) async {
    await openLabours(tester, location: '/labours/9');
    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, '450'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Wage per day'),
      '500',
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('applies to attendance saved from now on'),
      findsOneWidget,
    );
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Save'));
    expect(body(last('PUT', '/labours/9'))['wage_amount'], '500');
    expect(currentPath(), '/labours/9');
    expect(find.text('₹500 / day'), findsOneWidget);
  });

  testWidgets('deactivate asks for the leaving date; activate asks first', (
    tester,
  ) async {
    await openLabours(tester, location: '/labours/9');
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deactivate'));
    await tester.pumpAndSettle();
    expect(find.text('Abdul Karim left?'), findsOneWidget);
    expect(find.text('09 Nov 2026'), findsOneWidget); // default: today
    await tester.tap(find.widgetWithText(FilledButton, 'Deactivate'));
    await tester.pumpAndSettle();
    expect(body(last('PATCH', '/labours/9/status')), {
      'is_active': false,
      'left_date': '2026-11-09',
    });
    expect(find.text('Labour deactivated'), findsOneWidget);
    expect(find.text('Leaving date'), findsOneWidget);

    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Activate'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Activate'));
    await tester.pumpAndSettle();
    expect(body(last('PATCH', '/labours/9/status')), {'is_active': true});
    expect(find.text('Labour activated'), findsOneWidget);
  });

  for (final size in const [Size(360, 800), Size(800, 1000), Size(1440, 900)]) {
    for (final dark in [false, true]) {
      testWidgets('no overflow at ${size.width.toInt()} px '
          '(${dark ? 'dark' : 'light'}, Bengali)', (tester) async {
        api = FakeLabours();
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
        for (final path in [
          '/labours',
          '/labours/new',
          '/labours/9',
          '/labours/1',
        ]) {
          testContainer.read(routerProvider).go(path);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: path);
        }
      });
    }
  }
}
