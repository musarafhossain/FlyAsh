import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';

/// Scrollable page body: screen-size side padding and a centered column no
/// wider than [maxWidth] (forms 560, detail pages 720 — 04-UI-UX §11).
class PageBody extends StatelessWidget {
  const PageBody({
    super.key,
    required this.children,
    this.maxWidth = 560,
    this.onRefresh,
  });

  final List<Widget> children;
  final double maxWidth;

  /// Pull down to load again (detail pages).
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final gutter = Breakpoints.gutter(MediaQuery.sizeOf(context).width);
    final body = SafeArea(
      top: false,
      child: SingleChildScrollView(
        physics: onRefresh == null
            ? null
            : const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(gutter),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
    return onRefresh == null
        ? body
        : RefreshIndicator(onRefresh: onRefresh!, child: body);
  }
}

/// A group of settings-style rows in one card, with an optional caption.
class MenuGroup extends StatelessWidget {
  const MenuGroup({super.key, this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.s1,
              Space.s4,
              Space.s1,
              Space.s2,
            ),
            child: Text(
              title!.toUpperCase(),
              style: AppTypography.micro.copyWith(
                color: t.textTertiary,
                letterSpacing: 0.8,
              ),
            ),
          ),
        Material(
          color: t.surface,
          shape: RoundedRectangleBorder(
            borderRadius: Radii.mdAll,
            side: BorderSide(color: t.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) Divider(height: 1, color: t.border),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One row of a [MenuGroup]: icon, title, optional value/subtitle, chevron.
class MenuRow extends StatelessWidget {
  const MenuRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.onTap,
    this.color,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Short value on the right, e.g. the current language.
  final String? value;
  final VoidCallback? onTap;

  /// Color for icon and title (e.g. error for Log out).
  final Color? color;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.s4,
            vertical: Space.s3,
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: color ?? t.textSecondary),
              const SizedBox(width: Space.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.body.copyWith(
                        color: color ?? t.textPrimary,
                        fontWeight: color != null ? FontWeight.w600 : null,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: t.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: Space.s2),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(
                    value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(color: t.textSecondary),
                  ),
                ),
              ],
              if (showChevron && onTap != null) ...[
                const SizedBox(width: Space.s1),
                Icon(Icons.chevron_right, color: t.textTertiary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Label above a value, for detail pages ("Phone" / "9876543210").
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.s2),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: t.textTertiary),
            const SizedBox(width: Space.s3),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(color: t.textTertiary),
                ),
                SelectableText(
                  value,
                  style: AppTypography.body.copyWith(color: t.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
