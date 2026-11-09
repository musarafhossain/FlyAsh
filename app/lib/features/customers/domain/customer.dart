import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_response.dart';
import '../../sales/domain/sale_summary.dart';

/// A customer with their totals over delivered sales (07-API §8).
@immutable
class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.address,
    this.isActive = true,
    this.totalSales = '0.00',
    this.totalPaid = '0.00',
    this.totalDue = '0.00',
  });

  final String id;
  final String name;
  final String phone;
  final String? address;
  final bool isActive;
  final String totalSales;
  final String totalPaid;
  final String totalDue;

  bool get hasDue =>
      (Decimal.tryParse(totalDue) ?? Decimal.zero) > Decimal.zero;

  factory Customer.fromJson(Json json) => Customer(
    id: idOf(json['id']),
    name: json['name'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    address: json['address'] as String?,
    isActive: json['is_active'] as bool? ?? true,
    totalSales: '${json['total_sales'] ?? '0.00'}',
    totalPaid: '${json['total_paid'] ?? '0.00'}',
    totalDue: '${json['total_due'] ?? '0.00'}',
  );
}

/// What the form sends for a new or edited customer.
@immutable
class CustomerInput {
  const CustomerInput({required this.name, required this.phone, this.address});

  final String name;
  final String phone;
  final String? address;

  Json toJson() => {
    'name': name.trim(),
    'phone': phone.trim(),
    'address': address,
  };
}

/// Customers API (07-API §8). Methods throw a `Failure` on error.
/// A duplicate phone is a `ValidationFailure` whose `data` has
/// `existing_customer_id` (the app offers to open that customer).
abstract interface class CustomersRepository {
  /// GET /customers?page&search&has_due&active (newest first; with
  /// has_due=true sorted by highest due)
  Future<Paginated<Customer>> list({
    int page = 1,
    String? search,
    bool? hasDue,
    bool? active,
  });

  Future<Customer> get(String id);

  Future<Customer> create(CustomerInput input);

  Future<Customer> update(String id, CustomerInput input);

  /// PATCH /customers/:id/status → (customer, message)
  Future<(Customer, String)> setActive(String id, bool active);

  /// DELETE /customers/:id → message. 409 when they have sales.
  Future<String> delete(String id);

  /// GET /customers/:id/sales?page
  Future<Paginated<SaleSummary>> sales(String id, {int page = 1});
}
