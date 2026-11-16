import 'package:flutter_test/flutter_test.dart';
import 'package:flyash/core/pdf/pdf_text.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  test('only text with Bengali letters needs shaping', () {
    expect(needsShaping('রহিম ট্রেডার্স'), isTrue);
    expect(needsShaping('Rahim ₹1,000.00'), isFalse);
    expect(needsShaping('Fly Ash ইট'), isTrue);
  });

  testWidgets('Bengali becomes a drawn image; Latin stays PDF text', (
    tester,
  ) async {
    final widgets = await tester.runAsync(
      () => PdfText.build((t) => [t('ক্রেতা', size: 9), t('Total', size: 9)]),
    );
    expect(widgets![0], isA<pw.Image>());
    expect(widgets[1], isA<pw.Text>());
  });
}
