import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flyash/app.dart';
import 'package:flyash/core/router/app_router.dart';
import 'package:flyash/core/widgets/data_table_card.dart';
import 'package:flyash/features/expenses/presentation/pages/expenses_list_page.dart';

import '../fake_api.dart';
import '../helpers.dart';

Map<String, Object?> body(RequestOptions o) =>
    (o.data is String ? jsonDecode(o.data as String) : o.data)
        as Map<String, Object?>;

/// In-memory expenses and categories (07-API §13).
class FakeExpenses {
  final requests = <RequestOptions>[];
  int _next = 100;

  final categories = <Map<String, Object?>>[
    {
      'id': 1,
      'name': 'Labour Tiffin',
      'icon': 'utensils',
      'is_active': true,
      'sort_order': 1,
    },
    {
      'id': 2,
      'name': 'Machine Repair',
      'icon': 'wrench',
      'is_active': true,
      'sort_order': 2,
    },
    {
      'id': 3,
      'name': 'Old Category',
      'icon': null,
      'is_active': false,
      'sort_order': 3,
    },
  ];
  late final expenses = <Map<String, Object?>>[
    _e(55, 1, '2026-11-08', '850.00', 'Tiffin for 15 labours'),
    _e(54, 2, '2026-11-05', '2300.00', 'Belt changed'),
    _e(40, 1, '2026-10-20', '600.00', null),
  ];

  Map<String, Object?> _e(
    int id,
    int cat,
    String date,
    String amount,
    String? note,
  ) {
    final c = categories.firstWhere((x) => x['id'] == cat);
    return {
      'id': id,
      'expense_category_id': cat,
      'expense_date': date,
      'amount': amount,
      'note': note,
      'category': {'id': c['id'], 'name': c['name'], 'icon': c['icon']},
      'created_by': {'id': 1, 'name': 'Test Owner'},
    };
  }

  Reply _ok(Object? d, [String m = 'ok', int c = 200]) =>
      (c, envelope(c, m, d), {});

  Reply _taken() => (
    422,
    envelope(422, 'Validation failed', {
      'errors': [
        {'field': 'name', 'message': 'This name is already taken'},
      ],
    }),
    {},
  );

  FakeRoutes get routes => {
    'GET /expenses': (o) {
      final q = o.queryParameters;
      final search = (q['search'] as String? ?? '').toLowerCase();
      final items = [
        for (final e in expenses)
          if ((q['from'] == null ||
                  (e['expense_date']! as String).compareTo(
                        q['from'] as String,
                      ) >=
                      0) &&
              (q['to'] == null ||
                  (e['expense_date']! as String).compareTo(q['to'] as String) <=
                      0) &&
              (q['category_id'] == null ||
                  '${e['expense_category_id']}' == '${q['category_id']}') &&
              (search.isEmpty ||
                  ((e['note'] as String?) ?? '').toLowerCase().contains(
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
        b['expense_category_id']! as int,
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
          b['expense_category_id']! as int,
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
    'GET /expense-categories': (o) {
      final active = o.queryParameters['active'];
      return _ok([
        for (final c in categories)
          if (active == null || '${c['is_active']}' == '$active') c,
      ]);
    },
    'POST /expense-categories': (o) {
      final b = body(o);
      if (categories.any((c) => c['name'] == b['name'])) return _taken();
      final c = {
        'id': _next++,
        'name': b['name'],
        'icon': b['icon'],
        'is_active': true,
        'sort_order': categories.length + 1,
      };
      categories.add(c);
      return _ok(c, 'Category created', 201);
    },
    for (final id in [1, 2, 3])
      'PUT /expense-categories/$id': (o) {
        final c = categories.firstWhere((x) => x['id'] == id);
        c.addAll(body(o));
        return _ok(c, 'Category updated');
      },
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

void main() {
  testWidgets('this month by default: total, category chips, rows', (
    tester,
  ) async {
    await openAt(tester, '/expenses');
    final q = lastList().queryParameters;
    expect(q['from'], '2026-11-01');
    expect(q['to'], '2026-11-09');
    expect(find.text('Spent: This month'), findsOneWidget);
    expect(find.text('₹3,150'), findsOneWidget); // 850 + 2,300
    expect(find.byType(ExpenseTile), findsNWidgets(2));
    expect(find.text('Tiffin for 15 labours'), findsOneWidget);
    expect(find.text('08 Nov 2026 · Labour Tiffin'), findsOneWidget);
    // Only active categories as chips
    expect(find.widgetWithText(ChoiceChip, 'Machine Repair'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Old Category'), findsNothing);
  });

  testWidgets('period, category and search filters ask the server', (
    tester,
  ) async {
    await openAt(tester, '/expenses');
    await tapVisible(tester, find.widgetWithText(ChoiceChip, 'Last month'));
    expect(lastList().queryParameters['from'], '2026-10-01');
    expect(lastList().queryParameters['to'], '2026-10-31');
    expect(find.text('₹600'), findsWidgets);

    await tapVisible(tester, find.widgetWithText(ChoiceChip, 'This month'));
    await tapVisible(tester, find.widgetWithText(ChoiceChip, 'Machine Repair'));
    expect(lastList().queryParameters['category_id'], 2);
    expect(find.text('₹2,300'), findsWidgets);
    expect(find.byType(ExpenseTile), findsOneWidget);

    await tapVisible(tester, find.widgetWithText(ChoiceChip, 'All'));
    await tester.enterText(find.byType(TextField).last, 'belt');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(lastList().queryParameters['search'], 'belt');
    expect(find.byType(ExpenseTile), findsOneWidget);
  });

  testWidgets('desktop: a table', (tester) async {
    await openAt(tester, '/expenses', size: const Size(1440, 900));
    expect(find.byType(DataTableCard), findsOneWidget);
    expect(find.text('Entered by'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('add: category required, amount > 0, saved, list refreshed', (
    tester,
  ) async {
    await openAt(tester, '/expenses');
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(currentPath(), '/expenses/new');

    await tapVisible(tester, find.widgetWithText(FilledButton, 'Add expense'));
    expect(find.text('Select a category'), findsOneWidget);
    expect(api.requests.where((r) => r.method == 'POST'), isEmpty);

    await tapVisible(tester, find.byIcon(Icons.category_outlined).last);
    await tester.tap(find.text('Machine Repair').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '0');
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Add expense'));
    expect(find.text('Enter an amount, e.g. 4.50'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Amount'),
      '1250.5',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Notes (optional)'),
      'Diesel',
    );
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Add expense'));
    expect(body(last('POST', '/expenses')), {
      'expense_category_id': 2,
      'expense_date': '2026-11-09',
      'amount': '1250.5',
      'note': 'Diesel',
    });
    expect(currentPath(), '/expenses');
    expect(find.text('Expense added'), findsOneWidget);
    expect(find.text('Diesel'), findsOneWidget);
    expect(find.text('₹4,401'), findsOneWidget); // 3,150 + 1,250.50 rounded
  });

  testWidgets('a new category from the picker is chosen right away', (
    tester,
  ) async {
    await openAt(tester, '/expenses/new');
    await tapVisible(tester, find.byIcon(Icons.category_outlined).last);
    await tester.tap(find.widgetWithText(FilledButton, 'New category'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Labour Tiffin',
    );
    await tester.tap(find.bySemanticsLabel('ticket'));
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('This name is already taken'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Gate pass',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(body(last('POST', '/expense-categories')), {
      'name': 'Gate pass',
      'icon': 'ticket',
    });
    expect(find.text('Gate pass'), findsOneWidget); // in the category field
  });

  testWidgets('edit then delete from the form', (tester) async {
    await openAt(tester, '/expenses');
    await tester.tap(find.text('Belt changed'));
    await tester.pumpAndSettle();
    expect(currentPath(), '/expenses/54/edit');
    expect(find.text('2300'), findsOneWidget);
    expect(find.text('05 Nov 2026'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Amount'),
      '2400',
    );
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Save'));
    expect(body(last('PUT', '/expenses/54'))['amount'], '2400');
    expect(find.text('Expense updated'), findsOneWidget);
    expect(find.text('₹2,400'), findsOneWidget);

    await tester.tap(find.text('Belt changed'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this expense?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(last('DELETE', '/expenses/54'), isNotNull);
    expect(currentPath(), '/expenses');
    expect(find.text('Belt changed'), findsNothing);
  });

  testWidgets('/expenses/:id opens the edit form', (tester) async {
    await openAt(tester, '/expenses/55');
    expect(currentPath(), '/expenses/55/edit');
    expect(find.text('Edit expense'), findsOneWidget);
  });

  testWidgets('manage categories: all listed, rename and deactivate', (
    tester,
  ) async {
    await openAt(tester, '/expenses');
    await tapVisible(
      tester,
      find.widgetWithText(ActionChip, 'Manage categories'),
    );
    expect(currentPath(), '/expenses/categories');
    expect(find.text('Old Category'), findsOneWidget);
    expect(find.text('Inactive'), findsOneWidget);

    await tester.tap(find.text('Machine Repair'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Repairs',
    );
    await tester.tap(find.byType(Switch));
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(body(last('PUT', '/expense-categories/2')), {
      'name': 'Repairs',
      'icon': 'wrench',
      'is_active': false,
    });
    expect(find.text('Category updated'), findsOneWidget);
    expect(find.text('Inactive'), findsNWidgets(2));

    // Back on the list the chip is gone
    testContainer.read(routerProvider).pop();
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ChoiceChip, 'Repairs'), findsNothing);
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
        for (final path in [
          '/expenses',
          '/expenses/new',
          '/expenses/55/edit',
          '/expenses/categories',
        ]) {
          testContainer.read(routerProvider).go(path);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: path);
        }
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();
      });
    }
  }
}
