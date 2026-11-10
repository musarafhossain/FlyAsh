import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/date_field.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../../sales/presentation/pages/sale_form_page.dart'
    show kPaymentMethods;
import '../../../sales/presentation/sale_labels.dart';

/// What a money sheet returns.
class MoneyEntry {
  const MoneyEntry({
    required this.amount,
    required this.date,
    this.method = 'cash',
    this.note,
  });

  final String amount;
  final String date;
  final String method;
  final String? note;
}

Future<MoneyEntry?> _sheet(BuildContext context, Widget child) =>
    showModalBottomSheet<MoneyEntry>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Space.s5, 0, Space.s5, Space.s5),
          child: child,
        ),
      ),
    );

/// Pay wage (03-AppFlow §7.3): amount prefilled with the balance, date,
/// method, note. Partial payments are allowed.
Future<MoneyEntry?> showPayWageSheet(
  BuildContext context, {
  required String labourName,
  required String month,
  required String balance,
  required String today,
}) {
  final due = Decimal.tryParse(balance) ?? Decimal.zero;
  return _sheet(
    context,
    _MoneySheet(
      title: context.l10n.payWageTitle(labourName, Fmt.month(month)),
      hint: due > Decimal.zero
          ? context.l10n.balanceAmount(Fmt.money(balance))
          : null,
      initialAmount: due > Decimal.zero ? due.toString() : '',
      defaultDate: today,
      today: today,
      withMethod: true,
      submitLabel: context.l10n.payWage,
    ),
  );
}

class _MoneySheet extends StatefulWidget {
  const _MoneySheet({
    required this.title,
    required this.defaultDate,
    required this.today,
    required this.withMethod,
    required this.submitLabel,
    this.hint,
    this.initialAmount = '',
  });

  final String title;
  final String? hint;
  final String initialAmount;
  final String defaultDate;
  final String today;
  final bool withMethod;
  final String submitLabel;

  @override
  State<_MoneySheet> createState() => _MoneySheetState();
}

class _MoneySheetState extends State<_MoneySheet> {
  final _form = GlobalKey<FormState>();
  late final _amount = TextEditingController(text: widget.initialAmount);
  final _note = TextEditingController();
  late String _date = widget.defaultDate;
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
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            style: AppTypography.h3.copyWith(color: t.textPrimary),
          ),
          if (widget.hint != null)
            Text(
              widget.hint!,
              style: AppTypography.body.copyWith(color: t.textSecondary),
            ),
          const SizedBox(height: Space.s4),
          MoneyField(
            controller: _amount,
            label: l.amount,
            validator: (x) {
              final e = v.money(x);
              if (e != null) return e;
              return Decimal.parse(x!.trim()) > Decimal.zero
                  ? null
                  : l.invalidAmount;
            },
          ),
          const SizedBox(height: Space.s3),
          DateField(
            label: l.date,
            value: _date,
            first: '2020-01-01',
            last: widget.today,
            onChanged: (d) => setState(() => _date = d),
          ),
          if (widget.withMethod) ...[
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
          ],
          const SizedBox(height: Space.s3),
          TextFormField(
            controller: _note,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: l.notesOptional,
              counterText: '',
            ),
          ),
          const SizedBox(height: Space.s4),
          FilledButton(
            onPressed: () {
              if (!_form.currentState!.validate()) return;
              Navigator.of(context).pop(
                MoneyEntry(
                  amount: _amount.text.trim(),
                  date: _date,
                  method: _method,
                  note: textOrNull(_note),
                ),
              );
            },
            child: Text(widget.submitLabel),
          ),
        ],
      ),
    );
  }
}
