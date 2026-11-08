import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/l10n/locale_controller.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/page_layout.dart';

/// Settings → Language: English / বাংলা. Applies instantly and is saved
/// on the device and to the account (PreferencesSync).
class LanguagePage extends ConsumerWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final code = ref.watch(localeProvider);
    final controller = ref.read(localeProvider.notifier);

    Widget option(String value, String title, String subtitle) => MenuRow(
      icon: code == value ? Icons.radio_button_checked : Icons.radio_button_off,
      color: code == value ? t.primary : null,
      title: title,
      subtitle: subtitle,
      showChevron: false,
      onTap: () => controller.setLocale(value),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l.language)),
      body: PageBody(
        children: [
          MenuGroup(
            children: [
              // Each language is named in itself, so anyone can find theirs.
              option('en', 'English', 'English'),
              option('bn', 'বাংলা', 'Bengali'),
            ],
          ),
          const SizedBox(height: Space.s3),
          Text(
            l.languageHint,
            style: AppTypography.caption.copyWith(color: t.textTertiary),
          ),
        ],
      ),
    );
  }
}
