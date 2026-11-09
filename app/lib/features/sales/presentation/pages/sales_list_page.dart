import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/network/session.dart';
import '../../../../core/router/app_bar_actions.dart';
import '../../../../core/router/app_shell.dart';
import '../../../../core/utils/dates.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/controls.dart';
import '../../../../core/widgets/paged_list.dart';
import '../../../../core/widgets/state_views.dart';
import '../../data/sales_repository_impl.dart';
import '../../domain/sale.dart';
import '../../domain/sale_summary.dart';
import '../sale_labels.dart';
import '../widgets/sale_filter_sheet.dart';
import '../widgets/sale_list_items.dart';

/// Sales list (03-AppFlow §5.3): tabs All / Instant / Booking, search by
/// invoice no., customer or phone (400 ms debounce), filter sheet (date
/// range presets + status), infinite scroll. Cards on phones and tablets,
/// a table on desktop. The truck button opens upcoming deliveries.
/// (The "New sale" button is added with the sale form in F11.)
class SalesListPage extends ConsumerStatefulWidget {
  const SalesListPage({super.key});

  @override
  ConsumerState<SalesListPage> createState() => _SalesListPageState();
}

class _SalesListPageState extends ConsumerState<SalesListPage> {
  final _list = PagedListController();
  final _search = TextEditingController();
  Timer? _debounce;
  SaleFilter _filter = const SaleFilter();

  @override
  void dispose() {
    _debounce?.cancel();
    _list.dispose();
    _search.dispose();
    super.dispose();
  }

  void _apply(SaleFilter filter) {
    setState(() => _filter = filter);
    _list.refresh();
  }

  void _onSearch(String text) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _apply(_filter.copyWith(search: text)),
    );
    setState(() {});
  }

  Future<void> _openFilters() async {
    final next = await showSaleFilterSheet(
      context,
      filter: _filter,
      today: ref.read(businessDateProvider),
    );
    if (next != null) _apply(next);
  }

  Future<void> _open(String location) async {
    await context.push(location);
    if (mounted) _list.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = ref.watch(salesRepositoryProvider);
    final desktop = MediaQuery.sizeOf(context).width >= Breakpoints.expanded;
    final searching = _search.text.trim().isNotEmpty;
    final filtered =
        searching || _filter.type != null || _filter.activeCount > 0;

    return Scaffold(
      appBar: AppBar(
        leading: ShellMenuButton.maybe(context),
        title: Text(l.navSales),
        actions: [
          IconButton(
            tooltip: l.upcomingDeliveries,
            onPressed: () => context.push('/sales/upcoming'),
            icon: const Icon(Icons.local_shipping_outlined),
          ),
          const AppBarActions(),
        ],
      ),
      body: PagedList<SaleSummary>(
        controller: _list,
        fetch: (page) => repo.list(page: page, filter: _filter),
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedTabs<String?>(
              segments: {
                null: l.filterAll,
                'instant': l.saleTypeInstant,
                'booking': l.saleTypeBooking,
              },
              selected: _filter.type,
              onChanged: (type) => _apply(_filter.copyWith(type: () => type)),
            ),
            const SizedBox(height: Space.s3),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: _onSearch,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: l.searchSales,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searching
                          ? IconButton(
                              tooltip: l.clear,
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _search.clear();
                                _debounce?.cancel();
                                _apply(_filter.copyWith(search: ''));
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: Space.s2),
                Badge.count(
                  count: _filter.activeCount,
                  isLabelVisible: _filter.activeCount > 0,
                  child: IconButton.outlined(
                    tooltip: l.filterSales,
                    onPressed: _openFilters,
                    icon: const Icon(Icons.tune),
                  ),
                ),
              ],
            ),
            if (_filter.activeCount > 0) ...[
              const SizedBox(height: Space.s2),
              Wrap(
                spacing: Space.s2,
                runSpacing: Space.s2,
                children: [
                  if (!_filter.range.isEmpty)
                    InputChip(
                      avatar: const Icon(Icons.event, size: 18),
                      label: Text(rangeText(l, _filter)),
                      onPressed: _openFilters,
                      onDeleted: () => _apply(
                        _filter.copyWith(
                          range: const DateRange(),
                          preset: () => null,
                        ),
                      ),
                    ),
                  if (_filter.status != null)
                    InputChip(
                      label: Text(
                        ['paid', 'partial', 'due'].contains(_filter.status)
                            ? l.paymentStatusText(_filter.status!)
                            : l.saleStatusText(_filter.status!),
                      ),
                      onPressed: _openFilters,
                      onDeleted: () =>
                          _apply(_filter.copyWith(status: () => null)),
                    ),
                ],
              ),
            ],
          ],
        ),
        empty: filtered
            ? EmptyState(icon: Icons.search_off, title: l.noResults)
            : EmptyState(
                icon: Icons.point_of_sale_outlined,
                title: l.noSalesYet,
                message: l.salesEmptyMessage,
              ),
        builder: (context, sales) => desktop
            ? SalesTable(
                sales: sales,
                showCustomer: true,
                onOpen: (s) => _open('/sales/${s.id}'),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final s in sales) ...[
                    SaleTile(
                      sale: s,
                      showCustomer: true,
                      onTap: () => _open('/sales/${s.id}'),
                    ),
                    const SizedBox(height: Space.s2),
                  ],
                ],
              ),
      ),
    );
  }
}
