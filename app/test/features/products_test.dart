import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flyash/app.dart';
import 'package:flyash/core/widgets/cards.dart';
import 'package:flyash/core/router/app_router.dart';
import 'package:flyash/core/widgets/data_table_card.dart';
import 'package:flyash/features/products/presentation/pages/products_list_page.dart';

import '../fake_api.dart';
import '../helpers.dart';

Map<String, Object?> body(RequestOptions o) =>
    (o.data is String ? jsonDecode(o.data as String) : o.data)
        as Map<String, Object?>;

Map<String, Object?> product(
  int id,
  String name, {
  String unit = 'piece',
  String? unitLabel,
  String cost = '4.50',
  String price = '7.00',
  bool active = true,
  bool usedInSales = false,
}) => {
  'id': id,
  'name': name,
  'unit': unit,
  'unit_label': unitLabel,
  'default_cost': cost,
  'default_price': price,
  'margin': (double.parse(price) - double.parse(cost)).toStringAsFixed(2),
  'notes': null,
  'is_active': active,
  '_used': usedInSales,
};

/// A small in-memory Products API (07-API §7).
class FakeProducts {
  FakeProducts(this.products);

  final List<Map<String, Object?>> products;
  final requests = <RequestOptions>[];

  Reply _page(RequestOptions o) {
    final search = (o.queryParameters['search'] as String? ?? '').toLowerCase();
    final active = o.queryParameters['active'];
    final items = [
      for (final p in products)
        if ((search.isEmpty ||
                (p['name'] as String).toLowerCase().contains(search)) &&
            (active == null || '${p['is_active']}' == '$active'))
          p,
    ];
    // Real paging: 20 per page.
    final page = int.tryParse('${o.queryParameters['page'] ?? 1}') ?? 1;
    const limit = 20;
    final from = ((page - 1) * limit).clamp(0, items.length);
    final to = (from + limit).clamp(0, items.length);
    return (
      200,
      envelope(200, 'Products fetched successfully', {
        'items': items.sublist(from, to),
        'page': page,
        'limit': limit,
        'total': items.length,
        'last_page': items.isEmpty ? 1 : (items.length / limit).ceil(),
      }),
      {},
    );
  }

  Reply _save(Map<String, Object?> target, Map<String, Object?> b) {
    if (products.any((p) => p['name'] == b['name'] && p != target)) {
      return (
        422,
        envelope(422, 'Validation failed', {
          'errors': [
            {'field': 'name', 'message': 'This name is already taken'},
          ],
        }),
        {},
      );
    }
    final cost = double.parse('${b['default_cost']}');
    final price = double.parse('${b['default_price']}');
    target
      ..addAll(b)
      ..['default_cost'] = cost.toStringAsFixed(2)
      ..['default_price'] = price.toStringAsFixed(2)
      ..['margin'] = (price - cost).toStringAsFixed(2);
    return (200, envelope(200, 'ok', target), {});
  }

  FakeRoutes get routes => {
    'GET /products': _page,
    'POST /products': (o) {
      final created = <String, Object?>{'id': 50, 'is_active': true};
      final reply = _save(created, body(o));
      if (reply.$1 == 200) products.add(created);
      return reply.$1 == 200
          ? (201, envelope(201, 'Product created successfully', created), {})
          : reply;
    },
    for (final p in products) ...{
      'GET /products/${p['id']}': (_) =>
          (200, envelope(200, 'Product fetched successfully', p), {}),
      'PUT /products/${p['id']}': (o) => _save(p, body(o)),
      'PATCH /products/${p['id']}/status': (o) {
        final active = body(o)['is_active']! as bool;
        p['is_active'] = active;
        return (
          200,
          envelope(
            200,
            active ? 'Product activated' : 'Product deactivated',
            p,
          ),
          {},
        );
      },
      'DELETE /products/${p['id']}': (_) {
        if (p['_used'] == true) {
          return (
            409,
            envelope(
              409,
              'Product is used in sales. Deactivate it instead',
              null,
            ),
            {},
          );
        }
        products.remove(p);
        return (200, envelope(200, 'Product deleted successfully', null), {});
      },
    },
  };
}

FakeProducts sampleProducts() => FakeProducts([
  product(1, 'Fly Ash Brick 9×4×3'),
  product(2, 'Red Brick', cost: '6.00', price: '5.50'), // sold at a loss
  product(3, 'Old Brick', active: false, usedInSales: true),
]);

Future<FakeProducts> openProducts(
  WidgetTester tester, {
  Size size = const Size(360, 800),
  FakeProducts? fake,
  String location = '/products',
}) async {
  final api = fake ?? sampleProducts();
  setScreenSize(tester, size);
  await tester.pumpWidget(
    await testApp(
      const FlyAshApp(),
      token: 'oat_saved',
      api: signedInRoutes(api.routes),
      requests: api.requests,
    ),
  );
  await tester.pumpAndSettle();
  testContainer.read(routerProvider).go(location);
  await tester.pumpAndSettle();
  return api;
}

String currentPath() =>
    testContainer.read(routerProvider).routeInformationProvider.value.uri.path;

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('phone: cards with unit, cost → price and margin', (
    tester,
  ) async {
    await openProducts(tester);
    expect(find.byType(ProductTile), findsNWidgets(3));
    expect(find.text('per Piece'), findsNWidgets(3));
    expect(find.text('₹4.50 → ₹7.00'), findsWidgets);
    expect(find.text('+₹2.50'), findsWidgets);
    expect(find.text('−₹0.50'), findsOneWidget, reason: 'loss in red');
    expect(find.text('Inactive'), findsWidgets);
    expect(find.byType(DataTableCard), findsNothing);
  });

  testWidgets('flat list: no card around the rows, no "Showing" line', (
    tester,
  ) async {
    await openProducts(tester);
    expect(
      find.ancestor(
        of: find.byType(ProductTile).first,
        matching: find.byType(AppCard),
      ),
      findsNothing,
    );
    expect(find.textContaining('Showing'), findsNothing);
  });

  testWidgets('endless scroll: the next page loads near the end', (
    tester,
  ) async {
    final api = await openProducts(
      tester,
      fake: FakeProducts([
        for (var i = 1; i <= 45; i++)
          product(i, 'Brick ${i.toString().padLeft(2, '0')}'),
      ]),
    );
    List<String?> pages() => [
      for (final r in api.requests)
        if (r.path == '/products') '${r.queryParameters['page']}',
    ];
    expect(pages(), ['1']);

    await tester.drag(find.byType(ListView).first, const Offset(0, -3000));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -3000));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(pages(), ['1', '2', '3']);
    expect(find.text('Brick 45'), findsOneWidget);
    expect(find.textContaining('Showing'), findsNothing);
  });

  testWidgets('desktop: products are a table', (tester) async {
    await openProducts(tester, size: const Size(1440, 900));
    expect(find.byType(DataTableCard), findsOneWidget);
    expect(find.text('Margin'), findsOneWidget); // column header
    expect(tester.takeException(), isNull);
  });

  testWidgets('filters and search ask the server', (tester) async {
    final api = await openProducts(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Inactive'));
    await tester.pumpAndSettle();
    expect(api.requests.last.queryParameters['active'], 'false');
    expect(find.byType(ProductTile), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'red');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(api.requests.last.queryParameters['search'], 'red');
    expect(find.byType(ProductTile), findsOneWidget);
  });

  testWidgets('empty list explains and offers Add product', (tester) async {
    await openProducts(tester, fake: FakeProducts([]));
    expect(find.text('No products yet'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Add product'));
    await tester.pumpAndSettle();
    expect(currentPath(), '/products/new');
  });

  testWidgets('add: checks the form, live margin, "Other" unit, server '
      'errors, then saves as strings', (tester) async {
    final api = await openProducts(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(currentPath(), '/products/new');

    // Empty form: client rules
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Add product'));
    expect(find.text('This field is required'), findsNWidgets(3));
    expect(api.requests.where((r) => r.method == 'POST'), isEmpty);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Fly Ash Brick 9×4×3'); // taken
    await tester.enterText(fields.at(1), '4.5');
    await tester.enterText(fields.at(2), '7');
    await tester.pumpAndSettle();
    expect(find.text('Margin per unit'), findsOneWidget);
    expect(find.text('₹2.50'), findsOneWidget);

    // A loss is shown in red wording
    await tester.enterText(fields.at(2), '4');
    await tester.pumpAndSettle();
    expect(find.text('Loss per unit'), findsOneWidget);
    await tester.enterText(fields.at(2), '7');

    // Letters cannot be typed into money fields
    await tester.enterText(fields.at(1), '4.5x');
    expect(find.text('4.5x'), findsNothing);

    // "Other" needs a unit name
    await tester.tap(find.widgetWithText(ChoiceChip, 'Other'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Add product'));
    expect(find.text('This field is required'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Unit name'),
      'cft',
    );

    // Server: name taken
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Add product'));
    expect(find.text('This name is already taken'), findsOneWidget);

    await tester.enterText(fields.at(0), 'Hollow Block');
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Add product'));
    final post = api.requests.lastWhere((r) => r.method == 'POST');
    expect(body(post), {
      'name': 'Hollow Block',
      'unit': 'other',
      'unit_label': 'cft',
      'default_cost': '4.5',
      'default_price': '7',
      'notes': null,
    });
    expect(currentPath(), '/products');
    expect(find.text('Product added'), findsOneWidget);
    expect(find.text('Hollow Block'), findsOneWidget);
    expect(find.text('per cft'), findsOneWidget);
  });

  testWidgets('tap a product → edit form filled in → save', (tester) async {
    final api = await openProducts(tester);
    await tester.tap(find.text('Fly Ash Brick 9×4×3'));
    await tester.pumpAndSettle();
    expect(currentPath(), '/products/1/edit');
    expect(find.text('4.5'), findsOneWidget); // "4.50" shown plainly
    expect(find.text('7'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(2), '7.25');
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Save'));
    final put = api.requests.lastWhere((r) => r.method == 'PUT');
    expect(body(put)['default_price'], '7.25');
    expect(currentPath(), '/products');
    expect(find.text('+₹2.75'), findsOneWidget);
  });

  testWidgets('/products/:id opens the edit form', (tester) async {
    await openProducts(tester, location: '/products/2');
    expect(currentPath(), '/products/2/edit');
    expect(find.text('Edit product'), findsOneWidget);
  });

  testWidgets('deactivate asks first, then shows Inactive', (tester) async {
    final api = await openProducts(tester, location: '/products/1/edit');
    await tapVisible(tester, find.text('Deactivate'));
    expect(find.text('Deactivate Fly Ash Brick 9×4×3?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Deactivate'));
    await tester.pumpAndSettle();
    expect(body(api.requests.lastWhere((r) => r.method == 'PATCH')), {
      'is_active': false,
    });
    expect(find.text('Product deactivated'), findsOneWidget);
    expect(find.text('Inactive'), findsOneWidget);
    expect(find.text('Activate'), findsOneWidget);
  });

  testWidgets('delete: used in sales → server message; unused → deleted', (
    tester,
  ) async {
    await openProducts(tester, location: '/products/3/edit');
    await tapVisible(tester, find.text('Delete'));
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(
      find.text('Product is used in sales. Deactivate it instead'),
      findsOneWidget,
    );
    expect(currentPath(), '/products/3/edit', reason: 'stays on the form');

    // Let the message disappear before the next step.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    testContainer.read(routerProvider).go('/products');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Red Brick'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Delete'));
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Product deleted successfully'), findsOneWidget);
    expect(currentPath(), '/products');
    expect(find.text('Red Brick'), findsNothing);
  });

  Finder sheet(String text) => find.descendant(
    of: find.byWidgetPredicate((w) => w is PopupMenuItem),
    matching: find.text(text),
  );
  final menu = find.byWidgetPredicate((w) => w is PopupMenuItem);

  testWidgets('long press opens the menu: Edit | Deactivate | Delete; edit '
      'returns to the list', (tester) async {
    await openProducts(tester);
    await tester.longPress(find.text('Fly Ash Brick 9×4×3'));
    await tester.pumpAndSettle();
    expect(menu, findsNWidgets(3));
    expect(
      find.byType(PopupMenuDivider),
      findsNWidgets(2),
      reason: 'Edit | Deactivate | Delete',
    );
    expect(sheet('Edit'), findsOneWidget);
    expect(sheet('Deactivate'), findsOneWidget);
    expect(sheet('Delete'), findsOneWidget);

    await tester.tap(sheet('Edit'));
    await tester.pumpAndSettle();
    expect(menu, findsNothing);
    expect(currentPath(), '/products/1/edit');

    // Saving an edit opened from the list goes back to the list
    await tester.enterText(
      find.byType(TextFormField).first,
      'Fly Ash Brick 10×4×3',
    );
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Save'));
    expect(currentPath(), '/products');
    expect(find.text('Fly Ash Brick 10×4×3'), findsOneWidget);
  });

  testWidgets('menu: Deactivate asks, saves, and the row shows Inactive', (
    tester,
  ) async {
    final api = await openProducts(tester);
    await tester.longPress(find.text('Red Brick'));
    await tester.pumpAndSettle();
    await tester.tap(sheet('Deactivate'));
    await tester.pumpAndSettle();
    expect(find.text('Deactivate Red Brick?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Deactivate'));
    await tester.pumpAndSettle();
    expect(
      api.requests.lastWhere((r) => r.method == 'PATCH').path,
      '/products/2/status',
    );
    expect(find.text('Product deactivated'), findsOneWidget);
    expect(
      find.text('Inactive'),
      findsNWidgets(3),
      reason: 'filter chip + Red + Old Brick',
    );

    // An inactive product offers Activate
    await tester.longPress(find.text('Red Brick'));
    await tester.pumpAndSettle();
    expect(sheet('Activate'), findsOneWidget);
  });

  testWidgets('menu: Delete; a product used in sales gets the server message', (
    tester,
  ) async {
    await openProducts(tester);
    await tester.longPress(find.text('Old Brick'));
    await tester.pumpAndSettle();
    await tester.tap(sheet('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(
      find.text('Product is used in sales. Deactivate it instead'),
      findsOneWidget,
    );
    expect(find.text('Old Brick'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.longPress(find.text('Red Brick'));
    await tester.pumpAndSettle();
    await tester.tap(sheet('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Product deleted successfully'), findsOneWidget);
    expect(find.text('Red Brick'), findsNothing);
  });

  testWidgets('menu: Cancel in the dialog changes nothing', (tester) async {
    final api = await openProducts(tester);
    await tester.longPress(find.text('Red Brick'));
    await tester.pumpAndSettle();
    await tester.tap(sheet('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(api.requests.where((r) => r.method == 'DELETE'), isEmpty);
    expect(find.text('Red Brick'), findsOneWidget);
  });

  for (final size in const [Size(360, 800), Size(800, 1000), Size(1440, 900)]) {
    for (final dark in [false, true]) {
      testWidgets('no overflow at ${size.width.toInt()} px '
          '(${dark ? 'dark' : 'light'}, Bengali)', (tester) async {
        setScreenSize(tester, size);
        final api = sampleProducts();
        await tester.pumpWidget(
          await testApp(
            const FlyAshApp(),
            prefs: {'app.locale': 'bn'},
            token: 'oat_saved',
            api: signedInRoutes(api.routes),
          ),
        );
        await tester.pumpAndSettle();
        for (final path in ['/products', '/products/new', '/products/1/edit']) {
          testContainer.read(routerProvider).go(path);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: path);
        }
      });
    }
  }
}
