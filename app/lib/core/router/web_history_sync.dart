import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'web_history/browser_stub.dart'
    if (dart.library.js_interop) 'web_history/browser_web.dart';

/// Keeps the browser history in step with the app's page stack (web only).
///
/// When the app closes a page itself (Save on a form, the ← arrow), Flutter's
/// router does not step back in the browser history: it adds a new entry for
/// the page underneath. The history then reads list → edit → list, and the
/// browser's back button opens the edit form again.
///
/// After such a close this class checks the entry two steps back: when it
/// shows the same page as now, the browser goes back two entries, so the
/// history reads list again and back goes where the user expects. The
/// entries are only compared, never guessed, so a page opened from a link
/// (nothing to go back to) is left alone.
class WebHistorySync {
  WebHistorySync({
    int? Function()? serial,
    void Function(int delta)? go,
    this.webOverride = false,
  }) : _serial = serial ?? browserHistorySerial,
       _go = go ?? browserHistoryGo;

  static final instance = WebHistorySync();

  final int? Function() _serial;
  final void Function(int) _go;

  /// Run as on the web (tests).
  bool webOverride;

  bool get _web => kIsWeb || webOverride;

  /// The page shown now (set by the router).
  String Function()? currentLocation;

  /// History serial → the page that entry shows.
  final _pages = <int, String>{};

  /// The browser itself is moving (back / forward): pages it closes are not
  /// "closed by the app".
  bool _browserMoving = false;

  /// Waits until the router has told the browser about the new page.
  @visibleForTesting
  Future<void> Function() settle = _afterReport;

  static Future<void> _afterReport() async {
    final frame = SchedulerBinding.instance.endOfFrame;
    SchedulerBinding.instance.scheduleFrame();
    await frame;
    await Future<void>.delayed(const Duration(milliseconds: 40));
  }

  void _record() {
    final n = _serial();
    final page = currentLocation?.call();
    if (n != null && page != null) _pages[n] = page;
  }

  /// The app moved to a page (push / go): remember what that entry shows.
  Future<void> navigated() async {
    if (!_web) return;
    await settle();
    _record();
  }

  /// The browser's back / forward button moved (from `BackGuard`).
  Future<void> browserMoved() async {
    if (!_web) return;
    _browserMoving = true;
    await settle();
    _browserMoving = false;
    _record();
  }

  /// A page was closed (popped). When the app did it, fold the extra entry
  /// away (see the class comment).
  /// A check is already waiting (one close can be reported by two
  /// navigators; checking twice would step back twice).
  bool _checking = false;

  Future<void> pagePopped() async {
    if (!_web || _browserMoving || _checking) return;
    _checking = true;
    try {
      await settle();
      if (!_browserMoving) _foldExtraEntry();
    } finally {
      _checking = false;
    }
  }

  void _foldExtraEntry() {
    final n = _serial();
    final page = currentLocation?.call();
    if (n == null || page == null) return;
    _pages[n] = page;
    if (n >= 2 && _pages[n - 2] == page) {
      _pages
        ..remove(n)
        ..remove(n - 1);
      // The browser now moves back two entries (to the same page).
      _browserMoving = true;
      _go(-2);
      // Normally cleared by browserMoved(); this is only a safety net.
      Future<void>.delayed(const Duration(seconds: 2), () {
        _browserMoving = false;
      });
    }
  }
}
