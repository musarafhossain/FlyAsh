import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../error/failure.dart';

export '../../l10n/app_localizations.dart';

extension L10nContext on BuildContext {
  /// UI strings in the current language: `context.l10n.navSales`.
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Text to show for a failure. Server messages are already translated
/// (Accept-Language); network problems have no server message, so they are
/// translated here.
String failureText(BuildContext context, Object error) {
  final l = context.l10n;
  return switch (error) {
    NetworkFailure(:final isTimeout) =>
      isTimeout ? l.networkTimeout : l.networkError,
    Failure(:final message) when message.isNotEmpty => message,
    _ => l.serverUnreachable,
  };
}
