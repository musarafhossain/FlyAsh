import 'package:flutter/foundation.dart';

import '../../../core/network/api_response.dart';

/// Attendance statuses, in the order of the P / H / A toggle.
const kAttendanceStatuses = ['present', 'half_day', 'absent'];

/// One labour on the attendance sheet.
@immutable
class AttendanceEntry {
  const AttendanceEntry({
    required this.labourId,
    required this.name,
    required this.wageType,
    required this.wageAmount,
    this.status,
  });

  final String labourId;
  final String name;
  final String wageType;
  final String wageAmount;

  /// present | half_day | absent | null (not marked)
  final String? status;

  factory AttendanceEntry.fromJson(Json json) => AttendanceEntry(
    labourId: idOf(json['labour_id']),
    name: json['name'] as String? ?? '',
    wageType: json['wage_type'] as String? ?? 'daily',
    wageAmount: '${json['wage_amount'] ?? '0'}',
    status: json['status'] as String?,
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

  /// PUT /attendance → the saved day and the message. A null status clears
  /// that labour's day.
  Future<(AttendanceDay, String)> save(String date, Map<String, String?> statuses);
}
