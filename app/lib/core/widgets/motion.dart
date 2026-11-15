import 'package:flutter/material.dart';

/// Motion tokens (04-UI-UX §7): short, snappy and the same everywhere.
abstract final class Motion {
  /// Press feedback, small state changes.
  static const fast = Duration(milliseconds: 120);

  /// Rows and cards entering, switches between states.
  static const base = Duration(milliseconds: 220);

  /// Each staggered row starts this much after the one before it.
  static const stagger = Duration(milliseconds: 35);

  /// Slow in, slow out: starts and ends gently.
  static const Curve standard = Curves.easeInOutCubic;

  /// Things that enter: fast first, then settle.
  static const Curve enter = Curves.easeOutCubic;

  /// "Reduce motion" is on in the system settings: no decorative movement.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

/// Squash on press: the child shrinks a little while a finger is on it and
/// springs back on release. It only listens, so the child's own tap
/// handling (InkWell …) still works; the animation can be interrupted at
/// any point (press, release and press again continue from where it is).
class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    this.enabled = true,
    this.scale = 0.97,
  });

  final Widget child;
  final bool enabled;
  final double scale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool down) {
    if (widget.enabled && down != _down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || Motion.reduced(context)) return widget.child;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: Motion.fast,
        curve: Motion.standard,
        child: widget.child,
      ),
    );
  }
}

/// A row that fades in and rises 12 px when it first appears; row [index]
/// starts a little after the one before it (stagger). Only the first
/// [_maxStaggered] rows wait, so a long list never feels slow. Runs once:
/// a reload that keeps the row does not replay it.
class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  static const _maxStaggered = 10;

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    final steps = widget.index.clamp(0, StaggeredEntrance._maxStaggered);
    final delay = Motion.stagger * steps;
    final total = delay + Motion.base;
    _c = AnimationController(vsync: this, duration: total);
    _t = CurvedAnimation(
      parent: _c,
      curve: Interval(
        delay.inMilliseconds / total.inMilliseconds,
        1,
        curve: Motion.enter,
      ),
    );
    _c.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Built in the background (a section next to the current one in the
    // swipe pager): show the row as is, so it is not invisible while it
    // slides into view.
    if (!TickerMode.valuesOf(context).enabled && !_c.isCompleted) {
      _c.value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) return widget.child;
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (_, child) => Opacity(
        opacity: _t.value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - _t.value)),
          child: child,
        ),
      ),
    );
  }
}
