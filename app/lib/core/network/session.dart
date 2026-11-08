import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/preferences.dart';

/// Stores the access token in secure storage (Keystore / Credential Manager)
/// and keeps a copy in memory so every request can read it synchronously.
class TokenStore {
  TokenStore(this._storage);

  static const _key = 'auth.token';
  final FlutterSecureStorage _storage;
  String? _token;

  String? get token => _token;
  bool get hasToken => _token != null && _token!.isNotEmpty;

  /// Called once at startup (before runApp).
  Future<void> load() async => _token = await _storage.read(key: _key);

  Future<void> save(String token) async {
    _token = token;
    await _storage.write(key: _key, value: token);
  }

  Future<void> clear() async {
    _token = null;
    await _storage.delete(key: _key);
  }
}

final tokenStoreProvider = Provider<TokenStore>(
  (ref) => TokenStore(const FlutterSecureStorage()),
);

/// Increments whenever the API answers 401 (token revoked, user deactivated).
/// The router (F6) listens and sends the user to Login.
class SessionExpiredSignal extends Notifier<int> {
  @override
  int build() => 0;

  void fire() => state++;
}

final sessionExpiredProvider = NotifierProvider<SessionExpiredSignal, int>(
  SessionExpiredSignal.new,
);

/// The factory's "today" (`X-Business-Date`, TRD §4.3). The app uses this
/// instead of the device clock for default dates. Cached so it is known
/// before the first request; falls back to the device date.
class BusinessDate extends Notifier<String> {
  static const _key = 'business.date';

  @override
  String build() =>
      ref.read(sharedPreferencesProvider).getString(_key) ?? _deviceToday();

  void update(String? ymd) {
    final valid = ymd != null && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(ymd);
    if (!valid || ymd == state) return;
    state = ymd;
    ref.read(sharedPreferencesProvider).setString(_key, ymd);
  }

  static String _deviceToday() {
    final d = DateTime.now();
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

final businessDateProvider = NotifierProvider<BusinessDate, String>(
  BusinessDate.new,
);
