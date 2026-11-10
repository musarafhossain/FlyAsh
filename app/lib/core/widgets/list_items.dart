import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';
import '../utils/formatters.dart';
import 'cards.dart';
import 'status_pill.dart';

/// Bright circle colours for list avatars. All are dark enough for white
/// text and icons on top (contrast ≥ 3:1), in light and dark mode.
const kAvatarColors = <Color>[
  Color(0xFF059669), // emerald
  Color(0xFF0284C7), // sky
  Color(0xFF9333EA), // purple
  Color(0xFFD97706), // amber
  Color(0xFFDB2777), // pink
  Color(0xFFDC2626), // red
  Color(0xFF0D9488), // teal
  Color(0xFF16A34A), // green
  Color(0xFF4F46E5), // indigo
  Color(0xFFEA580C), // orange
];

/// The same seed always gets the same colour (stable on every platform).
Color avatarColor(String seed) {
  var h = 0x811c9dc5;
  for (final c in seed.codeUnits) {
    h = ((h ^ c) * 0x01000193) & 0xFFFFFFFF;
  }
  return kAvatarColors[h % kAvatarColors.length];
}

/// A coloured circle with a white icon or short text, as in list rows.
/// [dimmed] shows it grey (e.g. an inactive record).
class ColorAvatar extends StatelessWidget {
  const ColorAvatar({
    super.key,
    required this.seed,
    this.icon,
    this.text,
    this.size = 48,
    this.dimmed = false,
  }) : assert(icon != null || text != null);

  final String seed;
  final IconData? icon;
  final String? text;
  final double size;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: dimmed ? t.textTertiary : avatarColor(seed),
        shape: BoxShape.circle,
      ),
      child: icon != null
          ? Icon(icon, size: size * 0.5, color: Colors.white)
          : Text(
              text!,
              style: AppTypography.label.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: size * 0.36,
              ),
            ),
    );
  }
}

/// Coloured circle with a person's initials ("Rahim Traders" → "RT").
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar(this.name, {super.key, this.size = 48});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) =>
      ColorAvatar(seed: name, text: Fmt.initials(name), size: size);
}

/// A list of rows split by thin lines (like a phone contacts list). Use
/// with [ListRowSurface] rows.
///
/// [flat]: no card, border or background of its own; the rows sit on the
/// page and line up with the search field above them.
class ListGroup extends StatelessWidget {
  const ListGroup({super.key, required this.children, this.flat = false});

  final List<Widget> children;
  final bool flat;

  @override
  Widget build(BuildContext context) {
    final rows = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, child) in children.indexed) ...[
          if (i > 0) const Divider(height: 1),
          child,
        ],
      ],
    );
    if (flat) return _FlatScope(child: rows);
    return AppCard(padding: EdgeInsets.zero, child: rows);
  }
}

/// Tells [ListRowSurface] it is in a flat [ListGroup].
class _FlatScope extends InheritedWidget {
  const _FlatScope({required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_FlatScope>() != null;

  @override
  bool updateShouldNotify(_FlatScope old) => false;
}

/// One flat, tappable row inside a [ListGroup] (no border of its own).
class ListRowSurface extends StatelessWidget {
  const ListRowSurface({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.symmetric(
      horizontal: Space.s4,
      vertical: Space.s3,
    ),
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Opens the row's action menu (edit, deactivate, delete …).
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        // Flat lists: no side padding, so rows line up with the page.
        padding: _FlatScope.of(context)
            ? const EdgeInsets.symmetric(vertical: Space.s3)
            : padding,
        child: child,
      ),
    ),
  );
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
    return ListRowSurface(
      onTap: onTap,
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
