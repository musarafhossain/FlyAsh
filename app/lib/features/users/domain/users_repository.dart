import '../../../core/network/api_response.dart';
import '../../auth/domain/app_user.dart';

/// Other users of the app (07-API §6). The logged-in user is never listed;
/// they change their own details in My profile. All users are equal.
/// Methods throw a `Failure` on error.
abstract interface class UsersRepository {
  /// GET /users?page&limit&search
  Future<Paginated<AppUser>> list({int page = 1, String? search});

  /// GET /users/:id
  Future<AppUser> get(String id);

  /// POST /users
  Future<AppUser> create({
    required String name,
    required String phone,
    String? email,
    required String password,
  });

  /// PUT /users/:id
  Future<AppUser> update(
    String id, {
    required String name,
    required String phone,
    String? email,
  });

  /// PATCH /users/:id/status → (user, message). Deactivating logs them out.
  Future<(AppUser, String)> setActive(String id, bool active);

  /// PUT /users/:id/password → message. Logs that user out everywhere.
  Future<String> resetPassword(
    String id, {
    required String password,
    required String confirmation,
  });
}
