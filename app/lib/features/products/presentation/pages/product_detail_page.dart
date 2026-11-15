import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/network/data_changed.dart';
import '../../../../core/network/optimistic.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/action_menu.dart';
import '../../../../core/widgets/cards.dart';
import '../../../../core/widgets/page_layout.dart';
import '../../../../core/widgets/skeletons.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../data/products_repository_impl.dart';
import '../../domain/product.dart';
import '../product_actions.dart';
import 'products_list_page.dart' show ProductIcon;

/// A product (read only): icon, name, price and status on top, then notes. ✏ opens the
/// edit form; ⋮ → Deactivate / Activate | Delete. Pull to refresh.
class ProductDetailPage extends ConsumerStatefulWidget {
  const ProductDetailPage({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  Product? _product;

  /// When [_product] was set; optimistic changes made after that are shown on
  /// top of it (see `OptimisticRef.patched`).
  DateTime _loadedAt = DateTime.now();

  void _show(Product value) {
    _product = value;
    _loadedAt = DateTime.now();
  }

  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final p = await ref
          .read(productsRepositoryProvider)
          .get(widget.productId);
      if (mounted) setState(() => _show(p));
    } on Failure catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _edit() async {
    final updated = await context.push<Product>(
      '/products/${widget.productId}/edit',
    );
    if (updated != null && mounted) setState(() => _show(updated));
  }

  Future<void> _toggleActive() async {
    final updated = await toggleProductActive(context, ref, _product!);
    if (updated != null && mounted) setState(() => _show(updated));
  }

  Future<void> _delete() async {
    if (await deleteProduct(context, ref, _product!) && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = ref.patched(_product, (x) => x.id, _loadedAt);
    // An edit elsewhere (e.g. from the list) shows here too.
    ref.onDataChanged({DataTag.products}, () {
      if (_product != null) _load();
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(p?.name ?? l.productDetails),
        actions: [
          if (p != null) ...[
            IconButton(
              tooltip: l.edit,
              onPressed: _edit,
              icon: const Icon(Icons.edit_outlined),
            ),
            ActionMenuButton(
              tooltip: l.moreActions,
              groups: [
                [
                  ActionMenuItem(
                    icon: p.isActive ? Icons.block : Icons.check_circle_outline,
                    label: p.isActive ? l.deactivate : l.activate,
                    onSelected: _toggleActive,
                  ),
                ],
                [
                  ActionMenuItem(
                    icon: Icons.delete_outline,
                    label: l.delete,
                    destructive: true,
                    onSelected: _delete,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
      body: p == null
          ? (_error != null
                ? ErrorState(
                    message: failureText(context, _error!),
                    onRetry: _load,
                  )
                : const DetailSkeleton(
                    children: [
                      SkeletonHeader(),
                      SizedBox(height: Space.s3),
                      SkeletonLines(count: 3),
                    ],
                  ))
          : PageBody(
              maxWidth: 720,
              onRefresh: _load,
              children: [
                _Header(product: p),
                const SizedBox(height: Space.s3),
                AppCard(
                  child: InfoRow(
                    icon: Icons.notes_outlined,
                    label: l.notesOptional,
                    value: (p.notes ?? '').isEmpty ? '—' : p.notes!,
                  ),
                ),
                if (!p.isActive) ...[
                  const SizedBox(height: Space.s3),
                  Text(
                    l.inactiveProductHint,
                    style: AppTypography.caption.copyWith(
                      color: context.tokens.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

/// Icon, name, status pill and the price in large type.
class _Header extends StatelessWidget {
  const _Header({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final p = product;
    return AppCard(
      child: Row(
        children: [
          ProductIcon(seed: p.name, active: p.isActive, size: 56),
          const SizedBox(width: Space.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: AppTypography.h3.copyWith(color: t.textPrimary),
                ),
                const SizedBox(height: Space.s1),
                Text(
                  Fmt.money(p.defaultPrice, decimals: true),
                  style: AppTypography.h2.copyWith(
                    color: t.primary,
                    fontFeatures: AppTypography.tabular,
                  ),
                ),
                const SizedBox(height: Space.s1),
                StatusPill(
                  p.isActive ? l.active : l.inactive,
                  tone: p.isActive ? StatusTone.success : StatusTone.neutral,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
