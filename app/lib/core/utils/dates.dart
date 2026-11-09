import 'package:flutter/foundation.dart';

/// Business dates as "YYYY-MM-DD" strings (02-TRD §4.3). Calculations use
/// UTC DateTimes so a timezone or DST change never shifts a day.
abstract final class Ymd {
  static DateTime parse(String ymd) {
    final p = ymd.split('-').map(int.parse).toList();
    return DateTime.utc(p[0], p[1], p[2]);
  }

  static String format(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String addDays(String ymd, int days) =>
      format(parse(ymd).add(Duration(days: days)));

  /// Monday of the week that contains [ymd].
  static String weekStart(String ymd) {
    final d = parse(ymd);
    return format(d.subtract(Duration(days: d.weekday - 1)));
  }

  static String monthStart(String ymd) {
    final d = parse(ymd);
    return format(DateTime.utc(d.year, d.month));
  }

  static String monthEnd(String ymd) {
    final d = parse(ymd);
    return format(DateTime.utc(d.year, d.month + 1, 0));
  }

  /// [ymd] moved by whole months, clamped to the month's last day.
  static String addMonths(String ymd, int months) {
    final d = parse(ymd);
    final first = DateTime.utc(d.year, d.month + months);
    final last = DateTime.utc(first.year, first.month + 1, 0).day;
    return format(DateTime.utc(first.year, first.month, d.day.clamp(1, last)));
  }
}

/// Quick choices for a date range, worked out from the factory's today.
enum DatePreset { today, yesterday, thisWeek, thisMonth, lastMonth, custom }

/// An inclusive range of business dates (either end may be open).
@immutable
class DateRange {
  const DateRange({this.from, this.to});

  final String? from;
  final String? to;

  bool get isEmpty => from == null && to == null;

  static DateRange preset(DatePreset preset, String today) => switch (preset) {
    DatePreset.today => DateRange(from: today, to: today),
    DatePreset.yesterday => DateRange(
      from: Ymd.addDays(today, -1),
      to: Ymd.addDays(today, -1),
    ),
    DatePreset.thisWeek => DateRange(from: Ymd.weekStart(today), to: today),
    DatePreset.thisMonth => DateRange(from: Ymd.monthStart(today), to: today),
    DatePreset.lastMonth => DateRange(
      from: Ymd.monthStart(Ymd.addMonths(Ymd.monthStart(today), -1)),
      to: Ymd.monthEnd(Ymd.addMonths(Ymd.monthStart(today), -1)),
    ),
    DatePreset.custom => const DateRange(),
  };

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}
