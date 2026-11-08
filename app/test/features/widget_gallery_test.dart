import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flyash/core/theme/app_colors.dart';
import 'package:flyash/core/theme/app_theme.dart';
import 'package:flyash/core/widgets/cards.dart';
import 'package:flyash/core/widgets/controls.dart';
import 'package:flyash/core/widgets/state_views.dart';
import 'package:flyash/features/dev/presentation/pages/widget_gallery_page.dart';

import '../helpers.dart';

Widget _host(Brightness b, {double fontScale = 1}) => MaterialApp(
  theme: AppTheme.build(AccentColor.emerald, b),
  // Same font-size handling as the real app
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(fontScale)),
    child: child!,
  ),
  home: const WidgetGalleryPage(),
);

void main() {
  for (final size in const [Size(360, 800), Size(800, 1000), Size(1440, 900)]) {
    for (final b in Brightness.values) {
      testWidgets(
        'widget gallery: no overflow at ${size.width.toInt()}px (${b.name})',
        (tester) async {
          setScreenSize(tester, size);
          await tester.pumpWidget(_host(b));
          await tester.pump(const Duration(seconds: 1));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('XL text on a small phone does not overflow', (tester) async {
    setScreenSize(tester, const Size(360, 800));
    await tester.pumpWidget(_host(Brightness.light, fontScale: 1.3));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('KPI chips: 2 per row on phones, 4 per row on desktop', (
    tester,
  ) async {
    for (final (width, perRow) in [(360.0, 2), (1440.0, 4)]) {
      setScreenSize(tester, Size(width, 900));
      await tester.pumpWidget(_host(Brightness.light));
      await tester.pump();
      final tops = tester
          .widgetList(find.byType(KpiChip))
          .map((w) => tester.getTopLeft(find.byWidget(w)).dy)
          .toSet();
      expect(tops.length, 4 ~/ perRow, reason: 'rows at width $width');
    }
  });

  testWidgets('segmented tabs, period arrows and confirm dialog work', (
    tester,
  ) async {
    setScreenSize(tester, const Size(800, 1600));
    await tester.pumpWidget(_host(Brightness.light));
    await tester.pump();

    await tester.tap(find.text('Booking'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      tester
          .widget<SegmentedTabs<String>>(find.byType(SegmentedTabs<String>))
          .selected,
      'booking',
    );

    expect(find.text('Nov 2026'), findsOneWidget);
    await tester.tap(find.byTooltip('Previous'));
    await tester.pump();
    expect(find.text('Oct 2026'), findsOneWidget);

    await tester.ensureVisible(find.text('Confirm dialog'));
    await tester.tap(find.text('Confirm dialog'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Delete INV-000101?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Last action: confirmed'), findsOneWidget);
  });

  testWidgets('empty state action and error retry call back', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(AccentColor.blue, Brightness.light),
        home: Scaffold(
          body: Column(
            children: [
              EmptyState(
                icon: Icons.inbox,
                title: 'Nothing',
                actionLabel: 'Add',
                onAction: () => tapped++,
              ),
              ErrorState(message: 'Oops', onRetry: () => tapped++),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Add'));
    await tester.tap(find.text('Retry'));
    expect(tapped, 2);
  });
}
