import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/pdf/pdf_text.dart';
import '../../../core/pdf/pdf_theme.dart';
import '../../../core/utils/contact_launcher.dart';
import '../../../core/utils/formatters.dart';
import '../../settings/domain/factory_settings.dart';
import '../domain/sale.dart';
import 'sale_labels.dart';

/// Sale receipt PDF (01-PRD SALE-14, F17), made on the device: the bundled
/// logo and the factory profile, invoice no. and dates, customer, items,
/// totals (2 decimals), paid and due, payments. Always light, in the
/// owner's accent colour (04-UI-UX §5: printed output), in the app language.

/// "INV-000101" → "INV-000101" (a file name: no slashes or spaces).
String receiptFileName(String invoiceNo) =>
    invoiceNo.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '-');

bool _isZero(String v) => (Decimal.tryParse(v) ?? Decimal.zero) == Decimal.zero;

Future<Uint8List> buildReceiptPdf({
  required Sale sale,
  required FactorySettings factory,
  required AppLocalizations l,
  required int accent,
  required String generatedOn,
}) async {
  final theme = await pdfTheme();
  final logo = pw.MemoryImage(
    (await rootBundle.load('assets/images/logo.png')).buffer.asUint8List(),
  );
  final doc = await PdfText.build(
    (t) => _receipt(t, theme, logo, sale, factory, l, accent, generatedOn),
  );
  return doc.save();
}

pw.Document _receipt(
  PdfTextFn t,
  pw.ThemeData theme,
  pw.MemoryImage logo,
  Sale sale,
  FactorySettings factory,
  AppLocalizations l,
  int accent,
  String generatedOn,
) {
  final brand = PdfColor.fromInt(accent);
  const ink = PdfColor.fromInt(0xFF0F172A);
  const grey = PdfColor.fromInt(0xFF64748B);
  const line = PdfColor.fromInt(0xFFE2E8F0);
  const soft = PdfColor.fromInt(0xFFF8FAFC);
  const red = PdfColor.fromInt(0xFFB91C1C);
  final s = sale.summary;
  const money = Fmt.moneyFixed;

  pw.Widget label(String text) =>
      t(text.toUpperCase(), size: 8, bold: true, color: grey);
  pw.Widget small(String text, {PdfColor color = grey, double? maxWidth}) =>
      t(text, size: 9, color: color, maxWidth: maxWidth);
  pw.Widget gap(double h) => pw.SizedBox(height: h);

  pw.Widget totalRow(
    String name,
    String value, {
    bool strong = false,
    PdfColor color = ink,
  }) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
    child: pw.Row(
      children: [
        pw.Expanded(
          child: pw.Align(
            alignment: pw.Alignment.centerLeft,
            child: t(
              name,
              size: strong ? 11 : 9.5,
              bold: strong,
              color: strong ? ink : grey,
            ),
          ),
        ),
        t(value, size: strong ? 11 : 9.5, bold: strong, color: color),
      ],
    ),
  );

  final factoryLines = [
    if (factory.address?.isNotEmpty ?? false) factory.address!,
    [
      if (factory.phone?.isNotEmpty ?? false) factory.phone!,
      if (factory.email?.isNotEmpty ?? false) factory.email!,
    ].join(' · '),
  ].where((x) => x.isNotEmpty);

  final doc = pw.Document(theme: theme, title: s.invoiceNo);
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 32, 36, 32),
      footer: (context) => pw.Row(
        children: [
          small(generatedOn),
          pw.Spacer(),
          if (context.pagesCount > 1)
            pw.Text(
              '${context.pageNumber} / ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 9, color: grey),
            ),
        ],
      ),
      build: (context) => [
        // Header: logo + factory · receipt title + invoice no.
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Image(logo, width: 52, height: 52),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  t(
                    factory.factoryName.isEmpty
                        ? 'FlyAsh'
                        : factory.factoryName,
                    size: 16,
                    bold: true,
                    color: ink,
                    maxWidth: 300,
                  ),
                  for (final x in factoryLines) ...[
                    gap(2),
                    small(x, maxWidth: 300),
                  ],
                ],
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                t(l.receipt, size: 18, bold: true, color: brand),
                gap(2),
                t(s.invoiceNo, size: 11, bold: true, color: ink),
                small(l.saleTypeText(s.type)),
              ],
            ),
          ],
        ),
        gap(14),
        pw.Container(height: 2, color: brand),
        gap(14),

        // Bill to · dates.
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  label(l.billTo),
                  gap(4),
                  t(s.customerName ?? '-', size: 11, bold: true, color: ink),
                  if (s.customerPhone?.isNotEmpty ?? false)
                    small(s.customerPhone!),
                  if (sale.customerAddress?.isNotEmpty ?? false)
                    small(sale.customerAddress!, maxWidth: 280),
                  if (sale.deliveryAddress?.isNotEmpty ?? false) ...[
                    gap(8),
                    label(l.deliverTo),
                    gap(4),
                    small(sale.deliveryAddress!, color: ink, maxWidth: 280),
                  ],
                ],
              ),
            ),
            pw.SizedBox(width: 16),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                label(l.saleDate),
                gap(4),
                t(Fmt.date(s.saleDate), color: ink),
                if (sale.deliveredDate != null) ...[
                  gap(8),
                  label(l.deliveredOnLabel),
                  gap(4),
                  t(Fmt.date(sale.deliveredDate), color: ink),
                ] else if (s.deliveryDate != null) ...[
                  gap(8),
                  label(l.deliveryDate),
                  gap(4),
                  t(Fmt.date(s.deliveryDate), color: ink),
                ],
                gap(8),
                label(l.status),
                gap(4),
                t(
                  s.isCancelled
                      ? l.saleCancelled
                      : l.paymentStatusText(s.paymentStatus),
                  bold: true,
                  color: s.isCancelled || !_isZero(s.dueAmount) ? red : ink,
                ),
              ],
            ),
          ],
        ),
        gap(18),

        // Items.
        pdfTable(
          t: t,
          headers: [
            '#',
            l.productColumn,
            l.quantityColumn,
            l.rateColumn,
            l.amountColumn,
          ],
          rows: [
            for (final (i, item) in sale.items.indexed)
              [
                '${i + 1}',
                item.productName,
                Fmt.count(item.quantity),
                money(item.unitPrice),
                money(item.lineTotal),
              ],
          ],
          numeric: const [false, false, true, true, true],
          widths: const {
            0: pw.FixedColumnWidth(30),
            1: pw.FlexColumnWidth(4),
            2: pw.FlexColumnWidth(2),
            3: pw.FlexColumnWidth(2),
            4: pw.FlexColumnWidth(2.4),
          },
          fontSize: 9.5,
          headerFill: soft,
          vPad: 6,
        ),
        gap(12),

        // Payments (left) · totals (right).
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 5,
              child: sale.payments.isEmpty
                  ? pw.SizedBox()
                  : pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        label(l.paymentsTitle),
                        gap(4),
                        for (final p in sale.payments)
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 2),
                            child: pw.Row(
                              children: [
                                pw.SizedBox(
                                  width: 70,
                                  child: small(Fmt.date(p.paymentDate)),
                                ),
                                pw.Expanded(
                                  child: small(l.paymentMethodText(p.method)),
                                ),
                                small(money(p.amount), color: ink),
                                pw.SizedBox(width: 24),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
            pw.Expanded(
              flex: 4,
              child: pw.Column(
                children: [
                  totalRow(l.subtotal, money(sale.subtotal)),
                  if (!_isZero(sale.transportCharge))
                    totalRow(l.transport, '+ ${money(sale.transportCharge)}'),
                  if (!_isZero(sale.discount))
                    totalRow(l.discount, '- ${money(sale.discount)}'),
                  if (!_isZero(sale.taxAmount))
                    totalRow(
                      l.taxLine(
                        (Decimal.tryParse(sale.taxPercent) ?? Decimal.zero)
                            .toString(),
                      ),
                      '+ ${money(sale.taxAmount)}',
                    ),
                  pw.Divider(color: line, height: 10, thickness: 0.8),
                  totalRow(l.total, money(s.total), strong: true),
                  totalRow(l.paid, money(s.paidAmount)),
                  pw.Container(
                    margin: const pw.EdgeInsets.only(top: 4),
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: pw.BoxDecoration(
                      color: soft,
                      border: pw.Border.all(color: line),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: totalRow(
                      l.due,
                      money(s.dueAmount),
                      strong: true,
                      color: _isZero(s.dueAmount) ? ink : red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        if (sale.notes?.isNotEmpty ?? false) ...[
          gap(16),
          label(l.note),
          gap(4),
          small(sale.notes!, color: ink, maxWidth: 480),
        ],
        gap(28),
        pw.Center(child: t(l.receiptThanks, color: brand)),
      ],
    ),
  );
  return doc;
}

/// What happened when sending the receipt to WhatsApp.
enum WhatsAppSend { sent, notInstalled }

/// Where a receipt goes. Tests replace [share] / [print] / [whatsApp].
abstract final class ReceiptOutput {
  /// The customer's WhatsApp chat with the PDF. Android: WhatsApp (or
  /// WhatsApp Business) opens that chat with the receipt attached. Web and
  /// Windows cannot attach a file to a chat: the PDF is saved (downloaded)
  /// and the chat opens with [text] typed in, to attach it there.
  static Future<WhatsAppSend> Function(
    Uint8List bytes,
    String fileName,
    String phone,
    String text,
  )
  whatsApp = _whatsApp;

  /// Share sheet (WhatsApp, mail, Files …); on the web the file downloads,
  /// on Windows a save dialog opens.
  static Future<void> Function(Uint8List bytes, String fileName) share =
      (bytes, fileName) =>
          Printing.sharePdf(bytes: bytes, filename: '$fileName.pdf');

  /// System print dialog (it also offers "Save as PDF").
  static Future<void> Function(Uint8List bytes, String fileName) print =
      (bytes, fileName) =>
          Printing.layoutPdf(name: fileName, onLayout: (_) async => bytes);
}

const _whatsAppChannel = MethodChannel('flyash/whatsapp');

Future<WhatsAppSend> _whatsApp(
  Uint8List bytes,
  String fileName,
  String phone,
  String text,
) async {
  final number = ContactLauncher.waNumber(phone);
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    // In cache/receipts/ (shared through the app's FileProvider).
    final dir = Directory('${(await getTemporaryDirectory()).path}/receipts');
    await dir.create(recursive: true);
    final file = File('${dir.path}/$fileName.pdf');
    await file.writeAsBytes(bytes, flush: true);
    final result = await _whatsAppChannel.invokeMethod<String>('sendFile', {
      'path': file.path,
      'phone': number,
      'text': text,
    });
    return result == 'sent' ? WhatsAppSend.sent : WhatsAppSend.notInstalled;
  }
  await ReceiptOutput.share(bytes, fileName);
  if (!await ContactLauncher.whatsApp(phone, text: text)) {
    throw StateError('could not open WhatsApp');
  }
  return WhatsAppSend.sent;
}
