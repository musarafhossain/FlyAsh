import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flyash/core/l10n/l10n.dart';
import 'package:flyash/features/sales/domain/sale.dart';
import 'package:flyash/features/sales/presentation/receipt_pdf.dart';
import 'package:flyash/features/settings/domain/factory_settings.dart';
import 'package:flyash/l10n/app_localizations_bn.dart';
import 'package:flyash/l10n/app_localizations_en.dart';

import 'sale_actions_test.dart' show fromMenu;
import 'sale_form_test.dart';

/// Captures what would be shared / printed.
final sent = <(String how, Uint8List bytes, String name)>[];

void main() {
  setUp(() {
    sent.clear();
    ReceiptOutput.share = (b, n) async => sent.add(('share', b, n));
    ReceiptOutput.print = (b, n) async => sent.add(('print', b, n));
  });

  // The PDF is built with real async work (fonts, logo), so the taps run
  // the build outside the fake clock.
  Future<void> tapAndBuild(WidgetTester tester, String label) async {
    await fromMenu(tester, label);
    for (var i = 0; i < 50 && sent.isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  testWidgets('⋮ Share receipt: a PDF named after the invoice', (tester) async {
    await openAt(tester, '/sales/104');
    await tapAndBuild(tester, 'Share receipt');
    expect(sent, hasLength(1));
    final (how, bytes, name) = sent.single;
    expect(how, 'share');
    expect(name, 'INV-000104');
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(
      backend.requests.where((r) => r.path == '/settings/factory'),
      isNotEmpty,
      reason: 'factory name and address come from Settings',
    );
  });

  testWidgets('⋮ Print receipt opens the print dialog', (tester) async {
    await openAt(tester, '/sales/104');
    await tapAndBuild(tester, 'Print receipt');
    expect(sent.single.$1, 'print');
  });

  testWidgets('no factory profile → "Could not make the receipt"', (
    tester,
  ) async {
    await openAt(tester, '/sales/104');
    backend.factory = null;
    await fromMenu(tester, 'Share receipt');
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(sent, isEmpty);
    expect(find.text('Could not make the receipt'), findsOneWidget);
  });

  group('buildReceiptPdf', () {
    final sale = Sale.fromJson({
      'id': '7',
      'invoice_no': 'INV-000007',
      'type': 'booking',
      'status': 'delivered',
      'sale_date': '2026-11-01',
      'delivery_date': '2026-11-05',
      'delivered_date': '2026-11-05',
      'total': '33075.00',
      'paid_amount': '10000.00',
      'due_amount': '23075.00',
      'payment_status': 'partial',
      'customer_id': '1',
      'customer': {
        'name': 'রহিম ট্রেডার্স',
        'phone': '9830000000',
        'address': 'কৃষ্ণনগর, নদিয়া',
      },
      'delivery_address': 'Site 4, NH-12',
      'subtotal': '30000.00',
      'transport_charge': '1500.00',
      'discount': '500.00',
      'tax_percent': '5.00',
      'tax_amount': '1575.00',
      'notes': 'Deliver before noon',
      'items': [
        for (var i = 0; i < 30; i++)
          {
            'product_id': '1',
            'product_name': i.isEven ? 'Fly Ash Brick' : 'ফ্লাই অ্যাশ ইট',
            'quantity': '1000.00',
            'unit_price': '1.00',
            'line_total': '1000.00',
          },
      ],
      'payments': [
        {
          'id': '1',
          'amount': '10000.00',
          'payment_date': '2026-11-01',
          'method': 'upi',
        },
      ],
    });
    const factory = FactorySettings(
      factoryName: 'মা তারা ইটভাটা',
      phone: '9830012345',
      address: 'Krishnanagar',
    );

    for (final (lang, l) in [
      ('en', AppLocalizationsEn() as AppLocalizations),
      ('bn', AppLocalizationsBn()),
    ]) {
      testWidgets('$lang: Bengali text, all lines, 30 items (2 pages)', (
        tester,
      ) async {
        final bytes = await tester.runAsync(
          () => buildReceiptPdf(
            sale: sale,
            factory: factory,
            l: l,
            accent: 0xFF1A56F0,
            generatedOn: 'Generated on 16 Nov 2026',
          ),
        );
        expect(String.fromCharCodes(bytes!.take(5)), '%PDF-');
        final text = String.fromCharCodes(bytes);
        expect(
          RegExp(r'/Type\s*/Page\b').allMatches(text).length,
          2,
          reason: 'long sales continue on a second page',
        );
      });
    }
  });

  test('file names keep letters, digits, - and _', () {
    expect(receiptFileName('INV-000101'), 'INV-000101');
    expect(receiptFileName('FA/24 007'), 'FA-24-007');
  });
}
