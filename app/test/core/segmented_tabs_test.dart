import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flyash/core/theme/app_colors.dart';
import 'package:flyash/core/theme/app_theme.dart';
import 'package:flyash/core/widgets/controls.dart';

void main() {
  Future<ValueNotifier<String>> pump(WidgetTester tester) async {
    final value = ValueNotifier('all');
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(AccentColor.values.first, Brightness.light),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: ValueListenableBuilder(
                valueListenable: value,
                builder: (_, v, _) => SegmentedTabs<String>(
                  segments: const {
                    'all': 'All',
                    'instant': 'Instant',
                    'booking': 'Booking',
                  },
                  selected: v,
                  onChanged: (n) => value.value = n,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return value;
  }

  final thumb = find.byKey(const Key('segmentedTabsThumb'));

  testWidgets('the pill slides to the tapped tab (not a jump)', (tester) async {
    final value = await pump(tester);
    final start = tester.getTopLeft(thumb).dx;
    await tester.tap(find.text('Booking'));
    await tester.pump();
    expect(value.value, 'booking');
    await tester.pump(const Duration(milliseconds: 100));
    final middle = tester.getTopLeft(thumb).dx;
    await tester.pumpAndSettle();
    final end = tester.getTopLeft(thumb).dx;
    expect(middle, greaterThan(start));
    expect(middle, lessThan(end), reason: 'on its way, not jumped');
    expect(
      tester.getCenter(thumb).dx,
      closeTo(tester.getCenter(find.text('Booking')).dx, 1),
    );
  });

  testWidgets(
    'light mode: the pill stays light while it moves (no dark flash)',
    (tester) async {
      await pump(tester);
      await tester.tap(find.text('Instant'));
      await tester.pump(const Duration(milliseconds: 60));
      final color =
          (tester
                      .widget<DecoratedBox>(
                        find.descendant(
                          of: thumb,
                          matching: find.byType(DecoratedBox),
                        ),
                      )
                      .decoration
                  as BoxDecoration)
              .color!;
      expect(color.computeLuminance(), greaterThan(0.8), reason: '$color');
    },
  );

  testWidgets('the whole segment is tappable, not just the text', (
    tester,
  ) async {
    final value = await pump(tester);
    final box = tester.getRect(find.byType(SegmentedTabs<String>));
    await tester.tapAt(Offset(box.right - 8, box.center.dy));
    await tester.pumpAndSettle();
    expect(value.value, 'booking');
  });
}
