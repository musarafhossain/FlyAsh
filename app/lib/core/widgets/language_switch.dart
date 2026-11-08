import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../l10n/locale_controller.dart';

/// "EN / বাংলা" switch for the top-right corner (Login, splash, settings).
/// Changing it switches the UI text and the API messages together.
class LanguageSwitch extends ConsumerWidget {
  const LanguageSwitch({super.key, this.iconOnly = false});

  /// Only the 文A icon (narrow app bars on phones).
  final bool iconOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = ref.watch(localeProvider);
    final l = context.l10n;
    return PopupMenuButton<String>(
      tooltip: l.language,
      initialValue: code,
      onSelected: (value) => ref.read(localeProvider.notifier).setLocale(value),
      itemBuilder: (_) => [
        CheckedPopupMenuItem(
          value: 'en',
          checked: code == 'en',
          child: Text(l.languageEnglish),
        ),
        CheckedPopupMenuItem(
          value: 'bn',
          checked: code == 'bn',
          child: Text(l.languageBengali),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.translate, size: 20),
            if (!iconOnly) ...[
              const SizedBox(width: 6),
              Text(code == 'bn' ? l.languageBengali : 'EN'),
            ],
          ],
        ),
      ),
    );
  }
}
