import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/app_bar_actions.dart';
import '../../../../core/router/app_shell.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/cards.dart';
import '../../../../core/widgets/page_layout.dart';
import '../../domain/reports.dart';

/// Reports grid (03-AppFlow §9): one tile per report → `/reports/<type>`.
class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final tiles = [
      (
        ReportType.sales,
        Icons.trending_up,
        l.reportSales,
        l.reportSalesHint,
        KpiTint.sky,
      ),
      (
        ReportType.dues,
        Icons.account_balance_wallet_outlined,
        l.reportDues,
        l.reportDuesHint,
        KpiTint.rose,
      ),
      (
        ReportType.expenses,
        Icons.receipt_long_outlined,
        l.reportExpenses,
        l.reportExpensesHint,
        KpiTint.amber,
      ),
      (
        ReportType.wages,
        Icons.engineering_outlined,
        l.reportWages,
        l.reportWagesHint,
        KpiTint.green,
      ),
      (
        ReportType.netProfit,
        Icons.savings_outlined,
        l.reportNetProfit,
        l.reportNetProfitHint,
        KpiTint.green,
      ),
      (
        ReportType.collections,
        Icons.payments_outlined,
        l.reportCollections,
        l.reportCollectionsHint,
        KpiTint.sky,
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        leading: ShellMenuButton.maybe(context),
        title: Text(l.navReports),
        actions: const [AppBarActions()],
      ),
      body: PageBody(
        maxWidth: 960,
        children: [
          LayoutBuilder(
            builder: (context, box) {
              final cols = box.maxWidth >= Breakpoints.medium ? 3 : 2;
              final width = (box.maxWidth - Space.s3 * (cols - 1)) / cols;
              return Wrap(
                spacing: Space.s3,
                runSpacing: Space.s3,
                children: [
                  for (final (type, icon, title, hint, tint) in tiles)
                    SizedBox(
                      width: width,
                      child: _ReportTile(
                        key: Key('reportTile-${type.path}'),
                        icon: icon,
                        title: title,
                        hint: hint,
                        tint: tint,
                        onTap: () => context.push('/reports/${type.path}'),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({
    super.key,
    required this.icon,
    required this.title,
    required this.hint,
    required this.tint,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String hint;
  final KpiTint tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final (fg, bg) = kpiTintColors(t, tint);
    return AppCard(
      onTap: onTap,
      child: SizedBox(
        // Icon (40) + gap (12) + title and 2 hint lines, which grow with the
        // font size setting; all tiles stay the same height.
        height: 52 + MediaQuery.textScalerOf(context).scale(64),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: bg, borderRadius: Radii.mdAll),
              child: Icon(icon, color: fg, size: 22),
            ),
            const SizedBox(height: Space.s3),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.title.copyWith(color: t.textPrimary),
            ),
            const SizedBox(height: 2),
            Text(
              hint,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(color: t.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
