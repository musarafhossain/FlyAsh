import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flyash/app.dart';
import 'package:flyash/core/router/app_router.dart';
import 'package:flyash/core/widgets/cards.dart';
import 'package:flyash/core/widgets/data_table_card.dart';

import '../fake_api.dart';
import '../helpers.dart';

Map<String, Object?> body(RequestOptions o) =>
    (o.data is String ? jsonDecode(o.data as String) : o.data)
        as Map<String, Object?>;

/// In-memory expenses (07-API §13). The category is plain text.
class FakeExpenses {
  final requests = <RequestOptions>[];
  int _next = 100;

  late final expenses = <Map<String, Object?>>[
    _e(55, 'Labour Tiffin', '2026-11-08', '850.00', 'Tiffin for 15 labours'),
    _e(54, 'Machine Repair', '2026-11-05', '2300.00', 'Belt changed'),
    _e(40, 'Labour Tiffin', '2026-10-20', '600.00', null),
  ];

  Map<String, Object?> _e(
    int id,
    String category,
    String date,
    String amount,
    String? note,
  ) => {
    'id': id,
    'category': category,
    'expense_date': date,
    'amount': amount,
    'note': note,
    'created_by': {'id': 1, 'name': 'Test Owner'},
  };

  Reply _ok(Object? d, [String m = 'ok', int c = 200]) =>
      (c, envelope(c, m, d), {});

  FakeRoutes get routes => {
    'GET /expenses': (o) {
      final q = o.queryParameters;
      final search = (q['search'] as String? ?? '').toLowerCase();
      bool inRange(String d) =>
          (q['from'] == null || d.compareTo(q['from'] as String) >= 0) &&
          (q['to'] == null || d.compareTo(q['to'] as String) <= 0);
      final items = [
        for (final e in expenses)
          if (inRange(e['expense_date']! as String) &&
              (q['category'] == null || e['category'] == q['category']) &&
              (search.isEmpty ||
                  '${e['note'] ?? ''} ${e['category']}'.toLowerCase().contains(
                    search,
                  )))
            e,
      ];
      final total = items.fold(
        Decimal.zero,
        (s, e) => s + Decimal.parse('${e['amount']}'),
      );
      return _ok({
        'items': items,
        'page': 1,
        'limit': 20,
        'total': items.length,
        'last_page': 1,
        'period_total': total.toStringAsFixed(2),
      });
    },
    'POST /expenses': (o) {
      final b = body(o);
      final e = _e(
        _next++,
        b['category']! as String,
        b['expense_date']! as String,
        Decimal.parse('${b['amount']}').toStringAsFixed(2),
        b['note'] as String?,
      );
      expenses.insert(0, e);
      return _ok(e, 'Expense added', 201);
    },
    for (final id in [55, 54, 40]) ...{
      'GET /expenses/$id': (_) =>
          _ok(expenses.firstWhere((e) => e['id'] == id)),
      'PUT /expenses/$id': (o) {
        final b = body(o);
        final i = expenses.indexWhere((e) => e['id'] == id);
        expenses[i] = _e(
          id,
          b['category']! as String,
          b['expense_date']! as String,
          Decimal.parse('${b['amount']}').toStringAsFixed(2),
          b['note'] as String?,
        );
        return _ok(expenses[i], 'Expense updated');
      },
      'DELETE /expenses/$id': (_) {
        expenses.removeWhere((e) => e['id'] == id);
        return _ok(null, 'Expense deleted');
      },
    },
    'GET /expense-categories': (_) =>
        _ok(['Labour Tiffin', 'Machine Repair', 'Diesel / Fuel', 'Transport']),
  };
}

late FakeExpenses api;

Future<void> openAt(
  WidgetTester tester,
  String location, {
  Size size = const Size(400, 900),
}) async {
  api = FakeExpenses();
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

RequestOptions lastList() =>
    api.requests.lastWhere((r) => r.method == 'GET' && r.path == '/expenses');
RequestOptions last(String method, String path) =>
    api.requests.lastWhere((r) => r.method == method && r.path == path);

/// Labels in the open row menu (long press), top to bottom.
List<String> rowMenu(WidgetTester tester) => [
  for (final e
      in find
          .descendant(
            of: find.byWidgetPredicate((w) => w is PopupMenuItem),
            matching: find.byType(Text),
          )
          .evaluate())
    (e.widget as Text).data ?? '',
];

Future<void> tapMenu(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(
      of: find.byWidgetPredicate((w) => w is PopupMenuItem),
      matching: find.text(label),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> longPress(WidgetTester tester, String text) async {
  await tester.longPress(find.text(text).first);
  await tester.pumpAndSettle();
}

/// A chip inside the open filter sheet.
Finder sheetChip(String label) => find.descendant(
  of: find.byType(BottomSheet),
  matching: find.widgetWithText(ChoiceChip, label),
);

void main() {
  testWidgets('long press: Edit | Delete; Delete asks and removes the row', (
    tester,
  ) async {
    await openAt(tester, '/expenses');
    await longPress(tester, 'Tiffin for 15 labours');
    expect(rowMenu(tester), ['Edit', 'Delete']);
    await tapMenu(tester, 'Delete');
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Expense deleted'), findsOneWidget);
    expect(find.text('Tiffin for 15 labours'), findsNothing);
  });

  testWidgets('this month by default: search with a filter button, no chips '
      'rows above, light total card, rows', (tester) async {
    await openAt(tester, '/expenses');
    final q = lastList().queryParameters;
    expect(q['from'], '2026-11-01');
    expect(q['to'], '2026-11-09'); // this month so far
    expect(find.text('Spent: This month'), findsOneWidget);
    expect(find.text('₹3,150'), findsOneWidget);
    expect(find.byType(HeroCard), findsOneWidget);
    expect(find.byTooltip('Filter expenses'), findsOneWidget);
    // Period and category chips are in the filter sheet now
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.byType(InputChip), findsNothing);
    expect(find.text('Tiffin for 15 labours'), findsOneWidget);
    expect(find.text('08 Nov 2026 · Labour Tiffin'), findsOneWidget);
  });

  testWidgets('filter sheet: period + category ask the server and show as '
      'removable chips', (tester) async {
    await openAt(tester, '/expenses');
    await tester.tap(find.byTooltip('Filter expenses'));
    await tester.pumpAndSettle();
    expect(find.text('Filter expenses'), findsWidgets);
    await tester.tap(sheetChip('Last month'));
    await tester.tap(sheetChip('Labour Tiffin'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
    await tester.pumpAndSettle();

    final q = lastList().queryParameters;
    expect(q['from'], '2026-10-01');
    expect(q['to'], '2026-10-31');
    expect(q['category'], 'Labour Tiffin');
    expect(find.text('Spent: Last month'), findsOneWidget);
    expect(find.widgetWithText(InputChip, 'Last month'), findsOneWidget);
    expect(find.widgetWithText(InputChip, 'Labour Tiffin'), findsOneWidget);
    expect(find.text('₹600'), findsWidgets);

    // Removing a chip clears that filter
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(InputChip, 'Labour Tiffin'),
        matching: find.byIcon(Icons.clear),
      ),
    );
    await tester.pumpAndSettle();
    expect(lastList().queryParameters.containsKey('category'), isFalse);

    // Reset → back to this month
    await tester.tap(find.byTooltip('Filter expenses'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Reset'));
    await tester.pumpAndSettle();
    expect(lastList().queryParameters['from'], '2026-11-01');
    expect(find.byType(InputChip), findsNothing);

    await tester.enterText(find.byType(TextField), 'belt');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(lastList().queryParameters['search'], 'belt');
  });

  testWidgets('desktop: a table with the category text', (tester) async {
    await openAt(tester, '/expenses', size: const Size(1440, 900));
    expect(find.byType(DataTableCard), findsOneWidget);
    expect(find.text('Machine Repair'), findsOneWidget);
  });

  testWidgets('add: any category text (or a suggestion chip), amount > 0, '
      'saved, list refreshed', (tester) async {
    await openAt(tester, '/expenses');
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(currentPath(), '/expenses/new');

    await tapVisible(tester, find.widgetWithText(FilledButton, 'Add expense'));
    expect(
      find.text('This field is required'),
      findsNWidgets(2),
    ); // category, amount

    // Suggestions as chips; they follow what is typed
    expect(find.widgetWithText(ActionChip, 'Labour Tiffin'), findsOneWidget);
    final category = find.widgetWithText(TextFormField, 'Category');
    await tester.enterText(category, 'die');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ActionChip, 'Diesel / Fuel'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'Labour Tiffin'), findsNothing);
    await tester.tap(find.widgetWithText(ActionChip, 'Diesel / Fuel'));
    await tester.pumpAndSettle();
    expect(find.text('Diesel / Fuel'), findsOneWidget, reason: 'in the field');

    // …or any new text
    await tester.enterText(category, '  Generator   rent ');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Amount'),
      '1500',
    );
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Add expense'));
    expect(body(last('POST', '/expenses')), {
      'category': 'Generator rent',
      'expense_date': '2026-11-09',
      'amount': '1500',
      'note': null,
    });
    expect(currentPath(), '/expenses');
    expect(find.text('Expense added'), findsOneWidget);
    expect(find.text('Generator rent'), findsOneWidget, reason: 'reloaded');
  });

  testWidgets('edit then delete from the form', (tester) async {
    await openAt(tester, '/expenses');
    await tester.tap(find.text('Belt changed'));
    await tester.pumpAndSettle();
    expect(currentPath(), '/expenses/54/edit');
    expect(find.text('Machine Repair'), findsOneWidget, reason: 'prefilled');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Amount'),
      '2400',
    );
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Save'));
    expect(body(last('PUT', '/expenses/54'))['category'], 'Machine Repair');
    expect(find.text('Expense updated'), findsOneWidget);
    expect(find.text('₹2,400'), findsOneWidget);

    await tester.tap(find.text('Belt changed'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Belt changed'), findsNothing);
  });

  testWidgets('/expenses/:id opens the edit form', (tester) async {
    await openAt(tester, '/expenses/55');
    expect(currentPath(), '/expenses/55/edit');
  });

  for (final size in const [Size(360, 800), Size(800, 1000), Size(1440, 900)]) {
    for (final dark in [false, true]) {
      testWidgets('no overflow at ${size.width.toInt()} px '
          '(${dark ? 'dark' : 'light'}, Bengali)', (tester) async {
        api = FakeExpenses();
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
        for (final location in ['/expenses', '/expenses/new']) {
          testContainer.read(routerProvider).go(location);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: location);
        }
        testContainer.read(routerProvider).go('/expenses');
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.tune));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'filter sheet');
      });
    }
  }
}
