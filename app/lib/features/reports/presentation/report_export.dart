import 'package:excel/excel.dart' as xl;
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/pdf/pdf_text.dart';
import '../../../core/pdf/pdf_theme.dart';
import 'widgets/report_view.dart';

/// Export of a report (01-PRD REP-7), made on the device from the same
/// [ReportView] the screen shows: PDF (share / print / save through the
/// system) and Excel (.xlsx, shared or downloaded).

/// "flyash-sales-2026-11-01_2026-11-16" (no extension).
String reportFileName(String type, String periodKey) =>
    'flyash-$type${periodKey.isEmpty ? '' : '-$periodKey'}';

/// The PDF: app name, title, period and date, the summary, then each table.
/// Bengali text is shaped by Flutter (see [PdfText]).
Future<Uint8List> buildReportPdf(
  ReportView view, {
  required String generatedOn,
  int accent = 0xFFC2410C,
}) async {
  final theme = await pdfTheme();
  final doc = await PdfText.build(
    (t) => _reportDoc(t, theme, view, generatedOn, accent),
  );
  return doc.save();
}

pw.Document _reportDoc(
  PdfTextFn t,
  pw.ThemeData theme,
  ReportView view,
  String generatedOn,
  int accentColor,
) {
  // The owner's accent in light mode (printed output is always light).
  final accent = PdfColor.fromInt(accentColor);
  const ink = PdfColor.fromInt(0xFF0F172A);
  const grey = PdfColor.fromInt(0xFF64748B);
  const line = PdfColor.fromInt(0xFFE2E8F0);

  final doc = pw.Document(theme: theme, title: view.title);
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Text(
                'FlyAsh',
                style: pw.TextStyle(
                  color: accent,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              pw.Spacer(),
              t(generatedOn, size: 9, color: grey),
            ],
          ),
          pw.SizedBox(height: 6),
          t(view.title, size: 18, bold: true, color: ink),
          if (view.period.isNotEmpty) t(view.period, color: grey),
          pw.SizedBox(height: 12),
        ],
      ),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          '${context.pageNumber} / ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 8, color: grey),
        ),
      ),
      build: (context) => [
        pw.Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            for (final f in view.summary)
              pw.Container(
                width: 120,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: line),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    t(f.label, size: 8, color: grey, maxWidth: 104),
                    pw.SizedBox(height: 2),
                    t(f.value, size: 12, bold: true, color: ink, maxWidth: 104),
                  ],
                ),
              ),
          ],
        ),
        for (final table in view.tables) ...[
          pw.SizedBox(height: 16),
          if (table.title.isNotEmpty) ...[
            t(table.title, size: 12, bold: true, color: ink),
            pw.SizedBox(height: 6),
          ],
          pdfTable(
            t: t,
            headers: [for (final c in table.columns) c.label],
            rows: table.rows,
            numeric: [for (final c in table.columns) c.numeric],
            widths: {
              for (final (i, c) in table.columns.indexed)
                i: pw.FlexColumnWidth(c.flex.toDouble()),
            },
          ),
        ],
      ],
    ),
  );
  return doc;
}

/// The Excel file: one sheet with the title, period, summary and tables.
Uint8List buildReportExcel(ReportView view, {required String generatedOn}) {
  final book = xl.Excel.createExcel();
  final name = view.title.length > 30
      ? view.title.substring(0, 30)
      : view.title;
  book.rename(book.getDefaultSheet()!, name);
  final sheet = book[name];
  final bold = xl.CellStyle(bold: true);

  void row(List<String> values, {bool strong = false}) {
    sheet.appendRow([
      for (final v in values) xl.TextCellValue(v.replaceAll('\n', ' ')),
    ]);
    if (strong) {
      final r = sheet.maxRows - 1;
      for (var c = 0; c < values.length; c++) {
        sheet
                .cell(
                  xl.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r),
                )
                .cellStyle =
            bold;
      }
    }
  }

  row(['FlyAsh · ${view.title}'], strong: true);
  if (view.period.isNotEmpty) row([view.period]);
  row([generatedOn]);
  row([]);
  for (final f in view.summary) {
    row([f.label, f.value]);
  }
  for (final t in view.tables) {
    row([]);
    row([t.title], strong: true);
    row([for (final c in t.columns) c.label], strong: true);
    for (final r in t.rows) {
      row(r);
    }
  }
  return Uint8List.fromList(book.encode()!);
}

/// Opens the system share / print / save for the PDF.
Future<void> sharePdf(Uint8List bytes, String fileName) =>
    Printing.sharePdf(bytes: bytes, filename: '$fileName.pdf');

/// Shares the Excel file (on the web it is downloaded).
Future<void> shareExcel(Uint8List bytes, String fileName) async {
  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(
          bytes,
          name: '$fileName.xlsx',
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      ],
      fileNameOverrides: ['$fileName.xlsx'],
    ),
  );
}
