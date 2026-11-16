import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/network/optimistic.dart';
import '../../../core/widgets/form_submit.dart';
import '../../../core/widgets/state_views.dart';
import '../data/products_repository_impl.dart';
import '../domain/product.dart';

/// Product actions shared by the list (long press) and the edit page.
/// Each asks first, shows the server's message, and returns the result.

/// Activate / deactivate. Returns the updated product, or null when the
/// user cancelled or it failed.
Future<Product?> toggleProductActive(
  BuildContext context,
  WidgetRef ref,
  Product p, {
  ValueChanged<bool>? onBusy,
}) async {
  final l = context.l10n;
  final deactivate = p.isActive;
  final ok = await showConfirmDialog(
    context,
    title: deactivate
        ? l.deactivateProductTitle(p.name)
        : l.activateProductTitle(p.name),
    message: deactivate ? l.deactivateProductMessage : l.activateProductMessage,
    confirmLabel: deactivate ? l.deactivate : l.activate,
    destructive: deactivate,
  );
  if (!ok || !context.mounted) return null;
  onBusy?.call(true);
  try {
    // Optimistic: the new state shows at once and goes back on failure.
    final (updated, message) = await ref.optimistic(
      p.id,
      p.withActive(!deactivate),
      () => ref.read(productsRepositoryProvider).setActive(p.id, !deactivate),
    );
    if (context.mounted) showMessage(context, message);
    return updated;
  } on Failure catch (f) {
    if (context.mounted) showMessage(context, failureText(context, f));
    return null;
  } finally {
    onBusy?.call(false);
  }
}

/// Delete. Returns true when deleted. A product used in sales is refused
/// (409) and the server's message says to deactivate it instead.
Future<bool> deleteProduct(
  BuildContext context,
  WidgetRef ref,
  Product p, {
  ValueChanged<bool>? onBusy,
}) async {
  final l = context.l10n;
  // The dialog waits for the server; the row goes when it is really gone.
  return confirmDelete(
    context,
    title: l.deleteProductTitle(p.name),
    message: l.deleteProductMessage,
    delete: () => ref.read(productsRepositoryProvider).delete(p.id),
  );
}
