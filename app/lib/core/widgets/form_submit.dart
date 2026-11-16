import 'package:flutter/material.dart';

import '../error/failure.dart';
import '../l10n/l10n.dart';
import 'state_views.dart' show showConfirmDialog;

/// Shared submit flow for forms: validate → busy → call the API →
/// field errors under the inputs (422) or one message above the button.
///
///     await submit(() async { ... });   // returns true on success
mixin FormSubmit<T extends StatefulWidget> on State<T> {
  final formKey = GlobalKey<FormState>();
  bool busy = false;
  String? error;
  Map<String, String> fieldErrors = const {};

  /// Extra data of the last 422, e.g. `existing_customer_id`.
  Map<String, Object?>? errorData;

  Future<bool> submit(Future<void> Function() action) async {
    setState(() {
      error = null;
      fieldErrors = const {};
      errorData = null;
    });
    if (!(formKey.currentState?.validate() ?? true)) return false;
    setState(() => busy = true);
    try {
      await action();
      return true;
    } on ValidationFailure catch (f) {
      if (mounted) {
        setState(() {
          fieldErrors = f.fieldErrors;
          errorData = f.data;
          if (f.fieldErrors.isEmpty) error = failureText(context, f);
        });
      }
    } on Failure catch (f) {
      if (mounted) setState(() => error = failureText(context, f));
    } finally {
      if (mounted) setState(() => busy = false);
    }
    return false;
  }
}

/// Shows a short message, replacing the one on screen.
void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Delete with confirmation (03-AppFlow §13): "Keep this" / "Yes, delete".
/// The dialog stays open while [delete] runs (buttons off, spinner); it
/// closes when the server confirms and the success message is shown. On
/// failure the server's message is shown (toast + in the dialog) and the
/// dialog stays open. Returns true when deleted.
Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
  required Future<String> Function() delete,
}) async {
  final l = context.l10n;
  String? done;
  final ok = await showConfirmDialog(
    context,
    title: title,
    message: message,
    confirmLabel: l.yesDelete,
    cancelLabel: l.keepThis,
    destructive: true,
    onConfirm: () async {
      try {
        done = await delete();
        return null;
      } on Failure catch (f) {
        return context.mounted ? failureText(context, f) : f.message;
      }
    },
  );
  if (ok && done != null && context.mounted) showMessage(context, done!);
  return ok;
}
