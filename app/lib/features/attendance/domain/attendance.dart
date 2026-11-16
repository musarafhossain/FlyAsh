import 'package:flutter/foundation.dart';

import '../../../core/network/api_response.dart';

/// One labour on the attendance sheet.
@immutable
class AttendanceEntry {
  const AttendanceEntry({
    required this.labourId,
    required this.name,
    required this.wageType,
    required this.wageAmount,
    this.present = false,
    String? dayWage,
    String? defaultDayWage,
  }) : dayWage = dayWage ?? wageAmount,
       defaultDayWage = defaultDayWage ?? dayWage ?? wageAmount;

  final String labourId;
  final String name;
  final String wageType;
  final String wageAmount;

  /// Present = a row is saved for that day; absent = no row.
  final bool present;

  /// The wage for this day ("450.00"): the saved day's wage when present,
  /// else the labour's wage for one day (monthly ÷ days in the month).
  final String dayWage;

  /// The labour's usual wage for one day (also when this day was saved with
  /// another wage).
  final String defaultDayWage;

  factory AttendanceEntry.fromJson(Json json) => AttendanceEntry(
    labourId: idOf(json['labour_id']),
    name: json['name'] as String? ?? '',
    wageType: json['wage_type'] as String? ?? 'daily',
    wageAmount: '${json['wage_amount'] ?? '0'}',
    present: json['present'] == true,
    dayWage: json['day_wage'] == null ? null : '${json['day_wage']}',
    defaultDayWage: json['default_day_wage'] == null
        ? null
        : '${json['default_day_wage']}',
  );
}

/// The sheet for one day: every labour employed on that date.
@immutable
class AttendanceDay {
  const AttendanceDay({required this.date, required this.entries});

  final String date;
  final List<AttendanceEntry> entries;

  factory AttendanceDay.fromJson(Json json) => AttendanceDay(
    date: json['date'] as String? ?? '',
    entries: [
      for (final e in (json['items'] as List<Object?>? ?? const []))
        AttendanceEntry.fromJson(e! as Json),
    ],
  );
}

/// Attendance API (07-API §11). Methods throw a `Failure` on error.
abstract interface class AttendanceRepository {
  /// GET /attendance?date
  Future<AttendanceDay> day(String date);

  /// PUT /attendance: labour id → present (true) or absent (false).
  /// [wages]: labour id → that day's wage ("500" …), used when the labour
  /// is marked present (an edited wage). Returns the saved day.
  Future<AttendanceDay> save(
    String date,
    Map<String, bool> present, {
    Map<String, String> wages = const {},
  });
}
