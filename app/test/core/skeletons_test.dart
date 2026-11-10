import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flyash/core/theme/app_spacing.dart';
import 'package:flyash/core/theme/app_theme.dart';
import 'package:flyash/core/theme/app_colors.dart';
import 'package:flyash/core/widgets/skeletons.dart';
import 'package:flyash/core/widgets/state_views.dart';
import 'package:flyash/features/sales/presentation/pages/sale_detail_page.dart'
    show SaleDetailSkeleton;

import '../helpers.dart';

/// Every loading screen shape, as used by the pages.
final screens = <String, Widget>{
  'list rows': const SingleChildScrollView(child: SkeletonList()),
  'attendance rows': const SingleChildScrollView(
    child: SkeletonList(leading: false, toggle: true),
  ),
  'table': const SingleChildScrollView(child: SkeletonTable()),
  'customer detail': const DetailSkeleton(
    maxWidth: 960,
    children: [
      SkeletonHeader(buttons: 2),
      SizedBox(height: Space.s3),
      SkeletonKpis(),
      SkeletonSectionTitle(action: true),
      SkeletonList(count: 4),
    ],
  ),
  'labour detail': const DetailSkeleton(
    children: [
      SkeletonHeader(),
      SizedBox(height: Space.s3),
      SkeletonLines(count: 3, title: true),
      SkeletonSectionTitle(),
      SkeletonCalendar(),
    ],
  ),
  'sale detail': const SaleDetailSkeleton(),
  'dashboard kpis': const DetailSkeleton(children: [SkeletonKpis(count: 4)]),
  'form': const FormSkeleton(fields: 6, big: {2}),
};

void main() {
  for (final e in screens.entries) {
    for (final size in const [
      Size(360, 800),
      Size(800, 1000),
      Size(1440, 900),
    ]) {
      for (final dark in [false, true]) {
        testWidgets('${e.key}: no overflow at ${size.width.toInt()} px '
            '(${dark ? 'dark' : 'light'})', (tester) async {
          setScreenSize(tester, size);
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.build(
                AccentColor.blue,
                dark ? Brightness.dark : Brightness.light,
              ),
              home: Scaffold(body: e.value),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);
          expect(find.byType(SkeletonBox), findsWidgets);
          expect(find.byType(CircularProgressIndicator), findsNothing);
        });
      }
    }
  }
}
