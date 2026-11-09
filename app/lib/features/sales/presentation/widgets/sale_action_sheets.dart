import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/dates.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../domain/sale.dart';
import '../pages/sale_form_page.dart' show kPaymentMethods;
import '../sale_labels.dart';

DateTime _local(String ymd) {
  final d = Ymd.parse(ymd);
  return DateTime(d.year, d.month, d.day);
}

String _ymd(DateTime d) => Ymd.format(DateTime.utc(d.year, d.month, d.day));

/// Date row that opens a date picker between [first] and [last].
class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.value,
    required this.first,
    required this.last,
    required this.onChanged,
  });

  final String label;
  final String value;
  final String first;
  final String last;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: Radii.mdAll,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _local(value),
          firstDate: _local(first),
          lastDate: _local(last),
        );
        if (picked != null) onChanged(_ymd(picked));
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.event),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(Fmt.date(value)),
      ),
    );
  }
}

Future<T?> _sheet<T>(BuildContext context, Widget child) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (context) => Padding(
        // Keeps the fields above the keyboard.
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Space.s5, 0, Space.s5, Space.s5),
          child: child,
        ),
      ),
    );

/// Add payment (03-AppFlow §5.2): amount prefilled with the due, date
/// (today), method, note. Pops with a [PaymentInput].
Future<PaymentInput?> showAddPaymentSheet(
  BuildContext context, {
  required Sale sale,
  required String today,
}) => _sheet(context, _AddPaymentSheet(sale: sale, today: today));

class _AddPaymentSheet extends StatefulWidget {
  const _AddPaymentSheet({required this.sale, required this.today});

  final Sale sale;
  final String today;

  @override
  State<_AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends State<_AddPaymentSheet> {
  final _form = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: (Decimal.tryParse(widget.sale.summary.dueAmount) ?? Decimal.zero)
        .toString(),
  );
  final _note = TextEditingController();
  late String _date = widget.today;
  String _method = 'cash';

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final v = Validators.of(context);
    final due = Decimal.tryParse(widget.sale.summary.dueAmount) ?? Decimal.zero;
    final saleDate = widget.sale.summary.saleDate;

    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.addPayment,
            style: AppTypography.h3.copyWith(color: t.textPrimary),
          ),
          Text(
            l.dueAmount(Fmt.money(widget.sale.summary.dueAmount)),
            style: AppTypography.body.copyWith(color: t.error),
          ),
          const SizedBox(height: Space.s4),
          MoneyField(
            controller: _amount,
            label: l.amount,
            validator: (x) {
              final e = v.money(x);
              if (e != null) return e;
              final value = Decimal.parse(x!.trim());
              if (value <= Decimal.zero) return l.invalidAmount;
              return value > due
                  ? l.cannotExceedDue(Fmt.money(due.toString(), decimals: true))
                  : null;
            },
          ),
          const SizedBox(height: Space.s3),
          _DateRow(
            label: l.paymentDate,
            value: _date,
            first: saleDate.compareTo(widget.today) > 0
                ? widget.today
                : saleDate,
            last: widget.today,
            onChanged: (d) => setState(() => _date = d),
          ),
          const SizedBox(height: Space.s3),
          Wrap(
            spacing: Space.s2,
            runSpacing: Space.s2,
            children: [
              for (final m in kPaymentMethods)
                ChoiceChip(
                  label: Text(l.paymentMethodText(m)),
                  selected: _method == m,
                  onSelected: (_) => setState(() => _method = m),
                ),
            ],
          ),
          const SizedBox(height: Space.s3),
          TextFormField(
            controller: _note,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: l.paymentNoteOptional,
              counterText: '',
            ),
          ),
          const SizedBox(height: Space.s4),
          FilledButton(
            onPressed: () {
              if (!_form.currentState!.validate()) return;
              Navigator.of(context).pop(
                PaymentInput(
                  amount: _amount.text.trim(),
                  method: _method,
                  note: textOrNull(_note),
                  paymentDate: _date,
                ),
              );
            },
            child: Text(l.addPayment),
          ),
        ],
      ),
    );
  }
}

/// Mark delivered (03-AppFlow §5.2): delivered date, default today.
/// Pops with the date.
Future<String?> showDeliverSheet(
  BuildContext context, {
  required String invoiceNo,
  required String saleDate,
  required String today,
}) => _sheet(
  context,
  _DeliverSheet(invoiceNo: invoiceNo, saleDate: saleDate, today: today),
);

class _DeliverSheet extends StatefulWidget {
  const _DeliverSheet({
    required this.invoiceNo,
    required this.saleDate,
    required this.today,
  });

  final String invoiceNo;
  final String saleDate;
  final String today;

  @override
  State<_DeliverSheet> createState() => _DeliverSheetState();
}

class _DeliverSheetState extends State<_DeliverSheet> {
  late String _date = widget.today;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.markDeliveredTitle(widget.invoiceNo),
          style: AppTypography.h3.copyWith(color: t.textPrimary),
        ),
        const SizedBox(height: Space.s4),
        _DateRow(
          label: l.deliveredOn,
          value: _date,
          first: widget.saleDate.compareTo(widget.today) > 0
              ? widget.today
              : widget.saleDate,
          last: widget.today,
          onChanged: (d) => setState(() => _date = d),
        ),
        const SizedBox(height: Space.s4),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(_date),
          icon: const Icon(Icons.check),
          label: Text(l.markDelivered),
        ),
      ],
    );
  }
}
