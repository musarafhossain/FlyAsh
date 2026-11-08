import 'package:flutter/widgets.dart';

import '../l10n/l10n.dart';

/// Form validators with translated messages (same rules as the API).
/// Usage: `validator: Validators.of(context).phone`.
class Validators {
  Validators.of(BuildContext context) : _l = context.l10n;

  final AppLocalizations _l;

  static final _phone = RegExp(r'^[6-9]\d{9}$');
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  String? required(String? v) =>
      (v == null || v.trim().isEmpty) ? _l.fieldRequired : null;

  /// 10-digit Indian mobile number starting with 6–9.
  String? phone(String? v) =>
      required(v) ?? (_phone.hasMatch(v!.trim()) ? null : _l.invalidPhone);

  /// Like [phone], but empty is allowed.
  String? optionalPhone(String? v) =>
      (v == null || v.trim().isEmpty) ? null : phone(v);

  /// Empty is allowed (the email is optional everywhere).
  String? optionalEmail(String? v) =>
      (v == null || v.trim().isEmpty || _email.hasMatch(v.trim()))
      ? null
      : _l.invalidEmail;

  /// 6–64 characters.
  String? password(String? v) => (v == null || v.length < 6)
      ? _l.passwordRule
      : v.length > 64
      ? _l.passwordTooLong
      : null;

  /// Must equal [other] (read when validating).
  FormFieldValidator<String> sameAs(TextEditingController other) =>
      (v) => required(v) ?? (v == other.text ? null : _l.passwordsDontMatch);
}

/// Trimmed text, or null when empty (for optional API fields).
String? textOrNull(TextEditingController c) {
  final v = c.text.trim();
  return v.isEmpty ? null : v;
}
