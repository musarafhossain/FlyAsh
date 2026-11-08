import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';

/// One accent color choice: a 44 dp circle, ring + ✓ when selected (§8.1).
class AccentSwatch extends StatelessWidget {
  const AccentSwatch({
    super.key,
    required this.accent,
    required this.label,
    required this.selected,
    required this.onTap,
    this.width = 76,
  });

  final AccentColor accent;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Null = as wide as the parent (e.g. inside an Expanded).
  final double? width;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.accent(accent, Theme.of(context).brightness);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.mdAll,
        child: SizedBox(
          width: width,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.s1),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: palette.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? context.tokens.textPrimary
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: selected
                      ? Icon(Icons.check, color: palette.onPrimary)
                      : null,
                ),
                const SizedBox(height: Space.s1),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: selected
                        ? context.tokens.textPrimary
                        : context.tokens.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : null,
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
