import 'package:flutter/material.dart';

import 'motion.dart';

import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';
import 'skeletons.dart';
import 'state_views.dart';

/// Categorical tints for KPI chips (04-UI-UX §5.4).
enum KpiTint { rose, green, amber, sky }

/// (icon colour, background) of a tint.
(Color, Color) kpiTintColors(AppTokens t, KpiTint tint) => switch (tint) {
  KpiTint.rose => (t.tintRose, t.tintRoseBg),
  KpiTint.green => (t.tintGreen, t.tintGreenBg),
  KpiTint.amber => (t.tintAmber, t.tintAmberBg),
  KpiTint.sky => (t.tintSky, t.tintSkyBg),
};

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

    return PressScale(
      enabled: onTap != null,
      scale: 0.98,
      child: _card(context, t, fg),
    );
  }

  Widget _card(BuildContext context, AppTokens t, Color fg) {
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
          // Label, value and caption on the left; the icon top right and
          // the arrow bottom right.
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
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
                          child: CountUpText(
                            value,
                            style: AppTypography.display.copyWith(
                              color: fg,
                              fontFeatures: AppTypography.tabular,
                            ),
                          ),
                        ),
                      if (caption != null)
                        loading
                            ? const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: SkeletonBox(width: 60, height: 12),
                              )
                            : Text(
                                caption!,
                                style: AppTypography.caption.copyWith(
                                  color: t.textSecondary,
                                ),
                              ),
                    ],
                  ),
                ),
                const SizedBox(width: Space.s3),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: t.primary,
                        borderRadius: Radii.mdAll,
                      ),
                      child: Icon(icon, size: 22, color: t.onPrimary),
                    ),
                    if (onTap != null)
                      Icon(
                        Icons.arrow_forward,
                        size: 20,
                        color: t.textSecondary,
                      ),
                  ],
                ),
              ],
            ),
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
    final (fg, bg) = kpiTintColors(t, tint);
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
                  // Exactly the value's line height: no jump when it loads.
                  SkeletonLine(style: AppTypography.h3)
                else
                  // A long amount shrinks to fit, but the line keeps its
                  // full height (same as the loading placeholder).
                  Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Text(
                        '0',
                        style: AppTypography.h3.copyWith(
                          color: Colors.transparent,
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: CountUpText(
                          value,
                          style: AppTypography.h3.copyWith(
                            color: t.textPrimary,
                            fontFeatures: AppTypography.tabular,
                          ),
                        ),
                      ),
                    ],
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
    // Tappable cards squash a little while pressed.
    return PressScale(
      enabled: onTap != null,
      child: Material(
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
      ),
    );
  }
}

/// Quick action like an app icon on a phone's home screen (§9.4): a
/// rounded, tinted square with the icon, the label below. Each action has
/// its own tint (the same tints as the KPI tiles).
class QuickActionTile extends StatelessWidget {
  const QuickActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.tint = KpiTint.sky,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final KpiTint tint;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final (fg, bg) = kpiTintColors(t, tint);
    return PressScale(
      scale: 0.94,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: Radii.lgAll,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.s2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: fg.withValues(alpha: 0.16)),
                  ),
                  child: Icon(icon, size: 26, color: fg),
                ),
                const SizedBox(height: Space.s2),
                Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Quick actions in one row of app-style icons (4 per row on every size).
class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final child in children) Expanded(child: child)],
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
