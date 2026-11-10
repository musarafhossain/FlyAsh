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
import '../../../../core/widgets/list_items.dart';
import '../../../../core/widgets/data_table_card.dart';
import '../../../../core/widgets/paged_list.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../data/products_repository_impl.dart';
import '../../domain/product.dart';

/// Unit name in the current language ("Piece", "1000 pieces", "cft" …).
String unitText(AppLocalizations l, ProductUnit unit, [String? label]) =>
    switch (unit) {
      ProductUnit.piece => l.unitPiece,
      ProductUnit.thousand => l.unitThousand,
      ProductUnit.truck => l.unitTruck,
      ProductUnit.other =>
        (label == null || label.trim().isEmpty) ? l.unitOther : label,
    };

/// Which products the list shows.
enum ProductFilter { all, active, inactive }

/// Products (03-AppFlow §6, PRD PROD-1…5): search, All/Active/Inactive,
/// cards on phones and tablets, a table on desktop. Tap a product to edit it.
class ProductsListPage extends ConsumerStatefulWidget {
  const ProductsListPage({super.key});

  @override
  ConsumerState<ProductsListPage> createState() => _ProductsListPageState();
}

class _ProductsListPageState extends ConsumerState<ProductsListPage> {
  final _list = PagedListController();
  final _search = TextEditingController();
  Timer? _debounce;
  ProductFilter _filter = ProductFilter.all;

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

  void _setFilter(ProductFilter filter) {
    setState(() => _filter = filter);
    _list.refresh();
  }

  /// Opens a page and reloads the list when the user comes back.
  Future<void> _open(String location) async {
    await context.push(location);
    if (mounted) _list.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = ref.watch(productsRepositoryProvider);
    final desktop = MediaQuery.sizeOf(context).width >= Breakpoints.expanded;
    final searching = _search.text.trim().isNotEmpty;
    final filtered = searching || _filter != ProductFilter.all;

    return Scaffold(
      appBar: AppBar(
        leading: ShellMenuButton.maybe(context),
        title: Text(l.navProducts),
        actions: const [AppBarActions()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open('/products/new'),
        icon: const Icon(Icons.add),
        label: Text(l.addProduct),
      ),
      body: PagedList<Product>(
        controller: _list,
        fetch: (page) => repo.list(
          page: page,
          search: _search.text,
          active: switch (_filter) {
            ProductFilter.all => null,
            ProductFilter.active => true,
            ProductFilter.inactive => false,
          },
        ),
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _search,
              onChanged: _onSearch,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l.searchProducts,
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
                  (ProductFilter.all, l.filterAll),
                  (ProductFilter.active, l.active),
                  (ProductFilter.inactive, l.inactive),
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
                icon: Icons.inventory_2_outlined,
                title: l.productsEmptyTitle,
                message: l.productsEmptyMessage,
                actionLabel: l.addProduct,
                onAction: () => _open('/products/new'),
              ),
        builder: (context, products) => desktop
            ? _ProductsTable(
                products: products,
                onOpen: (p) => _open('/products/${p.id}/edit'),
              )
            : ListGroup(
                children: [
                  for (final p in products)
                    ProductTile(
                      product: p,
                      onTap: () => _open('/products/${p.id}/edit'),
                    ),
                ],
              ),
      ),
    );
  }
}

/// Brick icon in a coloured circle (colour from the name; grey when inactive).
class ProductIcon extends StatelessWidget {
  const ProductIcon({
    super.key,
    this.seed = '',
    this.active = true,
    this.size = 48,
  });

  final String seed;
  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) => ColorAvatar(
    seed: seed,
    icon: Icons.view_module_rounded,
    size: size,
    dimmed: !active,
  );
}

/// Phone/tablet row: icon · name · "per Piece" · cost → price · margin.
class ProductTile extends StatelessWidget {
  const ProductTile({super.key, required this.product, this.onTap});

  final Product product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final p = product;
    final unit = unitText(l, p.unit, p.unitLabel);

    return Opacity(
      opacity: p.isActive ? 1 : 0.6,
      child: ListRowSurface(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          horizontal: Space.s4,
          vertical: Space.s3,
        ),
        child: Row(
          children: [
            ProductIcon(seed: p.name, active: p.isActive),
            const SizedBox(width: Space.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.title.copyWith(color: t.textPrimary),
                  ),
                  Text(
                    l.perUnit(unit),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: t.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${Fmt.money(p.defaultCost, decimals: true)} → '
                    '${Fmt.money(p.defaultPrice, decimals: true)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: t.textTertiary,
                      fontFeatures: AppTypography.tabular,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Space.s2),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!p.isActive) ...[
                  StatusPill(l.inactive),
                  const SizedBox(height: Space.s1),
                ],
                MarginText(product: p),
                Text(
                  l.margin,
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

/// "+₹2.50" in green, or "−₹1.00" in red when sold at a loss.
class MarginText extends StatelessWidget {
  const MarginText({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final loss = product.isLoss;
    final amount = Fmt.money(
      loss ? product.margin.substring(1) : product.margin,
      decimals: true,
    );
    return Text(
      '${loss ? '−' : '+'}$amount',
      style: AppTypography.bodyStrong.copyWith(
        color: loss ? t.error : t.success,
        fontFeatures: AppTypography.tabular,
      ),
    );
  }
}

class _ProductsTable extends StatelessWidget {
  const _ProductsTable({required this.products, required this.onOpen});

  final List<Product> products;
  final ValueChanged<Product> onOpen;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    String money(String v) => Fmt.money(v, decimals: true);
    return DataTableCard(
      columns: [
        TableColumnDef(l.productName, flex: 4),
        TableColumnDef(l.unitField, flex: 2),
        TableColumnDef(l.defaultCost, flex: 2, alignEnd: true),
        TableColumnDef(l.defaultPrice, flex: 2, alignEnd: true),
        TableColumnDef(l.margin, flex: 2, alignEnd: true),
        TableColumnDef(l.status, flex: 2, alignEnd: true),
      ],
      rows: [
        for (final p in products)
          [
            Row(
              children: [
                ProductIcon(seed: p.name, active: p.isActive, size: 32),
                const SizedBox(width: Space.s3),
                Expanded(child: CellText(p.name, strong: true)),
              ],
            ),
            CellText(unitText(l, p.unit, p.unitLabel)),
            CellText(money(p.defaultCost)),
            CellText(money(p.defaultPrice)),
            MarginText(product: p),
            StatusPill(
              p.isActive ? l.active : l.inactive,
              tone: p.isActive ? StatusTone.success : StatusTone.neutral,
            ),
          ],
      ],
      onTapRow: (i) => onOpen(products[i]),
    );
  }
}
