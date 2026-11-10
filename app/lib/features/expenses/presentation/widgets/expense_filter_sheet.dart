import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/dates.dart';
import '../../../../core/utils/formatters.dart';
import '../../../sales/presentation/widgets/sale_filter_sheet.dart'
    show presetText;

/// The expenses list filter: a period (default this month) and a category.
@immutable
class ExpenseFilter {
  const ExpenseFilter({
    required this.preset,
    required this.range,
    this.category,
  });

  final DatePreset preset;
  final DateRange range;

  /// null = all categories
  final String? category;

  static ExpenseFilter initial(String today) => ExpenseFilter(
    preset: DatePreset.thisMonth,
    range: DateRange.preset(DatePreset.thisMonth, today),
  );

  /// Filters other than the default "this month, all categories".
  int get activeCount =>
      (preset != DatePreset.thisMonth ? 1 : 0) + (category != null ? 1 : 0);

  ExpenseFilter copyWith({
    DatePreset? preset,
    DateRange? range,
    String? Function()? category,
  }) => ExpenseFilter(
    preset: preset ?? this.preset,
    range: range ?? this.range,
    category: category != null ? category() : this.category,
  );

  /// "This month" or "01 Nov 2026 – 09 Nov 2026".
  String periodText(AppLocalizations l) {
    if (preset != DatePreset.custom) return presetText(l, preset);
    if (range.from == range.to) return Fmt.date(range.from);
    return '${Fmt.date(range.from)} – ${Fmt.date(range.to)}';
  }
}

/// Bottom sheet: period and category. Pops with the new filter.
Future<ExpenseFilter?> showExpenseFilterSheet(
  BuildContext context, {
  required ExpenseFilter filter,
  required List<String> categories,
  required String today,
}) => showModalBottomSheet<ExpenseFilter>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useRootNavigator: true,
  constraints: const BoxConstraints(maxWidth: 560),
  builder: (_) =>
      _ExpenseFilterSheet(filter: filter, categories: categories, today: today),
);

class _ExpenseFilterSheet extends StatefulWidget {
  const _ExpenseFilterSheet({
    required this.filter,
    required this.categories,
    required this.today,
  });

  final ExpenseFilter filter;
  final List<String> categories;
  final String today;

  @override
  State<_ExpenseFilterSheet> createState() => _ExpenseFilterSheetState();
}

class _ExpenseFilterSheetState extends State<_ExpenseFilterSheet> {
  late ExpenseFilter _f = widget.filter;

  Future<void> _choosePreset(DatePreset p) async {
    if (p != DatePreset.custom) {
      setState(
        () => _f = _f.copyWith(
          preset: p,
          range: DateRange.preset(p, widget.today),
        ),
      );
      return;
    }
    DateTime local(String ymd) {
      final d = Ymd.parse(ymd);
      return DateTime(d.year, d.month, d.day);
    }

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: local(widget.today),
      initialDateRange: DateTimeRange(
        start: local(_f.range.from ?? widget.today),
        end: local(_f.range.to ?? widget.today),
      ),
    );
    if (picked == null) return;
    String ymd(DateTime d) => Ymd.format(DateTime.utc(d.year, d.month, d.day));
    setState(
      () => _f = _f.copyWith(
        preset: DatePreset.custom,
        range: DateRange(from: ymd(picked.start), to: ymd(picked.end)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    // A category chosen earlier stays listed even if it is not suggested.
    final categories = [
      ...widget.categories,
      if (_f.category != null && !widget.categories.contains(_f.category))
        _f.category!,
    ];

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
              l.filterExpenses,
              style: AppTypography.h3.copyWith(color: t.textPrimary),
            ),
            caption(l.date),
            Wrap(
              spacing: Space.s2,
              runSpacing: Space.s2,
              children: [
                for (final p in const [
                  DatePreset.today,
                  DatePreset.thisWeek,
                  DatePreset.thisMonth,
                  DatePreset.lastMonth,
                  DatePreset.custom,
                ])
                  ChoiceChip(
                    avatar: p == DatePreset.custom
                        ? const Icon(Icons.date_range, size: 18)
                        : null,
                    label: Text(
                      p == DatePreset.custom && _f.preset == p
                          ? _f.periodText(l)
                          : presetText(l, p),
                    ),
                    selected: _f.preset == p,
                    onSelected: (_) => _choosePreset(p),
                  ),
              ],
            ),
            caption(l.category),
            Wrap(
              spacing: Space.s2,
              runSpacing: Space.s2,
              children: [
                ChoiceChip(
                  label: Text(l.allCategories),
                  selected: _f.category == null,
                  onSelected: (_) =>
                      setState(() => _f = _f.copyWith(category: () => null)),
                ),
                for (final c in categories)
                  ChoiceChip(
                    label: Text(c),
                    selected: _f.category == c,
                    onSelected: (_) =>
                        setState(() => _f = _f.copyWith(category: () => c)),
                  ),
              ],
            ),
            const SizedBox(height: Space.s6),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(ExpenseFilter.initial(widget.today)),
                    child: Text(l.reset),
                  ),
                ),
                const SizedBox(width: Space.s3),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(_f),
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
