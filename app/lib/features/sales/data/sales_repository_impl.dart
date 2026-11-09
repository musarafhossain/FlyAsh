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
}

final salesRepositoryProvider = Provider<SalesRepository>(
  (ref) => SalesRepositoryImpl(ref.watch(apiClientProvider)),
);
