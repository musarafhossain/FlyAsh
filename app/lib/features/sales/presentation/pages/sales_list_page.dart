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
import '../../../../core/widgets/list_items.dart';
import '../../../../core/widgets/controls.dart';
import '../../../../core/widgets/paged_list.dart';
import '../../../../core/widgets/state_views.dart';
import '../../data/sales_repository_impl.dart';
import '../../domain/sale.dart';
import '../../domain/sale_summary.dart';
import '../sale_labels.dart';
import '../widgets/sale_filter_sheet.dart';
import 'sale_form_page.dart' show kReturnSale;
import '../widgets/sale_list_items.dart';

/// Sales list (03-AppFlow §5.3): tabs All / Instant / Booking, search by
/// invoice no., customer or phone (400 ms debounce), filter sheet (date
/// range presets + status), infinite scroll. Cards on phones and tablets,
/// a table on desktop. The truck button opens upcoming deliveries; the
/// "New sale" button opens the form and then the saved sale.
class SalesListPage extends ConsumerStatefulWidget {
  const SalesListPage({super.key, this.initialPeriod});

  /// From `?period=today` (Home → Today's sales).
  final String? initialPeriod;

  @override
  ConsumerState<SalesListPage> createState() => _SalesListPageState();
}

class _SalesListPageState extends ConsumerState<SalesListPage> {
  final _list = PagedListController();
  final _search = TextEditingController();
  Timer? _debounce;
  late SaleFilter _filter = _filterFor(widget.initialPeriod);

  SaleFilter _filterFor(String? period) => period == 'today'
      ? SaleFilter(
          range: DateRange.preset(
            DatePreset.today,
            ref.read(businessDateProvider),
          ),
          preset: DatePreset.today,
        )
      : const SaleFilter();

  @override
  void didUpdateWidget(SalesListPage old) {
    super.didUpdateWidget(old);
    // The page stays alive in the shell; a new ?period= applies anew.
    if (widget.initialPeriod != old.initialPeriod &&
        widget.initialPeriod != null) {
      _apply(_filterFor(widget.initialPeriod));
    }
  }

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

  /// Form → (saved) → the new sale's detail; Back returns here.
  Future<void> _newSale() async {
    final type = _filter.type == 'booking' ? 'booking' : 'instant';
    final sale = await context.push<Sale>(
      '/sales/new?type=$type',
      extra: kReturnSale,
    );
    if (!mounted) return;
    _list.refresh();
    if (sale != null) await _open('/sales/${sale.id}');
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newSale,
        icon: const Icon(Icons.add),
        label: Text(l.newSale),
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
                actionLabel: l.newSale,
                onAction: _newSale,
              ),
        builder: (context, sales) => desktop
            ? SalesTable(
                sales: sales,
                showCustomer: true,
                onOpen: (s) => _open('/sales/${s.id}'),
              )
            : ListGroup(
                children: [
                  for (final s in sales)
                    SaleTile(
                      sale: s,
                      showCustomer: true,
                      onTap: () => _open('/sales/${s.id}'),
                    ),
                ],
              ),
      ),
    );
  }
}
