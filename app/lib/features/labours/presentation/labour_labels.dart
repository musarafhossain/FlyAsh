import '../../../core/l10n/l10n.dart';
import '../../../core/utils/formatters.dart';

/// Translated labour labels.
extension LabourLabels on AppLocalizations {
  /// "₹500 / day" or "₹15,000 / month".
  String wageText(String wageType, String amount) => wageType == 'monthly'
      ? perMonth(Fmt.money(amount))
      : perDay(Fmt.money(amount));

  /// "Present" or "Absent".
  String attendanceText(bool present) => present ? attPresent : attAbsent;
}
