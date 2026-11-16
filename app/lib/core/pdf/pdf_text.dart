import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Text for app PDFs that also prints Bengali correctly.
///
/// The `pdf` package does not shape Bengali (vowel signs and conjuncts come
/// out in the wrong order), so any text with Bengali letters is laid out by
/// Flutter's own text engine (which does) and placed as a sharp image.
/// Latin text and numbers stay real PDF text.
///
/// Use [PdfText.build]: it calls `make` once to see which texts are
/// needed, draws the Bengali ones, then calls `make` again for the result.
typedef PdfTextFn =
    pw.Widget Function(
      String text, {
      double size,
      bool bold,
      PdfColor color,
      double? maxWidth,
    });

final _bengali = RegExp('[ঀ-৿]');

/// True when [text] needs Flutter's shaping.
bool needsShaping(String text) => _bengali.hasMatch(text);

class _Key {
  const _Key(this.text, this.size, this.bold, this.color, this.maxWidth);
  final String text;
  final double size;
  final bool bold;
  final int color;
  final double? maxWidth;

  @override
  bool operator ==(Object other) =>
      other is _Key &&
      other.text == text &&
      other.size == size &&
      other.bold == bold &&
      other.color == color &&
      other.maxWidth == maxWidth;

  @override
  int get hashCode => Object.hash(text, size, bold, color, maxWidth);
}

class _Shaped {
  const _Shaped(this.image, this.width, this.height);
  final pw.MemoryImage image;
  final double width;
  final double height;
}

abstract final class PdfText {
  /// Pixels per PDF point in the drawn images (sharp when printed).
  static const _scale = 4.0;

  static Future<T> build<T>(T Function(PdfTextFn t) make) async {
    final wanted = <_Key>{};
    make((text, {size = 10, bold = false, color = PdfColors.black, maxWidth}) {
      if (needsShaping(text)) {
        wanted.add(_Key(text, size, bold, color.toInt(), maxWidth));
      }
      return pw.SizedBox();
    });
    final shaped = <_Key, _Shaped>{for (final k in wanted) k: await _draw(k)};
    return make((
      text, {
      size = 10,
      bold = false,
      color = PdfColors.black,
      maxWidth,
    }) {
      final s = shaped[_Key(text, size, bold, color.toInt(), maxWidth)];
      if (s != null) {
        return pw.Image(s.image, width: s.width, height: s.height);
      }
      final style = pw.TextStyle(
        fontSize: size,
        color: color,
        fontWeight: bold ? pw.FontWeight.bold : null,
      );
      return maxWidth == null
          ? pw.Text(text, style: style)
          : pw.ConstrainedBox(
              constraints: pw.BoxConstraints(maxWidth: maxWidth),
              child: pw.Text(text, style: style),
            );
    });
  }

  static Future<_Shaped> _draw(_Key k) async {
    final painter = TextPainter(
      text: TextSpan(
        text: k.text,
        style: TextStyle(
          fontFamily: 'HindSiliguri',
          fontFamilyFallback: const ['Inter'],
          fontSize: k.size,
          height: 1.25,
          fontWeight: k.bold ? FontWeight.w600 : FontWeight.w400,
          color: Color(k.color),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: k.maxWidth ?? double.infinity);
    final w = painter.width.ceilToDouble().clamp(1.0, 4000.0);
    final h = painter.height.ceilToDouble().clamp(1.0, 4000.0);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(_scale);
    painter.paint(canvas, Offset.zero);
    final image = await recorder.endRecording().toImage(
      (w * _scale).ceil(),
      (h * _scale).ceil(),
    );
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    painter.dispose();
    return _Shaped(pw.MemoryImage(png!.buffer.asUint8List()), w, h);
  }
}

/// A table of [PdfTextFn] cells (`TableHelper.fromTextArray` only takes
/// plain strings, which would not shape Bengali).
pw.Widget pdfTable({
  required PdfTextFn t,
  required List<String> headers,
  required List<List<String>> rows,
  required List<bool> numeric,
  Map<int, pw.TableColumnWidth>? widths,
  double fontSize = 9,
  PdfColor ink = const PdfColor.fromInt(0xFF0F172A),
  PdfColor grey = const PdfColor.fromInt(0xFF64748B),
  PdfColor line = const PdfColor.fromInt(0xFFE2E8F0),
  PdfColor? headerFill,
  double vPad = 5,
}) {
  pw.Widget cell(String text, int col, {bool header = false}) => pw.Container(
    alignment: numeric[col]
        ? pw.Alignment.centerRight
        : pw.Alignment.centerLeft,
    padding: pw.EdgeInsets.symmetric(vertical: vPad, horizontal: 5),
    child: t(
      text.replaceAll('\n', ' '),
      size: fontSize,
      bold: header,
      color: header ? grey : ink,
    ),
  );
  return pw.Table(
    columnWidths: widths,
    defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
    border: pw.TableBorder(
      horizontalInside: pw.BorderSide(color: line, width: 0.5),
      bottom: pw.BorderSide(color: line, width: 0.5),
    ),
    children: [
      pw.TableRow(
        repeat: true,
        decoration: pw.BoxDecoration(
          color: headerFill,
          border: pw.Border(bottom: pw.BorderSide(color: line)),
        ),
        children: [
          for (final (i, h) in headers.indexed) cell(h, i, header: true),
        ],
      ),
      for (final r in rows)
        pw.TableRow(children: [for (final (i, c) in r.indexed) cell(c, i)]),
    ],
  );
}
