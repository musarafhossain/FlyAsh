import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/dev/presentation/pages/section_placeholder_page.dart';
import '../../features/dev/presentation/pages/theme_gallery_page.dart';
import '../../features/dev/presentation/pages/widget_gallery_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import 'app_shell.dart';
import 'nav_items.dart';

/// App routes (03-AppFlow §3.2). Every section is a branch of one
/// StatefulShellRoute, so each keeps its own navigation stack.
/// F6 adds the auth redirect (no token → /login).
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashPage()),
      if (kDebugMode) ...[
        GoRoute(
          path: '/dev/theme',
          builder: (_, _) => const ThemeGalleryPage(),
        ),
        GoRoute(
          path: '/dev/widgets',
          builder: (_, _) => const WidgetGalleryPage(),
        ),
      ],
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          for (final item in kNavItems)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: item.path,
                  builder: (_, _) => SectionPlaceholderPage(item: item),
                ),
              ],
            ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
