import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_response.dart';
import '../../../core/utils/dates.dart';
import '../../products/domain/product.dart';
import 'sale_summary.dart';

/// One line of a sale: a snapshot of the product at sale time.
@immutable
class SaleItem {
  const SaleItem({
    required this.productName,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.unitCost,
    required this.lineTotal,
    required this.lineCost,
  });

  final String productName;
  final ProductUnit unit;
  final String quantity;
  final String unitPrice;
  final String unitCost;
  final String lineTotal;
  final String lineCost;

  factory SaleItem.fromJson(Json json) => SaleItem(
    productName: json['product_name'] as String? ?? '',
    unit: ProductUnit.values.firstWhere(
      (u) => u.name == json['unit'],
      orElse: () => ProductUnit.other,
    ),
    quantity: '${json['quantity'] ?? '0'}',
    unitPrice: '${json['unit_price'] ?? '0'}',
    unitCost: '${json['unit_cost'] ?? '0'}',
    lineTotal: '${json['line_total'] ?? '0'}',
    lineCost: '${json['line_cost'] ?? '0'}',
  );
}

/// Money received for a sale.
@immutable
class SalePayment {
  const SalePayment({
    required this.id,
    required this.amount,
    required this.paymentDate,
    required this.method,
    this.note,
    this.createdBy,
  });

  final int id;
  final String amount;
  final String paymentDate;

  /// cash | upi | bank | cheque | other
  final String method;
  final String? note;
  final String? createdBy;

  factory SalePayment.fromJson(Json json) => SalePayment(
    id: (json['id'] as num).toInt(),
    amount: '${json['amount'] ?? '0'}',
    paymentDate: json['payment_date'] as String? ?? '',
    method: json['method'] as String? ?? 'cash',
    note: json['note'] as String?,
    createdBy: (json['created_by'] as Json?)?['name'] as String?,
  );
}

/// A full sale (GET /sales/:id): the list fields plus customer address,
/// money breakdown, items and payments.
@immutable
class Sale {
  const Sale({
    required this.summary,
    this.deliveredDate,
    this.deliveryAddress,
    this.customerAddress,
    required this.subtotal,
    required this.transportCharge,
    required this.discount,
    required this.totalCost,
    required this.profit,
    this.notes,
    this.createdBy,
    this.items = const [],
    this.payments = const [],
  });

  final SaleSummary summary;
  final String? deliveredDate;
  final String? deliveryAddress;
  final String? customerAddress;
  final String subtotal;
  final String transportCharge;
  final String discount;
  final String totalCost;
  final String profit;
  final String? notes;
  final String? createdBy;
  final List<SaleItem> items;
  final List<SalePayment> payments;

  int get id => summary.id;

  /// True for "0.00" (to hide empty lines such as no transport charge).
  static bool isZeroAmount(String v) =>
      (Decimal.tryParse(v) ?? Decimal.zero) == Decimal.zero;

  factory Sale.fromJson(Json json) => Sale(
    summary: SaleSummary.fromJson(json),
    deliveredDate: json['delivered_date'] as String?,
    deliveryAddress: json['delivery_address'] as String?,
    customerAddress: (json['customer'] as Json?)?['address'] as String?,
    subtotal: '${json['subtotal'] ?? '0'}',
    transportCharge: '${json['transport_charge'] ?? '0'}',
    discount: '${json['discount'] ?? '0'}',
    totalCost: '${json['total_cost'] ?? '0'}',
    profit: '${json['profit'] ?? '0'}',
    notes: json['notes'] as String?,
    createdBy: (json['created_by'] as Json?)?['name'] as String?,
    items: [
      for (final i in (json['items'] as List<Object?>? ?? const []))
        SaleItem.fromJson(i! as Json),
    ],
    payments: [
      for (final p in (json['payments'] as List<Object?>? ?? const []))
        SalePayment.fromJson(p! as Json),
    ],
  );
}

/// Sales list filters (07-API GET /sales).
@immutable
class SaleFilter {
  const SaleFilter({
    this.search,
    this.type,
    this.status,
    this.range = const DateRange(),
    this.preset,
  });

  final String? search;

  /// instant | booking (null = all)
  final String? type;

  /// paid | partial | due | booked | delivered | cancelled (null = all)
  final String? status;
  final DateRange range;

  /// Which quick choice made [range] (null = any date).
  final DatePreset? preset;

  /// Filters chosen in the filter sheet (not search or the type tabs).
  int get activeCount => (status != null ? 1 : 0) + (range.isEmpty ? 0 : 1);

  SaleFilter copyWith({
    String? search,
    String? Function()? type,
    String? Function()? status,
    DateRange? range,
    DatePreset? Function()? preset,
  }) => SaleFilter(
    search: search ?? this.search,
    type: type != null ? type() : this.type,
    status: status != null ? status() : this.status,
    range: range ?? this.range,
    preset: preset != null ? preset() : this.preset,
  );
}

/// Sales API (07-API §9, read side). Methods throw a `Failure` on error.
abstract interface class SalesRepository {
  /// GET /sales?page&search&type&status&from&to (newest sale date first)
  Future<Paginated<SaleSummary>> list({int page = 1, SaleFilter filter});

  /// GET /sales/:id
  Future<Sale> get(int id);

  /// GET /sales/upcoming-deliveries (booked, by delivery date, overdue first)
  Future<Paginated<SaleSummary>> upcoming({int page = 1});
}
