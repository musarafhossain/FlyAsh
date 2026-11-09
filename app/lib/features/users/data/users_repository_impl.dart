import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../auth/domain/app_user.dart';
import '../domain/users_repository.dart';

class UsersRepositoryImpl implements UsersRepository {
  UsersRepositoryImpl(this._api);

  final ApiClient _api;

  static AppUser _user(Object? d) => AppUser.fromJson(d as Json);

  @override
  Future<Paginated<AppUser>> list({int page = 1, String? search}) =>
      _api.getPage(
        '/users',
        page: page,
        query: {'search': search?.trim()},
        item: AppUser.fromJson,
      );

  @override
  Future<AppUser> get(String id) async =>
      (await _api.get('/users/$id', parse: _user)).data;

  @override
  Future<AppUser> create({
    required String name,
    required String phone,
    String? email,
    required String password,
  }) async {
    final res = await _api.post(
      '/users',
      body: {
        'name': name.trim(),
        'phone': phone.trim(),
        'email': email,
        'password': password,
      },
      parse: _user,
    );
    return res.data;
  }

  @override
  Future<AppUser> update(
    String id, {
    required String name,
    required String phone,
    String? email,
  }) async {
    final res = await _api.put(
      '/users/$id',
      body: {'name': name.trim(), 'phone': phone.trim(), 'email': email},
      parse: _user,
    );
    return res.data;
  }

  @override
  Future<(AppUser, String)> setActive(String id, bool active) async {
    final res = await _api.patch(
      '/users/$id/status',
      body: {'is_active': active},
      parse: _user,
    );
    return (res.data, res.message);
  }

  @override
  Future<String> resetPassword(
    String id, {
    required String password,
    required String confirmation,
  }) async {
    final res = await _api.put(
      '/users/$id/password',
      body: {'password': password, 'password_confirmation': confirmation},
      parse: (d) => d,
    );
    return res.message;
  }
}

final usersRepositoryProvider = Provider<UsersRepository>(
  (ref) => UsersRepositoryImpl(ref.watch(apiClientProvider)),
);
