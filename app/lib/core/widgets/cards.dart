import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';
import 'state_views.dart';

/// Categorical tints for KPI chips (04-UI-UX §5.4).
enum KpiTint { rose, green, amber, sky }

/// Big card with the screen's most important number (§9.2): a soft accent
/// tint (accent container) with the accent icon, in light and dark mode.
class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.caption,
    this.onTap,
    this.loading = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? caption;
  final VoidCallback? onTap;

  /// A pulsing placeholder instead of the value (still loading).
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final fg = t.onPrimaryContainer;

    return Material(
      color: t.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: Radii.lgAll,
        side: BorderSide(color: t.primary.withValues(alpha: 0.18)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.lgAll,
        child: Padding(
          padding: const EdgeInsets.all(Space.s5),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: t.primary,
                  borderRadius: Radii.mdAll,
                ),
                child: Icon(icon, color: t.onPrimary),
              ),
              const SizedBox(width: Space.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTypography.caption.copyWith(
                        color: t.textSecondary,
                      ),
                    ),
                    if (loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: Space.s1),
                        child: SkeletonBox(width: 150, height: 32),
                      )
                    else
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: AppTypography.display.copyWith(
                            color: fg,
                            fontFeatures: AppTypography.tabular,
                          ),
                        ),
                      ),
                    if (caption != null)
                      Text(
                        caption!,
                        style: AppTypography.caption.copyWith(
                          color: t.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right, color: t.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small KPI tile: tinted icon square, label and value (§9.3).
class KpiChip extends StatelessWidget {
  const KpiChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.tint = KpiTint.sky,
    this.onTap,
    this.loading = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final KpiTint tint;
  final VoidCallback? onTap;

  /// A pulsing placeholder instead of the value (still loading).
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final (fg, bg) = switch (tint) {
      KpiTint.rose => (t.tintRose, t.tintRoseBg),
      KpiTint.green => (t.tintGreen, t.tintGreenBg),
      KpiTint.amber => (t.tintAmber, t.tintAmberBg),
      KpiTint.sky => (t.tintSky, t.tintSkyBg),
    };
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(Space.s3),
      // Label and value on the left, the tinted icon on the right.
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(color: t.textSecondary),
                ),
                const SizedBox(height: Space.s1),
                if (loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 2),
                    child: FractionallySizedBox(
                      widthFactor: 0.8,
                      child: SkeletonBox(height: 20),
                    ),
                  )
                else
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: AppTypography.h3.copyWith(
                        color: t.textPrimary,
                        fontFeatures: AppTypography.tabular,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: Space.s2),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: bg, borderRadius: Radii.mdAll),
            child: Icon(icon, size: 20, color: fg),
          ),
        ],
      ),
    );
  }
}

/// Lays out KPI chips: on phones up to 3 in one row (4+ → 2 per row), all
/// in one row on wider screens. Values shrink to fit (FittedBox in KpiChip).
class KpiRow extends StatelessWidget {
  const KpiRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final perRow = c.maxWidth < Breakpoints.medium
            ? (children.length <= 3 ? children.length : 2)
            : children.length.clamp(1, 6);
        final width = (c.maxWidth - Space.s2 * (perRow - 1)) / perRow;
        return Wrap(
          spacing: Space.s2,
          runSpacing: Space.s2,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

/// Bordered surface card used everywhere (level 0 elevation).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(Space.s4),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      color: t.surface,
      shape: RoundedRectangleBorder(
        borderRadius: Radii.mdAll,
        side: BorderSide(color: t.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Quick action tile: icon in an accent circle + label (§9.4).
class QuickActionTile extends StatelessWidget {
  const QuickActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: Space.s3,
        vertical: Space.s3,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: t.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: t.onPrimaryContainer),
          ),
          const SizedBox(width: Space.s3),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.label.copyWith(color: t.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Grid of quick actions: 2 columns on phones, 4 on wider screens.
class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth < Breakpoints.medium ? 2 : 4;
        final width = (c.maxWidth - Space.s2 * (cols - 1)) / cols;
        return Wrap(
          spacing: Space.s2,
          runSpacing: Space.s2,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

/// Section title with an optional action ("View all") (§3 headers).
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Space.s4, bottom: Space.s2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTypography.h3.copyWith(
                color: context.tokens.textPrimary,
              ),
            ),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}
