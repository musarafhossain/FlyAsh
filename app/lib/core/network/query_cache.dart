import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_response.dart';

/// The kinds of data the API serves. A GET is cached under its tags; a
/// write marks every tag it can change as stale (see [DataTag.affectedBy]).
abstract final class DataTag {
  static const products = 'products';
  static const customers = 'customers';
  static const sales = 'sales';
  static const labours = 'labours';
  static const attendance = 'attendance';
  static const wages = 'wages';
  static const expenses = 'expenses';
  static const users = 'users';
  static const settings = 'settings';
  static const dashboard = 'dashboard';
  static const reports = 'reports';

  /// Path segment → tag (`/labours/1/wage-payments` touches labours + wages).
  static const _segments = {
    'products': products,
    'customers': customers,
    'sales': sales,
    'labours': labours,
    'attendance': attendance,
    'wages': wages,
    'wage-payments': wages,
    'expenses': expenses,
    'expense-categories': expenses,
    'users': users,
    'settings': settings,
    'dashboard': dashboard,
    'reports': reports,
  };

  /// What else a change to a tag can change (totals, counts, reports …).
  static const _dependants = {
    products: {products},
    customers: {customers, sales, dashboard, reports},
    sales: {sales, customers, dashboard, reports},
    labours: {labours, attendance, wages, dashboard, reports},
    attendance: {attendance, labours, wages, dashboard, reports},
    wages: {wages, labours, dashboard, reports},
    expenses: {expenses, dashboard, reports},
    users: {users},
    settings: {settings},
    dashboard: {dashboard},
    reports: {reports},
  };

  /// Tags of the data a GET returns, e.g. `/customers/7/sales` →
  /// {customers, sales}. Empty = not cached (auth, health, app version).
  static Set<String> of(String path) => {
    for (final s in path.split('/')) ?_segments[s],
  };

  /// Tags a successful write to [path] makes stale.
  static Set<String> affectedBy(String path) => {
    for (final tag in of(path)) ...?_dependants[tag],
  };
}

/// In-memory cache of GET answers (the raw `{ success, data … }` envelope),
/// for this app session only. Screens opened again within [maxAge] show at
/// once without a request; a write removes the entries it made stale, so
/// the next read goes to the server.
class QueryCache {
  QueryCache({
    this.maxAge = const Duration(seconds: 60),
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  final Duration maxAge;
  final DateTime Function() _now;
  final _entries = <String, _Entry>{};

  /// A fresh answer for [key], or null.
  Json? read(String key) {
    final e = _entries[key];
    if (e == null) return null;
    if (_now().difference(e.at) > maxAge) {
      _entries.remove(key);
      return null;
    }
    return e.json;
  }

  void write(String key, Set<String> tags, Json json) {
    if (tags.isEmpty) return;
    _entries[key] = _Entry(json, tags, _now());
  }

  /// Drops every entry that has one of [tags].
  void invalidate(Set<String> tags) =>
      _entries.removeWhere((_, e) => e.tags.any(tags.contains));

  void clear() => _entries.clear();

  int get length => _entries.length;

  /// Runs [action] with the cache skipped for reads (pull to refresh,
  /// Retry): every GET inside goes to the server and refreshes the cache.
  static Future<T> fresh<T>(Future<T> Function() action) =>
      runZoned(action, zoneValues: {_freshKey: true});

  static bool get isFresh => Zone.current[_freshKey] == true;

  static const _freshKey = #queryCacheFresh;
}

class _Entry {
  _Entry(this.json, this.tags, this.at);

  final Json json;
  final Set<String> tags;
  final DateTime at;
}

final queryCacheProvider = Provider<QueryCache>((ref) => QueryCache());
