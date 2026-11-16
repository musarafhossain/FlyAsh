import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/network/data_changed.dart';
import '../../../../core/network/query_cache.dart';
import '../../../../core/network/session.dart';
import '../../../../core/router/app_bar_actions.dart';
import '../../../../core/router/app_shell.dart';
import '../../../../core/router/section_app_bar.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/dates.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../../../core/widgets/form_submit.dart';
import '../../../../core/widgets/state_views.dart';
import '../../data/attendance_repository_impl.dart';
import '../../domain/attendance.dart';
import '../../../../core/widgets/search_field.dart';
import '../../../../core/router/section_events.dart';
import '../../../../core/widgets/skeletons.dart';

/// Attendance for a day: ‹ date › (no future), search, and one row per
/// labour with a switch. Turning a switch on marks the labour present (a row
/// is saved); turning it off marks them absent (the row is removed). Each
/// switch saves at once, so there is no Save button.
///
/// Each row shows the day wage: the saved wage when present, the labour's
/// wage for one day when absent. ✏ (only while absent) edits the wage that
/// will be saved when the labour is marked present for this day.
class AttendancePage extends ConsumerStatefulWidget {
  const AttendancePage({super.key, this.initialDate});

  /// From `?date=YYYY-MM-DD`; default today.
  final String? initialDate;

  @override
  ConsumerState<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends ConsumerState<AttendancePage> {
  late String _date = _validDate(widget.initialDate);
  AttendanceDay? _day;
  Object? _error;
  final _search = TextEditingController();

  /// Labour id → present, as shown (changes before the server answers).
  final Map<String, bool> _present = {};

  /// Labours whose switch is being saved.
  final Set<String> _saving = {};

  /// Labour id → day wage set with ✏ (not the usual one), sent when the
  /// labour is marked present. Kept while this list is open, also after
  /// switching to absent, so a wage of 300 stays 300 (↺ goes back to the
  /// usual wage).
  final Map<String, String> _wages = {};

  /// The wage shown for [e]: the saved one when present, else the one set
  /// with ✏, else the usual wage.
  String _wageOf(AttendanceEntry e, bool present) =>
      present ? e.dayWage : (_wages[e.labourId] ?? e.defaultDayWage);

  static bool _same(String a, String b) => Decimal.parse(a) == Decimal.parse(b);

  String get _today => ref.read(businessDateProvider);

  String _validDate(String? ymd) {
    final today = ref.read(businessDateProvider);
    final ok = ymd != null && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(ymd);
    return ok && ymd.compareTo(today) <= 0 ? ymd : today;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final date = _date;
    setState(() {
      _day = null;
      _error = null;
    });
    try {
      final day = await ref.read(attendanceRepositoryProvider).day(date);
      if (!mounted || date != _date) return;
      setState(() {
        _day = day;
        _present
          ..clear()
          ..addAll({for (final e in day.entries) e.labourId: e.present});
        _saving.clear();
      });
    } on Failure catch (e) {
      if (mounted && date == _date) setState(() => _error = e);
    }
  }

  /// Shows the new value at once, saves it, and puts it back on failure.
  Future<void> _toggle(AttendanceEntry e, bool present) async {
    final date = _date;
    final id = e.labourId;
    // The wage shown before the switch: kept when going absent (see _wages).
    final shownBefore = _wageOf(e, !present);
    unawaited(HapticFeedback.selectionClick()); // a small tick with the switch
    setState(() {
      _present[id] = present;
      _saving.add(id);
    });
    try {
      final saved = await ref
          .read(attendanceRepositoryProvider)
          .save(date, {id: present}, wages: {id: ?_wages[id]});
      if (!mounted || date != _date) return;
      // The saved day wage (or the default again when absent) from the
      // server; switches still being saved keep what is shown.
      setState(() {
        _day = saved;
        if (!present && !_same(shownBefore, e.defaultDayWage)) {
          _wages[id] = shownBefore;
        } else if (present) {
          _wages.remove(id);
        }
      });
    } on Failure catch (f) {
      if (!mounted || date != _date) return;
      setState(() => _present[id] = !present);
      showMessage(context, failureText(context, f));
    } finally {
      if (mounted && date == _date) setState(() => _saving.remove(id));
    }
  }

  /// ✏: edit the day wage while the labour is absent.
  Future<void> _editWage(AttendanceEntry e) async {
    final wage = await showDialog<String>(
      context: context,
      builder: (_) => _DayWageDialog(
        name: e.name,
        date: Fmt.date(_date),
        initial: _wageOf(e, false),
      ),
    );
    if (wage == null || !mounted) return;
    setState(() {
      // Back to the usual wage = nothing to send.
      if (_same(wage, e.defaultDayWage)) {
        _wages.remove(e.labourId);
      } else {
        _wages[e.labourId] = wage;
      }
    });
  }

  /// ↺: back to the usual wage.
  void _resetWage(AttendanceEntry e) =>
      setState(() => _wages.remove(e.labourId));

  void _goTo(String date) {
    if (date == _date || date.compareTo(_today) > 0) return;
    _date = date;
    // Wages set with ✏ belong to the day that was open; a background
    // reload of the same day keeps them.
    _wages.clear();
    unawaited(_load());
  }

  Future<void> _pickDate() async {
    final today = Ymd.parse(_today);
    final current = Ymd.parse(_date);
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(current.year, current.month, current.day),
      firstDate: DateTime(2020),
      lastDate: DateTime(today.year, today.month, today.day),
    );
    if (picked != null) {
      _goTo(Ymd.format(DateTime.utc(picked.year, picked.month, picked.day)));
    }
  }

  String _dateLabel(AppLocalizations l) {
    final date = Fmt.date(_date);
    if (_date == _today) return l.todayWithDate(date);
    if (_date == Ymd.addDays(_today, -1)) return l.yesterdayWithDate(date);
    return date;
  }

  @override
  Widget build(BuildContext context) {
    // Leaving the section clears the search (03-AppFlow §13).
    ref.onSectionLeft('/attendance', () {
      if (_search.text.isEmpty) return;
      setState(_search.clear);
    });
    // A labour added or deactivated elsewhere shows here (own switches
    // are already on screen, so attendance changes are not listened to).
    ref.onDataChanged({DataTag.labours}, () => unawaited(_load()));
    final l = context.l10n;
    final gutter = Breakpoints.gutter(MediaQuery.sizeOf(context).width);

    return Scaffold(
      // In the swipe pager the bar stays put; only its contents change.
      backgroundColor: sectionBackground(context),
      appBar: SectionAppBar(
        leading: ShellMenuButton.maybe(context),
        title: Text(l.navAttendance),
        actions: const [AppBarActions()],
      ),
      body: RefreshIndicator(
        onRefresh: () => QueryCache.fresh(_load),
        child: ListView(
          padding: EdgeInsets.symmetric(vertical: gutter),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: gutter),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _DateBar(
                            label: _dateLabel(l),
                            onPrevious: () => _goTo(Ymd.addDays(_date, -1)),
                            onNext: _date.compareTo(_today) < 0
                                ? () => _goTo(Ymd.addDays(_date, 1))
                                : null,
                            onPick: _pickDate,
                          ),
                          const SizedBox(height: Space.s3),
                          const Divider(height: 1),
                          const SizedBox(height: Space.s3),
                          SearchField(
                            controller: _search,
                            hintText: l.searchLabour,
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Space.s2),
                    ..._content(context, gutter),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, double gutter) {
    final l = context.l10n;
    final day = _day;
    final pad = EdgeInsets.symmetric(horizontal: gutter);
    if (_error != null) {
      return [
        Padding(
          padding: pad,
          child: ErrorState(
            message: failureText(context, _error!),
            onRetry: _load,
          ),
        ),
      ];
    }
    if (day == null) {
      // The count line keeps its words; only the numbers and rows wait.
      return [
        Padding(
          padding: EdgeInsets.fromLTRB(gutter, Space.s2, gutter, Space.s2),
          child: SkeletonText(
            l.attendanceCount('', ''),
            style: AppTypography.caption.copyWith(
              color: context.tokens.textSecondary,
            ),
          ),
        ),
        Padding(
          padding: pad,
          child: const SkeletonRows(
            avatar: false,
            subtitleIcons: 1,
            trailing: SkeletonTrailing.toggle,
            padding: EdgeInsets.symmetric(vertical: Space.s2),
          ),
        ),
      ];
    }
    if (day.entries.isEmpty) {
      return [
        Padding(
          padding: pad,
          child: EmptyState(
            icon: Icons.how_to_reg_outlined,
            title: l.noLaboursOnDate,
            message: l.noLaboursOnDateMessage,
            actionLabel: l.addLabour,
            onAction: () async {
              await context.push('/labours/new');
              if (mounted) await _load();
            },
          ),
        ),
      ];
    }

    final present = _present.values.where((p) => p).length;
    final query = _search.text.trim().toLowerCase();
    final shown = [
      for (final e in day.entries)
        if (query.isEmpty || e.name.toLowerCase().contains(query)) e,
    ];

    return [
      Padding(
        padding: EdgeInsets.fromLTRB(gutter, Space.s2, gutter, Space.s2),
        child: Text(
          l.attendanceCount('$present', '${day.entries.length - present}'),
          style: AppTypography.caption.copyWith(
            color: context.tokens.textSecondary,
            fontFeatures: AppTypography.tabular,
          ),
        ),
      ),
      if (shown.isEmpty)
        Padding(
          padding: pad,
          child: EmptyState(icon: Icons.search_off, title: l.noResults),
        ),
      for (final e in shown) ...[
        _AttendanceRow(
          entry: e,
          present: _present[e.labourId] ?? false,
          saving: _saving.contains(e.labourId),
          wage: _wageOf(e, _present[e.labourId] ?? false),
          isUsualWage: _same(
            _wageOf(e, _present[e.labourId] ?? false),
            e.defaultDayWage,
          ),
          gutter: gutter,
          onChanged: (v) => _toggle(e, v),
          onEditWage: () => _editWage(e),
          onResetWage: () => _resetWage(e),
        ),
        const Divider(height: 1),
      ],
      const SizedBox(height: Space.s6),
    ];
  }
}

/// ‹  [ Select date · Today, 11 Nov 2026  📅 ]  ›
class _DateBar extends StatelessWidget {
  const _DateBar({
    required this.label,
    required this.onPrevious,
    required this.onNext,
    required this.onPick,
  });

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    return Row(
      children: [
        IconButton(
          tooltip: l.previous,
          onPressed: onPrevious,
          color: t.primary,
          icon: const Icon(Icons.chevron_left, size: 32),
        ),
        Expanded(
          child: InkWell(
            onTap: onPick,
            borderRadius: Radii.smAll,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: l.selectDate,
                suffixIcon: const Icon(Icons.calendar_today_outlined),
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyStrong.copyWith(
                  color: t.textPrimary,
                  fontFeatures: AppTypography.tabular,
                ),
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: l.next,
          onPressed: onNext,
          color: t.primary,
          icon: const Icon(Icons.chevron_right, size: 32),
        ),
      ],
    );
  }
}

/// Name, the day wage with ✏ (edit) and ↺ (back to the usual wage) right
/// next to it, and the present switch. Only the switch marks attendance;
/// ✏ and ↺ work while the labour is absent (03-AppFlow §7.2).
class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({
    required this.entry,
    required this.present,
    required this.saving,
    required this.wage,
    required this.isUsualWage,
    required this.gutter,
    required this.onChanged,
    required this.onEditWage,
    required this.onResetWage,
  });

  final AttendanceEntry entry;
  final bool present;
  final bool saving;

  /// The day wage shown ("450.00").
  final String wage;

  /// [wage] is the labour's usual wage (no ↺ then).
  final bool isUsualWage;
  final double gutter;
  final ValueChanged<bool> onChanged;
  final VoidCallback onEditWage;
  final VoidCallback onResetWage;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    // Present: the saved wage is used, so ✏ and ↺ are off.
    final canEdit = !present && !saving;
    Widget small(
      IconData icon,
      String tooltip,
      VoidCallback onPressed,
      Key key,
    ) => IconButton(
      key: key,
      tooltip: tooltip,
      onPressed: canEdit ? onPressed : null,
      color: t.primary,
      disabledColor: t.textTertiary.withValues(alpha: 0.5),
      iconSize: 18,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      padding: EdgeInsets.zero,
      icon: Icon(icon),
    );

    return Padding(
      key: ValueKey('attendanceRow-${entry.labourId}'),
      padding: EdgeInsets.fromLTRB(gutter, Space.s2, gutter, Space.s2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.title.copyWith(color: t.textPrimary),
                ),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        l.perDay(_money(wage)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body.copyWith(
                          color: t.textSecondary,
                          fontFeatures: AppTypography.tabular,
                        ),
                      ),
                    ),
                    small(
                      Icons.edit_outlined,
                      present ? l.dayWageLocked : l.editDayWage,
                      onEditWage,
                      Key('editWage-${entry.labourId}'),
                    ),
                    if (!isUsualWage)
                      small(
                        Icons.restart_alt,
                        present ? l.dayWageLocked : l.resetDayWage,
                        onResetWage,
                        Key('resetWage-${entry.labourId}'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: Space.s3),
          Switch(
            value: present,
            onChanged: saving ? null : onChanged,
            activeTrackColor: t.success,
            // White on green when present; a clear grey knob when absent.
            thumbColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected)
                  ? Colors.white
                  : t.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

String _money(String amount) => Fmt.money(amount);

/// Edit the day wage of one labour; returns the new amount ("500.5").
class _DayWageDialog extends StatefulWidget {
  const _DayWageDialog({
    required this.name,
    required this.date,
    required this.initial,
  });

  final String name;
  final String date;
  final String initial;

  @override
  State<_DayWageDialog> createState() => _DayWageDialogState();
}

class _DayWageDialogState extends State<_DayWageDialog> {
  final _form = GlobalKey<FormState>();
  late final _wage = TextEditingController(
    text: widget.initial.endsWith('.00')
        ? widget.initial.substring(0, widget.initial.length - 3)
        : widget.initial,
  );

  @override
  void dispose() {
    _wage.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    Navigator.of(context).pop(_wage.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final validators = Validators.of(context);
    return AlertDialog(
      title: Text(
        l.editDayWageTitle(widget.name),
        style: dialogTitleStyle(context),
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.editDayWageMessage(widget.name, widget.date),
                style: AppTypography.body.copyWith(color: t.textSecondary),
              ),
              const SizedBox(height: Space.s4),
              MoneyField(
                controller: _wage,
                label: l.dayWage,
                textInputAction: TextInputAction.done,
                validator: (v) =>
                    validators.money(v) ??
                    (Decimal.parse(v!.trim()) > Decimal.zero
                        ? null
                        : l.invalidAmount),
              ),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          style: dialogButtonStyle(context),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          style: dialogButtonStyle(context),
          onPressed: _save,
          child: Text(l.save),
        ),
      ],
    );
  }
}
