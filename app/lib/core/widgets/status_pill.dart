import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';

enum StatusTone { success, warning, error, info, neutral }

/// Rounded status label (04-UI-UX §9.8). The text is always shown, so the
/// meaning never depends on color alone.
class StatusPill extends StatelessWidget {
  const StatusPill(
    this.label, {
    super.key,
    this.tone = StatusTone.neutral,
    this.dot = false,
  });

  final String label;
  final StatusTone tone;
  final bool dot;

  /// Tone for API status values: payment status (paid | partial | due),
  /// sale status (booked | delivered | cancelled), attendance (present | half_day | absent).
  static StatusTone toneFor(String status) => switch (status) {
    'paid' || 'delivered' || 'present' || 'active' => StatusTone.success,
    'partial' || 'half_day' || 'overdue' => StatusTone.warning,
    'due' || 'absent' => StatusTone.error,
    'booked' || 'info' => StatusTone.info,
    _ => StatusTone.neutral,
  };

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final (fg, bg) = switch (tone) {
      StatusTone.success => (t.success, t.successBg),
      StatusTone.warning => (t.warning, t.warningBg),
      StatusTone.error => (t.error, t.errorBg),
      StatusTone.info => (t.info, t.infoBg),
      StatusTone.neutral => (t.textSecondary, t.surfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: Radii.fullAll),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: Space.s1),
          ],
          Text(label, style: AppTypography.micro.copyWith(color: fg)),
        ],
      ),
    );
  }
}
