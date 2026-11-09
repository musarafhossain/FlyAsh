import 'package:flutter_test/flutter_test.dart';

import 'package:flyash/core/utils/dates.dart';

void main() {
  group('Ymd', () {
    test('adds days across months and years', () {
      expect(Ymd.addDays('2026-11-30', 1), '2026-12-01');
      expect(Ymd.addDays('2026-01-01', -1), '2025-12-31');
      expect(Ymd.addDays('2028-02-28', 1), '2028-02-29'); // leap year
    });

    test('week starts on Monday', () {
      expect(Ymd.weekStart('2026-11-09'), '2026-11-09'); // a Monday
      expect(Ymd.weekStart('2026-11-15'), '2026-11-09'); // Sunday
      expect(Ymd.weekStart('2026-11-01'), '2026-10-26'); // crosses month
    });

    test('month start/end and adding months clamps the day', () {
      expect(Ymd.monthStart('2026-11-09'), '2026-11-01');
      expect(Ymd.monthEnd('2026-02-10'), '2026-02-28');
      expect(Ymd.monthEnd('2028-02-10'), '2028-02-29');
      expect(Ymd.addMonths('2026-03-31', -1), '2026-02-28');
      expect(Ymd.addMonths('2026-01-15', -1), '2025-12-15');
    });
  });

  group('DateRange.preset (factory today = 2026-11-09)', () {
    const today = '2026-11-09';
    DateRange p(DatePreset preset) => DateRange.preset(preset, today);

    test('each preset', () {
      expect(p(DatePreset.today), const DateRange(from: today, to: today));
      expect(
        p(DatePreset.yesterday),
        const DateRange(from: '2026-11-08', to: '2026-11-08'),
      );
      expect(
        p(DatePreset.thisWeek),
        const DateRange(from: '2026-11-09', to: today),
      );
      expect(
        p(DatePreset.thisMonth),
        const DateRange(from: '2026-11-01', to: today),
      );
      expect(
        p(DatePreset.lastMonth),
        const DateRange(from: '2026-10-01', to: '2026-10-31'),
      );
      expect(p(DatePreset.custom).isEmpty, isTrue);
    });

    test('last month in January is December of the previous year', () {
      expect(
        DateRange.preset(DatePreset.lastMonth, '2027-01-05'),
        const DateRange(from: '2026-12-01', to: '2026-12-31'),
      );
    });
  });
}
