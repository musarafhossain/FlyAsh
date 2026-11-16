import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

/// Fonts for every PDF the app makes (receipts, report exports): Inter,
/// with Hind Siliguri as a fallback so Bengali names and labels print.
Future<pw.ThemeData> pdfTheme() async {
  Future<pw.Font> font(String name) async =>
      pw.Font.ttf(await rootBundle.load('assets/fonts/$name.ttf'));
  final hind = await font('HindSiliguri-Regular');
  return pw.ThemeData.withFont(
    base: await font('Inter-Regular'),
    bold: await font('Inter-SemiBold'),
    fontFallback: [hind],
  );
}
