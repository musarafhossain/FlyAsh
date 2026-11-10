import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flyash/app.dart';
import 'package:flyash/core/router/app_router.dart';
import 'package:flyash/core/utils/contact_launcher.dart';
import 'package:flyash/core/widgets/data_table_card.dart';
import 'package:flyash/features/sales/presentation/widgets/sale_list_items.dart';

import '../fake_api.dart';
import '../helpers.dart';

Map<String, Object?> saleJson(
  int id, {
  String type = 'instant',
  String status = 'delivered',
  String payment = 'partial',
  String customer = 'Rahim Biswas Traders',
  int customerId = 1,
  String date = '2026-11-08',
  String? delivery,
  bool overdue = false,
  String total = '38000.00',
  String due = '28000.00',
}) => {
  'id': id,
  'invoice_no': 'INV-${id.toString().padLeft(6, '0')}',
  'type': type,
  'status': status,
  'customer_id': customerId,
  'sale_date': date,
  'delivery_date': delivery,
  'delivered_date': status == 'delivered' ? date : null,
  'delivery_address': null,
  'subtotal': '37000.00',
  'transport_charge': '1500.00',
  'discount': '500.00',
  'total': total,
  'total_cost': '23800.00',
  'profit': '14200.00',
  'paid_amount': '10000.00',
  'due_amount': due,
  'payment_status': payment,
  'notes': null,
  'customer': {'id': customerId, 'name': customer, 'phone': '9830000000'},
  'is_overdue': overdue,
};

final sales = [
  saleJson(104),
  saleJson(
    105,
    type: 'booking',
    status: 'booked',
    customer: 'Nazrul Islam',
    customerId: 45,
    delivery: '2026-11-15',
    total: '19500.00',
    due: '14500.00',
  ),
  saleJson(103, payment: 'paid', customer: 'Habib Enterprise', due: '0.00'),
  saleJson(102, status: 'cancelled', customer: 'Old Shop'),
];

/// Full sale for the detail page (07-API GET /sales/:id).
Map<String, Object?> detail104() => {
  ...saleJson(104),
  'notes': 'Deliver before noon',
  'customer': {
    'id': 1,
    'name': 'Rahim Biswas Traders',
    'phone': '9830000000',
    'address': 'Basirhat, North 24 Parganas',
  },
  'created_by': {'id': 1, 'name': 'Test Owner'},
  'items': [
    {
      'product_name': 'Fly Ash Brick 9×4×3',
      'unit': 'piece',
      'quantity': '5000.00',
      'unit_cost': '4.20',
      'unit_price': '6.50',
      'line_cost': '21000.00',
      'line_total': '32500.00',
    },
    {
      'product_name': 'Hollow Block 16×8×8',
      'unit': 'piece',
      'quantity': '100.00',
      'unit_cost': '28.00',
      'unit_price': '45.00',
      'line_cost': '2800.00',
      'line_total': '4500.00',
    },
  ],
  'payments': [
    {
      'id': 90,
      'amount': '10000.00',
      'payment_date': '2026-11-08',
      'method': 'upi',
      'note': 'Paid on spot',
      'created_by': {'id': 1, 'name': 'Test Owner'},
    },
  ],
};

Reply page(List<Object?> items) => (
  200,
  envelope(200, 'ok', {
    'items': items,
    'page': 1,
    'limit': 20,
    'total': items.length,
    'last_page': 1,
  }),
  {},
);

FakeRoutes salesRoutes() => {
  'GET /sales': (RequestOptions o) {
    final q = o.queryParameters;
    final search = (q['search'] as String? ?? '').toLowerCase();
    return page([
      for (final s in sales)
        if ((q['type'] == null || s['type'] == q['type']) &&
            (q['status'] == null ||
                s['status'] == q['status'] ||
                (s['status'] == 'delivered' &&
                    s['payment_status'] == q['status'])) &&
            (search.isEmpty ||
                '${s['invoice_no']}'.toLowerCase().contains(search) ||
                '${(s['customer']! as Map)['name']}'.toLowerCase().contains(
                  search,
                )))
          s,
    ]);
  },
  'GET /sales/upcoming-deliveries': (_) => page([
    saleJson(
      63,
      type: 'booking',
      status: 'booked',
      customer: 'Rahim Roy',
      delivery: '2026-09-16',
      overdue: true,
    ),
    saleJson(
      105,
      type: 'booking',
      status: 'booked',
      customer: 'Nazrul Islam',
      delivery: '2026-11-15',
    ),
  ]),
  'GET /sales/104': (_) => (200, envelope(200, 'ok', detail104()), {}),
  'GET /sales/105': (_) => (
    200,
    envelope(200, 'ok', {
      ...saleJson(
        105,
        type: 'booking',
        status: 'booked',
        customer: 'Nazrul Islam',
        customerId: 45,
        delivery: '2026-11-15',
      ),
      'delivery_address': 'Bongaon station road',
      'items': const [],
      'payments': const [],
    }),
    {},
  ),
  'GET /customers/1': (_) => (
    200,
    envelope(200, 'ok', {
      'id': 1,
      'name': 'Rahim Biswas Traders',
      'phone': '9830000000',
      'total_sales': '0.00',
      'total_paid': '0.00',
      'total_due': '0.00',
    }),
    {},
  ),
  'GET /customers/1/sales': (_) => page([saleJson(104)]),
};

Future<List<RequestOptions>> openSales(
  WidgetTester tester, {
  Size size = const Size(360, 800),
  String location = '/sales',
}) async {
  final requests = <RequestOptions>[];
  setScreenSize(tester, size);
  await tester.pumpWidget(
    await testApp(
      const FlyAshApp(),
      prefs: {'business.date': '2026-11-09'},
      token: 'oat_saved',
      api: signedInRoutes(salesRoutes()),
      requests: requests,
    ),
  );
  await tester.pumpAndSettle();
  testContainer.read(routerProvider).go(location);
  await tester.pumpAndSettle();
  return requests;
}

String currentPath() =>
    testContainer.read(routerProvider).routeInformationProvider.value.uri.path;

RequestOptions lastList(List<RequestOptions> r) =>
    r.lastWhere((o) => o.path == '/sales');

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

void main() {
  testWidgets('long press shows only what the sale allows', (tester) async {
    await openSales(tester);
    expect(find.textContaining('Showing'), findsNothing);
    await tester.longPress(find.textContaining('INV-000104'));
    await tester.pumpAndSettle();
    expect(rowMenu(tester), ['View', 'Edit', 'Add payment', 'Delete']);
    await tapMenu(tester, 'Edit');
    expect(currentPath(), '/sales/104/edit');

    testContainer.read(routerProvider).go('/sales');
    await tester.pumpAndSettle();
    await tester.longPress(find.textContaining('INV-000105'));
    await tester.pumpAndSettle();
    expect(
      rowMenu(tester),
      containsAllInOrder(['Mark delivered', 'Cancel booking', 'Delete']),
    );
  });

  late List<Uri> launched;
  setUp(() {
    launched = [];
    ContactLauncher.launch = (uri) async {
      launched.add(uri);
      return true;
    };
  });

  testWidgets('phone: rows with customer, invoice · date, total and pill', (
    tester,
  ) async {
    await openSales(tester);
    expect(find.byType(SaleTile), findsNWidgets(4));
    expect(find.text('Rahim Biswas Traders'), findsOneWidget);
    expect(find.text('INV-000104 · 08 Nov 2026'), findsOneWidget);
    expect(find.text('₹38,000'), findsWidgets);
    expect(find.text('Partial'), findsOneWidget);
    expect(find.text('Booked'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.byType(DataTableCard), findsNothing);
  });

  testWidgets('desktop: a table with the customer column', (tester) async {
    await openSales(tester, size: const Size(1440, 900));
    expect(find.byType(DataTableCard), findsOneWidget);
    expect(find.text('Customer'), findsOneWidget); // column header
    expect(find.text('₹28,000'), findsWidgets); // due column
    expect(tester.takeException(), isNull);
  });

  testWidgets('tabs All / Instant / Booking send ?type', (tester) async {
    final requests = await openSales(tester);
    await tester.tap(find.text('Booking').first);
    await tester.pumpAndSettle();
    expect(lastList(requests).queryParameters['type'], 'booking');
    expect(find.byType(SaleTile), findsOneWidget);

    await tester.tap(find.text('Instant').first);
    await tester.pumpAndSettle();
    expect(lastList(requests).queryParameters['type'], 'instant');

    await tester.tap(find.text('All').first);
    await tester.pumpAndSettle();
    expect(lastList(requests).queryParameters.containsKey('type'), isFalse);
  });

  testWidgets('search waits 400 ms, then asks the server', (tester) async {
    final requests = await openSales(tester);
    final before = requests.where((r) => r.path == '/sales').length;
    await tester.enterText(find.byType(TextField).first, 'nazrul');
    await tester.pump(const Duration(milliseconds: 200));
    expect(requests.where((r) => r.path == '/sales').length, before);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(lastList(requests).queryParameters['search'], 'nazrul');
    expect(find.byType(SaleTile), findsOneWidget);
  });

  testWidgets('filter sheet: This month + Partial → from/to/status; chips '
      'show and clear them', (tester) async {
    final requests = await openSales(tester);
    await tester.tap(find.byTooltip('Filter sales'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'This month'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Partial'));
    await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
    await tester.pumpAndSettle();

    final q = lastList(requests).queryParameters;
    expect(q['from'], '2026-11-01'); // factory today = 2026-11-09
    expect(q['to'], '2026-11-09');
    expect(q['status'], 'partial');
    expect(find.widgetWithText(InputChip, 'This month'), findsOneWidget);
    expect(find.widgetWithText(InputChip, 'Partial'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // badge on the filter button

    // ✕ on the date chip removes only the date
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(InputChip, 'This month'),
        matching: find.byIcon(Icons.clear),
      ),
    );
    await tester.pumpAndSettle();
    final q2 = lastList(requests).queryParameters;
    expect(q2.containsKey('from'), isFalse);
    expect(q2['status'], 'partial');

    // Reset clears everything
    await tester.tap(find.byTooltip('Filter sales'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Reset'));
    await tester.pumpAndSettle();
    expect(lastList(requests).queryParameters.containsKey('status'), isFalse);
    expect(find.byType(InputChip), findsNothing);
  });

  testWidgets('detail: pills, customer, items, money summary, payments', (
    tester,
  ) async {
    await openSales(tester);
    await tester.tap(find.text('Rahim Biswas Traders'));
    await tester.pumpAndSettle();
    expect(currentPath(), '/sales/104');

    expect(find.text('INV-000104'), findsWidgets);
    expect(find.text('Instant'), findsOneWidget);
    expect(find.text('Delivered'), findsOneWidget);
    expect(find.text('Partial'), findsOneWidget);
    expect(find.text('Sale date: 08 Nov 2026'), findsOneWidget);
    expect(find.text('Deliver before noon'), findsOneWidget);
    expect(find.text('Entered by Test Owner'), findsOneWidget);
    expect(find.text('Basirhat, North 24 Parganas'), findsOneWidget);

    expect(find.text('Items (2)'), findsOneWidget);
    expect(find.text('5,000 × ₹6.50 per Piece'), findsOneWidget);
    expect(find.text('₹32,500'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Profit'), 200);
    expect(find.text('+ ₹1,500.00'), findsOneWidget); // transport
    expect(find.text('− ₹500.00'), findsOneWidget); // discount
    expect(find.text('₹38,000.00'), findsOneWidget); // total
    expect(find.text('₹14,200.00'), findsOneWidget); // profit
    expect(find.text('₹28,000.00'), findsOneWidget); // due

    await tester.scrollUntilVisible(find.text('Payments (1)'), 200);
    expect(find.text('08 Nov 2026 · UPI'), findsOneWidget);
    expect(find.text('Paid on spot · by Test Owner'), findsOneWidget);
  });

  testWidgets('detail: Call / WhatsApp and the customer card opens them', (
    tester,
  ) async {
    await openSales(tester, location: '/sales/104');
    await tester.tap(find.text('Call'));
    await tester.tap(find.text('WhatsApp'));
    await tester.pumpAndSettle();
    expect(launched, [
      Uri.parse('tel:+919830000000'),
      Uri.parse('https://wa.me/919830000000'),
    ]);

    await tester.tap(find.text('Rahim Biswas Traders').first);
    await tester.pumpAndSettle();
    expect(currentPath(), '/customers/1');
  });

  testWidgets('booking detail shows delivery date and address', (tester) async {
    await openSales(tester, location: '/sales/105');
    expect(find.text('Booking'), findsOneWidget);
    expect(find.text('Booked'), findsOneWidget);
    expect(find.text('Delivery date: 15 Nov 2026'), findsOneWidget);
    expect(find.text('Bongaon station road'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('No payment received yet'), 200);
  });

  testWidgets('truck button → upcoming deliveries, overdue first', (
    tester,
  ) async {
    await openSales(tester);
    await tester.tap(find.byTooltip('Upcoming deliveries'));
    await tester.pumpAndSettle();
    expect(currentPath(), '/sales/upcoming');
    expect(find.text('Overdue'), findsOneWidget);
    expect(find.text('INV-000063 · Deliver 16 Sep 2026'), findsOneWidget);
    expect(find.text('INV-000105 · Deliver 15 Nov 2026'), findsOneWidget);

    await tester.tap(find.text('Nazrul Islam'));
    await tester.pumpAndSettle();
    expect(currentPath(), '/sales/105');
  });

  testWidgets('a sale on the customer page opens the sale', (tester) async {
    await openSales(tester, location: '/customers/1');
    await tester.ensureVisible(find.text('INV-000104'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('INV-000104'));
    await tester.pumpAndSettle();
    expect(currentPath(), '/sales/104');
  });

  testWidgets('an unknown sale shows an error with Retry', (tester) async {
    await openSales(tester, location: '/sales/999');
    expect(find.text('Route not found'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  for (final size in const [Size(360, 800), Size(800, 1000), Size(1440, 900)]) {
    for (final dark in [false, true]) {
      testWidgets('no overflow at ${size.width.toInt()} px '
          '(${dark ? 'dark' : 'light'}, Bengali)', (tester) async {
        setScreenSize(tester, size);
        await tester.pumpWidget(
          await testApp(
            const FlyAshApp(),
            prefs: {'app.locale': 'bn', 'theme.mode': dark ? 'dark' : 'light'},
            token: 'oat_saved',
            api: signedInRoutes(salesRoutes()),
          ),
        );
        await tester.pumpAndSettle();
        for (final path in [
          '/sales',
          '/sales/upcoming',
          '/sales/104',
          '/sales/105',
        ]) {
          testContainer.read(routerProvider).go(path);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: path);
        }
        testContainer.read(routerProvider).go('/sales');
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.tune));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'filter sheet');
      });
    }
  }
}
