import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flyash/core/router/app_router.dart';
import 'package:flyash/core/theme/app_typography.dart';
import 'package:flyash/core/theme/oklch.dart';
import 'package:flyash/core/utils/validators.dart';
import 'package:flyash/core/widgets/form_fields.dart';
import 'package:flyash/core/widgets/list_items.dart';
import 'package:flyash/core/widgets/motion.dart';

import '../features/products_test.dart' show openProducts, currentPath;
import '../helpers.dart';

double _contrastWithWhite(Color c) => 1.05 / (c.computeLuminance() + 0.05);

void main() {
  test('OKLCH: known colours, and avatar colours share one lightness', () {
    expect(oklch(1, 0, 0), const Color(0xFFFFFFFF));
    expect(oklch(0, 0, 0), const Color(0xFF000000));
    final red = oklch(0.628, 0.2577, 29.23); // sRGB red
    expect((red.r * 255).round(), greaterThan(250));
    expect((red.g * 255).round(), lessThan(8));

    expect(kAvatarColors.toSet(), hasLength(10));
    for (final c in kAvatarColors) {
      expect(_contrastWithWhite(c), greaterThan(4.0), reason: '$c');
      expect(_contrastWithWhite(c), lessThan(6.5), reason: '$c');
    }
  });

  test('tracking: big headings tighter, micro wider, body untouched', () {
    expect(AppTypography.display.letterSpacing, lessThan(0));
    expect(AppTypography.h1.letterSpacing, lessThan(0));
    expect(AppTypography.body.letterSpacing, 0);
    expect(AppTypography.micro.letterSpacing, greaterThan(0));
    // Leading: body lines are 20 px on 14 px text
    expect(AppTypography.body.height! * AppTypography.body.fontSize!, 20);
  });

  test('phone input is liberal (Postel): +91, 0, spaces, dashes', () {
    expect(normalizePhone('+91 98765-43210'), '9876543210');
    expect(normalizePhone('098765 43210'), '9876543210');
    expect(normalizePhone('919876543210'), '9876543210');
    expect(normalizePhone('9198765432'), '9198765432', reason: 'a real number');
    const f = PhoneInputFormatter();
    String typed(String v) => f
        .formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: v))
        .text;
    expect(typed('+91 98765 43210'), '9876543210');
    expect(typed('98765432109999'), '9876543210');
  });

  testWidgets('press: a tappable card squashes and springs back', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: PressScale(
            child: ColoredBox(
              color: Colors.blue,
              child: SizedBox.square(dimension: 100),
            ),
          ),
        ),
      ),
    );
    double scale() =>
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;
    final g = await tester.startGesture(
      tester.getCenter(find.byType(PressScale)),
    );
    await tester.pump();
    expect(scale(), lessThan(1));
    await g.up();
    await tester.pumpAndSettle();
    expect(scale(), 1);
  });

  testWidgets('stagger: later rows start later; reduce motion = no animation', (
    tester,
  ) async {
    Widget app({bool reduce = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduce),
        child: const ListGroup(
          flat: true,
          children: [Text('one'), Text('two'), Text('three')],
        ),
      ),
    );
    double opacityOf(String text) => tester
        .widget<Opacity>(
          find
              .ancestor(of: find.text(text), matching: find.byType(Opacity))
              .first,
        )
        .opacity;

    await tester.pumpWidget(app());
    await tester.pump(const Duration(milliseconds: 60));
    expect(opacityOf('one'), greaterThan(opacityOf('three')));
    await tester.pumpAndSettle();
    expect(opacityOf('three'), 1);

    await tester.pumpWidget(app(reduce: true));
    await tester.pump();
    expect(find.byType(Opacity), findsNothing);
  });

  testWidgets('list → detail: the page shows at once (no skeleton) and the '
      'avatar is a shared element', (tester) async {
    await openProducts(tester);
    expect(find.byType(Hero), findsWidgets);
    await tester.tap(find.text('Red Brick'));
    await tester.pump(); // route pushed
    await tester.pump(const Duration(milliseconds: 50));
    expect(currentPath(), '/products/2');
    expect(find.text('₹5.50'), findsWidgets, reason: 'data from the row');
    await tester.pumpAndSettle();
    expect(tester.widget<Hero>(find.byType(Hero).last).tag, 'product-2');
    expect(testContainer.read(routerProvider), isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dialogs sit at the optical centre (a little above the middle)', (
    tester,
  ) async {
    await openProducts(tester, location: '/products/1');
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deactivate'));
    await tester.pumpAndSettle();
    final dialog = tester.getCenter(
      find
          .descendant(of: find.byType(Dialog), matching: find.byType(Material))
          .first,
    );
    final screen = tester.getCenter(find.byType(MaterialApp));
    expect(dialog.dy, lessThan(screen.dy));
  });
}
