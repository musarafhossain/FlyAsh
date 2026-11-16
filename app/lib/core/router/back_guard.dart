import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'web_history_sync.dart';

/// The back button closes what is open on top (the drawer, a dialog, a
/// bottom sheet, a ⋮ menu) before it changes the page (03-AppFlow §3.1).
///
/// - Android / app back: dialogs, sheets and menus are routes, so the
///   navigator already pops them first; the drawer is handled by `AppShell`.
/// - Web: the browser's back button changes the URL, which would change the
///   page under an open drawer or dialog. This observer runs before the
///   router: while something is open it closes it, keeps the page, and puts
///   the current URL back into the address bar.
class BackGuard with WidgetsBindingObserver {
  BackGuard._();

  static final instance = BackGuard._();

  /// Web behaviour on/off (tests switch it on).
  @visibleForTesting
  static bool webOverride = false;

  static bool get _web => kIsWeb || webOverride;

  /// Open things, oldest first, each with how to close it.
  final _open = <Object, VoidCallback>{};

  /// The page shown now (set by the router).
  Uri Function()? currentUri;

  int _users = 0;

  /// Something opened (drawer, dialog …); [close] closes it.
  void opened(Object key, VoidCallback close) => _open[key] = close;

  /// It closed (by itself, a button, a tap outside, or [closeTop]).
  void closed(Object key) => _open.remove(key);

  bool get hasOpen => _open.isNotEmpty;

  /// Closes the newest open thing. Returns false when nothing was open.
  bool closeTop() {
    if (_open.isEmpty) return false;
    final key = _open.keys.last;
    final close = _open.remove(key)!;
    close();
    return true;
  }

  /// Registers with the binding (call before the router starts listening,
  /// so this observer is asked first). Counted, so tests that build the
  /// app many times stay balanced with [detach].
  void attach() {
    if (_users++ == 0) WidgetsBinding.instance.addObserver(this);
  }

  void detach() {
    if (--_users == 0) {
      WidgetsBinding.instance.removeObserver(this);
      _open.clear();
    }
  }

  @override
  Future<bool> didPushRouteInformation(
    RouteInformation routeInformation,
  ) async {
    if (!_web) return false;
    // The browser moves in its history: pages closed now are not "closed by
    // the app" (WebHistorySync).
    unawaited(WebHistorySync.instance.browserMoved());
    if (!closeTop()) return false;
    // The browser already shows the previous URL: show the current one
    // again, as a new entry, so the next back goes where it should.
    final uri = currentUri?.call();
    if (uri != null) {
      await SystemNavigator.routeInformationUpdated(uri: uri, replace: false);
    }
    return true; // handled: the router does not change the page
  }
}

/// Reports dialogs, bottom sheets and popup menus of one navigator to
/// [BackGuard] (one instance per navigator).
class BackGuardObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is! PopupRoute) return;
    BackGuard.instance.opened(route, () {
      final nav = route.navigator;
      if (nav == null) return;
      route.isCurrent ? nav.pop() : nav.removeRoute(route);
    });
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    BackGuard.instance.closed(route);
    // A page (not a dialog) closed: keep the browser history in step.
    if (route.settings is Page) {
      unawaited(WebHistorySync.instance.pagePopped());
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      BackGuard.instance.closed(route);
}
