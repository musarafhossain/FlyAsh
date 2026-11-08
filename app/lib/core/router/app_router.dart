import 'dart:convert';

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

/// The page to return to after login is kept in `?from=` as base64url
/// (only A–Z a–z 0–9 - _), because Flutter web shows percent-encoded
/// values decoded in the address bar (`from=/sales`). Encoded:
/// `/login?from=L3NhbGVz`.
String encodeFrom(String location) =>
    base64Url.encode(utf8.encode(location)).replaceAll('=', '');

/// Reads `from`; returns null if it is missing, broken or not an internal,
/// private page (e.g. an outside URL or the login page itself).
String? decodeFrom(String? value) {
  if (value == null || value.isEmpty) return null;
  try {
    final location = utf8.decode(base64Url.decode(base64Url.normalize(value)));
    final safe =
        location.startsWith('/') &&
        !location.startsWith('//') &&
        !isPublicRoute(Uri.parse(location).path) &&
        location != '/splash';
    return safe ? location : null;
  } on FormatException {
    return null;
  }
}

/// Where to go for a given auth state (null = stay). Keeps the page the
/// user asked for in `?from=` so they land there after login.
String? authRedirect(AuthState auth, Uri uri) {
  final location = uri.path;
  if (kDebugMode && location.startsWith('/dev')) return null;

  final rawFrom = uri.queryParameters['from'];
  final from = decodeFrom(rawFrom);

  // Home is the default after login, so it is never kept in `from`.
  String withFrom(String page) =>
      (location == '/splash' ||
          isPublicRoute(location) ||
          location == '/' ||
          location == '/home')
      ? page
      : '$page?from=${encodeFrom(uri.toString())}';

  switch (auth.status) {
    case AuthStatus.checking:
      return location == '/splash' ? null : withFrom('/splash');
    case AuthStatus.signedOut:
      if (isPublicRoute(location)) return null;
      return from != null ? '/login?from=$rawFrom' : withFrom('/login');
    case AuthStatus.signedIn:
      return (location == '/splash' ||
              isPublicRoute(location) ||
              location == '/')
          ? (from ?? '/home')
          : null;
  }
}

/// App routes (03-AppFlow §3.2). Every section is a branch of one
/// StatefulShellRoute, so each keeps its own navigation stack.
final routerProvider = Provider<GoRouter>((ref) {
  // Every screen shows its own address in the browser, also screens opened
  // with push() (forgot password, OTP, new password …). go_router keeps the
  // previous URL for push() unless this is on.
  GoRouter.optionURLReflectsImperativeAPIs = true;

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
        builder: (_, state) => ForgotPasswordPage(
          initialEmail: state.extra is String ? state.extra! as String : null,
        ),
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
