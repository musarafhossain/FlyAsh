import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../sales/presentation/sale_labels.dart';
import '../../domain/wages.dart';

/// "26 days" (days present).
String daysText(AppLocalizations l, int presentDays) =>
    l.daysWorked(Fmt.count('$presentDays'));

/// Balance in red while something is owed; "—" when settled.
class BalanceText extends StatelessWidget {
  const BalanceText(this.row, {super.key, this.big = false});

  final WageRow row;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final style = big ? AppTypography.title : AppTypography.bodyStrong;
    return Text(
      row.hasBalance ? Fmt.money(row.balance) : '—',
      style: style.copyWith(
        color: row.hasBalance ? t.error : t.textTertiary,
        fontFeatures: AppTypography.tabular,
      ),
    );
  }
}

/// Pill for a wage status: Paid / Partial / Due.
class WageStatusPill extends StatelessWidget {
  const WageStatusPill(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) => StatusPill(
    context.l10n.paymentStatusText(status),
    tone: StatusPill.toneFor(status),
  );
}
