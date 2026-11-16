import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../../core/utils/dates.dart';
import '../domain/reports.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  ReportsRepositoryImpl(this._api);

  final ApiClient _api;

  Future<T> _get<T>(String path, Json query, T Function(Json) parse) async =>
      (await _api.get(path, query: query, parse: (d) => parse(d as Json))).data;

  Json _range(DateRange r) => {'from': r.from, 'to': r.to};

  @override
  Future<SalesReport> sales(DateRange range) =>
      _get('/reports/sales', _range(range), SalesReport.fromJson);

  @override
  Future<ExpenseReport> expenses(DateRange range) =>
      _get('/reports/expenses', _range(range), ExpenseReport.fromJson);

  @override
  Future<NetProfitReport> netProfit(DateRange range) =>
      _get('/reports/net-profit', _range(range), NetProfitReport.fromJson);

  @override
  Future<CollectionsReport> collections(DateRange range) =>
      _get('/reports/collections', _range(range), CollectionsReport.fromJson);

  @override
  Future<WageReport> wages(String month) =>
      _get('/reports/wages', {'month': month}, WageReport.fromJson);

  @override
  Future<DuesReport> dues() async {
    final rows = <DueRow>[];
    var grand = '0.00';
    for (var page = 1; ; page++) {
      final p = await _api.getPage(
        '/reports/dues',
        page: page,
        limit: 100,
        item: DueRow.fromJson,
      );
      rows.addAll(p.items);
      grand = '${p.extra['grand_total'] ?? grand}';
      if (!p.hasMore) break;
    }
    return DuesReport(rows: rows, grandTotal: grand);
  }
}

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ReportsRepositoryImpl(ref.watch(apiClientProvider)),
);
