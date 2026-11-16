import 'package:flutter/foundation.dart';

import '../../../core/network/api_response.dart';
import '../../../core/utils/dates.dart';
import '../../wages/domain/wages.dart';

/// The six reports (01-PRD §5.10). [path] is the API path and the route
/// (`/reports/<path>`).
enum ReportType {
  sales('sales'),
  dues('dues'),
  expenses('expenses'),
  wages('wages'),
  netProfit('net-profit'),
  collections('collections');

  const ReportType(this.path);
  final String path;

  static ReportType? fromPath(String? path) {
    for (final t in values) {
      if (t.path == path) return t;
    }
    return null;
  }

  /// Wages are per month; dues have no period; the rest use a date range.
  bool get usesRange => this != wages && this != dues;
}

/// Period presets of the report screen (03-AppFlow §9).
enum ReportPeriod { today, thisWeek, thisMonth, lastMonth, thisYear, custom }

/// The range of a preset, from the factory's [today].
DateRange reportRange(ReportPeriod p, String today) => switch (p) {
  ReportPeriod.today => DateRange.preset(DatePreset.today, today),
  ReportPeriod.thisWeek => DateRange.preset(DatePreset.thisWeek, today),
  ReportPeriod.thisMonth => DateRange.preset(DatePreset.thisMonth, today),
  ReportPeriod.lastMonth => DateRange.preset(DatePreset.lastMonth, today),
  ReportPeriod.thisYear => DateRange(
    from: '${today.substring(0, 4)}-01-01',
    to: today,
  ),
  ReportPeriod.custom => const DateRange(),
};

String _s(Object? v, [String fallback = '0.00']) => v == null ? fallback : '$v';

List<T> _list<T>(Object? v, T Function(Json) f) => [
  for (final e in (v as List<Object?>? ?? const [])) f(e! as Json),
];

/// A value for one day (charts).
@immutable
class DayAmount {
  const DayAmount(this.date, this.amount);
  final String date;
  final String amount;
  factory DayAmount.fromJson(Json j) =>
      DayAmount(j['date'] as String? ?? '', _s(j['amount']));
}

@immutable
class SalesReport {
  const SalesReport({
    required this.from,
    required this.to,
    required this.count,
    required this.amount,
    required this.byProduct,
    required this.daily,
  });

  final String from;
  final String to;
  final int count;
  final String amount;
  final List<ProductSales> byProduct;
  final List<DayAmount> daily;

  factory SalesReport.fromJson(Json j) => SalesReport(
    from: j['from'] as String? ?? '',
    to: j['to'] as String? ?? '',
    count: (j['count'] as num?)?.toInt() ?? 0,
    amount: _s(j['amount']),
    byProduct: _list(j['by_product'], ProductSales.fromJson),
    daily: _list(j['daily'], DayAmount.fromJson),
  );
}

@immutable
class ProductSales {
  const ProductSales(this.name, this.quantity, this.amount);
  final String name;
  final String quantity;
  final String amount;
  factory ProductSales.fromJson(Json j) => ProductSales(
    j['product_name'] as String? ?? '',
    _s(j['quantity'], '0'),
    _s(j['amount']),
  );
}

/// One customer with dues.
@immutable
class DueRow {
  const DueRow({
    required this.customerId,
    required this.name,
    required this.phone,
    required this.totalDue,
    required this.oldestDueDate,
    required this.salesCount,
  });

  final String customerId;
  final String name;
  final String phone;
  final String totalDue;
  final String oldestDueDate;
  final int salesCount;

  factory DueRow.fromJson(Json j) => DueRow(
    customerId: idOf(j['customer_id']),
    name: j['name'] as String? ?? '',
    phone: j['phone'] as String? ?? '',
    totalDue: _s(j['total_due']),
    oldestDueDate: j['oldest_due_date'] as String? ?? '',
    salesCount: (j['sales_count'] as num?)?.toInt() ?? 0,
  );
}

@immutable
class DuesReport {
  const DuesReport({required this.rows, required this.grandTotal});
  final List<DueRow> rows;
  final String grandTotal;
}

@immutable
class ExpenseReport {
  const ExpenseReport({
    required this.from,
    required this.to,
    required this.total,
    required this.byCategory,
  });

  final String from;
  final String to;
  final String total;
  final List<CategoryAmount> byCategory;

  factory ExpenseReport.fromJson(Json j) => ExpenseReport(
    from: j['from'] as String? ?? '',
    to: j['to'] as String? ?? '',
    total: _s(j['total']),
    byCategory: _list(j['by_category'], CategoryAmount.fromJson),
  );
}

@immutable
class CategoryAmount {
  const CategoryAmount(this.name, this.amount, this.percent);
  final String name;
  final String amount;
  final double percent;
  factory CategoryAmount.fromJson(Json j) => CategoryAmount(
    j['name'] as String? ?? '',
    _s(j['amount']),
    (j['percent'] as num?)?.toDouble() ?? 0,
  );
}

@immutable
class WageReport {
  const WageReport({
    required this.month,
    required this.earned,
    required this.paid,
    required this.balance,
    required this.rows,
  });

  final String month;
  final String earned;
  final String paid;
  final String balance;
  final List<WageRow> rows;

  factory WageReport.fromJson(Json j) => WageReport(
    month: j['month'] as String? ?? '',
    earned: _s(j['earned']),
    paid: _s(j['paid']),
    balance: _s(j['balance']),
    rows: _list(j['rows'], WageRow.fromJson),
  );
}

@immutable
class NetProfitReport {
  const NetProfitReport({
    required this.from,
    required this.to,
    required this.sales,
    required this.expenses,
    required this.wages,
    required this.netProfit,
    required this.monthly,
  });

  final String from;
  final String to;
  final String sales;
  final String expenses;
  final String wages;
  final String netProfit;
  final List<MonthProfit> monthly;

  factory NetProfitReport.fromJson(Json j) => NetProfitReport(
    from: j['from'] as String? ?? '',
    to: j['to'] as String? ?? '',
    sales: _s(j['sales']),
    expenses: _s(j['expenses']),
    wages: _s(j['wages']),
    netProfit: _s(j['net_profit']),
    monthly: _list(j['monthly'], MonthProfit.fromJson),
  );
}

@immutable
class MonthProfit {
  const MonthProfit({
    required this.month,
    required this.sales,
    required this.expenses,
    required this.wages,
    required this.netProfit,
  });
  final String month;
  final String sales;
  final String expenses;
  final String wages;
  final String netProfit;
  factory MonthProfit.fromJson(Json j) => MonthProfit(
    month: j['month'] as String? ?? '',
    sales: _s(j['sales']),
    expenses: _s(j['expenses']),
    wages: _s(j['wages']),
    netProfit: _s(j['net_profit']),
  );
}

@immutable
class CollectionsReport {
  const CollectionsReport({
    required this.from,
    required this.to,
    required this.total,
    required this.byMethod,
    required this.daily,
  });

  final String from;
  final String to;
  final String total;
  final List<MethodAmount> byMethod;
  final List<DayAmount> daily;

  factory CollectionsReport.fromJson(Json j) => CollectionsReport(
    from: j['from'] as String? ?? '',
    to: j['to'] as String? ?? '',
    total: _s(j['total']),
    byMethod: _list(j['by_method'], MethodAmount.fromJson),
    daily: _list(j['daily'], DayAmount.fromJson),
  );
}

@immutable
class MethodAmount {
  const MethodAmount(this.method, this.amount);
  final String method;
  final String amount;
  factory MethodAmount.fromJson(Json j) =>
      MethodAmount(j['method'] as String? ?? 'cash', _s(j['amount']));
}

/// Reports API (07-API §14). Methods throw a `Failure` on error.
abstract interface class ReportsRepository {
  Future<SalesReport> sales(DateRange range);
  Future<ExpenseReport> expenses(DateRange range);
  Future<NetProfitReport> netProfit(DateRange range);
  Future<CollectionsReport> collections(DateRange range);
  Future<WageReport> wages(String month);

  /// Every customer with dues (all pages).
  Future<DuesReport> dues();
}
