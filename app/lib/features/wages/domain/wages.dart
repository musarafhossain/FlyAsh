import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_response.dart';

Decimal _d(String v) => Decimal.tryParse(v) ?? Decimal.zero;

/// One labour's wage for a month (07-API §12):
/// earned = worked days × daily rate (monthly wage ÷ days in month);
/// balance = earned − paid for the month (a payment covers advances too).
@immutable
class WageRow {
  const WageRow({
    required this.labourId,
    required this.name,
    required this.wageType,
    required this.wageAmount,
    this.isActive = true,
    required this.presentDays,
    required this.absentDays,
    required this.earned,
    required this.paid,
    required this.balance,
    required this.status,
  });

  final String labourId;
  final String name;
  final String wageType;
  final String wageAmount;
  final bool isActive;
  final int presentDays;

  /// Employed days so far in the month without a present mark.
  final int absentDays;
  final String earned;

  final String paid;
  final String balance;

  /// due | partial | paid
  final String status;

  bool get hasBalance => _d(balance) > Decimal.zero;

  factory WageRow.fromJson(Json json) {
    int n(String k) => (json[k] as num?)?.toInt() ?? 0;
    String m(String k) => '${json[k] ?? '0'}';
    return WageRow(
      labourId: idOf(json['labour_id']),
      name: json['name'] as String? ?? '',
      wageType: json['wage_type'] as String? ?? 'daily',
      wageAmount: m('wage_amount'),
      isActive: json['is_active'] as bool? ?? true,
      presentDays: n('present_days'),
      absentDays: n('absent_days'),
      earned: m('earned'),
      paid: m('paid'),
      balance: m('balance'),
      status: json['status'] as String? ?? 'due',
    );
  }
}

/// Totals of the whole month's wage sheet.
@immutable
class WageTotals {
  const WageTotals({
    this.earned = '0.00',
    this.paid = '0.00',
    this.balance = '0.00',
  });

  final String earned;
  final String paid;
  final String balance;

  factory WageTotals.fromJson(Json? json) => json == null
      ? const WageTotals()
      : WageTotals(
          earned: '${json['earned'] ?? '0.00'}',
          paid: '${json['paid'] ?? '0.00'}',
          balance: '${json['balance'] ?? '0.00'}',
        );
}

/// Wages paid for a month.
@immutable
class WagePayment {
  const WagePayment({
    required this.id,
    required this.amount,
    required this.date,
    required this.method,
    this.note,
    this.createdBy,
  });

  final String id;
  final String amount;
  final String date;
  final String method;
  final String? note;
  final String? createdBy;

  factory WagePayment.fromJson(Json json) => WagePayment(
    id: idOf(json['id']),
    amount: '${json['amount'] ?? '0'}',
    date: json['payment_date'] as String? ?? '',
    method: json['method'] as String? ?? 'cash',
    note: json['note'] as String?,
    createdBy: (json['created_by'] as Json?)?['name'] as String?,
  );
}

/// One day of the month with what it earned.
@immutable
class WageDay {
  const WageDay({required this.date, required this.earned});

  /// A present day.
  final String date;
  final String earned;

  factory WageDay.fromJson(Json json) => WageDay(
    date: json['date'] as String? ?? '',
    earned: '${json['earned'] ?? '0'}',
  );
}

/// GET /labours/:id/wages: the row plus days and payments.
@immutable
class WageDetail {
  const WageDetail({
    required this.row,
    required this.month,
    this.days = const [],
    this.payments = const [],
  });

  final WageRow row;
  final String month;
  final List<WageDay> days;
  final List<WagePayment> payments;

  factory WageDetail.fromJson(Json json) {
    return WageDetail(
      row: WageRow.fromJson(json),
      month: json['month'] as String? ?? '',
      days: [
        for (final d in (json['days'] as List<Object?>? ?? const []))
          WageDay.fromJson(d! as Json),
      ],
      payments: [
        for (final p in (json['payments'] as List<Object?>? ?? const []))
          WagePayment.fromJson(p! as Json),
      ],
    );
  }
}

/// Wages API (07-API §12). Methods throw a `Failure` on error.
abstract interface class WagesRepository {
  /// GET /wages?month&page&search → rows; `extra` has `totals`.
  Future<Paginated<WageRow>> sheet({
    required String month,
    int page = 1,
    String? search,
  });

  /// GET /labours/:id/wages?month
  Future<WageDetail> detail(String labourId, String month);

  /// POST /labours/:id/wage-payments → message (partial payments allowed)
  Future<String> pay(
    String labourId, {
    required String month,
    required String amount,
    required String date,
    String method = 'cash',
    String? note,
  });

  /// DELETE /wage-payments/:id → message
  Future<String> deletePayment(String id);
}
