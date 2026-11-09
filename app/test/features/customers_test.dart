import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flyash/app.dart';
import 'package:flyash/core/router/app_router.dart';
import 'package:flyash/core/utils/contact_launcher.dart';
import 'package:flyash/core/widgets/data_table_card.dart';
import 'package:flyash/features/customers/presentation/pages/customer_detail_page.dart';
import 'package:flyash/features/customers/presentation/pages/customers_list_page.dart';

import '../fake_api.dart';
import '../helpers.dart';

Map<String, Object?> body(RequestOptions o) =>
    (o.data is String ? jsonDecode(o.data as String) : o.data)
        as Map<String, Object?>;

Map<String, Object?> customer(
  int id,
  String name,
  String phone, {
  String? address,
  String sales = '0.00',
  String paid = '0.00',
  String due = '0.00',
  bool active = true,
}) => {
  'id': id,
  'name': name,
  'phone': phone,
  'address': address,
  'is_active': active,
  'total_sales': sales,
  'total_paid': paid,
  'total_due': due,
};

Map<String, Object?> sale(
  int id, {
  String status = 'delivered',
  String payment = 'partial',
  String type = 'instant',
  String total = '40500.00',
  String due = '30500.00',
}) => {
  'id': id,
  'invoice_no': 'INV-${id.toString().padLeft(6, '0')}',
  'type': type,
  'status': status,
  'sale_date': '2026-11-08',
  'total': total,
  'paid_amount': '10000.00',
  'due_amount': due,
  'payment_status': payment,
};

/// A small in-memory Customers API (07-API §8).
class FakeCustomers {
  FakeCustomers(this.customers, {this.salesOf = const {}});

  final List<Map<String, Object?>> customers;
  final Map<int, List<Map<String, Object?>>> salesOf;
  final requests = <RequestOptions>[];

  Reply _ok(Object? data, [int status = 200, String message = 'ok']) =>
      (status, envelope(status, message, data), {});

  Reply _page(List<Object?> items) => _ok({
    'items': items,
    'page': 1,
    'limit': 20,
    'total': items.length,
    'last_page': 1,
  });

  Reply _list(RequestOptions o) {
    final q = o.queryParameters;
    final search = (q['search'] as String? ?? '').toLowerCase();
    return _page([
      for (final c in customers)
        if ((search.isEmpty ||
                (c['name'] as String).toLowerCase().contains(search) ||
                (c['phone'] as String).contains(search)) &&
            (q['has_due'] == null || c['total_due'] != '0.00') &&
            (q['active'] == null || '${c['is_active']}' == '${q['active']}'))
          c,
    ]);
  }

  /// Phone taken → 422 with existing_customer_id.
  Reply? _phoneTaken(Map<String, Object?> b, Object? selfId) {
    for (final c in customers) {
      if (c['phone'] == b['phone'] && c['id'] != selfId) {
        return (
          422,
          envelope(422, 'Validation failed', {
            'errors': [
              {
                'field': 'phone',
                'message': 'This phone belongs to ${c['name']}',
              },
            ],
            'existing_customer_id': c['id'],
          }),
          {},
        );
      }
    }
    return null;
  }

  FakeRoutes get routes => {
    'GET /customers': _list,
    'POST /customers': (o) {
      final b = body(o);
      final taken = _phoneTaken(b, null);
      if (taken != null) return taken;
      final created = customer(
        70,
        b['name']! as String,
        b['phone']! as String,
        address: b['address'] as String?,
      );
      customers.add(created);
      return _ok(created, 201, 'Customer created successfully');
    },
    'GET /customers/70': (_) => _ok(customers.firstWhere((c) => c['id'] == 70)),
    'GET /customers/70/sales': (_) => _page(const []),
    for (final c in customers) ...{
      'GET /customers/${c['id']}': (_) => _ok(c),
      'PUT /customers/${c['id']}': (o) {
        final b = body(o);
        final taken = _phoneTaken(b, c['id']);
        if (taken != null) return taken;
        c.addAll(b);
        return _ok(c, 200, 'Customer updated successfully');
      },
      'PATCH /customers/${c['id']}/status': (o) {
        final active = body(o)['is_active']! as bool;
        c['is_active'] = active;
        return _ok(
          c,
          200,
          active ? 'Customer activated' : 'Customer deactivated',
        );
      },
      'DELETE /customers/${c['id']}': (_) {
        if ((salesOf[c['id']] ?? const []).isNotEmpty) {
          return (
            409,
            envelope(409, 'Customer has sales. Deactivate them instead', null),
            {},
          );
        }
        customers.remove(c);
        return _ok(null, 200, 'Customer deleted successfully');
      },
      'GET /customers/${c['id']}/sales': (_) =>
          _page(salesOf[c['id']] ?? const []),
    },
  };
}

FakeCustomers sampleCustomers() => FakeCustomers(
  [
    customer(
      1,
      'Rahim Biswas Traders',
      '9830000000',
      address: 'Basirhat, North 24 Parganas',
      sales: '222000.00',
      paid: '100000.00',
      due: '122000.00',
    ),
    customer(
      2,
      'Habib Enterprise',
      '9774686411',
      sales: '5000.00',
      paid: '5000.00',
    ),
    customer(3, 'Old Shop', '9000000003', active: false),
  ],
  salesOf: {
    1: [
      sale(98),
      sale(97, payment: 'paid', due: '0.00'),
      sale(96, status: 'booked', type: 'booking', payment: 'due'),
      sale(95, status: 'cancelled'),
    ],
  },
);

Future<FakeCustomers> openCustomers(
  WidgetTester tester, {
  Size size = const Size(360, 800),
  FakeCustomers? fake,
  String location = '/customers',
}) async {
  final api = fake ?? sampleCustomers();
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
  late List<Uri> launched;
  setUp(() {
    launched = [];
    ContactLauncher.launch = (uri) async {
      launched.add(uri);
      return true;
    };
  });

  testWidgets('phone: cards with phone, address and the due in red', (
    tester,
  ) async {
    await openCustomers(tester);
    expect(find.byType(CustomerTile), findsNWidgets(3));
    expect(find.text('9830000000'), findsOneWidget);
    expect(find.text('Basirhat, North 24 Parganas'), findsOneWidget);
    expect(find.text('₹1,22,000'), findsOneWidget);
    expect(find.text('No due'), findsNWidgets(2));
    expect(find.text('Inactive'), findsWidgets);
    expect(find.byType(DataTableCard), findsNothing);
  });

  testWidgets('desktop: customers are a table with purchases, paid, due', (
    tester,
  ) async {
    await openCustomers(tester, size: const Size(1440, 900));
    expect(find.byType(DataTableCard), findsOneWidget);
    expect(find.text('₹2,22,000'), findsOneWidget);
    expect(find.text('₹1,00,000'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Has due / Inactive filters and search ask the server', (
    tester,
  ) async {
    final api = await openCustomers(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Has due'));
    await tester.pumpAndSettle();
    expect(api.requests.last.queryParameters['has_due'], 'true');
    expect(find.byType(CustomerTile), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Inactive'));
    await tester.pumpAndSettle();
    expect(api.requests.last.queryParameters['active'], 'false');
    expect(api.requests.last.queryParameters.containsKey('has_due'), isFalse);
    expect(find.text('Old Shop'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '97746');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(api.requests.last.queryParameters['search'], '97746');
    expect(find.text('Habib Enterprise'), findsOneWidget);
  });

  testWidgets('empty list explains and offers Add customer', (tester) async {
    await openCustomers(tester, fake: FakeCustomers([]));
    expect(find.text('No customers yet'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Add customer'));
    await tester.pumpAndSettle();
    expect(currentPath(), '/customers/new');
  });

  testWidgets('add: duplicate phone offers to open that customer', (
    tester,
  ) async {
    await openCustomers(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Someone');
    await tester.enterText(fields.at(1), '9774686411');
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Add customer'));
    expect(find.text('This phone belongs to Habib Enterprise'), findsOneWidget);

    await tester.tap(find.text('Open that customer'));
    await tester.pumpAndSettle();
    expect(currentPath(), '/customers/2');
    expect(find.text('Habib Enterprise'), findsWidgets);
  });

  testWidgets('add: saves and opens the new customer', (tester) async {
    final api = await openCustomers(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(1), '12345');
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Add customer'));
    expect(find.text('This field is required'), findsOneWidget);
    expect(
      find.text('Enter a 10-digit mobile number starting with 6–9'),
      findsOneWidget,
    );

    await tester.enterText(fields.at(0), 'New Brick Buyer');
    await tester.enterText(fields.at(1), '9123456780');
    await tester.enterText(fields.at(2), 'Habra');
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Add customer'));
    expect(body(api.requests.lastWhere((r) => r.method == 'POST')), {
      'name': 'New Brick Buyer',
      'phone': '9123456780',
      'address': 'Habra',
    });
    expect(currentPath(), '/customers/70');
    expect(find.text('Customer added'), findsOneWidget);
    expect(find.text('No sales yet'), findsOneWidget);

    // Back goes to the list (the form was replaced), which now has them.
    testContainer.read(routerProvider).pop();
    await tester.pumpAndSettle();
    expect(currentPath(), '/customers');
    expect(find.text('New Brick Buyer'), findsOneWidget);
  });

  testWidgets('detail: totals, sales with their status, Call and WhatsApp', (
    tester,
  ) async {
    await openCustomers(tester);
    await tester.tap(find.text('Rahim Biswas Traders'));
    await tester.pumpAndSettle();
    expect(currentPath(), '/customers/1');

    expect(find.text('₹2,22,000'), findsOneWidget); // purchases
    expect(find.text('₹1,00,000'), findsOneWidget); // paid
    expect(find.text('₹1,22,000'), findsOneWidget); // due
    await tester.ensureVisible(find.text('INV-000095'));
    expect(find.byType(SaleTile), findsNWidgets(4));
    expect(find.text('Partial'), findsOneWidget);
    expect(find.text('Paid'), findsWidgets);
    expect(find.text('Booked'), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('08 Nov 2026 · Booking'), findsOneWidget);

    await tapVisible(tester, find.text('Call'));
    await tapVisible(tester, find.text('WhatsApp'));
    expect(launched, [
      Uri.parse('tel:+919830000000'),
      Uri.parse('https://wa.me/919830000000'),
    ]);
  });

  testWidgets('a link that cannot open shows a message', (tester) async {
    ContactLauncher.launch = (_) async => false;
    await openCustomers(tester, location: '/customers/1');
    await tapVisible(tester, find.text('Call'));
    expect(find.text('Could not open it on this device'), findsOneWidget);
  });

  testWidgets('edit from the detail page updates it', (tester) async {
    final api = await openCustomers(tester, location: '/customers/2');
    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();
    expect(currentPath(), '/customers/2/edit');
    expect(find.text('9774686411'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(2), 'Barasat');
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Save'));
    expect(
      body(api.requests.lastWhere((r) => r.method == 'PUT'))['address'],
      'Barasat',
    );
    expect(currentPath(), '/customers/2');
    expect(find.text('Barasat'), findsOneWidget);
    expect(find.text('Customer updated'), findsOneWidget);
  });

  testWidgets('⋮ Deactivate asks first, then shows Inactive', (tester) async {
    final api = await openCustomers(tester, location: '/customers/2');
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deactivate'));
    await tester.pumpAndSettle();
    expect(find.text('Deactivate Habib Enterprise?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Deactivate'));
    await tester.pumpAndSettle();
    expect(body(api.requests.lastWhere((r) => r.method == 'PATCH')), {
      'is_active': false,
    });
    expect(find.text('Customer deactivated'), findsOneWidget);
    expect(find.text('Inactive'), findsOneWidget);
  });

  testWidgets('⋮ Delete: with sales → server message; without → deleted', (
    tester,
  ) async {
    await openCustomers(tester, location: '/customers/1');
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(
      find.text('Customer has sales. Deactivate them instead'),
      findsOneWidget,
    );
    expect(currentPath(), '/customers/1');

    testContainer.read(routerProvider).go('/customers');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Habib Enterprise'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Customer deleted successfully'), findsOneWidget);
    expect(currentPath(), '/customers');
    expect(find.text('Habib Enterprise'), findsNothing);
  });

  for (final size in const [Size(360, 800), Size(800, 1000), Size(1440, 900)]) {
    for (final dark in [false, true]) {
      testWidgets('no overflow at ${size.width.toInt()} px '
          '(${dark ? 'dark' : 'light'}, Bengali)', (tester) async {
        setScreenSize(tester, size);
        final api = sampleCustomers();
        await tester.pumpWidget(
          await testApp(
            const FlyAshApp(),
            prefs: {'app.locale': 'bn', 'theme.mode': dark ? 'dark' : 'light'},
            token: 'oat_saved',
            api: signedInRoutes(api.routes),
          ),
        );
        await tester.pumpAndSettle();
        for (final path in [
          '/customers',
          '/customers/new',
          '/customers/1',
          '/customers/1/edit',
        ]) {
          testContainer.read(routerProvider).go(path);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: path);
        }
      });
    }
  }
}
