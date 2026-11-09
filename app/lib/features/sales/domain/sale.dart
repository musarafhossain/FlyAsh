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
    this.productId,
    required this.productName,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.unitCost,
    required this.lineTotal,
    required this.lineCost,
  });

  final int? productId;
  final String productName;
  final ProductUnit unit;
  final String quantity;
  final String unitPrice;
  final String unitCost;
  final String lineTotal;
  final String lineCost;

  factory SaleItem.fromJson(Json json) => SaleItem(
    productId: (json['product_id'] as num?)?.toInt(),
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

/// One line the sale form sends. Money and quantity are decimal strings.
@immutable
class SaleItemInput {
  const SaleItemInput({
    required this.productId,
    required this.quantity,
    required this.unitCost,
    required this.unitPrice,
  });

  final int productId;
  final String quantity;
  final String unitCost;
  final String unitPrice;

  Json toJson() => {
    'product_id': productId,
    'quantity': quantity,
    'unit_cost': unitCost,
    'unit_price': unitPrice,
  };
}

/// A new customer created together with the sale.
@immutable
class NewCustomerInput {
  const NewCustomerInput({
    required this.name,
    required this.phone,
    this.address,
  });

  final String name;
  final String phone;
  final String? address;

  Json toJson() => {
    'name': name.trim(),
    'phone': phone.trim(),
    'address': address,
  };
}

/// Money received (with a new sale, or later on the sale detail page).
@immutable
class PaymentInput {
  const PaymentInput({
    required this.amount,
    this.method = 'cash',
    this.note,
    this.paymentDate,
  });

  final String amount;

  /// cash | upi | bank | other
  final String method;
  final String? note;

  /// Null = today (only for payments added later).
  final String? paymentDate;

  Json toJson() => {
    'amount': amount,
    'method': method,
    'note': note,
    'payment_date': ?paymentDate,
  };
}

/// What the sale form sends (POST /sales; PUT without type and payment).
@immutable
class SaleInput {
  const SaleInput({
    required this.type,
    this.customerId,
    this.newCustomer,
    required this.saleDate,
    this.deliveryDate,
    this.deliveryAddress,
    required this.items,
    this.transportCharge = '0',
    this.discount = '0',
    this.payment,
    this.notes,
  });

  /// instant | booking
  final String type;
  final int? customerId;
  final NewCustomerInput? newCustomer;
  final String saleDate;
  final String? deliveryDate;
  final String? deliveryAddress;
  final List<SaleItemInput> items;
  final String transportCharge;
  final String discount;
  final PaymentInput? payment;
  final String? notes;

  Json toJson({bool forEdit = false}) => {
    if (!forEdit) 'type': type,
    'customer_id': ?customerId,
    if (newCustomer != null) 'new_customer': newCustomer!.toJson(),
    'sale_date': saleDate,
    if (type == 'booking') 'delivery_date': deliveryDate,
    'delivery_address': type == 'booking' ? deliveryAddress : null,
    'items': [for (final i in items) i.toJson()],
    'transport_charge': transportCharge,
    'discount': discount,
    if (!forEdit && payment != null) 'payment': payment!.toJson(),
    'notes': notes,
  };
}

/// Sales API (07-API §9). Methods throw a `Failure` on error; actions return
/// the updated sale and the server message.
abstract interface class SalesRepository {
  /// GET /sales?page&search&type&status&from&to (newest sale date first)
  Future<Paginated<SaleSummary>> list({int page = 1, SaleFilter filter});

  /// GET /sales/:id
  Future<Sale> get(int id);

  /// GET /sales/upcoming-deliveries (booked, by delivery date, overdue first)
  Future<Paginated<SaleSummary>> upcoming({int page = 1});

  /// POST /sales
  Future<(Sale, String)> create(SaleInput input);

  /// PUT /sales/:id (items replaced, totals recalculated)
  Future<(Sale, String)> update(int id, SaleInput input);

  /// DELETE /sales/:id (soft delete) → message
  Future<String> delete(int id);

  /// POST /sales/:id/deliver
  Future<(Sale, String)> deliver(int id, {String? deliveredDate});

  /// POST /sales/:id/cancel (booked, without payments)
  Future<(Sale, String)> cancel(int id);

  /// POST /sales/:id/payments
  Future<(Sale, String)> addPayment(int id, PaymentInput payment);

  /// DELETE /sales/:id/payments/:paymentId
  Future<(Sale, String)> deletePayment(int id, int paymentId);
}
