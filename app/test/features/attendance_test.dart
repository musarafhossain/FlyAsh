import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flyash/app.dart';
import 'package:flyash/core/router/app_router.dart';

import '../fake_api.dart';
import '../helpers.dart';

Map<String, Object?> body(RequestOptions o) =>
    (o.data is String ? jsonDecode(o.data as String) : o.data)
        as Map<String, Object?>;

/// In-memory attendance per date for three labours.
class FakeAttendance {
  FakeAttendance({this.empty = false});

  final bool empty;
  final requests = <RequestOptions>[];
  final Map<String, Map<int, String?>> days = {
    '2026-11-09': {9: 'present', 12: null, 1: null},
    '2026-11-08': {9: 'present', 12: 'absent', 1: 'half_day'},
  };

  static const names = {9: 'Abdul Karim', 12: 'Asit Roy', 1: 'Kartik Mondal'};

  Map<String, Object?> _day(String date) {
    final d = days.putIfAbsent(date, () => {9: null, 12: null, 1: null});
    return {
      'date': date,
      'items': empty
          ? const []
          : [
              for (final e in d.entries)
                {
                  'labour_id': e.key,
                  'name': names[e.key],
                  'wage_type': e.key == 1 ? 'monthly' : 'daily',
                  'wage_amount': e.key == 1 ? '15000.00' : '450.00',
                  'status': e.value,
                },
            ],
    };
  }

  FakeRoutes get routes => {
    'GET /attendance': (o) => (
      200,
      envelope(200, 'ok', _day(o.queryParameters['date'] as String)),
      {},
    ),
    'PUT /attendance': (o) {
      final b = body(o);
      final date = b['date']! as String;
      if (date == '2026-11-01') {
        return (
          400,
          envelope(400, 'Labour(s) 1 were not employed on 2026-11-01', null),
          {},
        );
      }
      final d = days[date]!;
      for (final r in (b['records']! as List).cast<Map<String, Object?>>()) {
        d[int.parse('${r['labour_id']}')] = r['status'] as String?;
      }
      return (200, envelope(200, 'Attendance saved for $date', _day(date)), {});
    },
  };
}

late FakeAttendance api;

Future<void> openAttendance(
  WidgetTester tester, {
  Size size = const Size(400, 900),
  String location = '/attendance',
  bool empty = false,
}) async {
  api = FakeAttendance(empty: empty);
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

Finder toggle(String name, String status) =>
    find.bySemanticsLabel('$name: $status');

Future<void> tapToggle(WidgetTester tester, String name, String status) async {
  await tester.ensureVisible(toggle(name, status));
  await tester.pumpAndSettle();
  await tester.tap(toggle(name, status));
}

RequestOptions lastGet() =>
    api.requests.lastWhere((r) => r.method == 'GET' && r.path == '/attendance');

void main() {
  testWidgets('today: ring, tiles, P/H/A, save sends only the changes', (
    tester,
  ) async {
    await openAttendance(tester);
    expect(lastGet().queryParameters['date'], '2026-11-09');
    expect(find.text('Today, 09 Nov 2026'), findsOneWidget);
    expect(find.text('1/3'), findsOneWidget); // ring: present / total
    expect(find.text('No changes'), findsOneWidget);

    await tapToggle(tester, 'Asit Roy', 'Half day');
    await tapToggle(tester, 'Kartik Mondal', 'Absent');
    await tester.pumpAndSettle();
    expect(find.text('2 changed'), findsOneWidget);

    // Tapping the chosen one again clears it
    await tapToggle(tester, 'Kartik Mondal', 'Absent');
    await tester.pumpAndSettle();
    expect(find.text('1 changed'), findsOneWidget);
    await tapToggle(tester, 'Kartik Mondal', 'Absent');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Save attendance'));
    await tester.pumpAndSettle();
    final put = api.requests.lastWhere((r) => r.method == 'PUT');
    expect(body(put), {
      'date': '2026-11-09',
      'records': [
        {'labour_id': '12', 'status': 'half_day'},
        {'labour_id': '1', 'status': 'absent'},
      ],
    });
    expect(find.text('Attendance saved for 09 Nov 2026'), findsOneWidget);
    expect(find.text('No changes'), findsOneWidget);
  });

  testWidgets('Mark all present, then clearing a saved day sends null', (
    tester,
  ) async {
    await openAttendance(tester);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Mark all present'));
    await tester.pumpAndSettle();
    expect(find.text('3/3'), findsOneWidget);
    expect(find.text('2 changed'), findsOneWidget);

    await tapToggle(tester, 'Abdul Karim', 'Present'); // was saved present
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save attendance'));
    await tester.pumpAndSettle();
    final records = body(
      api.requests.lastWhere((r) => r.method == 'PUT'),
    )['records'];
    expect(
      records,
      containsAll([
        {'labour_id': '9', 'status': null},
        {'labour_id': '12', 'status': 'present'},
        {'labour_id': '1', 'status': 'present'},
      ]),
    );
  });

  testWidgets('no future: › is off today; ‹ loads yesterday', (tester) async {
    await openAttendance(tester);
    expect(
      tester
          .widget<IconButton>(
            find.ancestor(
              of: find.byIcon(Icons.chevron_right),
              matching: find.byType(IconButton),
            ),
          )
          .onPressed,
      isNull,
    );
    await tester.ensureVisible(find.byTooltip('Previous'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Previous'));
    await tester.pumpAndSettle();
    expect(lastGet().queryParameters['date'], '2026-11-08');
    expect(find.text('Yesterday, 08 Nov 2026'), findsOneWidget);
    expect(find.text('2/3'), findsNothing);
    expect(find.text('1/3'), findsOneWidget);
  });

  testWidgets('unsaved changes + date change asks: Cancel, Discard, Save', (
    tester,
  ) async {
    await openAttendance(tester);
    await tapToggle(tester, 'Asit Roy', 'Present');
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byTooltip('Previous'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Previous'));
    await tester.pumpAndSettle();
    expect(find.text('Save changes for 09 Nov 2026?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Today, 09 Nov 2026'), findsOneWidget);
    expect(find.text('1 changed'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('Previous'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Previous'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(api.days['2026-11-09']![12], 'present');
    expect(find.text('Yesterday, 08 Nov 2026'), findsOneWidget);

    await tapToggle(tester, 'Asit Roy', 'Present');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Discard'));
    await tester.pumpAndSettle();
    expect(api.days['2026-11-08']![12], 'absent', reason: 'not saved');
    expect(find.text('Today, 09 Nov 2026'), findsOneWidget);
  });

  testWidgets('?date= opens that day; a server refusal shows its message', (
    tester,
  ) async {
    await openAttendance(tester, location: '/attendance?date=2026-11-01');
    expect(lastGet().queryParameters['date'], '2026-11-01');
    await tapToggle(tester, 'Kartik Mondal', 'Present');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save attendance'));
    await tester.pumpAndSettle();
    expect(
      find.text('Labour(s) 1 were not employed on 2026-11-01'),
      findsOneWidget,
    );
    expect(find.text('1 changed'), findsOneWidget, reason: 'kept on screen');
  });

  testWidgets('a future ?date= falls back to today', (tester) async {
    await openAttendance(tester, location: '/attendance?date=2099-01-01');
    expect(lastGet().queryParameters['date'], '2026-11-09');
  });

  testWidgets('nobody employed: explains and offers Add labour', (
    tester,
  ) async {
    await openAttendance(tester, empty: true);
    expect(find.text('No labours on this date'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Add labour'), findsOneWidget);
    expect(find.text('Save attendance'), findsNothing);
  });

  for (final size in const [Size(360, 800), Size(800, 1000), Size(1440, 900)]) {
    for (final dark in [false, true]) {
      testWidgets('no overflow at ${size.width.toInt()} px '
          '(${dark ? 'dark' : 'light'}, Bengali)', (tester) async {
        api = FakeAttendance();
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
        testContainer.read(routerProvider).go('/attendance');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
