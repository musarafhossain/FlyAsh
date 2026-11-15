import 'package:flutter/foundation.dart';

import '../../../core/network/api_response.dart';

/// A product the factory sells, with a default price (no cost).
/// Money stays a string ("4.50") as sent by the API; format with `Fmt.money`.
@immutable
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.defaultPrice,
    this.notes,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String defaultPrice;

  final String? notes;
  final bool isActive;

  /// A copy with another active state (for optimistic updates).
  Product withActive(bool active) => Product(
    id: id,
    name: name,
    defaultPrice: defaultPrice,
    notes: notes,
    isActive: active,
  );

  factory Product.fromJson(Json json) => Product(
    id: idOf(json['id']),
    name: json['name'] as String? ?? '',
    defaultPrice: '${json['default_price'] ?? '0'}',
    notes: json['notes'] as String?,
    isActive: json['is_active'] as bool? ?? true,
  );
}

/// What the form sends for a new or edited product.
@immutable
class ProductInput {
  const ProductInput({
    required this.name,
    required this.defaultPrice,
    this.notes,
  });

  final String name;

  /// Decimal string, e.g. "6.50" (never a double).
  final String defaultPrice;
  final String? notes;

  Json toJson() => {
    'name': name.trim(),
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
