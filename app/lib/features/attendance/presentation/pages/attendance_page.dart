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
import '../../../../core/widgets/cards.dart';
import '../../../../core/widgets/controls.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../../../core/widgets/form_submit.dart';
import '../../../../core/widgets/list_items.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../labours/presentation/labour_labels.dart';
import '../../data/attendance_repository_impl.dart';
import '../../domain/attendance.dart';

enum _Unsaved { save, discard, stay }

/// Attendance for a day (03-AppFlow §7.2, 04-UI-UX "Attendance"):
/// ‹ date › (no future), ring with present / total, tiles Present · Half
/// day · Absent · Not marked, "Mark all present", a P / H / A toggle per
/// labour (tap the chosen one again to clear it), and a sticky Save that
/// sends only what changed. Changing the date or leaving with unsaved
/// changes asks "Save changes for 08 Nov?".
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
  bool _saving = false;

  /// What the server has, and what is on screen.
  Map<String, String?> _saved = const {};
  Map<String, String?> _current = {};

  String get _today => ref.read(businessDateProvider);

  String _validDate(String? ymd) {
    final today = ref.read(businessDateProvider);
    final ok = ymd != null && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(ymd);
    return ok && ymd.compareTo(today) <= 0 ? ymd : today;
  }

  Map<String, String?> get _changes => {
    for (final e in _current.entries)
      if (_saved[e.key] != e.value) e.key: e.value,
  };

  @override
  void initState() {
    super.initState();
    _load();
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
      _apply(day);
    } on Failure catch (e) {
      if (mounted && date == _date) setState(() => _error = e);
    }
  }

  void _apply(AttendanceDay day) {
    setState(() {
      _day = day;
      _saved = {for (final e in day.entries) e.labourId: e.status};
      _current = Map.of(_saved);
    });
  }

  Future<bool> _save() async {
    final changes = _changes;
    if (changes.isEmpty) return true;
    setState(() => _saving = true);
    try {
      final (day, _) = await ref
          .read(attendanceRepositoryProvider)
          .save(_date, changes);
      if (!mounted) return true;
      _apply(day);
      showMessage(context, context.l10n.attendanceSaved(Fmt.date(_date)));
      return true;
    } on Failure catch (f) {
      if (mounted) showMessage(context, failureText(context, f));
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// With unsaved changes: Save / Discard / stay. True = may continue.
  Future<bool> _resolveUnsaved() async {
    if (_changes.isEmpty) return true;
    final l = context.l10n;
    final choice = await showDialog<_Unsaved>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.saveChangesFor(Fmt.date(_date))),
        content: Text(l.unsavedAttendance('${_changes.length}')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_Unsaved.stay),
            child: Text(l.cancel),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(_Unsaved.discard),
            child: Text(l.discard),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_Unsaved.save),
            child: Text(l.save),
          ),
        ],
      ),
    );
    return switch (choice) {
      _Unsaved.save => await _save(),
      _Unsaved.discard => true,
      _Unsaved.stay || null => false,
    };
  }

  Future<void> _goTo(String date) async {
    if (date == _date || date.compareTo(_today) > 0) return;
    if (!await _resolveUnsaved()) return;
    _date = date;
    await _load();
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
      await _goTo(
        Ymd.format(DateTime.utc(picked.year, picked.month, picked.day)),
      );
    }
  }

  void _set(String labourId, String status) => setState(() {
    // Tapping the chosen status again clears it (not marked).
    _current[labourId] = _current[labourId] == status ? null : status;
  });

  void _markAllPresent() => setState(() {
    for (final id in _current.keys) {
      _current[id] = 'present';
    }
  });

  String _dateLabel(AppLocalizations l) {
    final date = Fmt.date(_date);
    if (_date == _today) return l.todayWithDate(date);
    if (_date == Ymd.addDays(_today, -1)) return l.yesterdayWithDate(date);
    return date;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final changes = _changes.length;

    return PopScope(
      canPop: changes == 0,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _resolveUnsaved() && context.mounted) {
          final navigator = Navigator.of(context);
          setState(() => _current = Map.of(_saved));
          // Pop after the rebuild, when nothing is unsaved any more.
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => navigator.maybePop(),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: ShellMenuButton.maybe(context),
          title: Text(l.navAttendance),
          actions: const [AppBarActions()],
        ),
        bottomNavigationBar: (_day?.entries.isNotEmpty ?? false)
            ? _SaveBar(changes: changes, busy: _saving, onSave: _save)
            : null,
        body: RefreshIndicator(
          onRefresh: () async {
            if (await _resolveUnsaved()) await _load();
          },
          child: ListView(
            padding: EdgeInsets.all(
              Breakpoints.gutter(MediaQuery.sizeOf(context).width),
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PeriodSelector(
                        label: _dateLabel(l),
                        onPrevious: () =>
                            unawaited(_goTo(Ymd.addDays(_date, -1))),
                        onNext: _date.compareTo(_today) < 0
                            ? () => _goTo(Ymd.addDays(_date, 1))
                            : null,
                        onTapLabel: _pickDate,
                      ),
                      const SizedBox(height: Space.s4),
                      ..._content(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context) {
    final l = context.l10n;
    final day = _day;
    if (_error != null) {
      return [
        ErrorState(message: failureText(context, _error!), onRetry: _load),
      ];
    }
    if (day == null) {
      return [const SkeletonList(count: 5)];
    }
    if (day.entries.isEmpty) {
      return [
        EmptyState(
          icon: Icons.how_to_reg_outlined,
          title: l.noLaboursOnDate,
          message: l.noLaboursOnDateMessage,
          actionLabel: l.addLabour,
          onAction: () async {
            await context.push('/labours/new');
            if (mounted) await _load();
          },
        ),
      ];
    }

    final values = _current.values;
    final present = values.where((s) => s == 'present').length;
    final half = values.where((s) => s == 'half_day').length;
    final absent = values.where((s) => s == 'absent').length;
    final notMarked = values.where((s) => s == null).length;
    final total = values.length;

    return [
      _Summary(
        present: present,
        half: half,
        absent: absent,
        notMarked: notMarked,
        total: total,
      ),
      const SizedBox(height: Space.s3),
      Align(
        alignment: Alignment.centerRight,
        child: OutlinedButton.icon(
          onPressed: present == total ? null : _markAllPresent,
          icon: const Icon(Icons.done_all),
          label: Text(l.markAllPresent),
        ),
      ),
      const SizedBox(height: Space.s3),
      for (final e in day.entries) ...[
        _LabourRow(
          entry: e,
          status: _current[e.labourId],
          changed: _saved[e.labourId] != _current[e.labourId],
          onSet: (s) => _set(e.labourId, s),
        ),
        const SizedBox(height: Space.s2),
      ],
      const SizedBox(height: Space.s4),
    ];
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.present,
    required this.half,
    required this.absent,
    required this.notMarked,
    required this.total,
  });

  final int present;
  final int half;
  final int absent;
  final int notMarked;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.medium;

    final ring = ProgressRing(
      value: total == 0 ? 0 : present / total,
      size: wide ? 140 : 120,
      center: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$present/$total',
            style: AppTypography.h2.copyWith(
              color: t.textPrimary,
              fontFeatures: AppTypography.tabular,
            ),
          ),
          Text(
            l.attPresent,
            style: AppTypography.caption.copyWith(color: t.textSecondary),
          ),
        ],
      ),
    );
    final tiles = KpiRow(
      children: [
        KpiChip(
          icon: Icons.check_circle_outline,
          label: l.attPresent,
          value: '$present',
          tint: KpiTint.green,
        ),
        KpiChip(
          icon: Icons.timelapse,
          label: l.attHalfDay,
          value: '$half',
          tint: KpiTint.amber,
        ),
        KpiChip(
          icon: Icons.cancel_outlined,
          label: l.attAbsent,
          value: '$absent',
          tint: KpiTint.rose,
        ),
        KpiChip(
          icon: Icons.help_outline,
          label: l.attNotMarked,
          value: '$notMarked',
        ),
      ],
    );

    return AppCard(
      child: wide
          ? Row(
              children: [
                ring,
                const SizedBox(width: Space.s5),
                Expanded(child: tiles),
              ],
            )
          : Column(
              children: [
                ring,
                const SizedBox(height: Space.s4),
                tiles,
              ],
            ),
    );
  }
}

/// One labour: avatar, name, wage, and the P / H / A toggle.
class _LabourRow extends StatelessWidget {
  const _LabourRow({
    required this.entry,
    required this.status,
    required this.changed,
    required this.onSet,
  });

  final AttendanceEntry entry;
  final String? status;
  final bool changed;
  final ValueChanged<String> onSet;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.s3,
        vertical: Space.s2,
      ),
      child: Row(
        children: [
          InitialsAvatar(entry.name, size: 36),
          const SizedBox(width: Space.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyStrong.copyWith(
                          color: t.textPrimary,
                        ),
                      ),
                    ),
                    if (changed) ...[
                      const SizedBox(width: Space.s1),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: t.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  l.wageText(entry.wageType, entry.wageAmount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(color: t.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: Space.s2),
          _PhaToggle(status: status, onSet: onSet, name: entry.name),
        ],
      ),
    );
  }
}

/// Three 48 dp buttons P / H / A; the chosen one is filled with its colour.
class _PhaToggle extends StatelessWidget {
  const _PhaToggle({
    required this.status,
    required this.onSet,
    required this.name,
  });

  final String? status;
  final ValueChanged<String> onSet;
  final String name;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, s) in kAttendanceStatuses.indexed) ...[
          if (i > 0) const SizedBox(width: Space.s1),
          () {
            final selected = status == s;
            final (fg, bg) = switch (s) {
              'present' => (t.success, t.successBg),
              'half_day' => (t.warning, t.warningBg),
              _ => (t.error, t.errorBg),
            };
            return Semantics(
              button: true,
              selected: selected,
              label: '$name: ${l.attendanceText(s)}',
              excludeSemantics: true,
              child: Tooltip(
                message: l.attendanceText(s),
                child: Material(
                  color: selected ? fg : bg.withValues(alpha: 0.5),
                  borderRadius: Radii.mdAll,
                  child: InkWell(
                    borderRadius: Radii.mdAll,
                    onTap: () => onSet(s),
                    child: SizedBox(
                      width: kMinTouchTarget,
                      height: kMinTouchTarget,
                      child: Center(
                        child: Text(
                          l.attendanceLetter(s),
                          style: AppTypography.title.copyWith(
                            color: selected ? t.surface : fg,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }(),
        ],
      ],
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.changes,
    required this.busy,
    required this.onSave,
  });

  final int changes;
  final bool busy;
  final Future<bool> Function() onSave;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    return Material(
      color: t.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.s4,
            vertical: Space.s3,
          ),
          // heightFactor 1: only as tall as the bar.
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      changes == 0 ? l.noChanges : l.changesCount('$changes'),
                      style: AppTypography.body.copyWith(
                        color: changes == 0 ? t.textTertiary : t.textPrimary,
                      ),
                    ),
                  ),
                  BusyButton(
                    label: l.saveAttendance,
                    busy: busy,
                    onPressed: changes == 0 ? null : onSave,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
