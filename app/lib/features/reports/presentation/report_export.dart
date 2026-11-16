import 'package:excel/excel.dart' as xl;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'widgets/report_view.dart';

/// Export of a report (01-PRD REP-7), made on the device from the same
/// [ReportView] the screen shows: PDF (share / print / save through the
/// system) and Excel (.xlsx, shared or downloaded).

/// "flyash-sales-2026-11-01_2026-11-16" (no extension).
String reportFileName(String type, String periodKey) =>
    'flyash-$type${periodKey.isEmpty ? '' : '-$periodKey'}';

Future<pw.ThemeData> _pdfTheme() async {
  Future<pw.Font> font(String name) async =>
      pw.Font.ttf(await rootBundle.load('assets/fonts/$name.ttf'));
  final hind = await font('HindSiliguri-Regular');
  return pw.ThemeData.withFont(
    base: await font('Inter-Regular'),
    bold: await font('Inter-SemiBold'),
    // Bengali names (customers, labours) still show.
    fontFallback: [hind],
  );
}

/// The PDF: app name, title, period and date, the summary, then each table.
Future<Uint8List> buildReportPdf(
  ReportView view, {
  required String generatedOn,
}) async {
  final doc = pw.Document(theme: await _pdfTheme(), title: view.title);
  const accent = PdfColor.fromInt(0xFF1D4ED8);
  const grey = PdfColor.fromInt(0xFF64748B);
  const line = PdfColor.fromInt(0xFFE2E8F0);

  pw.Widget table(
    List<String> header,
    List<List<String>> rows,
    List<bool> numeric,
  ) => pw.TableHelper.fromTextArray(
    headers: header,
    data: rows
        .map((r) => r.map((c) => c.replaceAll('\n', ' ')).toList())
        .toList(),
    border: const pw.TableBorder(
      horizontalInside: pw.BorderSide(color: line, width: 0.5),
      bottom: pw.BorderSide(color: line, width: 0.5),
    ),
    headerStyle: pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 9,
      color: grey,
    ),
    cellStyle: const pw.TextStyle(fontSize: 9),
    headerDecoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: line)),
    ),
    cellAlignments: {
      for (var i = 0; i < numeric.length; i++)
        i: numeric[i] ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
    },
    headerAlignments: {
      for (var i = 0; i < numeric.length; i++)
        i: numeric[i] ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
    },
    cellPadding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
  );

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
              pw.Text(
                generatedOn,
                style: const pw.TextStyle(fontSize: 9, color: grey),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            view.title,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          if (view.period.isNotEmpty)
            pw.Text(
              view.period,
              style: const pw.TextStyle(fontSize: 10, color: grey),
            ),
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
                    pw.Text(
                      f.label,
                      style: const pw.TextStyle(fontSize: 8, color: grey),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      f.value,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        for (final t in view.tables) ...[
          pw.SizedBox(height: 16),
          pw.Text(
            t.title,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          table(
            [for (final c in t.columns) c.label],
            t.rows,
            [for (final c in t.columns) c.numeric],
          ),
        ],
      ],
    ),
  );
  return doc.save();
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
