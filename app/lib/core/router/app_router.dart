import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/pages/forgot_password_pages.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/dev/presentation/pages/section_placeholder_page.dart';
import '../../features/dev/presentation/pages/theme_gallery_page.dart';
import '../../features/dev/presentation/pages/widget_gallery_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import 'app_shell.dart';
import 'nav_items.dart';

/// Pages that do not need a login.
bool isPublicRoute(String location) =>
    location == '/login' || location.startsWith('/forgot-password');

/// Where to go for a given auth state (null = stay). Keeps the page the
/// user asked for in `?from=` so they land there after login.
String? authRedirect(AuthState auth, Uri uri) {
  final location = uri.path;
  if (kDebugMode && location.startsWith('/dev')) return null;

  final from = uri.queryParameters['from'];
  final target =
      (from != null &&
          from.startsWith('/') &&
          !isPublicRoute(from) &&
          from != '/splash')
      ? from
      : '/home';
  String withFrom(String page) =>
      (location == '/splash' || isPublicRoute(location) || location == '/')
      ? page
      : '$page?from=${Uri.encodeComponent(uri.toString())}';

  switch (auth.status) {
    case AuthStatus.checking:
      return location == '/splash' ? null : withFrom('/splash');
    case AuthStatus.signedOut:
      if (isPublicRoute(location)) return null;
      return from != null
          ? '/login?from=${Uri.encodeComponent(from)}'
          : withFrom('/login');
    case AuthStatus.signedIn:
      return (location == '/splash' ||
              isPublicRoute(location) ||
              location == '/')
          ? target
          : null;
  }
}

/// App routes (03-AppFlow §3.2). Every section is a branch of one
/// StatefulShellRoute, so each keeps its own navigation stack.
final routerProvider = Provider<GoRouter>((ref) {
  // Re-run the redirect whenever the auth state changes.
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) =>
        authRedirect(ref.read(authControllerProvider), state.uri),
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashPage()),
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const ForgotPasswordPage(),
        routes: [
          GoRoute(
            path: 'verify',
            redirect: (_, state) =>
                state.extra is String ? null : '/forgot-password',
            builder: (_, state) => VerifyOtpPage(email: state.extra! as String),
          ),
          GoRoute(
            path: 'reset',
            redirect: (_, state) =>
                state.extra is String ? null : '/forgot-password',
            builder: (_, state) =>
                ResetPasswordPage(resetToken: state.extra! as String),
          ),
        ],
      ),
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
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
