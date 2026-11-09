import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../domain/dashboard.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<DashboardData> get() async => (await _api.get(
    '/dashboard',
    parse: (d) => DashboardData.fromJson(d as Json),
  )).data;
}

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepositoryImpl(ref.watch(apiClientProvider)),
);
