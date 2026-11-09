import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/cards.dart';
import '../../../../core/widgets/data_table_card.dart';
import '../../../../core/widgets/list_items.dart';
import '../../../../core/widgets/paged_list.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../data/labours_repository_impl.dart';
import '../../domain/labour.dart';
import '../labour_labels.dart';

enum _LabourFilter { active, inactive, all }

/// The "Labours" tab: search, Active / Inactive / All, each labour with
/// their wage and today's attendance. Cards on phones and tablets, a table
/// on desktop. "Add labour" opens the form, then the new labour.
class LaboursTab extends ConsumerStatefulWidget {
  const LaboursTab({super.key});

  @override
  ConsumerState<LaboursTab> createState() => _LaboursTabState();
}

class _LaboursTabState extends ConsumerState<LaboursTab> {
  final _list = PagedListController();
  final _search = TextEditingController();
  Timer? _debounce;
  _LabourFilter _filter = _LabourFilter.active;

  @override
  void dispose() {
    _debounce?.cancel();
    _list.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _open(String location) async {
    await context.push(location);
    if (mounted) _list.refresh();
  }

  Future<void> _add() async {
    final created = await context.push<Labour>('/labours/new');
    if (!mounted) return;
    _list.refresh();
    if (created != null) await _open('/labours/${created.id}');
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = ref.watch(laboursRepositoryProvider);
    final desktop = MediaQuery.sizeOf(context).width >= Breakpoints.expanded;
    final searching = _search.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(l.addLabour),
      ),
      body: PagedList<Labour>(
        controller: _list,
        fetch: (page) => repo.list(
          page: page,
          search: _search.text,
          active: switch (_filter) {
            _LabourFilter.active => true,
            _LabourFilter.inactive => false,
            _LabourFilter.all => null,
          },
        ),
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _search,
              onChanged: (_) {
                _debounce?.cancel();
                _debounce = Timer(
                  const Duration(milliseconds: 350),
                  _list.refresh,
                );
                setState(() {});
              },
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l.searchNamePhone,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searching
                    ? IconButton(
                        tooltip: l.clear,
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _search.clear();
                          _list.refresh();
                          setState(() {});
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: Space.s3),
            Wrap(
              spacing: Space.s2,
              runSpacing: Space.s2,
              children: [
                for (final (f, label) in [
                  (_LabourFilter.active, l.active),
                  (_LabourFilter.inactive, l.inactive),
                  (_LabourFilter.all, l.filterAll),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: _filter == f,
                    onSelected: (_) {
                      setState(() => _filter = f);
                      _list.refresh();
                    },
                  ),
              ],
            ),
          ],
        ),
        empty: searching || _filter != _LabourFilter.active
            ? EmptyState(icon: Icons.search_off, title: l.noResults)
            : EmptyState(
                icon: Icons.engineering_outlined,
                title: l.laboursEmptyTitle,
                message: l.laboursEmptyMessage,
                actionLabel: l.addLabour,
                onAction: _add,
              ),
        builder: (context, labours) => desktop
            ? _LaboursTable(
                labours: labours,
                onOpen: (lb) => _open('/labours/${lb.id}'),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final lb in labours) ...[
                    LabourTile(
                      labour: lb,
                      onTap: () => _open('/labours/${lb.id}'),
                    ),
                    const SizedBox(height: Space.s2),
                  ],
                ],
              ),
      ),
    );
  }
}

/// Today's attendance as a pill ("Present", "Not marked" …).
class TodayPill extends StatelessWidget {
  const TodayPill(this.status, {super.key});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return StatusPill(
      l.attendanceText(status),
      tone: status == null ? StatusTone.neutral : StatusPill.toneFor(status!),
    );
  }
}

/// Phone/tablet row: avatar · name · wage | today's status.
class LabourTile extends StatelessWidget {
  const LabourTile({super.key, required this.labour, this.onTap});

  final Labour labour;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final lb = labour;
    return Opacity(
      opacity: lb.isActive ? 1 : 0.6,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          horizontal: Space.s4,
          vertical: Space.s3,
        ),
        child: Row(
          children: [
            InitialsAvatar(lb.name),
            const SizedBox(width: Space.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lb.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.title.copyWith(color: t.textPrimary),
                  ),
                  Text(
                    l.wageText(lb.wageType, lb.wageAmount),
                    style: AppTypography.caption.copyWith(
                      color: t.textSecondary,
                      fontFeatures: AppTypography.tabular,
                    ),
                  ),
                  if (lb.phone != null && lb.phone!.isNotEmpty)
                    Text(
                      lb.phone!,
                      style: AppTypography.caption.copyWith(
                        color: t.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: Space.s2),
            lb.isActive ? TodayPill(lb.todayStatus) : StatusPill(l.inactive),
          ],
        ),
      ),
    );
  }
}

class _LaboursTable extends StatelessWidget {
  const _LaboursTable({required this.labours, required this.onOpen});

  final List<Labour> labours;
  final ValueChanged<Labour> onOpen;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return DataTableCard(
      columns: [
        TableColumnDef(l.nameField, flex: 4),
        TableColumnDef(l.phoneField, flex: 2),
        TableColumnDef(l.wage, flex: 2),
        TableColumnDef(l.joined, flex: 2),
        TableColumnDef(l.today, flex: 2, alignEnd: true),
      ],
      rows: [
        for (final lb in labours)
          [
            Row(
              children: [
                InitialsAvatar(lb.name, size: 32),
                const SizedBox(width: Space.s3),
                Expanded(child: CellText(lb.name, strong: true)),
              ],
            ),
            CellText(lb.phone ?? '—'),
            CellText(l.wageText(lb.wageType, lb.wageAmount)),
            CellText(Fmt.date(lb.joiningDate)),
            lb.isActive ? TodayPill(lb.todayStatus) : StatusPill(l.inactive),
          ],
      ],
      onTapRow: (i) => onOpen(labours[i]),
    );
  }
}
