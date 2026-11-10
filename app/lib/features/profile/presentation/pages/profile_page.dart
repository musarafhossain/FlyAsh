import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_bar_actions.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/app_shell.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/cards.dart';
import '../../../../core/widgets/list_items.dart';
import '../../../../core/widgets/page_layout.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../users/presentation/pages/users_list_page.dart';
import '../../../../core/widgets/skeletons.dart';

/// My profile (03-AppFlow §10): details → Edit profile · Change password.
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    // Fresh details (e.g. last login); the saved ones show meanwhile.
    Future.microtask(_reload);
  }

  Future<void> _reload() async {
    setState(() => _error = null);
    try {
      await ref.read(authControllerProvider.notifier).reloadUser();
    } on Failure catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final user = ref.watch(authControllerProvider.select((s) => s.user));

    return Scaffold(
      appBar: AppBar(
        // Opened from the drawer there is nothing to go back to: show ☰.
        leading: Navigator.of(context).canPop()
            ? null
            : ShellMenuButton.maybe(context),
        title: Text(l.myProfile),
        actions: const [AppBarActions()],
      ),
      body: user == null
          ? (_error != null
                ? ErrorState(
                    message: failureText(context, _error!),
                    onRetry: _reload,
                  )
                : const DetailSkeleton(
                    children: [
                      SkeletonHeader(),
                      SizedBox(height: Space.s3),
                      SkeletonLines(count: 3),
                      SizedBox(height: Space.s3),
                      SkeletonLines(count: 3),
                    ],
                  ))
          : PageBody(
              children: [
                AppCard(
                  child: Column(
                    children: [
                      InitialsAvatar(user.name, size: 72),
                      const SizedBox(height: Space.s3),
                      Text(
                        user.name,
                        textAlign: TextAlign.center,
                        style: AppTypography.h2.copyWith(color: t.textPrimary),
                      ),
                      const SizedBox(height: Space.s4),
                      InfoRow(
                        icon: Icons.phone_outlined,
                        label: l.phoneField,
                        value: user.phone,
                      ),
                      InfoRow(
                        icon: Icons.mail_outline,
                        label: l.emailField,
                        value: user.email ?? '—',
                      ),
                      InfoRow(
                        icon: Icons.schedule,
                        label: l.lastLoginColumn,
                        value: lastLoginText(context, user),
                      ),
                    ],
                  ),
                ),
                if (user.email == null) ...[
                  const SizedBox(height: Space.s2),
                  Text(
                    l.noEmailHintSelf,
                    style: AppTypography.caption.copyWith(color: t.warning),
                  ),
                ],
                const SizedBox(height: Space.s4),
                MenuGroup(
                  children: [
                    MenuRow(
                      icon: Icons.edit_outlined,
                      title: l.editProfile,
                      onTap: () => context.push('/profile/edit'),
                    ),
                    MenuRow(
                      icon: Icons.lock_outline,
                      title: l.changePassword,
                      subtitle: l.changePasswordHint,
                      onTap: () => context.push('/profile/password'),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
