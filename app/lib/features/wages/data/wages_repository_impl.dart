import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../domain/wages.dart';

class WagesRepositoryImpl implements WagesRepository {
  WagesRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<Paginated<WageRow>> sheet({
    required String month,
    int page = 1,
    String? search,
  }) => _api.getPage(
    '/wages',
    page: page,
    query: {'month': month, 'search': search?.trim()},
    item: WageRow.fromJson,
  );

  @override
  Future<WageDetail> detail(String labourId, String month) async {
    final res = await _api.get(
      '/labours/$labourId/wages',
      query: {'month': month},
      parse: (d) => WageDetail.fromJson(d as Json),
    );
    return res.data;
  }

  @override
  Future<String> pay(
    String labourId, {
    required String month,
    required String amount,
    required String date,
    String method = 'cash',
    String? note,
  }) async => (await _api.post(
    '/labours/$labourId/wage-payments',
    body: {
      'wage_month': month,
      'amount': amount,
      'payment_date': date,
      'method': method,
      'note': note,
    },
    parse: (d) => d,
  )).message;

  @override
  Future<String> deletePayment(String id) async =>
      (await _api.delete('/wage-payments/$id', parse: (d) => d)).message;
}

final wagesRepositoryProvider = Provider<WagesRepository>(
  (ref) => WagesRepositoryImpl(ref.watch(apiClientProvider)),
);
