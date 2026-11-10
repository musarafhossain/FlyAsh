import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/l10n/l10n.dart';
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
    final (updated, message) = await ref
        .read(productsRepositoryProvider)
        .setActive(p.id, !deactivate);
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
  final ok = await showConfirmDialog(
    context,
    title: l.deleteProductTitle(p.name),
    message: l.deleteProductMessage,
    confirmLabel: l.delete,
    destructive: true,
  );
  if (!ok || !context.mounted) return false;
  onBusy?.call(true);
  try {
    final message = await ref.read(productsRepositoryProvider).delete(p.id);
    if (context.mounted) showMessage(context, message);
    return true;
  } on Failure catch (f) {
    if (context.mounted) showMessage(context, failureText(context, f));
    return false;
  } finally {
    onBusy?.call(false);
  }
}
