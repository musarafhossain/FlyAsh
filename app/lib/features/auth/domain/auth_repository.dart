import 'app_user.dart';

/// Authentication API (07-API §Auth, §Forgot password).
/// Methods throw a `Failure` (core/error/failure.dart) on error.
abstract interface class AuthRepository {
  /// POST /auth/login → token + user
  Future<({String token, AppUser user})> login({
    required String login,
    required String password,
    String? deviceName,
  });

  /// GET /auth/me
  Future<AppUser> me();

  /// POST /auth/logout (revokes the current token on the server)
  Future<void> logout();

  /// POST /auth/forgot-password → message (always the same)
  Future<String> forgotPassword(String email);

  /// POST /auth/verify-otp → signed reset token (10 min, single use)
  Future<String> verifyOtp({required String email, required String otp});

  /// POST /auth/reset-password → message
  Future<String> resetPassword({
    required String resetToken,
    required String password,
    required String confirmation,
  });
}
