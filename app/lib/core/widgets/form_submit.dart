import 'package:flutter/material.dart';

import '../error/failure.dart';
import '../l10n/l10n.dart';

/// Shared submit flow for forms: validate → busy → call the API →
/// field errors under the inputs (422) or one message above the button.
///
///     await submit(() async { ... });   // returns true on success
mixin FormSubmit<T extends StatefulWidget> on State<T> {
  final formKey = GlobalKey<FormState>();
  bool busy = false;
  String? error;
  Map<String, String> fieldErrors = const {};

  Future<bool> submit(Future<void> Function() action) async {
    setState(() {
      error = null;
      fieldErrors = const {};
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
