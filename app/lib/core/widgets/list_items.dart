import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';
import '../utils/formatters.dart';
import 'cards.dart';
import 'status_pill.dart';

/// Circle with a person's initials ("Rahim Traders" → "RT").
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar(this.name, {super.key, this.size = 40});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: t.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Text(
        Fmt.initials(name),
        style: AppTypography.label.copyWith(
          color: t.onPrimaryContainer,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.34,
        ),
      ),
    );
  }
}

/// One row in a list of customers, sales, labours … (§9.7)
///
///   [avatar]  Title                      (pill)
///             Subtitle                   Trailing
///             Meta
class EntityListTile extends StatelessWidget {
  const EntityListTile({
    super.key,
    required this.title,
    this.leading,
    this.subtitle,
    this.meta,
    this.trailing,
    this.trailingTone,
    this.status,
    this.statusTone = StatusTone.neutral,
    this.onTap,
  });

  final String title;
  final Widget? leading;
  final String? subtitle;
  final String? meta;

  /// Right-aligned value, e.g. "₹33,500"
  final String? trailing;

  /// Color for the trailing value (e.g. error for a due amount)
  final Color? trailingTone;
  final String? status;
  final StatusTone statusTone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: Space.s4,
        vertical: Space.s3,
      ),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: Space.s3)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.title.copyWith(color: t.textPrimary),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: t.textSecondary,
                    ),
                  ),
                if (meta != null)
                  Text(
                    meta!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: t.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: Space.s2),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (status != null) StatusPill(status!, tone: statusTone),
              if (trailing != null) ...[
                if (status != null) const SizedBox(height: Space.s1),
                Text(
                  trailing!,
                  style: AppTypography.bodyStrong.copyWith(
                    color: trailingTone ?? t.textPrimary,
                    fontFeatures: AppTypography.tabular,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// One line in a summary card.
class SummaryLine {
  const SummaryLine(
    this.label,
    this.value, {
    this.icon,
    this.emphasis = false,
    this.color,
    this.dividerBefore = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final bool emphasis;
  final Color? color;
  final bool dividerBefore;
}

/// Label → amount rows with an optional total line (§9.12),
/// e.g. sale totals, wage breakdown.
class LineItemSummaryCard extends StatelessWidget {
  const LineItemSummaryCard({super.key, required this.lines, this.title});

  final String? title;
  final List<SummaryLine> lines;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: AppTypography.title.copyWith(color: t.textPrimary),
            ),
            const SizedBox(height: Space.s2),
          ],
          for (final line in lines) ...[
            if (line.dividerBefore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: Space.s2),
                child: Divider(),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.s1),
              child: Row(
                children: [
                  if (line.icon != null) ...[
                    Icon(line.icon, size: 18, color: t.textTertiary),
                    const SizedBox(width: Space.s2),
                  ],
                  Expanded(
                    child: Text(
                      line.label,
                      style:
                          (line.emphasis
                                  ? AppTypography.title
                                  : AppTypography.body)
                              .copyWith(
                                color: line.emphasis
                                    ? t.textPrimary
                                    : t.textSecondary,
                              ),
                    ),
                  ),
                  Text(
                    line.value,
                    style:
                        (line.emphasis
                                ? AppTypography.title
                                : AppTypography.bodyStrong)
                            .copyWith(
                              color: line.color ?? t.textPrimary,
                              fontFeatures: AppTypography.tabular,
                            ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
