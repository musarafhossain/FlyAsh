import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';
import 'form_submit.dart' show showMessage;

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

/// Compact dialog buttons for phones (04-UI-UX §9.15): 40 px high, 13 px
/// labels. Use for every dialog's actions.
ButtonStyle dialogButtonStyle(BuildContext context) => ButtonStyle(
  minimumSize: const WidgetStatePropertyAll(Size(64, 40)),
  padding: const WidgetStatePropertyAll(
    EdgeInsets.symmetric(horizontal: Space.s4),
  ),
  textStyle: WidgetStatePropertyAll(
    AppTypography.label.copyWith(fontWeight: FontWeight.w600),
  ),
  visualDensity: VisualDensity.compact,
);

/// Title style for dialogs (smaller than page headings).
TextStyle dialogTitleStyle(BuildContext context) =>
    AppTypography.title.copyWith(color: context.tokens.textPrimary);

/// Asks before an action. Returns true when confirmed (and, with
/// [onConfirm], when the action succeeded).
///
/// With [onConfirm] the dialog stays open while the action runs: both
/// buttons are disabled and a spinner shows next to the confirm label.
/// [onConfirm] returns null when it worked (the dialog closes) or an error
/// message: it is shown in the dialog and as a toast, the buttons are on
/// again, and the user closes the dialog or tries again.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String? cancelLabel,
  bool destructive = false,
  Future<String?> Function()? onConfirm,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => _ConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel ?? context.l10n.cancel,
      destructive: destructive,
      onConfirm: onConfirm,
      toastContext: context,
    ),
  );
  return result ?? false;
}

class _ConfirmDialog extends StatefulWidget {
  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.destructive,
    required this.onConfirm,
    required this.toastContext,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;
  final Future<String?> Function()? onConfirm;
  final BuildContext toastContext;

  @override
  State<_ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<_ConfirmDialog> {
  bool _busy = false;
  String? _error;

  Future<void> _confirm() async {
    final action = widget.onConfirm;
    if (action == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await action();
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = false;
      _error = error;
    });
    if (widget.toastContext.mounted) showMessage(widget.toastContext, error);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final style = dialogButtonStyle(context);
    final fg = widget.destructive ? t.surface : t.onPrimary;
    return PopScope(
      // No closing (back, tap outside) while the action runs.
      canPop: !_busy,
      child: AlertDialog(
        title: Text(widget.title, style: dialogTitleStyle(context)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.message,
              style: AppTypography.body.copyWith(color: t.textSecondary),
            ),
            if (_error != null) ...[
              const SizedBox(height: Space.s3),
              Text(
                _error!,
                key: const Key('confirmDialogError'),
                style: AppTypography.body.copyWith(color: t.error),
              ),
            ],
          ],
        ),
        actions: [
          OutlinedButton(
            style: style,
            onPressed: _busy ? null : () => Navigator.of(context).pop(false),
            child: Text(widget.cancelLabel),
          ),
          FilledButton(
            style: widget.destructive
                ? style.merge(
                    FilledButton.styleFrom(
                      backgroundColor: t.error,
                      foregroundColor: t.surface,
                      disabledBackgroundColor: t.error.withValues(alpha: 0.6),
                      disabledForegroundColor: t.surface,
                    ),
                  )
                : style,
            onPressed: _busy ? null : _confirm,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.confirmLabel),
                if (_busy) ...[
                  const SizedBox(width: Space.s2),
                  SizedBox.square(
                    key: const Key('confirmDialogSpinner'),
                    dimension: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
