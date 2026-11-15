import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'motion.dart';

import '../l10n/l10n.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';

/// Pill-shaped tabs on a track (§9.9), e.g. All / Instant / Booking.
class SegmentedTabs<T> extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  /// value → label
  final Map<T, String> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final keys = segments.keys.toList();
    final index = keys.indexOf(selected).clamp(0, keys.length - 1);
    final duration = Motion.reduced(context) ? Duration.zero : Motion.base;

    return Container(
      height: 44,
      padding: const EdgeInsets.all(Space.s1),
      decoration: BoxDecoration(
        color: t.surfaceVariant,
        borderRadius: Radii.fullAll,
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final width = box.maxWidth / keys.length;
          return Stack(
            children: [
              // One pill that slides to the selected segment (it never fades
              // through a dark colour, unlike fading from Colors.transparent).
              AnimatedPositioned(
                key: const Key('segmentedTabsThumb'),
                duration: duration,
                curve: Motion.standard,
                left: width * index,
                top: 0,
                bottom: 0,
                width: width,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: t.surface,
                    borderRadius: Radii.fullAll,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x140F172A),
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (final key in keys)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: key == selected,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onChanged(key),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: duration,
                              curve: Motion.standard,
                              style: AppTypography.label.copyWith(
                                color: key == selected
                                    ? t.primary
                                    : t.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                              child: Text(
                                segments[key]!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// ‹ November 2026 › (§9.10). The middle label opens a picker.
class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    super.key,
    required this.label,
    this.onPrevious,
    this.onNext,
    this.onTapLabel,
  });

  final String label;

  /// null disables the arrow (e.g. no future periods)
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onTapLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: Radii.mdAll,
        border: Border.all(color: t.border),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left),
            tooltip: context.l10n.previous,
          ),
          Expanded(
            child: InkWell(
              onTap: onTapLabel,
              borderRadius: Radii.mdAll,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Space.s3),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTypography.title.copyWith(color: t.textPrimary),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
            tooltip: context.l10n.next,
          ),
        ],
      ),
    );
  }
}

/// Circular progress (§9.11), e.g. labours present / total.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 160,
    this.stroke = 10,
    this.center,
  });

  /// 0.0 – 1.0
  final double value;
  final double size;
  final double stroke;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0, 1)),
        duration: MediaQuery.of(context).disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, v, child) => CustomPaint(
          painter: _RingPainter(v, stroke, t.surfaceVariant, t.primary),
          child: child,
        ),
        // The center content shrinks to fit inside the ring (large font sizes).
        child: Padding(
          padding: EdgeInsets.all(stroke * 2),
          child: Center(
            child: FittedBox(fit: BoxFit.scaleDown, child: center),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.stroke, this.track, this.arc);

  final double value;
  final double stroke;
  final Color track;
  final Color arc;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final r = rect.deflate(stroke / 2);
    canvas.drawArc(r, 0, math.pi * 2, false, paint..color = track);
    if (value > 0) {
      canvas.drawArc(
        r,
        -math.pi / 2,
        math.pi * 2 * value,
        false,
        paint..color = arc,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.arc != arc || old.track != track;
}
