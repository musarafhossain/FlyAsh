import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../domain/sale.dart';
import '../domain/sale_summary.dart';

class SalesRepositoryImpl implements SalesRepository {
  SalesRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<Paginated<SaleSummary>> list({
    int page = 1,
    SaleFilter filter = const SaleFilter(),
  }) => _api.getPage(
    '/sales',
    page: page,
    query: {
      'search': filter.search?.trim(),
      'type': filter.type,
      'status': filter.status,
      'from': filter.range.from,
      'to': filter.range.to,
    },
    item: SaleSummary.fromJson,
  );

  @override
  Future<Sale> get(int id) async => (await _api.get(
    '/sales/$id',
    parse: (d) => Sale.fromJson(d as Json),
  )).data;

  @override
  Future<Paginated<SaleSummary>> upcoming({int page = 1}) => _api.getPage(
    '/sales/upcoming-deliveries',
    page: page,
    item: SaleSummary.fromJson,
  );

  static Sale _sale(Object? d) => Sale.fromJson(d as Json);

  (Sale, String) _pair(ApiResponse<Sale> r) => (r.data, r.message);

  @override
  Future<(Sale, String)> create(SaleInput input) async =>
      _pair(await _api.post('/sales', body: input.toJson(), parse: _sale));

  @override
  Future<(Sale, String)> update(int id, SaleInput input) async => _pair(
    await _api.put(
      '/sales/$id',
      body: input.toJson(forEdit: true),
      parse: _sale,
    ),
  );

  @override
  Future<String> delete(int id) async =>
      (await _api.delete('/sales/$id', parse: (d) => d)).message;

  @override
  Future<(Sale, String)> deliver(int id, {String? deliveredDate}) async =>
      _pair(
        await _api.post(
          '/sales/$id/deliver',
          body: {'delivered_date': ?deliveredDate},
          parse: _sale,
        ),
      );

  @override
  Future<(Sale, String)> cancel(int id) async =>
      _pair(await _api.post('/sales/$id/cancel', parse: _sale));

  @override
  Future<(Sale, String)> addPayment(int id, PaymentInput payment) async =>
      _pair(
        await _api.post(
          '/sales/$id/payments',
          body: payment.toJson(),
          parse: _sale,
        ),
      );

  @override
  Future<(Sale, String)> deletePayment(int id, int paymentId) async =>
      _pair(await _api.delete('/sales/$id/payments/$paymentId', parse: _sale));
}

final salesRepositoryProvider = Provider<SalesRepository>(
  (ref) => SalesRepositoryImpl(ref.watch(apiClientProvider)),
);
