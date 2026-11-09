import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/pages/forgot_password_pages.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/customers/presentation/pages/customer_detail_page.dart';
import '../../features/customers/presentation/pages/customer_form_page.dart';
import '../../features/customers/presentation/pages/customers_list_page.dart';
import '../../features/dev/presentation/pages/section_placeholder_page.dart';
import '../../features/dev/presentation/pages/theme_gallery_page.dart';
import '../../features/dev/presentation/pages/widget_gallery_page.dart';
import '../../features/labours/presentation/pages/labours_page.dart';
import '../../features/products/presentation/pages/product_form_page.dart';
import '../../features/products/presentation/pages/products_list_page.dart';
import '../../features/profile/presentation/pages/change_password_page.dart';
import '../../features/profile/presentation/pages/profile_edit_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/sales/presentation/pages/sale_detail_page.dart';
import '../../features/sales/presentation/pages/sales_list_page.dart';
import '../../features/sales/presentation/pages/upcoming_deliveries_page.dart';
import '../../features/settings/presentation/pages/about_page.dart';
import '../../features/settings/presentation/pages/appearance_page.dart';
import '../../features/settings/presentation/pages/factory_profile_page.dart';
import '../../features/settings/presentation/pages/language_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/auth/domain/app_user.dart';
import '../../features/users/presentation/pages/user_detail_page.dart';
import '../../features/users/presentation/pages/user_form_page.dart';
import '../../features/users/presentation/pages/users_list_page.dart';
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

  // Re-run the redirect when the login status changes (not when only the
  // user's details change, which would rebuild the open pages).
  final refresh = ValueNotifier<int>(0);
  ref.listen(
    authControllerProvider.select((s) => s.status),
    (_, _) => refresh.value++,
  );

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
            StatefulShellBranch(routes: sectionRoutes(item)),
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

/// The routes of one section (its own navigation stack in the shell).
/// Sections without a real screen yet show a placeholder.
List<RouteBase> sectionRoutes(NavItem item) => switch (item.path) {
  '/users' => [
    GoRoute(
      path: '/users',
      builder: (_, _) => const UsersListPage(),
      routes: [
        GoRoute(path: 'new', builder: (_, _) => const UserFormPage()),
        GoRoute(
          path: ':id',
          redirect: (_, state) =>
              _intParam(state, 'id') == null ? '/users' : null,
          builder: (_, state) =>
              UserDetailPage(userId: _intParam(state, 'id')!),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (_, state) => UserFormPage(
                userId: _intParam(state, 'id'),
                initial: state.extra is AppUser
                    ? state.extra! as AppUser
                    : null,
              ),
            ),
          ],
        ),
      ],
    ),
  ],
  '/settings' => [
    GoRoute(
      path: '/settings',
      builder: (_, _) => const SettingsPage(),
      routes: [
        GoRoute(path: 'factory', builder: (_, _) => const FactoryProfilePage()),
        GoRoute(path: 'appearance', builder: (_, _) => const AppearancePage()),
        GoRoute(path: 'language', builder: (_, _) => const LanguagePage()),
        GoRoute(path: 'about', builder: (_, _) => const AboutPage()),
      ],
    ),
    // My profile lives in the Settings section (Settings stays selected).
    GoRoute(
      path: '/profile',
      builder: (_, _) => const ProfilePage(),
      routes: [
        GoRoute(path: 'edit', builder: (_, _) => const ProfileEditPage()),
        GoRoute(
          path: 'password',
          builder: (_, _) => const ChangePasswordPage(),
        ),
      ],
    ),
  ],
  '/sales' => [
    GoRoute(
      path: '/sales',
      builder: (_, _) => const SalesListPage(),
      routes: [
        // Before ':id' so "upcoming" is not read as a sale id.
        GoRoute(
          path: 'upcoming',
          builder: (_, _) => const UpcomingDeliveriesPage(),
        ),
        GoRoute(
          path: ':id',
          redirect: (_, state) =>
              _intParam(state, 'id') == null ? '/sales' : null,
          builder: (_, state) =>
              SaleDetailPage(saleId: _intParam(state, 'id')!),
        ),
      ],
    ),
  ],
  '/customers' => [
    GoRoute(
      path: '/customers',
      builder: (_, _) => const CustomersListPage(),
      routes: [
        GoRoute(path: 'new', builder: (_, _) => const CustomerFormPage()),
        GoRoute(
          path: ':id',
          redirect: (_, state) =>
              _intParam(state, 'id') == null ? '/customers' : null,
          builder: (_, state) =>
              CustomerDetailPage(customerId: _intParam(state, 'id')!),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (_, state) =>
                  CustomerFormPage(customerId: _intParam(state, 'id')),
            ),
          ],
        ),
      ],
    ),
  ],
  '/products' => [
    GoRoute(
      path: '/products',
      builder: (_, _) => const ProductsListPage(),
      routes: [
        GoRoute(path: 'new', builder: (_, _) => const ProductFormPage()),
        // No separate detail page: /products/:id opens the edit form.
        GoRoute(
          path: ':id',
          redirect: (_, state) {
            final id = _intParam(state, 'id');
            if (id == null) return '/products';
            return state.uri.path == '/products/$id'
                ? '/products/$id/edit'
                : null;
          },
          routes: [
            GoRoute(
              path: 'edit',
              builder: (_, state) =>
                  ProductFormPage(productId: _intParam(state, 'id')),
            ),
          ],
        ),
      ],
    ),
  ],
  // Labours · Wages are two tabs of one section; switching tabs does not
  // animate like opening a new page.
  '/labours' => [
    for (final tab in LaboursTab.values)
      GoRoute(
        path: tab.path,
        pageBuilder: (_, state) => NoTransitionPage(
          key: state.pageKey,
          child: LaboursPage(tab: tab),
        ),
      ),
  ],
  _ => [
    GoRoute(
      path: item.path,
      builder: (_, _) => SectionPlaceholderPage(item: item),
    ),
  ],
};

int? _intParam(GoRouterState state, String name) =>
    int.tryParse(state.pathParameters[name] ?? '');
