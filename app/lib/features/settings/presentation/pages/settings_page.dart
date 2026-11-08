import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/l10n/locale_controller.dart';
import '../../../../core/router/app_shell.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/widgets/cards.dart';
import '../../../../core/widgets/list_items.dart';
import '../../../../core/widgets/page_layout.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../data/settings_repository_impl.dart';

/// Settings (03-AppFlow §11): My profile · Factory profile · Appearance ·
/// Language · About · Log out.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final user = ref.watch(authControllerProvider.select((s) => s.user));
    final factory = ref.watch(factorySettingsProvider).value;
    final locale = ref.watch(localeProvider);
    final theme = ref.watch(themeControllerProvider);

    Future<void> logout() async {
      final ok = await showConfirmDialog(
        context,
        title: l.logoutConfirmTitle,
        message: l.logoutConfirmMessage,
        confirmLabel: l.logout,
        destructive: true,
      );
      if (ok) await ref.read(authControllerProvider.notifier).logout();
    }

    return Scaffold(
      appBar: AppBar(
        leading: ShellMenuButton.maybe(context),
        title: Text(l.navSettings),
      ),
      body: PageBody(
        maxWidth: 720,
        children: [
          // Profile card → My profile
          AppCard(
            onTap: () => context.push('/profile'),
            child: Row(
              children: [
                InitialsAvatar(user?.name ?? '?', size: 52),
                const SizedBox(width: Space.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? l.myProfile,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.title.copyWith(
                          color: t.textPrimary,
                        ),
                      ),
                      Text(
                        user == null ? l.viewProfile : user.phone,
                        style: AppTypography.caption.copyWith(
                          color: t.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: t.textTertiary),
              ],
            ),
          ),
          MenuGroup(
            title: l.settingsAccount,
            children: [
              MenuRow(
                icon: Icons.person_outline,
                title: l.myProfile,
                onTap: () => context.push('/profile'),
              ),
              MenuRow(
                icon: Icons.lock_outline,
                title: l.changePassword,
                onTap: () => context.push('/profile/password'),
              ),
            ],
          ),
          MenuGroup(
            title: l.settingsFactory,
            children: [
              MenuRow(
                icon: Icons.factory_outlined,
                title: l.factoryProfile,
                subtitle: factory?.factoryName,
                onTap: () => context.push('/settings/factory'),
              ),
            ],
          ),
          MenuGroup(
            title: l.settingsApp,
            children: [
              MenuRow(
                icon: Icons.palette_outlined,
                title: l.appearance,
                value: themeModeLabel(l, theme.mode),
                onTap: () => context.push('/settings/appearance'),
              ),
              MenuRow(
                icon: Icons.translate,
                title: l.language,
                value: locale == 'bn' ? l.languageBengali : l.languageEnglish,
                onTap: () => context.push('/settings/language'),
              ),
              MenuRow(
                icon: Icons.info_outline,
                title: l.aboutApp,
                onTap: () => context.push('/settings/about'),
              ),
            ],
          ),
          if (kDebugMode)
            MenuGroup(
              title: 'Developer',
              children: [
                MenuRow(
                  icon: Icons.palette_outlined,
                  title: 'Theme gallery',
                  onTap: () => context.push('/dev/theme'),
                ),
                MenuRow(
                  icon: Icons.widgets_outlined,
                  title: 'Widget gallery',
                  onTap: () => context.push('/dev/widgets'),
                ),
              ],
            ),
          const SizedBox(height: Space.s4),
          MenuGroup(
            children: [
              MenuRow(
                icon: Icons.logout,
                title: l.logout,
                color: t.error,
                onTap: logout,
                showChevron: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "System" / "Light" / "Dark" in the current language.
String themeModeLabel(AppLocalizations l, ThemeMode mode) => switch (mode) {
  ThemeMode.system => l.themeSystem,
  ThemeMode.light => l.themeLight,
  ThemeMode.dark => l.themeDark,
};
