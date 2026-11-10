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

/// In-memory attendance per date for three labours: a present labour has a
/// row, an absent one has none.
class FakeAttendance {
  FakeAttendance({this.empty = false});

  final bool empty;
  bool fail = false;
  final requests = <RequestOptions>[];
  final Map<String, Set<String>> present = {
    '2026-11-09': {'9'},
    '2026-11-08': {'9', '1'},
  };

  static const names = {
    '9': 'Abdul Karim',
    '12': 'Asit Roy',
    '1': 'Kartik Mondal',
  };

  Map<String, Object?> _day(String date) {
    final p = present.putIfAbsent(date, () => {});
    return {
      'date': date,
      'items': empty
          ? const []
          : [
              for (final id in names.keys)
                {
                  'labour_id': id,
                  'name': names[id],
                  'wage_type': id == '1' ? 'monthly' : 'daily',
                  'wage_amount': id == '1' ? '15000.00' : '450.00',
                  'present': p.contains(id),
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
      if (fail || date == '2026-11-01') {
        return (
          400,
          envelope(400, 'Labour(s) 1 were not employed on $date', null),
          {},
        );
      }
      final p = present.putIfAbsent(date, () => {});
      for (final r in (b['records']! as List).cast<Map<String, Object?>>()) {
        final id = '${r['labour_id']}';
        r['present'] == true ? p.add(id) : p.remove(id);
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

/// The switch on the row of [name].
Finder switchOf(String name) => find.descendant(
  of: find.ancestor(of: find.text(name), matching: find.byType(InkWell)).first,
  matching: find.byType(Switch),
);

bool isOn(WidgetTester tester, String name) =>
    tester.widget<Switch>(switchOf(name)).value;

Future<void> flip(WidgetTester tester, String name) async {
  await tester.ensureVisible(switchOf(name));
  await tester.pumpAndSettle();
  await tester.tap(switchOf(name));
  await tester.pumpAndSettle();
}

RequestOptions lastGet() =>
    api.requests.lastWhere((r) => r.method == 'GET' && r.path == '/attendance');

List<RequestOptions> puts() => api.requests
    .where((r) => r.method == 'PUT' && r.path == '/attendance')
    .toList();

void main() {
  testWidgets('today: names, wages, switches; no Save button, no half day', (
    tester,
  ) async {
    await openAttendance(tester);
    expect(lastGet().queryParameters['date'], '2026-11-09');
    expect(find.text('Today, 09 Nov 2026'), findsOneWidget);
    expect(find.text('Select date'), findsOneWidget);
    expect(find.text('Asit Roy'), findsOneWidget);
    expect(find.text('₹450 / day'), findsNWidgets(2));
    expect(find.text('₹15,000 / month'), findsOneWidget);
    expect(find.text('1 present · 2 absent'), findsOneWidget);
    expect(find.byType(Switch), findsNWidgets(3));
    expect(isOn(tester, 'Abdul Karim'), isTrue);
    expect(isOn(tester, 'Asit Roy'), isFalse);
    expect(find.textContaining('Save'), findsNothing);
    expect(find.textContaining('Half'), findsNothing);
  });

  testWidgets('a switch saves at once: on = present, off = absent', (
    tester,
  ) async {
    await openAttendance(tester);

    await flip(tester, 'Asit Roy');
    expect(isOn(tester, 'Asit Roy'), isTrue);
    expect(body(puts().last), {
      'date': '2026-11-09',
      'records': [
        {'labour_id': '12', 'present': true},
      ],
    });
    expect(api.present['2026-11-09'], {'9', '12'});
    expect(find.text('2 present · 1 absent'), findsOneWidget);

    await flip(tester, 'Abdul Karim');
    expect(isOn(tester, 'Abdul Karim'), isFalse);
    expect(body(puts().last)['records'], [
      {'labour_id': '9', 'present': false},
    ]);
    expect(api.present['2026-11-09'], {'12'});

    // Tapping the name flips it too
    await tester.tap(find.text('Kartik Mondal'));
    await tester.pumpAndSettle();
    expect(isOn(tester, 'Kartik Mondal'), isTrue);
    expect(puts(), hasLength(3));
  });

  testWidgets('a refused save puts the switch back and shows the message', (
    tester,
  ) async {
    await openAttendance(tester);
    api.fail = true;
    await flip(tester, 'Asit Roy');
    expect(isOn(tester, 'Asit Roy'), isFalse);
    expect(
      find.text('Labour(s) 1 were not employed on 2026-11-09'),
      findsOneWidget,
    );
  });

  testWidgets('search filters the names', (tester) async {
    await openAttendance(tester);
    await tester.enterText(find.byType(TextField), 'kart');
    await tester.pumpAndSettle();
    expect(find.text('Kartik Mondal'), findsOneWidget);
    expect(find.text('Asit Roy'), findsNothing);
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('No results found'), findsOneWidget);
  });

  testWidgets('no future: › is off today; ‹ loads yesterday', (tester) async {
    await openAttendance(tester);
    final next = find.ancestor(
      of: find.byTooltip('Next'),
      matching: find.byType(IconButton),
    );
    expect(tester.widget<IconButton>(next).onPressed, isNull);

    await tester.tap(find.byTooltip('Previous'));
    await tester.pumpAndSettle();
    expect(lastGet().queryParameters['date'], '2026-11-08');
    expect(find.text('Yesterday, 08 Nov 2026'), findsOneWidget);
    expect(isOn(tester, 'Kartik Mondal'), isTrue);
    expect(isOn(tester, 'Asit Roy'), isFalse);

    // A switch on yesterday saves for yesterday
    await flip(tester, 'Asit Roy');
    expect(body(puts().last)['date'], '2026-11-08');

    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(find.text('Today, 09 Nov 2026'), findsOneWidget);
  });

  testWidgets('?date= opens that day; a future ?date= falls back to today', (
    tester,
  ) async {
    await openAttendance(tester, location: '/attendance?date=2026-11-08');
    expect(lastGet().queryParameters['date'], '2026-11-08');
    testContainer.read(routerProvider).go('/home');
    await tester.pumpAndSettle();
    await openAttendance(tester, location: '/attendance?date=2099-01-01');
    expect(lastGet().queryParameters['date'], '2026-11-09');
  });

  testWidgets('nobody employed: explains and offers Add labour', (
    tester,
  ) async {
    await openAttendance(tester, empty: true);
    expect(find.text('No labours on this date'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Add labour'), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
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
