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
/// Each row shows the day wage (a monthly labour: the monthly wage, which
/// one present day in the month earns in full): the saved wage when present, the labour's
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

  /// Page 1 of the day (null while loading); the rows shown are [_entries].
  AttendanceDay? _day;

  /// Every page loaded so far (20 labours a page, by name).
  final List<AttendanceEntry> _entries = [];
  int _page = 1;
  bool _hasMore = false;
  bool _loadingMore = false;

  /// The day's counts (every labour, not only the loaded pages).
  int _presentCount = 0;
  int _employed = 0;

  final _scroll = ScrollController();
  Timer? _searchDebounce;

  /// Ignores answers to an older request (date or search changed).
  int _request = 0;
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
    _scroll.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  /// Near the end of the list: the next 20.
  void _onScroll() {
    if (_scroll.position.extentAfter < 400) unawaited(_loadMore());
  }

  /// A short first page on a tall screen: keep loading until it scrolls.
  void _fillScreen() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && _scroll.hasClients && _scroll.position.extentAfter < 400) {
      unawaited(_loadMore());
    }
  });

  /// Search on the server, a moment after typing stops.
  void _searchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) unawaited(_load(keep: true));
    });
  }

  /// Page 1 for the date and search. [keep]: the rows stay on screen
  /// until the answer comes (a new search), instead of the skeleton.
  Future<void> _load({bool keep = false}) async {
    final request = ++_request;
    final date = _date;
    setState(() {
      if (!keep) _day = null;
      _error = null;
      _loadingMore = false;
    });
    try {
      final day = await ref
          .read(attendanceRepositoryProvider)
          .day(date, search: _search.text.trim());
      if (!mounted || request != _request) return;
      setState(() {
        _day = day;
        _entries
          ..clear()
          ..addAll(day.entries);
        _page = day.page;
        _hasMore = day.hasMore;
        _presentCount = day.present;
        _employed = day.employed;
        _present
          ..clear()
          ..addAll({for (final e in day.entries) e.labourId: e.present});
        _saving.clear();
      });
      _fillScreen();
    } on Failure catch (e) {
      if (mounted && request == _request) setState(() => _error = e);
    }
  }

  /// The next page, added under the rows already shown.
  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore || _day == null) return;
    final request = _request;
    setState(() => _loadingMore = true);
    try {
      final next = await ref
          .read(attendanceRepositoryProvider)
          .day(_date, page: _page + 1, search: _search.text.trim());
      if (!mounted || request != _request) return;
      setState(() {
        final known = {for (final e in _entries) e.labourId};
        for (final e in next.entries) {
          if (!known.add(e.labourId)) continue;
          _entries.add(e);
          _present.putIfAbsent(e.labourId, () => e.present);
        }
        _page = next.page;
        _hasMore = next.hasMore;
        // Counts from the server, unless a switch is still being saved.
        if (_saving.isEmpty) {
          _presentCount = next.present;
          _employed = next.employed;
        }
      });
      _fillScreen();
    } on Failure catch (f) {
      if (mounted) showMessage(context, failureText(context, f));
    } finally {
      if (mounted && request == _request) {
        setState(() => _loadingMore = false);
      }
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
      _presentCount += present ? 1 : -1;
    });
    try {
      final saved = await ref
          .read(attendanceRepositoryProvider)
          .save(date, {id: present}, wages: {id: ?_wages[id]});
      if (!mounted || date != _date) return;
      // The saved day wage (or the default again when absent) from the
      // server; switches still being saved keep what is shown.
      setState(() {
        // The saved row (its day wage) replaces the one shown; the day's
        // counts come from the server once nothing else is being saved.
        for (final s in saved.entries) {
          final i = _entries.indexWhere((x) => x.labourId == s.labourId);
          if (i >= 0) _entries[i] = s;
        }
        if (_saving.length == 1) {
          _presentCount = saved.present;
          _employed = saved.employed;
        }
        if (!present && !_same(shownBefore, e.defaultDayWage)) {
          _wages[id] = shownBefore;
        } else if (present) {
          _wages.remove(id);
        }
      });
    } on Failure catch (f) {
      if (!mounted || date != _date) return;
      setState(() {
        _present[id] = !present;
        _presentCount += present ? -1 : 1;
      });
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
    // Leaving the section clears the search and goes back to today, so
    // Attendance always opens on today (03-AppFlow §7, §13).
    ref.onSectionLeft('/attendance', () {
      final searched = _search.text.isNotEmpty;
      if (searched) setState(_search.clear);
      if (_date != _today) {
        _goTo(_today);
      } else if (searched) {
        unawaited(_load(keep: true));
      }
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
          controller: _scroll,
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
                            onChanged: _searchChanged,
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
    if (_employed == 0) {
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

    final present = _presentCount;
    final shown = _entries;

    return [
      Padding(
        padding: EdgeInsets.fromLTRB(gutter, Space.s2, gutter, Space.s2),
        child: Text(
          l.attendanceCount('$present', '${_employed - present}'),
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
      // While the next page loads (scrolling near the end starts it).
      if (_loadingMore)
        const Padding(
          key: Key('attendanceMore'),
          padding: EdgeInsets.all(Space.s4),
          child: Center(
            child: SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        ),
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
    // Monthly: one present day in a month earns the full monthly wage, so
    // the row shows "₹16,000 / month" and has no day wage to edit.
    final monthly = entry.wageType == 'monthly';
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
                        monthly
                            ? l.perMonth(_money(wage))
                            : l.perDay(_money(wage)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body.copyWith(
                          color: t.textSecondary,
                          fontFeatures: AppTypography.tabular,
                        ),
                      ),
                    ),
                    if (!monthly)
                      small(
                        Icons.edit_outlined,
                        present ? l.dayWageLocked : l.editDayWage,
                        onEditWage,
                        Key('editWage-${entry.labourId}'),
                      ),
                    if (!monthly && !isUsualWage)
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
