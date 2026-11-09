import 'package:flutter/foundation.dart';

import '../../../core/network/api_response.dart';

/// A worker with a daily or monthly wage (07-API §10).
@immutable
class Labour {
  const Labour({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    required this.wageType,
    required this.wageAmount,
    required this.joiningDate,
    this.leftDate,
    this.isActive = true,
    this.todayStatus,
  });

  final String id;
  final String name;
  final String? phone;
  final String? address;

  /// daily | monthly
  final String wageType;

  /// ₹ per day or per month ("450.00").
  final String wageAmount;
  final String joiningDate;
  final String? leftDate;
  final bool isActive;

  /// present | half_day | absent | null (not marked today)
  final String? todayStatus;

  bool get isMonthly => wageType == 'monthly';

  factory Labour.fromJson(Json json) => Labour(
    id: idOf(json['id']),
    name: json['name'] as String? ?? '',
    phone: json['phone'] as String?,
    address: json['address'] as String?,
    wageType: json['wage_type'] as String? ?? 'daily',
    wageAmount: '${json['wage_amount'] ?? '0'}',
    joiningDate: json['joining_date'] as String? ?? '',
    leftDate: json['left_date'] as String?,
    isActive: json['is_active'] as bool? ?? true,
    todayStatus: json['today_status'] as String?,
  );
}

/// What the labour form sends. Money is a decimal string.
@immutable
class LabourInput {
  const LabourInput({
    required this.name,
    this.phone,
    this.address,
    required this.wageType,
    required this.wageAmount,
    required this.joiningDate,
  });

  final String name;
  final String? phone;
  final String? address;
  final String wageType;
  final String wageAmount;
  final String joiningDate;

  Json toJson() => {
    'name': name.trim(),
    'phone': phone,
    'address': address,
    'wage_type': wageType,
    'wage_amount': wageAmount,
    'joining_date': joiningDate,
  };
}

/// One labour's month: the status of every day (GET /labours/:id/attendance).
@immutable
class LabourMonth {
  const LabourMonth({
    required this.month,
    required this.days,
    required this.present,
    required this.halfDay,
    required this.absent,
  });

  /// "2026-11"
  final String month;

  /// date → status (null = not marked)
  final Map<String, String?> days;
  final int present;
  final int halfDay;
  final int absent;

  factory LabourMonth.fromJson(Json json) {
    final summary = json['summary'] as Json? ?? const {};
    int n(String k) => (summary[k] as num?)?.toInt() ?? 0;
    return LabourMonth(
      month: json['month'] as String? ?? '',
      days: {
        for (final d in (json['days'] as List<Object?>? ?? const []))
          (d! as Json)['date']! as String: (d as Json)['status'] as String?,
      },
      present: n('present'),
      halfDay: n('half_day'),
      absent: n('absent'),
    );
  }
}

/// Labours API (07-API §10). Methods throw a `Failure` on error.
abstract interface class LaboursRepository {
  /// GET /labours?page&search&active (each with today's status)
  Future<Paginated<Labour>> list({int page = 1, String? search, bool? active});

  Future<Labour> get(String id);

  Future<Labour> create(LabourInput input);

  /// New wage applies to attendance saved from now on.
  Future<Labour> update(String id, LabourInput input);

  /// PATCH /labours/:id/status; deactivating sets the leaving date.
  Future<(Labour, String)> setActive(String id, bool active, {String? leftDate});

  /// GET /labours/:id/attendance?month=YYYY-MM
  Future<LabourMonth> month(String id, String month);
}
