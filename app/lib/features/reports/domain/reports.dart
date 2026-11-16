import 'package:flutter/foundation.dart';

import '../../../core/network/api_response.dart';
import '../../../core/utils/dates.dart';

/// Reports = the net profit report only (03-AppFlow §9, changed on
/// 2026-11-16: the other five reports were removed from the app).

/// Period chips of the report.
enum ReportPeriod { today, last7Days, thisMonth, lastMonth, thisYear, custom }

/// The range of a preset, from the factory's [today].
DateRange reportRange(ReportPeriod p, String today) => switch (p) {
  ReportPeriod.today => DateRange.preset(DatePreset.today, today),
  // Today and the 6 days before (a calendar week would be only "today" on
  // a Monday).
  ReportPeriod.last7Days => DateRange(from: Ymd.addDays(today, -6), to: today),
  ReportPeriod.thisMonth => DateRange.preset(DatePreset.thisMonth, today),
  ReportPeriod.lastMonth => DateRange.preset(DatePreset.lastMonth, today),
  ReportPeriod.thisYear => DateRange(
    from: '${today.substring(0, 4)}-01-01',
    to: today,
  ),
  ReportPeriod.custom => const DateRange(),
};

String _s(Object? v) => '${v ?? '0'}';

/// `GET /reports/net-profit`: sales (with tax) − expenses − wages paid.
@immutable
class NetProfitReport {
  const NetProfitReport({
    required this.from,
    required this.to,
    required this.sales,
    required this.expenses,
    required this.wagesPaid,
    required this.netProfit,
    required this.monthly,
  });

  final String from;
  final String to;

  /// Sales with tax (delivered in the period).
  final String sales;
  final String expenses;
  final String wagesPaid;
  final String netProfit;
  final List<MonthProfit> monthly;

  factory NetProfitReport.fromJson(Json j) => NetProfitReport(
    from: j['from'] as String? ?? '',
    to: j['to'] as String? ?? '',
    sales: _s(j['sales']),
    expenses: _s(j['expenses']),
    wagesPaid: _s(j['wages_paid']),
    netProfit: _s(j['net_profit']),
    monthly: [
      for (final m in (j['monthly'] as List<Object?>? ?? const []))
        MonthProfit.fromJson(m! as Json),
    ],
  );
}

/// One month of [NetProfitReport.monthly].
@immutable
class MonthProfit {
  const MonthProfit({
    required this.month,
    required this.sales,
    required this.expenses,
    required this.wagesPaid,
    required this.netProfit,
  });

  /// "2026-11".
  final String month;
  final String sales;
  final String expenses;
  final String wagesPaid;
  final String netProfit;

  factory MonthProfit.fromJson(Json j) => MonthProfit(
    month: j['month'] as String? ?? '',
    sales: _s(j['sales']),
    expenses: _s(j['expenses']),
    wagesPaid: _s(j['wages_paid']),
    netProfit: _s(j['net_profit']),
  );
}

abstract interface class ReportsRepository {
  /// Throws a `Failure` on error.
  Future<NetProfitReport> netProfit(DateRange range);
}
