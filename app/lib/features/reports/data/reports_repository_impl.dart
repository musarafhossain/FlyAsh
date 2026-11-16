import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../../core/utils/dates.dart';
import '../domain/reports.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  ReportsRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<NetProfitReport> netProfit(DateRange range) async => (await _api.get(
    '/reports/net-profit',
    query: {'from': range.from, 'to': range.to},
    parse: (d) => NetProfitReport.fromJson(d as Json),
  )).data;
}

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ReportsRepositoryImpl(ref.watch(apiClientProvider)),
);
