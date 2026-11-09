import 'package:flutter/foundation.dart';

import '../../../core/network/api_response.dart';

/// One sale as shown in lists (07-API §9 sale object, without items).
/// Money values are strings ("40500.00"); dates are business dates.
@immutable
class SaleSummary {
  const SaleSummary({
    required this.id,
    required this.invoiceNo,
    required this.type,
    required this.status,
    required this.saleDate,
    this.deliveryDate,
    required this.total,
    required this.paidAmount,
    required this.dueAmount,
    required this.paymentStatus,
    this.customerName,
  });

  final int id;
  final String invoiceNo;

  /// instant | booking
  final String type;

  /// booked | delivered | cancelled
  final String status;
  final String saleDate;
  final String? deliveryDate;
  final String total;
  final String paidAmount;
  final String dueAmount;

  /// paid | partial | due
  final String paymentStatus;
  final String? customerName;

  bool get isCancelled => status == 'cancelled';

  factory SaleSummary.fromJson(Json json) => SaleSummary(
    id: (json['id'] as num).toInt(),
    invoiceNo: json['invoice_no'] as String? ?? '',
    type: json['type'] as String? ?? 'instant',
    status: json['status'] as String? ?? 'delivered',
    saleDate: json['sale_date'] as String? ?? '',
    deliveryDate: json['delivery_date'] as String?,
    total: '${json['total'] ?? '0'}',
    paidAmount: '${json['paid_amount'] ?? '0'}',
    dueAmount: '${json['due_amount'] ?? '0'}',
    paymentStatus: json['payment_status'] as String? ?? 'due',
    customerName: (json['customer'] as Json?)?['name'] as String?,
  );
}
