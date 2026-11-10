import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flyash/core/widgets/list_items.dart';

import 'sale_form_test.dart';

/// Opens the app bar ⋮ menu and taps [label].
Future<void> fromMenu(WidgetTester tester, String label) async {
  await tester.tap(find.byTooltip('More actions'));
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(
      of: find.byWidgetPredicate((w) => w is PopupMenuItem),
      matching: find.text(label),
    ),
  );
  await tester.pumpAndSettle();
}

/// Long-presses the first payment row and taps "Delete payment".
Future<void> deleteFirstPayment(WidgetTester tester) async {
  // Let a message from the step before go (it can cover the row).
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
  final row = find.byType(PaymentAvatar).first;
  await tester.ensureVisible(row);
  await tester.pumpAndSettle();
  await tester.longPress(row);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Delete payment'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Add payment: prefilled with the due, checks the max, saves', (
    tester,
  ) async {
    await openAt(tester, '/sales/104');
    expect(find.text('₹23,500.00'), findsWidgets); // due before

    // No action buttons on the page: they are in the ⋮ menu
    expect(find.widgetWithText(FilledButton, 'Add payment'), findsNothing);
    await fromMenu(tester, 'Add payment');
    expect(find.text('Due ₹23,500'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '23500'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Amount'),
      '30000',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Add payment').last);
    await tester.pumpAndSettle();
    expect(find.text('Cannot be more than the due ₹23,500.00'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Amount'),
      '8000',
    );
    await tester.tap(find.widgetWithText(ChoiceChip, 'Cash'));
    await tester.tap(find.widgetWithText(FilledButton, 'Add payment').last);
    await tester.pumpAndSettle();

    expect(body(last('POST', '/sales/104/payments')), {
      'amount': '8000',
      'method': 'cash',
      'note': null,
      'payment_date': '2026-11-09',
    });
    expect(find.text('Payment added'), findsOneWidget);
    expect(find.text('₹15,500.00'), findsWidgets); // new due
    expect(find.text('Payments (2)'), findsOneWidget);
  });

  testWidgets('Delete a payment asks first; the due goes up', (tester) async {
    await openAt(tester, '/sales/104');
    await deleteFirstPayment(tester);
    expect(find.text('Delete payment of ₹10,000.00?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(last('DELETE', '/sales/104/payments/90'), isNotNull);
    expect(find.text('Payment removed'), findsOneWidget);
    expect(find.text('No payment received yet'), findsOneWidget);
  });

  testWidgets('Booking: Mark delivered sends the date and updates pills', (
    tester,
  ) async {
    await openAt(tester, '/sales/105');
    expect(find.text('Booked'), findsOneWidget);
    await fromMenu(tester, 'Mark delivered');
    expect(find.text('Deliver INV-000105'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Mark delivered').last);
    await tester.pumpAndSettle();
    expect(body(last('POST', '/sales/105/deliver')), {
      'delivered_date': '2026-11-09',
    });
    expect(find.text('Marked as delivered'), findsOneWidget);
    expect(find.text('Delivered'), findsOneWidget);
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    expect(find.text('Mark delivered'), findsNothing, reason: 'delivered');
  });

  testWidgets('Cancel booking: with payments explains; without asks, cancels', (
    tester,
  ) async {
    await openAt(tester, '/sales/105');
    // Add an advance first → cancel is refused with an explanation.
    await fromMenu(tester, 'Add payment');
    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '500');
    await tester.tap(find.widgetWithText(FilledButton, 'Add payment').last);
    await tester.pumpAndSettle();

    await fromMenu(tester, 'Cancel booking');
    expect(find.textContaining('Delete them first'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'OK'));
    await tester.pumpAndSettle();
    expect(
      backend.requests.where((r) => r.path == '/sales/105/cancel'),
      isEmpty,
    );

    // Remove the payment, then cancel.
    await deleteFirstPayment(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    await fromMenu(tester, 'Cancel booking');
    expect(find.text('Cancel INV-000105?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Cancel booking'));
    await tester.pumpAndSettle();
    expect(last('POST', '/sales/105/cancel'), isNotNull);
    expect(find.text('Booking cancelled'), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);
    expect(
      find.byTooltip('Edit'),
      findsNothing,
      reason: 'no edit when cancelled',
    );
  });

  testWidgets('⋮ Delete sale asks first and returns to the list', (
    tester,
  ) async {
    await openAt(tester, '/sales');
    await tester.tap(find.text('Rahim Biswas Traders').first);
    await tester.pumpAndSettle();
    expect(currentPath(), '/sales/104');

    await fromMenu(tester, 'Delete sale');
    expect(find.text('Delete INV-000104?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(last('DELETE', '/sales/104'), isNotNull);
    expect(currentPath(), '/sales');
    expect(find.text('Sale deleted successfully'), findsOneWidget);
    expect(find.text('INV-000104 · 08 Nov 2026'), findsNothing);
  });

  for (final size in const [Size(360, 800), Size(1440, 900)]) {
    testWidgets('Upcoming deliveries: "Mark delivered" on a row '
        '(${size.width.toInt()} px)', (tester) async {
      await openAt(tester, '/sales/upcoming', size: size);
      expect(find.textContaining('INV-000105'), findsWidgets);
      await tester.tap(find.widgetWithText(TextButton, 'Mark delivered'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Mark delivered'));
      await tester.pumpAndSettle();
      expect(last('POST', '/sales/105/deliver'), isNotNull);
      expect(find.text('Marked as delivered'), findsOneWidget);
      expect(find.text('No deliveries pending'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final size in const [Size(360, 800), Size(1440, 900)]) {
    testWidgets('sheets: no overflow at ${size.width.toInt()} px (Bengali)', (
      tester,
    ) async {
      await openAt(tester, '/sales/105', size: size);
      await testerSetBengali(tester);
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add_card));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tapAt(const Offset(10, 10)); // close
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.local_shipping_outlined).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
