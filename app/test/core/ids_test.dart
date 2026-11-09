import 'package:flutter_test/flutter_test.dart';

import 'package:flyash/core/network/api_response.dart';
import 'package:flyash/features/customers/domain/customer.dart';
import 'package:flyash/features/sales/domain/sale_summary.dart';

void main() {
  const saleId = '01a1c190-6803-714c-81bb-28d324f11d43';
  const customerId = '01a1c190-6388-76fc-8fcb-5f1c2e90d89c';

  test('ids are UUID strings; numbers still parse as text', () {
    expect(idOf(saleId), saleId);
    expect(idOf(12), '12');
    expect(idOrNull(null), isNull);
  });

  test('models keep UUID ids as they are', () {
    final s = SaleSummary.fromJson({
      'id': saleId,
      'invoice_no': 'INV-000080',
      'type': 'instant',
      'status': 'delivered',
      'customer_id': customerId,
      'sale_date': '2026-11-09',
      'total': '100.00',
      'paid_amount': '0.00',
      'due_amount': '100.00',
      'payment_status': 'due',
    });
    expect(s.id, saleId);
    expect(s.customerId, customerId);

    final c = Customer.fromJson({
      'id': customerId,
      'name': 'Rahim',
      'phone': '9876543210',
    });
    expect(c.id, customerId);
  });
}
