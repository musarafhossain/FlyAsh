import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../sales/domain/sale_summary.dart';
import '../domain/customer.dart';

class CustomersRepositoryImpl implements CustomersRepository {
  CustomersRepositoryImpl(this._api);

  final ApiClient _api;

  static Customer _customer(Object? d) => Customer.fromJson(d as Json);

  @override
  Future<Paginated<Customer>> list({
    int page = 1,
    String? search,
    bool? hasDue,
    bool? active,
  }) => _api.getPage(
    '/customers',
    page: page,
    query: {'search': search?.trim(), 'has_due': hasDue, 'active': active},
    item: Customer.fromJson,
  );

  @override
  Future<Customer> get(String id) async =>
      (await _api.get('/customers/$id', parse: _customer)).data;

  @override
  Future<Customer> create(CustomerInput input) async {
    final res = await _api.post(
      '/customers',
      body: input.toJson(),
      parse: _customer,
    );
    return res.data;
  }

  @override
  Future<Customer> update(String id, CustomerInput input) async {
    final res = await _api.put(
      '/customers/$id',
      body: input.toJson(),
      parse: _customer,
    );
    return res.data;
  }

  @override
  Future<(Customer, String)> setActive(String id, bool active) async {
    final res = await _api.patch(
      '/customers/$id/status',
      body: {'is_active': active},
      parse: _customer,
    );
    return (res.data, res.message);
  }

  @override
  Future<String> delete(String id) async =>
      (await _api.delete('/customers/$id', parse: (d) => d)).message;

  @override
  Future<Paginated<SaleSummary>> sales(String id, {int page = 1}) => _api.getPage(
    '/customers/$id/sales',
    page: page,
    item: SaleSummary.fromJson,
  );
}

final customersRepositoryProvider = Provider<CustomersRepository>(
  (ref) => CustomersRepositoryImpl(ref.watch(apiClientProvider)),
);
