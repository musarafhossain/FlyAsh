import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/app_bar_actions.dart';
import '../../../../core/router/app_shell.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/data_table_card.dart';
import '../../../../core/widgets/list_items.dart';
import '../../../../core/widgets/paged_list.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../data/customers_repository_impl.dart';
import '../../domain/customer.dart';

/// Which customers the list shows.
enum CustomerFilter { all, hasDue, inactive }

/// Customers (03-AppFlow §6, PRD CUST-2): search by name or phone, filters
/// All / Has due / Inactive, the due on every row. Cards on phones and
/// tablets, a table on desktop. Tap → customer detail.
class CustomersListPage extends ConsumerStatefulWidget {
  const CustomersListPage({super.key, this.initialFilter});

  /// From `?filter=due` (Home → Total due).
  final String? initialFilter;

  @override
  ConsumerState<CustomersListPage> createState() => _CustomersListPageState();
}

class _CustomersListPageState extends ConsumerState<CustomersListPage> {
  final _list = PagedListController();
  final _search = TextEditingController();
  Timer? _debounce;
  late CustomerFilter _filter = widget.initialFilter == 'due'
      ? CustomerFilter.hasDue
      : CustomerFilter.all;

  @override
  void didUpdateWidget(CustomersListPage old) {
    super.didUpdateWidget(old);
    // The page stays alive in the shell; a new ?filter= applies anew.
    if (widget.initialFilter != old.initialFilter &&
        widget.initialFilter == 'due') {
      _setFilter(CustomerFilter.hasDue);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _list.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _list.refresh);
    setState(() {});
  }

  void _setFilter(CustomerFilter filter) {
    setState(() => _filter = filter);
    _list.refresh();
  }

  Future<void> _open(String location) async {
    await context.push(location);
    if (mounted) _list.refresh();
  }

  /// Add form → (saved) → the new customer's detail page; Back returns here.
  Future<void> _add() async {
    final created = await context.push<Customer>('/customers/new');
    if (!mounted) return;
    _list.refresh();
    if (created != null) await _open('/customers/${created.id}');
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = ref.watch(customersRepositoryProvider);
    final desktop = MediaQuery.sizeOf(context).width >= Breakpoints.expanded;
    final searching = _search.text.trim().isNotEmpty;
    final filtered = searching || _filter != CustomerFilter.all;

    return Scaffold(
      appBar: AppBar(
        leading: ShellMenuButton.maybe(context),
        title: Text(l.navCustomers),
        actions: const [AppBarActions()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(l.addCustomer),
      ),
      body: PagedList<Customer>(
        controller: _list,
        fetch: (page) => repo.list(
          page: page,
          search: _search.text,
          hasDue: _filter == CustomerFilter.hasDue ? true : null,
          active: _filter == CustomerFilter.inactive ? false : null,
        ),
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _search,
              onChanged: _onSearch,
              keyboardType: TextInputType.text,
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
                          _onSearch('');
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
                for (final (filter, label) in [
                  (CustomerFilter.all, l.filterAll),
                  (CustomerFilter.hasDue, l.filterHasDue),
                  (CustomerFilter.inactive, l.inactive),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: _filter == filter,
                    onSelected: (_) => _setFilter(filter),
                  ),
              ],
            ),
          ],
        ),
        empty: filtered
            ? EmptyState(icon: Icons.search_off, title: l.noResults)
            : EmptyState(
                icon: Icons.people_outline,
                title: l.customersEmptyTitle,
                message: l.customersEmptyMessage,
                actionLabel: l.addCustomer,
                onAction: _add,
              ),
        builder: (context, customers) => desktop
            ? _CustomersTable(
                customers: customers,
                onOpen: (c) => _open('/customers/${c.id}'),
              )
            : ListGroup(
                children: [
                  for (final c in customers)
                    CustomerTile(
                      customer: c,
                      onTap: () => _open('/customers/${c.id}'),
                    ),
                ],
              ),
      ),
    );
  }
}

/// "₹33,098 due" in red, or "No due" in grey.
class DueText extends StatelessWidget {
  const DueText({super.key, required this.customer, this.compact = false});

  final Customer customer;

  /// Only the amount (tables).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = context.l10n;
    if (!customer.hasDue) {
      return Text(
        compact ? '—' : l.noDue,
        style: AppTypography.caption.copyWith(color: t.textTertiary),
      );
    }
    return Text(
      Fmt.money(customer.totalDue),
      style: AppTypography.bodyStrong.copyWith(
        color: t.error,
        fontFeatures: AppTypography.tabular,
      ),
    );
  }
}

/// Phone/tablet row: initials · name · phone · address | due.
class CustomerTile extends StatelessWidget {
  const CustomerTile({super.key, required this.customer, this.onTap});

  final Customer customer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final c = customer;
    return Opacity(
      opacity: c.isActive ? 1 : 0.6,
      child: ListRowSurface(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          horizontal: Space.s4,
          vertical: Space.s3,
        ),
        child: Row(
          children: [
            InitialsAvatar(c.name),
            const SizedBox(width: Space.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.title.copyWith(color: t.textPrimary),
                  ),
                  Text(
                    c.phone,
                    style: AppTypography.caption.copyWith(
                      color: t.textSecondary,
                      fontFeatures: AppTypography.tabular,
                    ),
                  ),
                  if (c.address != null && c.address!.isNotEmpty)
                    Text(
                      c.address!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: t.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: Space.s2),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!c.isActive) ...[
                  StatusPill(l.inactive),
                  const SizedBox(height: Space.s1),
                ],
                DueText(customer: c),
                if (c.hasDue)
                  Text(
                    l.due,
                    style: AppTypography.micro.copyWith(color: t.textTertiary),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomersTable extends StatelessWidget {
  const _CustomersTable({required this.customers, required this.onOpen});

  final List<Customer> customers;
  final ValueChanged<Customer> onOpen;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return DataTableCard(
      columns: [
        TableColumnDef(l.nameField, flex: 4),
        TableColumnDef(l.phoneField, flex: 2),
        TableColumnDef(l.addressField, flex: 3),
        TableColumnDef(l.purchases, flex: 2, alignEnd: true),
        TableColumnDef(l.paid, flex: 2, alignEnd: true),
        TableColumnDef(l.due, flex: 2, alignEnd: true),
      ],
      rows: [
        for (final c in customers)
          [
            Row(
              children: [
                InitialsAvatar(c.name, size: 32),
                const SizedBox(width: Space.s3),
                Expanded(child: CellText(c.name, strong: true)),
                if (!c.isActive) ...[
                  const SizedBox(width: Space.s2),
                  StatusPill(l.inactive),
                ],
              ],
            ),
            CellText(c.phone),
            CellText(c.address ?? '—'),
            CellText(Fmt.money(c.totalSales)),
            CellText(Fmt.money(c.totalPaid)),
            DueText(customer: c, compact: true),
          ],
      ],
      onTapRow: (i) => onOpen(customers[i]),
    );
  }
}
