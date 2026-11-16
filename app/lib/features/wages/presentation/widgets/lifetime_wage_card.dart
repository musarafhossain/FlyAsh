import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/cards.dart';
import '../../../../core/widgets/motion.dart';

/// "Total wage (all time)": earned · paid · balance since the labour
/// joined (labour detail and wage detail pages).
class LifetimeWageCard extends StatelessWidget {
  const LifetimeWageCard({
    super.key,
    required this.earned,
    required this.paid,
    required this.balance,
  });

  final String earned;
  final String paid;
  final String balance;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final owed = (double.tryParse(balance) ?? 0) > 0;
    Widget cell(String label, String value, Color color) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(color: t.textSecondary),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: CountUpText(
              Fmt.money(value),
              style: AppTypography.bodyStrong.copyWith(
                color: color,
                fontFeatures: AppTypography.tabular,
              ),
            ),
          ),
        ],
      ),
    );
    return AppCard(
      key: const Key('lifetimeWageCard'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.totalWageAllTime,
            style: AppTypography.title.copyWith(color: t.textPrimary),
          ),
          const SizedBox(height: Space.s3),
          Row(
            children: [
              cell(l.earned, earned, t.textPrimary),
              const SizedBox(width: Space.s3),
              cell(l.paid, paid, t.success),
              const SizedBox(width: Space.s3),
              cell(l.balance, balance, owed ? t.error : t.textPrimary),
            ],
          ),
        ],
      ),
    );
  }
}
