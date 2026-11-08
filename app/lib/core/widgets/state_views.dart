import 'package:flutter/material.dart';

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
    this.retryLabel = 'Retry',
    this.onRetry,
  });

  final String message;
  final String retryLabel;
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
                label: Text(retryLabel),
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
    final color = context.tokens.surfaceVariant;
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

/// Loading placeholder shaped like a list of entity rows.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      children: [
        for (var i = 0; i < count; i++)
          Container(
            margin: const EdgeInsets.only(bottom: Space.s2),
            padding: const EdgeInsets.all(Space.s4),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: Radii.mdAll,
              border: Border.all(color: t.border),
            ),
            child: const Row(
              children: [
                SkeletonBox(width: 40, height: 40, radius: 20),
                SizedBox(width: Space.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 160),
                      SizedBox(height: Space.s2),
                      SkeletonBox(width: 100, height: 12),
                    ],
                  ),
                ),
                SkeletonBox(width: 64),
              ],
            ),
          ),
      ],
    );
  }
}

/// Confirm dialog (§9.15). Returns true when confirmed.
/// [destructive] shows the confirm button in the error color.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
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
          child: Text(cancelLabel),
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
