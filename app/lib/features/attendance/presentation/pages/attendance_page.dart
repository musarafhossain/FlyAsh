import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/network/session.dart';
import '../../../../core/router/app_bar_actions.dart';
import '../../../../core/router/app_shell.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/dates.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/form_submit.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../labours/presentation/labour_labels.dart';
import '../../data/attendance_repository_impl.dart';
import '../../domain/attendance.dart';

/// Attendance for a day: ‹ date › (no future), search, and one row per
/// labour with a switch. Turning a switch on marks the labour present (a row
/// is saved); turning it off marks them absent (the row is removed). Each
/// switch saves at once, so there is no Save button.
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
    setState(() {
      _present[id] = present;
      _saving.add(id);
    });
    try {
      await ref.read(attendanceRepositoryProvider).save(date, {id: present});
    } on Failure catch (f) {
      if (!mounted || date != _date) return;
      setState(() => _present[id] = !present);
      showMessage(context, failureText(context, f));
    } finally {
      if (mounted && date == _date) setState(() => _saving.remove(id));
    }
  }

  void _goTo(String date) {
    if (date == _date || date.compareTo(_today) > 0) return;
    _date = date;
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
    final l = context.l10n;
    final gutter = Breakpoints.gutter(MediaQuery.sizeOf(context).width);

    return Scaffold(
      appBar: AppBar(
        leading: ShellMenuButton.maybe(context),
        title: Text(l.navAttendance),
        actions: const [AppBarActions()],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
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
                          TextField(
                            controller: _search,
                            onChanged: (_) => setState(() {}),
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: l.searchLabour,
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _search.text.isNotEmpty
                                  ? IconButton(
                                      tooltip: l.clear,
                                      icon: const Icon(Icons.close),
                                      onPressed: () => setState(_search.clear),
                                    )
                                  : null,
                            ),
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
      return [
        Padding(
          padding: pad,
          child: const SkeletonList(count: 6, leading: false, toggle: true),
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
          gutter: gutter,
          onChanged: (v) => _toggle(e, v),
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

/// Name, wage, and the present switch. Tapping the row flips the switch.
class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({
    required this.entry,
    required this.present,
    required this.saving,
    required this.gutter,
    required this.onChanged,
  });

  final AttendanceEntry entry;
  final bool present;
  final bool saving;
  final double gutter;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    return MergeSemantics(
      child: InkWell(
        onTap: saving ? null : () => onChanged(!present),
        child: Padding(
          padding: EdgeInsets.fromLTRB(gutter, Space.s3, gutter, Space.s3),
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
                    const SizedBox(height: 2),
                    Text(
                      l.wageText(entry.wageType, entry.wageAmount),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body.copyWith(
                        color: t.textSecondary,
                        fontFeatures: AppTypography.tabular,
                      ),
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
        ),
      ),
    );
  }
}
