import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flyash/app.dart';
import 'package:flyash/core/l10n/locale_controller.dart';
import 'package:flyash/core/router/app_router.dart';

import '../fake_api.dart';
import '../helpers.dart';

Map<String, Object?> body(RequestOptions o) =>
    (o.data is String ? jsonDecode(o.data as String) : o.data)
        as Map<String, Object?>;

String m(Decimal d) => d.toStringAsFixed(2);
Decimal d(Object? v) => Decimal.parse('${v ?? 0}');

final products = [
  {
    'id': 1,
    'name': 'Fly Ash Brick 9×4×3',
    'unit': 'piece',
    'unit_label': null,
    'default_cost': '4.20',
    'default_price': '6.50',
    'margin': '2.30',
    'is_active': true,
  },
  {
    'id': 3,
    'name': 'Hollow Block 16×8×8',
    'unit': 'piece',
    'unit_label': null,
    'default_cost': '28.00',
    'default_price': '45.00',
    'margin': '17.00',
    'is_active': true,
  },
];

final customers = [
  {
    'id': 1,
    'name': 'Rahim Biswas Traders',
    'phone': '9830000000',
    'address': 'Basirhat',
    'is_active': true,
    'total_sales': '0.00',
    'total_paid': '0.00',
    'total_due': '0.00',
  },
  {
    'id': 2,
    'name': 'Habib Enterprise',
    'phone': '9774686411',
    'address': null,
    'is_active': true,
    'total_sales': '0.00',
    'total_paid': '0.00',
    'total_due': '0.00',
  },
];

/// In-memory sales backend: computes totals like the server (subtotal,
/// total = subtotal + transport − discount, profit = total − cost, due).
class FakeSalesBackend {
  FakeSalesBackend() {
    sales[104] = _build(
      id: 104,
      type: 'instant',
      customerId: 1,
      saleDate: '2026-11-08',
      items: [
        {
          'product_id': '1',
          'quantity': '5000',
          'unit_cost': '4.2',
          'unit_price': '6.5',
        },
      ],
      transport: '1500',
      discount: '500',
      payments: [
        {
          'id': 90,
          'amount': '10000.00',
          'payment_date': '2026-11-08',
          'method': 'upi',
        },
      ],
    );
    sales[105] = _build(
      id: 105,
      type: 'booking',
      customerId: 2,
      saleDate: '2026-11-08',
      deliveryDate: '2026-11-15',
      items: [
        {
          'product_id': 1,
          'quantity': '3000',
          'unit_cost': '4.2',
          'unit_price': '6.5',
        },
      ],
    );
  }

  final Map<int, Map<String, Object?>> sales = {};
  final requests = <RequestOptions>[];
  int _nextId = 200;
  int _nextPayment = 500;

  Map<String, Object?> _build({
    required int id,
    required String type,
    required int customerId,
    required String saleDate,
    String? deliveryDate,
    String? deliveryAddress,
    required List<Map<String, Object?>> items,
    String transport = '0',
    String discount = '0',
    List<Map<String, Object?>> payments = const [],
    String? status,
    String? notes,
  }) {
    final c = customers.firstWhere((c) => c['id'] == customerId);
    var subtotal = Decimal.zero;
    var cost = Decimal.zero;
    final lines = [
      for (final i in items)
        () {
          final p = products.firstWhere(
            (p) => '${p['id']}' == '${i['product_id']}',
          );
          final q = d(i['quantity']);
          final lineTotal = q * d(i['unit_price']);
          final lineCost = q * d(i['unit_cost']);
          subtotal += lineTotal;
          cost += lineCost;
          return {
            'product_id': p['id'],
            'product_name': p['name'],
            'unit': p['unit'],
            'quantity': m(q),
            'unit_cost': m(d(i['unit_cost'])),
            'unit_price': m(d(i['unit_price'])),
            'line_cost': m(lineCost),
            'line_total': m(lineTotal),
          };
        }(),
    ];
    final total = subtotal + d(transport) - d(discount);
    final paid = payments.fold(Decimal.zero, (s, p) => s + d(p['amount']));
    final due = total - paid;
    final st = status ?? (type == 'booking' ? 'booked' : 'delivered');
    return {
      'id': id,
      'invoice_no': 'INV-${id.toString().padLeft(6, '0')}',
      'type': type,
      'status': st,
      'customer_id': customerId,
      'sale_date': saleDate,
      'delivery_date': deliveryDate,
      'delivered_date': st == 'delivered' ? saleDate : null,
      'delivery_address': deliveryAddress,
      'subtotal': m(subtotal),
      'transport_charge': m(d(transport)),
      'discount': m(d(discount)),
      'total': m(total),
      'total_cost': m(cost),
      'profit': m(total - cost),
      'paid_amount': m(paid),
      'due_amount': m(due),
      'payment_status': paid == Decimal.zero
          ? 'due'
          : (due == Decimal.zero ? 'paid' : 'partial'),
      'notes': notes,
      'customer': {...c},
      'items': lines,
      'payments': [
        for (final p in payments)
          {
            ...p,
            'created_by': {'id': 1, 'name': 'Test Owner'},
          },
      ],
      // kept to rebuild after edits
      '_items': items,
      '_transport': transport,
      '_discount': discount,
      '_payments': payments,
    };
  }

  Map<String, Object?> _rebuild(
    Map<String, Object?> s, {
    List<Map<String, Object?>>? items,
    String? transport,
    String? discount,
    List<Map<String, Object?>>? payments,
    String? status,
    String? saleDate,
    String? deliveryDate,
    String? notes,
  }) => _build(
    id: s['id']! as int,
    type: s['type']! as String,
    customerId: s['customer_id']! as int,
    saleDate: saleDate ?? s['sale_date']! as String,
    deliveryDate: deliveryDate ?? s['delivery_date'] as String?,
    deliveryAddress: s['delivery_address'] as String?,
    items: items ?? (s['_items']! as List).cast(),
    transport: transport ?? s['_transport']! as String,
    discount: discount ?? s['_discount']! as String,
    payments: payments ?? (s['_payments']! as List).cast(),
    status: status ?? s['status'] as String?,
    notes: notes ?? s['notes'] as String?,
  );

  Reply _ok(Object? data, [String message = 'ok', int code = 200]) =>
      (code, envelope(code, message, data), {});
  Reply _bad(String message) => (400, envelope(400, message, null), {});
  Reply _page(List<Object?> items) => _ok({
    'items': items,
    'page': 1,
    'limit': 20,
    'total': items.length,
    'last_page': 1,
  });

  Reply _create(RequestOptions o) {
    final b = body(o);
    var customerId = int.tryParse('${b['customer_id']}');
    final nc = b['new_customer'] as Map<String, Object?>?;
    if (nc != null) {
      final existing = customers.where((c) => c['phone'] == nc['phone']);
      if (existing.isNotEmpty) {
        return (
          422,
          envelope(422, 'Validation failed', {
            'errors': [
              {
                'field': 'new_customer.phone',
                'message': 'This phone belongs to ${existing.first['name']}',
              },
            ],
            'existing_customer_id': existing.first['id'],
          }),
          {},
        );
      }
      customerId = 60;
      customers.add({
        'id': 60,
        ...nc,
        'is_active': true,
        'total_sales': '0.00',
        'total_paid': '0.00',
        'total_due': '0.00',
      });
    }
    final payment = b['payment'] as Map<String, Object?>?;
    final id = _nextId++;
    final sale = _build(
      id: id,
      type: b['type']! as String,
      customerId: customerId!,
      saleDate: b['sale_date']! as String,
      deliveryDate: b['delivery_date'] as String?,
      deliveryAddress: b['delivery_address'] as String?,
      items: (b['items']! as List).cast(),
      transport: '${b['transport_charge'] ?? '0'}',
      discount: '${b['discount'] ?? '0'}',
      payments: [
        if (payment != null)
          {
            'id': _nextPayment++,
            'amount': m(d(payment['amount'])),
            'payment_date': b['sale_date'],
            'method': payment['method'] ?? 'cash',
            'note': payment['note'],
          },
      ],
      notes: b['notes'] as String?,
    );
    sales[id] = sale;
    return _ok(sale, 'Sale saved successfully', 201);
  }

  FakeRoutes get routes => {
    'GET /products': (_) => _page(products),
    'GET /customers': (_) => _page(customers),
    for (final c in [1, 2, 60])
      'GET /customers/$c': (_) => _ok(
        customers.firstWhere(
          (x) => x['id'] == c,
          orElse: () => customers.first,
        ),
      ),
    'GET /customers/1/sales': (_) => _page(const []),
    'GET /sales': (_) => _page(sales.values.toList()),
    'POST /sales': _create,
    'GET /sales/upcoming-deliveries': (_) => _page([
      for (final s in sales.values)
        if (s['status'] == 'booked') {...s, 'is_overdue': false},
    ]),
    for (final id in [104, 105, 200, 201]) ...{
      'GET /sales/$id': (_) => sales[id] == null
          ? (404, envelope(404, 'Record not found', null), {})
          : _ok(sales[id]),
      'PUT /sales/$id': (o) {
        final b = body(o);
        final s = sales[id]!;
        final next = _rebuild(
          s,
          items: (b['items']! as List).cast(),
          transport: '${b['transport_charge']}',
          discount: '${b['discount']}',
          saleDate: b['sale_date'] as String?,
          notes: b['notes'] as String?,
        );
        if (d(next['total']) < d(s['paid_amount'])) {
          return _bad(
            'Payments (₹${s['paid_amount']}) cannot be more than the total (₹${next['total']})',
          );
        }
        sales[id] = next;
        return _ok(next, 'Sale updated successfully');
      },
      'DELETE /sales/$id': (_) {
        sales.remove(id);
        return _ok(null, 'Sale deleted successfully');
      },
      'POST /sales/$id/payments': (o) {
        final b = body(o);
        final s = sales[id]!;
        final next = _rebuild(
          s,
          payments: [
            ...(s['_payments']! as List).cast<Map<String, Object?>>(),
            {
              'id': _nextPayment++,
              'amount': m(d(b['amount'])),
              'payment_date': b['payment_date'],
              'method': b['method'],
              'note': b['note'],
            },
          ],
        );
        sales[id] = next;
        return _ok(next, 'Payment added');
      },
      'POST /sales/$id/deliver': (o) {
        final s = sales[id]!;
        final next = _rebuild(s, status: 'delivered')
          ..['delivered_date'] = body(o)['delivered_date'];
        sales[id] = next;
        return _ok(next, 'Marked as delivered');
      },
      'POST /sales/$id/cancel': (_) {
        final s = sales[id]!;
        if ((s['_payments']! as List).isNotEmpty) {
          return _bad(
            'This booking has payments. Remove them first (refund), then cancel',
          );
        }
        final next = _rebuild(s, status: 'cancelled');
        sales[id] = next;
        return _ok(next, 'Booking cancelled');
      },
      for (final pid in [90, 500, 501])
        'DELETE /sales/$id/payments/$pid': (_) {
          final s = sales[id]!;
          final next = _rebuild(
            s,
            payments: [
              for (final p
                  in (s['_payments']! as List).cast<Map<String, Object?>>())
                if (p['id'] != pid) p,
            ],
          );
          sales[id] = next;
          return _ok(next, 'Payment removed');
        },
    },
  };
}

late FakeSalesBackend backend;

Future<void> openAt(
  WidgetTester tester,
  String location, {
  Size size = const Size(400, 900),
}) async {
  backend = FakeSalesBackend();
  setScreenSize(tester, size);
  await tester.pumpWidget(
    await testApp(
      const FlyAshApp(),
      prefs: {'business.date': '2026-11-09'},
      token: 'oat_saved',
      api: signedInRoutes(backend.routes),
      requests: backend.requests,
    ),
  );
  await tester.pumpAndSettle();
  testContainer.read(routerProvider).go(location);
  await tester.pumpAndSettle();
}

/// Switches the running app to Bengali.
Future<void> testerSetBengali(WidgetTester tester) async {
  await testContainer.read(localeProvider.notifier).setLocale('bn');
  await tester.pumpAndSettle();
}

String currentPath() =>
    testContainer.read(routerProvider).routeInformationProvider.value.uri.path;

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder field(String label) => find.widgetWithText(TextFormField, label);
Finder saveButton(String label) => find.descendant(
  of: find.byType(BottomAppBar).evaluate().isEmpty
      ? find.byType(Scaffold).last
      : find.byType(BottomAppBar),
  matching: find.widgetWithText(FilledButton, label),
);

Future<void> pickCustomer(WidgetTester tester, String name) async {
  await tapVisible(tester, find.byIcon(Icons.person_search_outlined));
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
}

Future<void> pickProduct(
  WidgetTester tester,
  String name, {
  int index = 0,
}) async {
  await tapVisible(tester, find.byIcon(Icons.view_module_outlined).at(index));
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
}

RequestOptions last(String method, String path) =>
    backend.requests.lastWhere((r) => r.method == method && r.path == path);

void main() {
  testWidgets('New sale from the list: checks, live totals, saves strings, '
      'back to the list with the new sale', (tester) async {
    await openAt(tester, '/sales');
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(currentPath(), '/sales/new');
    expect(find.text('New sale'), findsWidgets);

    // Nothing chosen yet
    await tester.tap(find.widgetWithText(FilledButton, 'Save sale'));
    await tester.pumpAndSettle();
    expect(find.text('Select a customer or add a new one'), findsOneWidget);
    expect(find.text('Select a product'), findsOneWidget);
    expect(backend.requests.where((r) => r.method == 'POST'), isEmpty);

    await pickCustomer(tester, 'Rahim Biswas Traders');
    expect(find.text('Rahim Biswas Traders · 9830000000'), findsOneWidget);

    await pickProduct(tester, 'Fly Ash Brick 9×4×3');
    expect(find.text('6.5'), findsOneWidget); // price filled
    expect(find.text('4.2'), findsOneWidget); // cost filled

    await tester.enterText(field('Quantity'), '5000');
    await tester.pumpAndSettle();
    expect(find.text('₹32,500.00'), findsWidgets); // line total
    await tester.enterText(field('Transport'), '1500');
    await tester.enterText(field('Discount'), '500');
    await tester.pumpAndSettle();
    // Summary bar: total 33,500 · profit 33,500 − 21,000 · due
    expect(find.text('₹33,500'), findsWidgets);
    expect(find.text('₹12,500'), findsOneWidget);

    // Payment more than the total
    await tester.enterText(field('Amount (optional)'), '40000');
    await tester.tap(find.widgetWithText(FilledButton, 'Save sale'));
    await tester.pumpAndSettle();
    expect(find.text('Cannot be more than total ₹33,500.00'), findsOneWidget);

    await tester.enterText(field('Amount (optional)'), '10000');
    await tester.tap(find.widgetWithText(ChoiceChip, 'UPI'));
    await tester.pumpAndSettle();
    expect(find.text('₹23,500'), findsOneWidget); // due

    await tester.tap(find.widgetWithText(FilledButton, 'Save sale'));
    await tester.pumpAndSettle();
    expect(body(last('POST', '/sales')), {
      'type': 'instant',
      'customer_id': '1',
      'sale_date': '2026-11-09',
      'delivery_address': null,
      'items': [
        {
          'product_id': '1',
          'quantity': '5000',
          'unit_cost': '4.2',
          'unit_price': '6.5',
        },
      ],
      'transport_charge': '1500',
      'discount': '500',
      'payment': {'amount': '10000', 'method': 'upi', 'note': null},
      'notes': null,
    });
    expect(currentPath(), '/sales');
    expect(find.text('Sale saved successfully'), findsOneWidget);
    expect(
      find.textContaining('INV-000200'),
      findsOneWidget,
      reason: 'reloaded',
    );
    expect(testContainer.read(routerProvider).canPop(), isFalse);
  });

  testWidgets('Booking: delivery date and address, advance; two items, one '
      'removed', (tester) async {
    await openAt(tester, '/sales/new?type=booking');
    expect(find.text('New booking'), findsOneWidget);
    expect(find.text('Advance received'), findsOneWidget);
    expect(find.text('Delivery date'), findsOneWidget);

    await pickCustomer(tester, 'Habib Enterprise');
    await pickProduct(tester, 'Fly Ash Brick 9×4×3');
    await tester.enterText(field('Quantity'), '3000');

    await tapVisible(tester, find.text('Add item'));
    await pickProduct(tester, 'Hollow Block 16×8×8', index: 0);
    expect(find.text('Items (2)'), findsOneWidget);
    // remove the second card
    await tapVisible(tester, find.byTooltip('Remove item').last);
    expect(find.text('Items (1)'), findsOneWidget);

    await tester.enterText(field('Delivery address (optional)'), 'Bongaon');
    await tester.enterText(field('Amount (optional)'), '5000');
    await tester.tap(find.widgetWithText(FilledButton, 'Save sale'));
    await tester.pumpAndSettle();

    final b = body(last('POST', '/sales'));
    expect(b['type'], 'booking');
    expect(b['delivery_date'], '2026-11-09'); // defaults to the sale date
    expect(b['delivery_address'], 'Bongaon');
    expect((b['payment']! as Map)['amount'], '5000');
    expect((b['items']! as List).length, 1);
    // Opened on its own (/sales/new): saved → the sales list
    expect(currentPath(), '/sales');
    expect(find.textContaining('INV-000200'), findsOneWidget);
  });

  testWidgets('Inline new customer; a taken phone offers "Use this customer"', (
    tester,
  ) async {
    await openAt(tester, '/sales/new');
    await tapVisible(tester, find.byIcon(Icons.person_search_outlined));
    await tester.tap(find.text('New customer'));
    await tester.pumpAndSettle();

    await tester.enterText(field('Name'), 'Someone');
    await tester.enterText(field('Phone'), '9774686411');
    await pickProduct(tester, 'Fly Ash Brick 9×4×3');
    await tester.enterText(field('Quantity'), '10');
    await tester.tap(find.widgetWithText(FilledButton, 'Save sale'));
    await tester.pumpAndSettle();
    expect(find.text('This phone belongs to Habib Enterprise'), findsOneWidget);

    await tapVisible(tester, find.text('Use this customer'));
    expect(find.text('Habib Enterprise · 9774686411'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Save sale'));
    await tester.pumpAndSettle();
    expect(body(last('POST', '/sales'))['customer_id'], '2');
    expect(currentPath(), '/sales');
  });

  testWidgets('Leaving with changes asks first; untouched form leaves', (
    tester,
  ) async {
    await openAt(tester, '/sales');
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(currentPath(), '/sales', reason: 'nothing typed → no question');

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.ensureVisible(field('e.g. Deliver before noon'));
    await tester.pumpAndSettle();
    await tester.enterText(field('e.g. Deliver before noon'), 'x');
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Discard this sale?'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Keep editing'));
    await tester.pumpAndSettle();
    expect(currentPath(), '/sales/new');

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Discard'));
    await tester.pumpAndSettle();
    expect(currentPath(), '/sales');
  });

  testWidgets('Customer page "New sale" starts with that customer', (
    tester,
  ) async {
    await openAt(tester, '/customers/1');
    await tapVisible(tester, find.widgetWithText(TextButton, 'New sale'));
    expect(currentPath(), '/sales/new');
    expect(find.text('Rahim Biswas Traders · 9830000000'), findsOneWidget);
  });

  testWidgets('Edit: prefilled, no type/payment, PUT without them; a total '
      'below paid shows the server message', (tester) async {
    await openAt(tester, '/sales/104');
    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();
    expect(currentPath(), '/sales/104/edit');
    expect(find.text('Edit sale'), findsOneWidget);
    expect(find.text('Instant'), findsNothing, reason: 'type is fixed');
    expect(find.text('Payment received now'), findsNothing);
    expect(find.text('5000'), findsOneWidget);
    expect(find.text('Already paid'), findsOneWidget);

    // Too small: total below the ₹10,000 already paid
    await tester.enterText(field('Quantity'), '10');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('cannot be more than the total'),
      findsOneWidget,
    );

    await tester.enterText(field('Quantity'), '6000');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    final b = body(last('PUT', '/sales/104'));
    expect(b.containsKey('type'), isFalse);
    expect(b.containsKey('payment'), isFalse);
    expect((b['items']! as List).single, {
      'product_id': '1',
      'quantity': '6000',
      'unit_cost': '4.2',
      'unit_price': '6.5',
    });
    expect(currentPath(), '/sales/104');
    expect(find.text('Sale updated successfully'), findsOneWidget);
    expect(find.text('₹39,000'), findsOneWidget); // new line total
  });

  for (final size in const [Size(360, 800), Size(800, 1000), Size(1440, 900)]) {
    for (final dark in [false, true]) {
      testWidgets('form: no overflow at ${size.width.toInt()} px '
          '(${dark ? 'dark' : 'light'}, Bengali)', (tester) async {
        backend = FakeSalesBackend();
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
            api: signedInRoutes(backend.routes),
          ),
        );
        await tester.pumpAndSettle();
        for (final path in [
          '/sales/new',
          '/sales/new?type=booking',
          '/sales/104/edit',
        ]) {
          testContainer.read(routerProvider).go(path);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: path);
        }
        // The detail page under /edit loads too; let it finish.
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();
      });
    }
  }
}
