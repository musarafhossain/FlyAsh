import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../domain/product.dart';

class ProductsRepositoryImpl implements ProductsRepository {
  ProductsRepositoryImpl(this._api);

  final ApiClient _api;

  static Product _product(Object? d) => Product.fromJson(d as Json);

  @override
  Future<Paginated<Product>> list({
    int page = 1,
    String? search,
    bool? active,
  }) => _api.getPage(
    '/products',
    page: page,
    query: {'search': search?.trim(), 'active': active},
    item: Product.fromJson,
  );

  @override
  Future<Product> get(String id) async =>
      (await _api.get('/products/$id', parse: _product)).data;

  @override
  Future<Product> create(ProductInput input) async => (await _api.post(
    '/products',
    body: input.toJson(),
    parse: _product,
  )).data;

  @override
  Future<Product> update(String id, ProductInput input) async => (await _api.put(
    '/products/$id',
    body: input.toJson(),
    parse: _product,
  )).data;

  @override
  Future<(Product, String)> setActive(String id, bool active) async {
    final res = await _api.patch(
      '/products/$id/status',
      body: {'is_active': active},
      parse: _product,
    );
    return (res.data, res.message);
  }

  @override
  Future<String> delete(String id) async =>
      (await _api.delete('/products/$id', parse: (d) => d)).message;
}

final productsRepositoryProvider = Provider<ProductsRepository>(
  (ref) => ProductsRepositoryImpl(ref.watch(apiClientProvider)),
);
