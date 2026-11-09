import 'package:flutter/widgets.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/status_pill.dart';
import '../domain/sale_summary.dart';

/// Translated labels and pills for sale values (lists, detail, receipts).
extension SaleLabels on AppLocalizations {
  /// paid | partial | due
  String paymentStatusText(String status) => switch (status) {
    'paid' => paymentPaid,
    'partial' => paymentPartial,
    _ => paymentDue,
  };

  /// booked | delivered | cancelled
  String saleStatusText(String status) => switch (status) {
    'booked' => saleBooked,
    'cancelled' => saleCancelled,
    _ => saleDelivered,
  };

  /// instant | booking
  String saleTypeText(String type) =>
      type == 'booking' ? saleTypeBooking : saleTypeInstant;

  /// cash | upi | bank | cheque | other
  String paymentMethodText(String method) => switch (method) {
    'cash' => methodCash,
    'upi' => methodUpi,
    'bank' => methodBank,
    'cheque' => methodCheque,
    _ => methodOther,
  };
}

/// The pill for a sale in a list: "Cancelled" wins, then "Booked",
/// otherwise the payment status (Paid / Partial / Due).
class SaleStatusPill extends StatelessWidget {
  const SaleStatusPill(this.sale, {super.key});

  final SaleSummary sale;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (sale.isCancelled) return StatusPill(l.saleCancelled);
    if (sale.status == 'booked') {
      return StatusPill(l.saleBooked, tone: StatusTone.info);
    }
    return StatusPill(
      l.paymentStatusText(sale.paymentStatus),
      tone: StatusPill.toneFor(sale.paymentStatus),
    );
  }
}
