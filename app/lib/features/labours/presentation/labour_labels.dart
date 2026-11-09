import '../../../core/l10n/l10n.dart';
import '../../../core/utils/formatters.dart';

/// Translated labour labels.
extension LabourLabels on AppLocalizations {
  /// "₹500 / day" or "₹15,000 / month".
  String wageText(String wageType, String amount) => wageType == 'monthly'
      ? perMonth(Fmt.money(amount))
      : perDay(Fmt.money(amount));

  /// present | half_day | absent | null
  String attendanceText(String? status) => switch (status) {
    'present' => attPresent,
    'half_day' => attHalfDay,
    'absent' => attAbsent,
    _ => attNotMarked,
  };

  /// One letter for the P / H / A toggle.
  String attendanceLetter(String status) => switch (status) {
    'present' => attPresentShort,
    'half_day' => attHalfDayShort,
    _ => attAbsentShort,
  };
}
