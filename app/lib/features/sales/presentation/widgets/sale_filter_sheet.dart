import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/dates.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/sale.dart';
import '../sale_labels.dart';

/// Statuses the sales list can filter by (07-API GET /sales `status`).
const kSaleStatuses = [
  'paid',
  'partial',
  'due',
  'booked',
  'delivered',
  'cancelled',
];

/// Translated name of a date preset.
String presetText(AppLocalizations l, DatePreset p) => switch (p) {
  DatePreset.today => l.presetToday,
  DatePreset.yesterday => l.presetYesterday,
  DatePreset.thisWeek => l.presetThisWeek,
  DatePreset.thisMonth => l.presetThisMonth,
  DatePreset.lastMonth => l.presetLastMonth,
  DatePreset.custom => l.presetCustom,
};

/// "This month" or "01 Nov 2026 – 09 Nov 2026" for the active range.
String rangeText(AppLocalizations l, SaleFilter f) {
  if (f.preset != null && f.preset != DatePreset.custom) {
    return presetText(l, f.preset!);
  }
  final from = f.range.from;
  final to = f.range.to;
  if (from == to) return Fmt.date(from);
  return '${Fmt.date(from)} – ${Fmt.date(to)}';
}

/// Bottom sheet: date range (presets from the factory's today, or a
/// custom range) and status. Pops with the new [SaleFilter].
Future<SaleFilter?> showSaleFilterSheet(
  BuildContext context, {
  required SaleFilter filter,
  required String today,
}) => showModalBottomSheet<SaleFilter>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  constraints: const BoxConstraints(maxWidth: 560),
  builder: (_) => _SaleFilterSheet(filter: filter, today: today),
);

class _SaleFilterSheet extends StatefulWidget {
  const _SaleFilterSheet({required this.filter, required this.today});

  final SaleFilter filter;
  final String today;

  @override
  State<_SaleFilterSheet> createState() => _SaleFilterSheetState();
}

class _SaleFilterSheetState extends State<_SaleFilterSheet> {
  late DatePreset? _preset = widget.filter.preset;
  late DateRange _range = widget.filter.range;
  late String? _status = widget.filter.status;

  Future<void> _pickCustom() async {
    final first = DateTime(2020);
    final last = Ymd.parse(widget.today);
    final lastLocal = DateTime(last.year, last.month, last.day);
    DateTime local(String ymd) {
      final d = Ymd.parse(ymd);
      return DateTime(d.year, d.month, d.day);
    }

    final picked = await showDateRangePicker(
      context: context,
      firstDate: first,
      lastDate: lastLocal,
      initialDateRange: _range.isEmpty
          ? null
          : DateTimeRange(
              start: local(_range.from ?? widget.today),
              end: local(_range.to ?? widget.today),
            ),
    );
    if (picked == null) return;
    String ymd(DateTime d) => Ymd.format(DateTime.utc(d.year, d.month, d.day));
    setState(() {
      _preset = DatePreset.custom;
      _range = DateRange(from: ymd(picked.start), to: ymd(picked.end));
    });
  }

  void _choosePreset(DatePreset? preset) {
    if (preset == DatePreset.custom) {
      _pickCustom();
      return;
    }
    setState(() {
      _preset = preset;
      _range = preset == null
          ? const DateRange()
          : DateRange.preset(preset, widget.today);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final customLabel = _preset == DatePreset.custom && !_range.isEmpty
        ? rangeText(l, SaleFilter(range: _range, preset: DatePreset.custom))
        : l.presetCustom;

    Widget caption(String text) => Padding(
      padding: const EdgeInsets.only(top: Space.s4, bottom: Space.s2),
      child: Text(
        text,
        style: AppTypography.label.copyWith(color: t.textSecondary),
      ),
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.s5, 0, Space.s5, Space.s5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.filterSales,
              style: AppTypography.h3.copyWith(color: t.textPrimary),
            ),
            caption(l.date),
            Wrap(
              spacing: Space.s2,
              runSpacing: Space.s2,
              children: [
                ChoiceChip(
                  label: Text(l.anyDate),
                  selected: _preset == null,
                  onSelected: (_) => _choosePreset(null),
                ),
                for (final p in DatePreset.values)
                  ChoiceChip(
                    avatar: p == DatePreset.custom
                        ? const Icon(Icons.date_range, size: 18)
                        : null,
                    label: Text(
                      p == DatePreset.custom ? customLabel : presetText(l, p),
                    ),
                    selected: _preset == p,
                    onSelected: (_) => _choosePreset(p),
                  ),
              ],
            ),
            caption(l.status),
            Wrap(
              spacing: Space.s2,
              runSpacing: Space.s2,
              children: [
                ChoiceChip(
                  label: Text(l.filterAll),
                  selected: _status == null,
                  onSelected: (_) => setState(() => _status = null),
                ),
                for (final s in kSaleStatuses)
                  ChoiceChip(
                    label: Text(
                      ['paid', 'partial', 'due'].contains(s)
                          ? l.paymentStatusText(s)
                          : l.saleStatusText(s),
                    ),
                    selected: _status == s,
                    onSelected: (_) => setState(() => _status = s),
                  ),
              ],
            ),
            const SizedBox(height: Space.s6),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(
                      widget.filter.copyWith(
                        status: () => null,
                        range: const DateRange(),
                        preset: () => null,
                      ),
                    ),
                    child: Text(l.reset),
                  ),
                ),
                const SizedBox(width: Space.s3),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(
                      widget.filter.copyWith(
                        status: () => _status,
                        range: _range,
                        preset: () => _preset,
                      ),
                    ),
                    child: Text(l.apply),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
