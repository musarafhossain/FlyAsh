import 'dart:async';

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
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/dev/presentation/pages/section_placeholder_page.dart';
import '../../features/dev/presentation/pages/theme_gallery_page.dart';
import '../../features/dev/presentation/pages/widget_gallery_page.dart';
import '../../features/expenses/presentation/pages/expense_form_page.dart';
import '../../features/expenses/presentation/pages/expenses_list_page.dart';
import '../../features/labours/presentation/pages/labour_detail_page.dart';
import '../../features/labours/presentation/pages/labour_form_page.dart';
import '../../features/labours/presentation/pages/labours_page.dart';
import '../../features/products/presentation/pages/product_detail_page.dart';
import '../../features/products/presentation/pages/product_form_page.dart';
import '../../features/products/presentation/pages/products_list_page.dart';
import '../../features/profile/presentation/pages/change_password_page.dart';
import '../../features/profile/presentation/pages/profile_edit_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/sales/presentation/pages/sale_detail_page.dart';
import '../../features/sales/presentation/pages/sale_form_page.dart';
import '../../features/sales/presentation/pages/sales_list_page.dart';
import '../../features/sales/presentation/pages/upcoming_deliveries_page.dart';
import '../../features/settings/presentation/pages/about_page.dart';
import '../../features/settings/presentation/pages/appearance_page.dart';
import '../../features/settings/presentation/pages/factory_profile_page.dart';
import '../../features/settings/presentation/pages/language_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/attendance/presentation/pages/attendance_page.dart';
import '../../features/auth/domain/app_user.dart';
import '../../features/customers/domain/customer.dart';
import '../../features/labours/domain/labour.dart';
import '../../features/products/domain/product.dart';
import '../../features/users/presentation/pages/user_detail_page.dart';
import '../../features/wages/presentation/pages/wage_detail_page.dart';
import '../../features/users/presentation/pages/user_form_page.dart';
import '../../features/users/presentation/pages/users_list_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import 'app_shell.dart';
import '../../features/reports/domain/reports.dart';
import '../../features/reports/presentation/pages/report_page.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import 'back_guard.dart';
import 'web_history_sync.dart';
import 'shell_pager.dart';
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
    // Dialogs, sheets and menus: the back button closes them first.
    observers: [BackGuardObserver()],
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
      StatefulShellRoute(
        builder: (context, state, shell) => AppShell(shell: shell),
        // Phone / tablet: the bottom-bar sections can be swiped (ShellPager).
        navigatorContainerBuilder: (context, shell, children) =>
            ShellPager(shell: shell, children: children),
        branches: [
          for (final item in kNavItems)
            StatefulShellBranch(
              // The section's own first page, whatever the route order.
              initialLocation: item.path,
              // Bottom-bar sections are ready before the first swipe, so the
              // next page already shows its content while the finger moves.
              preload: item.primary,
              observers: [BackGuardObserver()],
              routes: sectionRoutes(item),
            ),
        ],
      ),
    ],
  );
  // Web: the browser history follows the page stack (see WebHistorySync).
  WebHistorySync.instance.currentLocation = () =>
      router.routeInformationProvider.value.uri.toString();
  void onNavigate() => unawaited(WebHistorySync.instance.navigated());
  router.routeInformationProvider.addListener(onNavigate);
  onNavigate();
  ref.onDispose(() {
    router.routeInformationProvider.removeListener(onNavigate);
    router.dispose();
    refresh.dispose();
  });
  return router;
});

/// The routes of one section (its own navigation stack in the shell).
/// Sections without a real screen yet show a placeholder.
List<RouteBase> sectionRoutes(NavItem item) => switch (item.path) {
  // Reports grid → one report (/reports/sales, /reports/net-profit …).
  '/reports' => [
    GoRoute(
      path: '/reports',
      builder: (_, _) => const ReportsPage(),
      routes: [
        GoRoute(
          path: ':type',
          redirect: (_, state) =>
              ReportType.fromPath(state.pathParameters['type']) == null
              ? '/reports'
              : null,
          builder: (_, state) => ReportPage(
            type: ReportType.fromPath(state.pathParameters['type'])!,
          ),
        ),
      ],
    ),
  ],
  '/users' => [
    GoRoute(
      path: '/users',
      builder: (_, _) => const UsersListPage(),
      routes: [
        GoRoute(path: 'new', builder: (_, _) => const UserFormPage()),
        GoRoute(
          path: ':id',
          redirect: (_, state) =>
              _idParam(state, 'id') == null ? '/users' : null,
          builder: (_, state) => UserDetailPage(
            userId: _idParam(state, 'id')!,
            initial: _extra<AppUser>(state),
          ),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (_, state) => UserFormPage(
                userId: _idParam(state, 'id'),
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
  '/home' => [GoRoute(path: '/home', builder: (_, _) => const DashboardPage())],
  '/sales' => [
    GoRoute(
      path: '/sales',
      builder: (_, state) =>
          SalesListPage(initialPeriod: state.uri.queryParameters['period']),
      routes: [
        // Before ':id' so "upcoming" / "new" are not read as sale ids.
        GoRoute(
          path: 'upcoming',
          builder: (_, _) => const UpcomingDeliveriesPage(),
        ),
        GoRoute(
          path: 'new',
          builder: (_, state) => SaleFormPage(
            initialType: state.uri.queryParameters['type'] ?? 'instant',
            customerId: _idOrNull(state.uri.queryParameters['customer']),
          ),
        ),
        GoRoute(
          path: ':id',
          redirect: (_, state) =>
              _idParam(state, 'id') == null ? '/sales' : null,
          builder: (_, state) => SaleDetailPage(saleId: _idParam(state, 'id')!),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (_, state) =>
                  SaleFormPage(saleId: _idParam(state, 'id')),
            ),
          ],
        ),
      ],
    ),
  ],
  '/customers' => [
    GoRoute(
      path: '/customers',
      builder: (_, state) =>
          CustomersListPage(initialFilter: state.uri.queryParameters['filter']),
      routes: [
        GoRoute(path: 'new', builder: (_, _) => const CustomerFormPage()),
        GoRoute(
          path: ':id',
          redirect: (_, state) =>
              _idParam(state, 'id') == null ? '/customers' : null,
          builder: (_, state) => CustomerDetailPage(
            customerId: _idParam(state, 'id')!,
            initial: _extra<Customer>(state),
          ),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (_, state) =>
                  CustomerFormPage(customerId: _idParam(state, 'id')),
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
        GoRoute(
          path: ':id',
          redirect: (_, state) =>
              _idParam(state, 'id') == null ? '/products' : null,
          builder: (_, state) => ProductDetailPage(
            productId: _idParam(state, 'id')!,
            initial: _extra<Product>(state),
          ),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (_, state) =>
                  ProductFormPage(productId: _idParam(state, 'id')),
            ),
          ],
        ),
      ],
    ),
  ],
  // The labour list only; a labour's wages are at /labours/:id/wages.
  '/labours' => [
    GoRoute(
      path: '/labours',
      builder: (_, _) => const LaboursPage(),
      routes: [
        GoRoute(path: 'new', builder: (_, _) => const LabourFormPage()),
        GoRoute(
          path: ':id',
          redirect: (_, state) =>
              _idParam(state, 'id') == null ? '/labours' : null,
          builder: (_, state) => LabourDetailPage(
            labourId: _idParam(state, 'id')!,
            initial: _extra<Labour>(state),
          ),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (_, state) =>
                  LabourFormPage(labourId: _idParam(state, 'id')),
            ),
            // The labour's wages for a month (?month=YYYY-MM).
            GoRoute(
              path: 'wages',
              builder: (_, state) => WageDetailPage(
                labourId: _idParam(state, 'id')!,
                month: state.uri.queryParameters['month'],
              ),
            ),
          ],
        ),
      ],
    ),
  ],
  '/expenses' => [
    GoRoute(
      path: '/expenses',
      builder: (_, _) => const ExpensesListPage(),
      routes: [
        GoRoute(path: 'new', builder: (_, _) => const ExpenseFormPage()),
        // No separate detail page: /expenses/:id opens the edit form.
        GoRoute(
          path: ':id',
          redirect: (_, state) {
            final id = _idParam(state, 'id');
            if (id == null) return '/expenses';
            return state.uri.path == '/expenses/$id'
                ? '/expenses/$id/edit'
                : null;
          },
          routes: [
            GoRoute(
              path: 'edit',
              builder: (_, state) =>
                  ExpenseFormPage(expenseId: _idParam(state, 'id')),
            ),
          ],
        ),
      ],
    ),
  ],
  '/attendance' => [
    GoRoute(
      path: '/attendance',
      builder: (_, state) =>
          AttendancePage(initialDate: state.uri.queryParameters['date']),
    ),
  ],
  _ => [
    GoRoute(
      path: item.path,
      builder: (_, _) => SectionPlaceholderPage(item: item),
    ),
  ],
};

/// One page for both Labours tabs (see the '/labours' routes).

/// The record handed over with `push(..., extra: record)` (a list row
/// opening its detail page), or null (deep link, refresh, other type).
T? _extra<T>(GoRouterState state) => state.extra is T ? state.extra as T : null;

/// A record id from the path (a UUID); anything else is not a record.
String? _idParam(GoRouterState state, String name) =>
    _idOrNull(state.pathParameters[name]);

final _idPattern = RegExp(r'^[0-9a-fA-F-]{1,36}$');

String? _idOrNull(String? v) => v != null && _idPattern.hasMatch(v) ? v : null;
