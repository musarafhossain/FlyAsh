import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../domain/labour.dart';

class LaboursRepositoryImpl implements LaboursRepository {
  LaboursRepositoryImpl(this._api);

  final ApiClient _api;

  static Labour _labour(Object? d) => Labour.fromJson(d as Json);

  @override
  Future<Paginated<Labour>> list({
    int page = 1,
    String? search,
    bool? active,
  }) => _api.getPage(
    '/labours',
    page: page,
    query: {'search': search?.trim(), 'active': active},
    item: Labour.fromJson,
  );

  @override
  Future<Labour> get(int id) async =>
      (await _api.get('/labours/$id', parse: _labour)).data;

  @override
  Future<Labour> create(LabourInput input) async =>
      (await _api.post('/labours', body: input.toJson(), parse: _labour)).data;

  @override
  Future<Labour> update(int id, LabourInput input) async => (await _api.put(
    '/labours/$id',
    body: input.toJson(),
    parse: _labour,
  )).data;

  @override
  Future<(Labour, String)> setActive(
    int id,
    bool active, {
    String? leftDate,
  }) async {
    final res = await _api.patch(
      '/labours/$id/status',
      body: {'is_active': active, 'left_date': ?leftDate},
      parse: _labour,
    );
    return (res.data, res.message);
  }

  @override
  Future<LabourMonth> month(int id, String month) async {
    final res = await _api.get(
      '/labours/$id/attendance',
      query: {'month': month},
      parse: (d) => LabourMonth.fromJson(d as Json),
    );
    return res.data;
  }
}

final laboursRepositoryProvider = Provider<LaboursRepository>(
  (ref) => LaboursRepositoryImpl(ref.watch(apiClientProvider)),
);
