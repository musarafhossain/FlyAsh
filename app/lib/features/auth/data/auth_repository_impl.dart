import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<({String token, AppUser user})> login({
    required String login,
    required String password,
    String? deviceName,
  }) async {
    final res = await _api.post(
      '/auth/login',
      body: {
        'login': login.trim(),
        'password': password,
        'device_name': ?deviceName,
      },
      parse: (d) => d as Json,
    );
    return (
      token: res.data['token'] as String,
      user: AppUser.fromJson(res.data['user'] as Json),
    );
  }

  @override
  Future<AppUser> me() async {
    final res = await _api.get(
      '/auth/me',
      parse: (d) => AppUser.fromJson(d as Json),
    );
    return res.data;
  }

  @override
  Future<void> logout() async => _api.post('/auth/logout', parse: (d) => d);

  @override
  Future<String> forgotPassword(String email) async {
    final res = await _api.post(
      '/auth/forgot-password',
      body: {'email': email.trim()},
      parse: (d) => d,
    );
    return res.message;
  }

  @override
  Future<String> verifyOtp({required String email, required String otp}) async {
    final res = await _api.post(
      '/auth/verify-otp',
      body: {'email': email.trim(), 'otp': otp},
      parse: (d) => (d as Json)['reset_token'] as String,
    );
    return res.data;
  }

  @override
  Future<String> resetPassword({
    required String resetToken,
    required String password,
    required String confirmation,
  }) async {
    final res = await _api.post(
      '/auth/reset-password',
      body: {
        'reset_token': resetToken,
        'password': password,
        'password_confirmation': confirmation,
      },
      parse: (d) => d,
    );
    return res.message;
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(apiClientProvider)),
);

/// Device name sent with login (shown as the token name on the server).
String deviceName() => kIsWeb ? 'Web' : defaultTargetPlatform.name;
