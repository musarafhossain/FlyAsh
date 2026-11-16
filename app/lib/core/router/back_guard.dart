import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'web_history/browser_stub.dart'
    if (dart.library.js_interop) 'web_history/browser_web.dart';
import 'web_history_sync.dart';

/// The back button closes what is open on top (the drawer, a dialog, a
/// bottom sheet, a ⋮ menu) before it changes the page (03-AppFlow §3.1).
///
/// - Android / app back: dialogs, sheets and menus are routes, so the
///   navigator already pops them first; the drawer is handled by `AppShell`.
/// - Web: the browser's back button changes the URL, which would change the
///   page under an open drawer or dialog. This observer runs before the
///   router: while something is open it closes it, keeps the page, and steps
///   the browser forward to the entry it was on.
class BackGuard with WidgetsBindingObserver {
  BackGuard._();

  static final instance = BackGuard._();

  /// Web behaviour on/off (tests switch it on).
  @visibleForTesting
  static bool webOverride = false;

  static bool get _web => kIsWeb || webOverride;

  /// Open things, oldest first, each with how to close it.
  final _open = <Object, VoidCallback>{};

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

  @visibleForTesting
  void resetForTest() {
    _restoring = false;
    _open.clear();
  }

  void detach() {
    if (--_users == 0) {
      WidgetsBinding.instance.removeObserver(this);
      _open.clear();
    }
  }

  /// We stepped the browser forward again ourselves: the next history
  /// event is that step, not the user.
  bool _restoring = false;

  /// Steps the browser forward one entry (tests replace it).
  @visibleForTesting
  void Function() stepForward = () => browserHistoryGo(1);

  @override
  Future<bool> didPushRouteInformation(
    RouteInformation routeInformation,
  ) async {
    if (!_web) return false;
    if (_restoring) {
      // Our own step forward: the page is already the right one.
      _restoring = false;
      return true;
    }
    // The browser moves in its history: pages closed now are not "closed by
    // the app" (WebHistorySync).
    unawaited(WebHistorySync.instance.browserMoved());
    if (!closeTop()) return false;
    // The browser already went back one entry. Step forward to the entry we
    // were on (it is still there) instead of adding a new one: no extra
    // entries, and Chrome on Android does not skip it later.
    _restoring = true;
    stepForward();
    // Safety net in case the step's event never arrives.
    Future<void>.delayed(const Duration(seconds: 1), () => _restoring = false);
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
