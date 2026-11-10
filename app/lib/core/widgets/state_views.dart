import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';

/// Nothing to show yet (§9.15): icon, title, hint and an optional action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: t.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: t.onPrimaryContainer),
            ),
            const SizedBox(height: Space.s4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.h3.copyWith(color: t.textPrimary),
            ),
            if (message != null) ...[
              const SizedBox(height: Space.s1),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: t.textSecondary),
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: Space.s4),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Something went wrong (§9.15): message + Retry.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.retryLabel,
    this.onRetry,
  });

  final String message;

  /// Defaults to the translated 'Retry'.
  final String? retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: t.error),
            const SizedBox(height: Space.s3),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: t.textPrimary),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: Space.s4),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryLabel ?? context.l10n.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Grey placeholder box that gently pulses while data loads (§9.15).
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.radius = Radii.sm,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // A touch darker than surfaceVariant, so it shows on cards and on the
    // page background alike (flat lists sit on the page).
    final color = Color.alphaBlend(
      t.textTertiary.withValues(alpha: 0.14),
      t.surfaceVariant,
    );
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return FadeTransition(
      opacity: reduceMotion
          ? const AlwaysStoppedAnimation(1)
          : Tween(begin: 0.5, end: 1.0).animate(_c),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// Loading placeholder shaped like the flat lists: rows split by thin
/// lines, each with a round avatar, two text lines and a value + pill on
/// the right. [leading] false: no avatar; [toggle] true: a switch on the
/// right instead (attendance).
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    this.count = 6,
    this.leading = true,
    this.toggle = false,
  });

  final int count;
  final bool leading;
  final bool toggle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < count; i++) ...[
        if (i > 0) const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.s3),
          child: Row(
            children: [
              if (leading) ...[
                const SkeletonBox(width: 48, height: 48, radius: 24),
                const SizedBox(width: Space.s3),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: i.isEven ? 170 : 140, height: 16),
                    const SizedBox(height: Space.s2),
                    SkeletonBox(width: i.isEven ? 110 : 130, height: 12),
                  ],
                ),
              ),
              const SizedBox(width: Space.s3),
              if (toggle)
                const SkeletonBox(width: 52, height: 32, radius: 16)
              else
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SkeletonBox(width: 64, height: 16),
                    SizedBox(height: Space.s2),
                    SkeletonBox(width: 52, height: 18, radius: 9),
                  ],
                ),
            ],
          ),
        ),
      ],
    ],
  );
}

/// Confirm dialog (§9.15). Returns true when confirmed.
/// [destructive] shows the confirm button in the error color.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String? cancelLabel,
  bool destructive = false,
}) async {
  final t = context.tokens;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        title,
        style: AppTypography.h3.copyWith(color: t.textPrimary),
      ),
      content: Text(
        message,
        style: AppTypography.body.copyWith(color: t.textSecondary),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel ?? context.l10n.cancel),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: t.error,
                  foregroundColor: t.surface,
                )
              : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
