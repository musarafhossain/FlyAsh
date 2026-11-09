import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/network/session.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/contact_launcher.dart';
import '../../../../core/utils/dates.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/cards.dart';
import '../../../../core/widgets/controls.dart';
import '../../../../core/widgets/date_field.dart';
import '../../../../core/widgets/form_submit.dart';
import '../../../../core/widgets/list_items.dart';
import '../../../../core/widgets/page_layout.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../wages/data/wages_repository_impl.dart';
import '../../../wages/domain/wages.dart';
import '../../../wages/presentation/widgets/wages_tab.dart';
import '../../data/labours_repository_impl.dart';
import '../../domain/labour.dart';
import '../labour_labels.dart';
import '../widgets/labours_tab.dart' show TodayPill;

/// Labour detail (03-AppFlow §7.1): info, Call / WhatsApp, the month's
/// attendance calendar (‹ month ›), Edit, and Deactivate (asks for the
/// leaving date) / Activate, and this month's wage (earned, advances, paid,
/// balance) with a link to the wage detail (advance, pay).
class LabourDetailPage extends ConsumerStatefulWidget {
  const LabourDetailPage({super.key, required this.labourId});

  final String labourId;

  @override
  ConsumerState<LabourDetailPage> createState() => _LabourDetailPageState();
}

class _LabourDetailPageState extends ConsumerState<LabourDetailPage> {
  Labour? _labour;
  Object? _error;
  late String _month = ref.read(businessDateProvider).substring(0, 7);
  LabourMonth? _calendar;
  Object? _calendarError;
  WageRow? _wage; // this month (null while loading or on error)

  String get _today => ref.read(businessDateProvider);

  @override
  void initState() {
    super.initState();
    _load();
    _loadMonth();
    _loadWage();
  }

  Future<void> _loadWage() async {
    try {
      final d = await ref
          .read(wagesRepositoryProvider)
          .detail(widget.labourId, _today.substring(0, 7));
      if (mounted) setState(() => _wage = d.row);
    } on Failure {
      // The card is just left out; the wage detail page shows errors.
    }
  }

  Future<void> _openWages() async {
    await context.push(
      '/labours/wages/${widget.labourId}?month=${_today.substring(0, 7)}',
    );
    if (mounted) unawaited(_loadWage());
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final lb = await ref.read(laboursRepositoryProvider).get(widget.labourId);
      if (mounted) setState(() => _labour = lb);
    } on Failure catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _loadMonth() async {
    setState(() {
      _calendar = null;
      _calendarError = null;
    });
    final month = _month;
    try {
      final cal = await ref
          .read(laboursRepositoryProvider)
          .month(widget.labourId, month);
      if (mounted && month == _month) setState(() => _calendar = cal);
    } on Failure catch (e) {
      if (mounted && month == _month) setState(() => _calendarError = e);
    }
  }

  void _moveMonth(int by) {
    _month = Ymd.addMonths('$_month-01', by).substring(0, 7);
    _loadMonth();
  }

  Future<void> _edit() async {
    final updated = await context.push<Labour>(
      '/labours/${widget.labourId}/edit',
    );
    if (updated != null && mounted) {
      setState(() => _labour = updated);
      unawaited(_loadMonth());
    }
  }

  Future<void> _contact(Future<bool> Function(String) open) async {
    final ok = await open(_labour!.phone ?? '');
    if (!ok && mounted) showMessage(context, context.l10n.couldNotOpen);
  }

  Future<void> _toggleActive() async {
    final lb = _labour!;
    final l = context.l10n;
    String? leftDate;
    if (lb.isActive) {
      leftDate = await showDialog<String>(
        context: context,
        builder: (_) => _LeavingDateDialog(labour: lb, today: _today),
      );
      if (leftDate == null) return;
    } else {
      final ok = await showConfirmDialog(
        context,
        title: l.activateLabourTitle(lb.name),
        message: l.activateLabourMessage,
        confirmLabel: l.activate,
      );
      if (!ok) return;
    }
    if (!mounted) return;
    try {
      final (updated, message) = await ref
          .read(laboursRepositoryProvider)
          .setActive(lb.id, !lb.isActive, leftDate: leftDate);
      if (!mounted) return;
      setState(() => _labour = updated);
      showMessage(context, message);
    } on Failure catch (f) {
      if (mounted) showMessage(context, failureText(context, f));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final lb = _labour;
    return Scaffold(
      appBar: AppBar(
        title: Text(lb?.name ?? l.labourDetails),
        actions: [
          if (lb != null) ...[
            IconButton(
              tooltip: l.edit,
              onPressed: _edit,
              icon: const Icon(Icons.edit_outlined),
            ),
            PopupMenuButton<void>(
              tooltip: l.moreActions,
              itemBuilder: (_) => [
                PopupMenuItem(
                  onTap: _toggleActive,
                  child: ListTile(
                    leading: Icon(
                      lb.isActive ? Icons.block : Icons.check_circle_outline,
                    ),
                    title: Text(lb.isActive ? l.deactivate : l.activate),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: lb == null
          ? (_error != null
                ? ErrorState(
                    message: failureText(context, _error!),
                    onRetry: _load,
                  )
                : const Center(child: CircularProgressIndicator()))
          : PageBody(
              maxWidth: 720,
              children: [
                _InfoCard(
                  labour: lb,
                  onCall: () => _contact(ContactLauncher.call),
                  onWhatsApp: () => _contact(ContactLauncher.whatsApp),
                ),
                if (_wage != null) ...[
                  const SizedBox(height: Space.s4),
                  _WageCard(row: _wage!, onOpen: _openWages),
                ],
                const SizedBox(height: Space.s4),
                SectionHeader(l.attendanceThisMonth),
                PeriodSelector(
                  label: Fmt.month(_month),
                  onPrevious: () => _moveMonth(-1),
                  onNext: _month.compareTo(_today.substring(0, 7)) < 0
                      ? () => _moveMonth(1)
                      : null,
                ),
                const SizedBox(height: Space.s3),
                if (_calendarError != null)
                  ErrorState(
                    message: failureText(context, _calendarError!),
                    onRetry: _loadMonth,
                  )
                else if (_calendar == null)
                  const Padding(
                    padding: EdgeInsets.all(Space.s6),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  _MonthCalendar(
                    month: _month,
                    data: _calendar!,
                    labour: lb,
                    today: _today,
                  ),
              ],
            ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.labour,
    required this.onCall,
    required this.onWhatsApp,
  });

  final Labour labour;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final lb = labour;
    final hasPhone = lb.phone != null && lb.phone!.isNotEmpty;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              InitialsAvatar(lb.name, size: 56),
              const SizedBox(width: Space.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lb.name,
                      style: AppTypography.h3.copyWith(color: t.textPrimary),
                    ),
                    Text(
                      l.wageText(lb.wageType, lb.wageAmount),
                      style: AppTypography.bodyStrong.copyWith(
                        color: t.textSecondary,
                        fontFeatures: AppTypography.tabular,
                      ),
                    ),
                    const SizedBox(height: Space.s1),
                    lb.isActive
                        ? TodayPill(lb.todayStatus)
                        : StatusPill(l.inactive),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.s3),
          if (hasPhone)
            InfoRow(
              icon: Icons.phone_outlined,
              label: l.phoneField,
              value: lb.phone!,
            ),
          if (lb.address != null && lb.address!.isNotEmpty)
            InfoRow(
              icon: Icons.place_outlined,
              label: l.addressField,
              value: lb.address!,
            ),
          InfoRow(
            icon: Icons.event_available_outlined,
            label: l.joiningDate,
            value: Fmt.date(lb.joiningDate),
          ),
          if (lb.leftDate != null)
            InfoRow(
              icon: Icons.event_busy_outlined,
              label: l.leavingDate,
              value: Fmt.date(lb.leftDate),
            ),
          if (hasPhone) ...[
            const SizedBox(height: Space.s3),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onCall,
                    icon: const Icon(Icons.call_outlined),
                    label: Text(l.call),
                  ),
                ),
                const SizedBox(width: Space.s3),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onWhatsApp,
                    icon: const Icon(Icons.chat_outlined),
                    label: Text(l.whatsApp),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Month grid (Mon–Sun) coloured by status, with totals.
class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.month,
    required this.data,
    required this.labour,
    required this.today,
  });

  final String month;
  final LabourMonth data;
  final Labour labour;
  final String today;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final first = Ymd.parse('$month-01');
    final daysInMonth = Ymd.parse(Ymd.monthEnd('$month-01')).day;
    final leading = first.weekday - 1; // Monday first
    final weekdays = [
      l.wkMon,
      l.wkTue,
      l.wkWed,
      l.wkThu,
      l.wkFri,
      l.wkSat,
      l.wkSun,
    ];

    (Color, Color) colors(String? status, bool employed) => switch (status) {
      'present' => (t.successBg, t.success),
      'half_day' => (t.warningBg, t.warning),
      'absent' => (t.errorBg, t.error),
      _ =>
        employed
            ? (t.surfaceVariant, t.textSecondary)
            : (Colors.transparent, t.textDisabled),
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (final w in weekdays)
                Expanded(
                  child: Center(
                    child: Text(
                      w,
                      style: AppTypography.micro.copyWith(
                        color: t.textTertiary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Space.s2),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: Space.s1,
            crossAxisSpacing: Space.s1,
            children: [
              for (var i = 0; i < leading; i++) const SizedBox.shrink(),
              for (var day = 1; day <= daysInMonth; day++)
                () {
                  final date = '$month-${day.toString().padLeft(2, '0')}';
                  final status = data.days[date];
                  final employed =
                      date.compareTo(labour.joiningDate) >= 0 &&
                      (labour.leftDate == null ||
                          date.compareTo(labour.leftDate!) <= 0) &&
                      date.compareTo(today) <= 0;
                  final (bg, fg) = colors(status, employed);
                  return Semantics(
                    label: '${Fmt.date(date)}: ${l.attendanceText(status)}',
                    excludeSemantics: true,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: Radii.smAll,
                        border: date == today
                            ? Border.all(color: t.primary, width: 2)
                            : null,
                      ),
                      child: Text(
                        '$day',
                        style: AppTypography.label.copyWith(
                          color: fg,
                          fontWeight: status != null ? FontWeight.w700 : null,
                        ),
                      ),
                    ),
                  );
                }(),
            ],
          ),
          const SizedBox(height: Space.s3),
          Wrap(
            spacing: Space.s4,
            runSpacing: Space.s2,
            children: [
              _Legend(
                color: t.success,
                label: '${l.attPresent} ${data.present}',
              ),
              _Legend(
                color: t.warning,
                label: '${l.attHalfDay} ${data.halfDay}',
              ),
              _Legend(color: t.error, label: '${l.attAbsent} ${data.absent}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: Space.s1),
      Text(
        label,
        style: AppTypography.caption.copyWith(
          color: context.tokens.textSecondary,
        ),
      ),
    ],
  );
}

/// Deactivate: asks for the leaving date (today by default, not before
/// joining). Pops with the date.
class _LeavingDateDialog extends StatefulWidget {
  const _LeavingDateDialog({required this.labour, required this.today});

  final Labour labour;
  final String today;

  @override
  State<_LeavingDateDialog> createState() => _LeavingDateDialogState();
}

class _LeavingDateDialogState extends State<_LeavingDateDialog> {
  late String _date = widget.today;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final joined = widget.labour.joiningDate;
    return AlertDialog(
      title: Text(l.deactivateLabourTitle(widget.labour.name)),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.deactivateLabourMessage,
              style: AppTypography.body.copyWith(color: t.textSecondary),
            ),
            const SizedBox(height: Space.s4),
            DateField(
              label: l.leavingDate,
              value: _date,
              first: joined.compareTo(widget.today) > 0 ? widget.today : joined,
              last: widget.today,
              onChanged: (d) => setState(() => _date = d),
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: t.error,
            foregroundColor: t.surface,
          ),
          onPressed: () => Navigator.of(context).pop(_date),
          child: Text(l.deactivate),
        ),
      ],
    );
  }
}

/// This month: earned, advances, paid and balance → wage detail.
class _WageCard extends StatelessWidget {
  const _WageCard({required this.row, required this.onOpen});

  final WageRow row;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    return AppCard(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.wageThisMonth,
                  style: AppTypography.title.copyWith(color: t.textPrimary),
                ),
              ),
              WageStatusPill(row.status),
              Icon(Icons.chevron_right, color: t.textTertiary),
            ],
          ),
          const SizedBox(height: Space.s3),
          KpiRow(
            children: [
              KpiChip(
                icon: Icons.payments_outlined,
                label: l.earned,
                value: Fmt.money(row.earned),
              ),
              KpiChip(
                icon: Icons.request_quote_outlined,
                label: l.advances,
                value: Fmt.money(row.advances),
                tint: KpiTint.amber,
              ),
              KpiChip(
                icon: Icons.account_balance_wallet_outlined,
                label: l.balance,
                value: Fmt.money(row.balance),
                tint: row.hasBalance ? KpiTint.rose : KpiTint.green,
              ),
            ],
          ),
          const SizedBox(height: Space.s2),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.payments_outlined, size: 18),
              label: Text(l.advanceOrPay),
            ),
          ),
        ],
      ),
    );
  }
}
