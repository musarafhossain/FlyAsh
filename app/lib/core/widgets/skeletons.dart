import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import 'state_views.dart';

/// Loading placeholders shaped like the real screens, so the layout does
/// not jump when the data arrives. Built from pulsing [SkeletonBox]es.

/// Bordered surface like `AppCard`, holding skeleton parts.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Space.s4),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: Radii.mdAll,
        border: Border.all(color: t.border),
      ),
      child: child,
    );
  }
}

/// A short title line between blocks (like `SectionHeader`).
class SkeletonSectionTitle extends StatelessWidget {
  const SkeletonSectionTitle({super.key, this.action = false});

  /// Also a small box on the right (e.g. "New sale").
  final bool action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Space.s5, bottom: Space.s3),
    child: Row(
      children: [
        const SkeletonBox(width: 120, height: 18),
        const Spacer(),
        if (action) const SkeletonBox(width: 80, height: 18),
      ],
    ),
  );
}

/// Record header: avatar, name, two lines, optional pill buttons.
class SkeletonHeader extends StatelessWidget {
  const SkeletonHeader({super.key, this.buttons = 0, this.avatar = true});

  final int buttons;
  final bool avatar;

  @override
  Widget build(BuildContext context) => SkeletonCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (avatar) ...[
              const SkeletonBox(width: 56, height: 56, radius: 28),
              const SizedBox(width: Space.s4),
            ],
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 180, height: 20),
                  SizedBox(height: Space.s2),
                  SkeletonBox(width: 120, height: 14),
                  SizedBox(height: Space.s2),
                  SkeletonBox(width: 150, height: 14),
                ],
              ),
            ),
          ],
        ),
        if (buttons > 0) ...[
          const SizedBox(height: Space.s4),
          Row(
            children: [
              for (var i = 0; i < buttons; i++) ...[
                if (i > 0) const SizedBox(width: Space.s2),
                const Expanded(child: SkeletonBox(height: 40, radius: 20)),
              ],
            ],
          ),
        ],
      ],
    ),
  );
}

/// Row of KPI tiles (icon, value, label), like `KpiRow`.
class SkeletonKpis extends StatelessWidget {
  const SkeletonKpis({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < count; i++) ...[
        if (i > 0) const SizedBox(width: Space.s2),
        const Expanded(
          child: SkeletonCard(
            padding: EdgeInsets.all(Space.s3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 28, height: 28, radius: 14),
                SizedBox(height: Space.s3),
                // Widths follow the tile, so four fit on a phone too.
                FractionallySizedBox(
                  widthFactor: 0.8,
                  child: SkeletonBox(height: 18),
                ),
                SizedBox(height: Space.s2),
                FractionallySizedBox(
                  widthFactor: 0.6,
                  child: SkeletonBox(height: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    ],
  );
}

/// Card of label → value lines (details, money summary …).
class SkeletonLines extends StatelessWidget {
  const SkeletonLines({super.key, this.count = 4, this.title = false});

  final int count;

  /// A title line on top of the card.
  final bool title;

  @override
  Widget build(BuildContext context) => SkeletonCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title) ...[
          const SkeletonBox(width: 140, height: 18),
          const SizedBox(height: Space.s4),
        ],
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(height: Space.s4),
          Row(
            children: [
              SkeletonBox(width: i.isEven ? 110 : 90, height: 14),
              const Spacer(),
              SkeletonBox(width: i.isEven ? 70 : 90, height: 14),
            ],
          ),
        ],
      ],
    ),
  );
}

/// A month calendar: weekday line and a 7 × 5 grid of day boxes.
class SkeletonCalendar extends StatelessWidget {
  const SkeletonCalendar({super.key});

  @override
  Widget build(BuildContext context) => SkeletonCard(
    child: Column(
      children: [
        for (var row = 0; row < 6; row++) ...[
          if (row > 0) const SizedBox(height: Space.s1),
          Row(
            children: [
              for (var col = 0; col < 7; col++) ...[
                if (col > 0) const SizedBox(width: Space.s1),
                Expanded(
                  child: row == 0
                      ? const Center(child: SkeletonBox(width: 20, height: 10))
                      : const AspectRatio(
                          aspectRatio: 1,
                          child: SkeletonBox(radius: Radii.sm),
                        ),
                ),
              ],
            ],
          ),
        ],
        const SizedBox(height: Space.s3),
        const Row(
          children: [
            SkeletonBox(width: 80, height: 12),
            SizedBox(width: Space.s4),
            SkeletonBox(width: 80, height: 12),
          ],
        ),
      ],
    ),
  );
}

/// Desktop list: a table header and rows.
class SkeletonTable extends StatelessWidget {
  const SkeletonTable({super.key, this.rows = 8, this.columns = 5});

  final int rows;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    Widget line(bool head) => Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.s4,
        vertical: Space.s3,
      ),
      child: Row(
        children: [
          if (!head) ...[
            const SkeletonBox(width: 32, height: 32, radius: 16),
            const SizedBox(width: Space.s3),
          ],
          for (var c = 0; c < columns; c++) ...[
            if (c > 0) const SizedBox(width: Space.s5),
            Expanded(
              flex: c == 0 ? 3 : 2,
              child: Align(
                alignment: c == columns - 1
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: SkeletonBox(
                  width: head ? 60 : (c == 0 ? 140 : 80),
                  height: head ? 12 : 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
    return SkeletonCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            color: t.surfaceVariant.withValues(alpha: 0.4),
            child: line(true),
          ),
          for (var i = 0; i < rows; i++) ...[
            const Divider(height: 1),
            line(false),
          ],
        ],
      ),
    );
  }
}

/// A form being loaded: labelled field boxes and the button.
class FormSkeleton extends StatelessWidget {
  const FormSkeleton({
    super.key,
    this.fields = 4,
    this.maxWidth = 560,
    this.big = const {},
  });

  final int fields;
  final double maxWidth;

  /// Indexes of fields that are taller (notes, address …).
  final Set<int> big;

  @override
  Widget build(BuildContext context) {
    final gutter = Breakpoints.gutter(MediaQuery.sizeOf(context).width);
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(gutter),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < fields; i++) ...[
                const SkeletonBox(width: 90, height: 12),
                const SizedBox(height: Space.s2),
                SkeletonBox(
                  height: big.contains(i) ? 96 : 52,
                  radius: Radii.md,
                ),
                const SizedBox(height: Space.s4),
              ],
              const SizedBox(height: Space.s2),
              const SkeletonBox(height: 48, radius: Radii.md),
            ],
          ),
        ),
      ),
    );
  }
}

/// A detail screen being loaded: [children] in a centred column of
/// [maxWidth], with the page gutter. Does not scroll (it is a placeholder).
class DetailSkeleton extends StatelessWidget {
  const DetailSkeleton({
    super.key,
    required this.children,
    this.maxWidth = 720,
  });

  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final gutter = Breakpoints.gutter(MediaQuery.sizeOf(context).width);
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
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
    );
  }
}
