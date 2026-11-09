import 'package:flutter/foundation.dart';

import '../../../core/network/api_response.dart';

/// Unit a product is sold in (07-API §7).
enum ProductUnit { piece, thousand, truck, other }

/// A product the factory sells, with default cost and price per unit.
/// Money stays a string ("4.50") as sent by the API; format with `Fmt.money`.
@immutable
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.unit,
    this.unitLabel,
    required this.defaultCost,
    required this.defaultPrice,
    required this.margin,
    this.notes,
    this.isActive = true,
  });

  final String id;
  final String name;
  final ProductUnit unit;

  /// Only for [ProductUnit.other], e.g. "cft".
  final String? unitLabel;
  final String defaultCost;
  final String defaultPrice;

  /// price − cost, per unit (can be negative).
  final String margin;
  final String? notes;
  final bool isActive;

  bool get isLoss => margin.startsWith('-');

  factory Product.fromJson(Json json) => Product(
    id: idOf(json['id']),
    name: json['name'] as String? ?? '',
    unit: ProductUnit.values.firstWhere(
      (u) => u.name == json['unit'],
      orElse: () => ProductUnit.other,
    ),
    unitLabel: json['unit_label'] as String?,
    defaultCost: '${json['default_cost'] ?? '0'}',
    defaultPrice: '${json['default_price'] ?? '0'}',
    margin: '${json['margin'] ?? '0'}',
    notes: json['notes'] as String?,
    isActive: json['is_active'] as bool? ?? true,
  );
}

/// What the form sends for a new or edited product.
@immutable
class ProductInput {
  const ProductInput({
    required this.name,
    required this.unit,
    this.unitLabel,
    required this.defaultCost,
    required this.defaultPrice,
    this.notes,
  });

  final String name;
  final ProductUnit unit;
  final String? unitLabel;

  /// Decimal strings, e.g. "4.50" (never doubles).
  final String defaultCost;
  final String defaultPrice;
  final String? notes;

  Json toJson() => {
    'name': name.trim(),
    'unit': unit.name,
    if (unit == ProductUnit.other) 'unit_label': unitLabel?.trim(),
    'default_cost': defaultCost,
    'default_price': defaultPrice,
    'notes': notes,
  };
}

/// Products API (07-API §7). Methods throw a `Failure` on error.
abstract interface class ProductsRepository {
  /// GET /products?page&limit&search&active (active first, then by name)
  Future<Paginated<Product>> list({int page = 1, String? search, bool? active});

  Future<Product> get(String id);

  Future<Product> create(ProductInput input);

  Future<Product> update(String id, ProductInput input);

  /// PATCH /products/:id/status → (product, message)
  Future<(Product, String)> setActive(String id, bool active);

  /// DELETE /products/:id → message. 409 when used in sales.
  Future<String> delete(String id);
}
