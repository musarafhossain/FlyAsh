import 'package:flutter/foundation.dart';

import '../../../core/network/api_response.dart';
import '../../sales/domain/sale_summary.dart';

/// Every home-screen number from one call (GET /dashboard).
@immutable
class DashboardData {
  const DashboardData({
    required this.date,
    required this.todaySalesAmount,
    required this.todaySalesCount,
    required this.todayProfit,
    required this.totalDue,
    required this.deliveriesToday,
    required this.overdueDeliveries,
    required this.presentToday,
    required this.laboursTotal,
    required this.monthExpenses,
    this.recentSales = const [],
  });

  /// The factory's today.
  final String date;
  final String todaySalesAmount;
  final int todaySalesCount;
  final String todayProfit;
  final String totalDue;
  final int deliveriesToday;
  final int overdueDeliveries;
  final int presentToday;
  final int laboursTotal;
  final String monthExpenses;

  /// The last 5 sales.
  final List<SaleSummary> recentSales;

  factory DashboardData.fromJson(Json json) {
    final today = json['today_sales'] as Json? ?? const {};
    int n(Object? v) => (v as num?)?.toInt() ?? 0;
    String m(Object? v) => '${v ?? '0.00'}';
    return DashboardData(
      date: json['date'] as String? ?? '',
      todaySalesAmount: m(today['amount']),
      todaySalesCount: n(today['count']),
      todayProfit: m(json['today_profit']),
      totalDue: m(json['total_due']),
      deliveriesToday: n(json['deliveries_today']),
      overdueDeliveries: n(json['overdue_deliveries']),
      presentToday: n(json['present_today']),
      laboursTotal: n(json['labours_total']),
      monthExpenses: m(json['month_expenses']),
      recentSales: [
        for (final s in (json['recent_sales'] as List<Object?>? ?? const []))
          SaleSummary.fromJson(s! as Json),
      ],
    );
  }
}

/// Dashboard API. Throws a `Failure` on error.
abstract interface class DashboardRepository {
  Future<DashboardData> get();
}
