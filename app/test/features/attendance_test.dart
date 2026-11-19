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

  /// date → labour id → wage saved with a present row (07-API §11).
  final Map<String, Map<String, String>> wages = {};

  static const sampleNames = {
    '9': 'Abdul Karim',
    '12': 'Asit Roy',
    '1': 'Kartik Mondal',
  };

  /// id → name, by name (more labours for paging tests).
  Map<String, String> names = sampleNames;

  /// Like the API: a page of 20 by name, `search` on the name, only
  /// [ids] after a save; `summary` counts the whole day.
  Map<String, Object?> _day(
    String date, {
    int page = 1,
    int limit = 20,
    String? search,
    Iterable<String>? ids,
  }) {
    final p = present.putIfAbsent(date, () => {});
    final saved = wages[date] ?? const {};
    final all = empty ? const <String>[] : names.keys.toList();
    final matching = [
      for (final id in all)
        if ((ids == null || ids.contains(id)) &&
            (search == null ||
                names[id]!.toLowerCase().contains(search.toLowerCase())))
          id,
    ];
    final size = ids == null ? limit : (matching.isEmpty ? 1 : matching.length);
    final pageIds = matching.skip((page - 1) * size).take(size).toList();
    return {
      'date': date,
      'summary': {
        'total': all.length,
        'present': all.where(p.contains).length,
        'absent': all.length - all.where(p.contains).length,
      },
      'page': page,
      'limit': size,
      'total': matching.length,
      'last_page': matching.isEmpty ? 1 : (matching.length / size).ceil(),
      'items': [
        for (final id in pageIds)
          {
            'labour_id': id,
            'name': names[id],
            'wage_type': id == '1' ? 'monthly' : 'daily',
            'wage_amount': id == '1' ? '15000.00' : '450.00',
            'present': p.contains(id),
            // Default: 450 a day, or 15,000 ÷ 30 days in November.
            'day_wage': p.contains(id)
                ? saved[id] ?? (id == '1' ? '15000.00' : '450.00')
                : (id == '1' ? '15000.00' : '450.00'),
            // Monthly: the month's wage (one present day earns all of it).
            'default_day_wage': id == '1' ? '15000.00' : '450.00',
          },
      ],
    };
  }

  FakeRoutes get routes => {
    'GET /attendance': (o) => (
      200,
      envelope(
        200,
        'ok',
        _day(
          o.queryParameters['date'] as String,
          page: (o.queryParameters['page'] as int?) ?? 1,
          limit: (o.queryParameters['limit'] as int?) ?? 20,
          search: o.queryParameters['search'] as String?,
        ),
      ),
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
      final records = (b['records']! as List).cast<Map<String, Object?>>();
      for (final r in records) {
        final id = '${r['labour_id']}';
        final day = wages.putIfAbsent(date, () => {});
        if (r['present'] == true) {
          if (!p.contains(id) && r['wage'] != null) {
            day[id] = double.parse('${r['wage']}').toStringAsFixed(2);
          }
          p.add(id);
        } else {
          p.remove(id);
          day.remove(id);
        }
      }
      return (
        200,
        envelope(
          200,
          'Attendance saved for $date',
          _day(date, ids: [for (final r in records) '${r['labour_id']}']),
        ),
        {},
      );
    },
  };
}

late FakeAttendance api;

Future<void> openAttendance(
  WidgetTester tester, {
  Size size = const Size(400, 900),
  String location = '/attendance',
  bool empty = false,
  Map<String, String>? names,
  Set<String>? presentToday,
}) async {
  api = FakeAttendance(empty: empty);
  if (names != null) api.names = names;
  if (presentToday != null) api.present['2026-11-09'] = presentToday;
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

/// The row of [name].
Finder rowOf(String name) => find.ancestor(
  of: find.text(name),
  matching: find.byWidgetPredicate(
    (w) => '${w.key}'.contains('attendanceRow-'),
  ),
);

/// The switch on the row of [name].
Finder switchOf(String name) =>
    find.descendant(of: rowOf(name), matching: find.byType(Switch));

/// The ✏ button on the row of [name].
Finder pencilOf(String name) => find.descendant(
  of: rowOf(name),
  matching: find.widgetWithIcon(IconButton, Icons.edit_outlined),
);

/// The ↺ button on the row of [name] (only when the wage is not the usual).
Finder resetOf(String name) => find.descendant(
  of: rowOf(name),
  matching: find.widgetWithIcon(IconButton, Icons.restart_alt),
);

bool pencilEnabled(WidgetTester tester, String name) =>
    tester.widget<IconButton>(pencilOf(name)).onPressed != null;

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
    // Daily: the day's wage; monthly: the full month (not ÷ days), no ✏
    expect(find.text('₹450 / day'), findsNWidgets(2));
    expect(find.text('₹15,000 / month'), findsOneWidget);
    expect(find.byKey(const Key('editWage-1')), findsNothing);
    expect(find.byKey(const Key('editWage-9')), findsOneWidget);
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
      'rows': 'saved', // only the saved rows come back
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

    // Only the switch marks attendance: tapping the name does nothing
    await tester.tap(find.text('Kartik Mondal'));
    await tester.pumpAndSettle();
    expect(isOn(tester, 'Kartik Mondal'), isFalse);
    expect(puts(), hasLength(2));
  });

  testWidgets('✏ is on only while absent; an edited wage shows and is saved '
      'when marked present', (tester) async {
    await openAttendance(tester);
    expect(pencilEnabled(tester, 'Abdul Karim'), isFalse, reason: 'present');
    expect(pencilEnabled(tester, 'Asit Roy'), isTrue, reason: 'absent');

    await tester.tap(pencilOf('Asit Roy'));
    await tester.pumpAndSettle();
    expect(find.text('Day wage for Asit Roy'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '450'), findsOneWidget);

    // Not more than 0 → error, dialog stays
    await tester.enterText(find.byType(TextFormField), '0');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('Day wage for Asit Roy'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '520.5');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    // Shown like any wage (no "edited" label), with ↺ next to ✏
    expect(find.text('₹520.50 / day'), findsOneWidget);
    expect(find.textContaining('edited'), findsNothing);
    expect(resetOf('Asit Roy'), findsOneWidget);
    expect(resetOf('Kartik Mondal'), findsNothing, reason: 'usual wage');
    expect(puts(), isEmpty, reason: 'nothing saved yet');

    await flip(tester, 'Asit Roy');
    expect(body(puts().last)['records'], [
      {'labour_id': '12', 'present': true, 'wage': '520.5'},
    ]);
    expect(find.text('₹520.50 / day'), findsOneWidget, reason: 'saved wage');
    expect(pencilEnabled(tester, 'Asit Roy'), isFalse);
    expect(
      tester.widget<IconButton>(resetOf('Asit Roy')).onPressed,
      isNull,
      reason: '↺ off while present, like ✏',
    );

    // Absent again: the wage stays 520.50 while the list is open
    await flip(tester, 'Asit Roy');
    expect(body(puts().last)['records'], [
      {'labour_id': '12', 'present': false},
    ]);
    expect(find.text('₹520.50 / day'), findsOneWidget);
    expect(pencilEnabled(tester, 'Asit Roy'), isTrue);

    // ↺ goes back to the usual wage and disappears
    await tester.tap(resetOf('Asit Roy'));
    await tester.pumpAndSettle();
    expect(find.text('₹450 / day'), findsNWidgets(2));
    expect(resetOf('Asit Roy'), findsNothing);
  });

  testWidgets('✏ cancel keeps the wage; the usual wage again sends no wage', (
    tester,
  ) async {
    await openAttendance(tester);
    await tester.tap(pencilOf('Asit Roy'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(find.textContaining('edited'), findsNothing);

    await tester.tap(pencilOf('Asit Roy'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '450');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.textContaining('edited'), findsNothing);
    await flip(tester, 'Asit Roy');
    expect(body(puts().last)['records'], [
      {'labour_id': '12', 'present': true},
    ]);
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

  testWidgets('20 a page: more load near the end; counts cover the day', (
    tester,
  ) async {
    // 45 labours "Worker 01" … "Worker 45" (by name, like the API).
    final many = {
      for (var i = 1; i <= 45; i++)
        'w$i': 'Worker ${i.toString().padLeft(2, '0')}',
    };
    await openAttendance(
      tester,
      names: many,
      presentToday: {'w1', 'w2', 'w44'},
    );

    List<int> pages() => [
      for (final r in api.requests)
        if (r.method == 'GET' && r.path == '/attendance')
          r.queryParameters['page'] as int,
    ];
    expect(lastGet().queryParameters['limit'], 20);
    expect(pages().last, 1);
    // The count line counts every labour of the day, not the 20 shown.
    expect(find.text('3 present · 42 absent'), findsOneWidget);
    expect(find.text('Worker 20'), findsOneWidget);
    expect(find.text('Worker 21'), findsNothing);

    // Scroll to the end: pages 2 and 3 load, up to Worker 45.
    for (var i = 0; i < 30 && find.text('Worker 45').evaluate().isEmpty; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -600));
      await tester.pumpAndSettle();
    }
    expect(find.text('Worker 45'), findsOneWidget);
    expect(pages(), containsAllInOrder([1, 2, 3]));
    expect(find.byKey(const Key('attendanceMore')), findsNothing);
    expect(isOn(tester, 'Worker 44'), isTrue);

    // A switch on page 3 saves and updates the day's count.
    await flip(tester, 'Worker 45');
    expect(body(puts().last)['records'], [
      {'labour_id': 'w45', 'present': true},
    ]);
    expect(find.text('4 present · 41 absent'), findsOneWidget);
  });

  testWidgets('pull to refresh loads the day again (few rows too)', (
    tester,
  ) async {
    await openAttendance(tester);
    final before = api.requests
        .where((r) => r.method == 'GET' && r.path == '/attendance')
        .length;
    // Someone else marks Asit present; a pull shows it.
    api.present['2026-11-09'] = {...?api.present['2026-11-09'], '12'};
    await tester.fling(find.text('Abdul Karim'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    final after = api.requests
        .where((r) => r.method == 'GET' && r.path == '/attendance')
        .length;
    expect(after, before + 1);
    expect(lastGet().queryParameters['date'], '2026-11-09');
    expect(isOn(tester, 'Asit Roy'), isTrue);
  });

  testWidgets('search filters the names', (tester) async {
    await openAttendance(tester);
    await tester.enterText(find.byType(TextField), 'kart');
    // The search runs on the server a moment after typing stops.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(lastGet().queryParameters['search'], 'kart');
    expect(find.text('Kartik Mondal'), findsOneWidget);
    expect(find.text('Asit Roy'), findsNothing);
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump(const Duration(milliseconds: 400));
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

  testWidgets('leaving Attendance and coming back opens today again', (
    tester,
  ) async {
    await openAttendance(tester);
    await tester.tap(find.byTooltip('Previous'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Previous'));
    await tester.pumpAndSettle();
    expect(find.text('07 Nov 2026'), findsOneWidget);

    // Another section, then back (bottom navigation).
    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Attendance').last);
    await tester.pumpAndSettle();
    // (Today's list comes from the 60 s cache: no new request needed.)
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
