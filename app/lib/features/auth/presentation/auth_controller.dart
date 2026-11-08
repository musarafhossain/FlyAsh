import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/preferences_sync.dart';
import '../../../core/error/failure.dart';
import '../../../core/network/session.dart';
import '../data/auth_repository_impl.dart';
import '../domain/app_user.dart';

enum AuthStatus { checking, signedOut, signedIn }

@immutable
class AuthState {
  const AuthState(this.status, {this.user, this.sessionExpired = false});

  final AuthStatus status;

  /// Null while offline at startup (token kept, profile not loaded yet).
  final AppUser? user;

  /// True when the server ended the session (401) — Login shows a notice.
  final bool sessionExpired;

  static const checking = AuthState(AuthStatus.checking);
  static const signedOut = AuthState(AuthStatus.signedOut);
}

/// Who is logged in, and the login / logout / startup flow (03-AppFlow §1–2).
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Any 401 from the API (token revoked, user deactivated) ends the session.
    ref.listen(sessionExpiredProvider, (_, _) {
      if (state.status == AuthStatus.signedIn) {
        state = const AuthState(AuthStatus.signedOut, sessionExpired: true);
      }
    });
    // Check the saved session right after startup.
    Future.microtask(bootstrap);
    return AuthState.checking;
  }

  /// Startup: no token → Login. Token → load the profile.
  Future<void> bootstrap() async {
    final tokens = ref.read(tokenStoreProvider);
    if (!tokens.hasToken) {
      state = AuthState.signedOut;
      return;
    }
    try {
      final user = await ref.read(authRepositoryProvider).me();
      await ref.read(preferencesSyncProvider).applyFromAccount(user.raw);
      state = AuthState(AuthStatus.signedIn, user: user);
    } on UnauthorizedFailure {
      await tokens.clear();
      state = AuthState.signedOut;
    } on Failure {
      // Offline or server down: keep the session; screens retry their own data.
      state = const AuthState(AuthStatus.signedIn);
    }
  }

  /// Throws a [Failure] for the Login screen to show.
  Future<void> login(String login, String password) async {
    final result = await ref
        .read(authRepositoryProvider)
        .login(login: login, password: password, deviceName: deviceName());
    await ref.read(tokenStoreProvider).save(result.token);
    await ref.read(preferencesSyncProvider).applyFromAccount(result.user.raw);
    state = AuthState(AuthStatus.signedIn, user: result.user);
  }

  /// Logs out on the server (best effort) and always locally.
  Future<void> logout() async {
    try {
      await ref.read(authRepositoryProvider).logout();
    } on Failure catch (e) {
      debugPrint('Logout request failed, clearing locally: $e');
    }
    await ref.read(tokenStoreProvider).clear();
    state = AuthState.signedOut;
  }

  /// After the user's own profile changes (F7).
  void updateUser(AppUser user) =>
      state = AuthState(AuthStatus.signedIn, user: user);
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
