import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import '../error/failure.dart';
import '../l10n/locale_controller.dart';
import 'api_response.dart';
import 'data_changed.dart';
import 'query_cache.dart';
import 'session.dart';

/// One Dio instance for the whole app (02-TRD §7.3):
/// - `Authorization: Bearer <token>` when logged in
/// - `Accept-Language: en|bn` so API messages match the app language
/// - reads `X-Business-Date` from every response (factory "today")
/// - on 401: clears the token and fires [sessionExpiredProvider]
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
      // Every status is a valid envelope; errors are mapped in ApiClient.
      validateStatus: (_) => true,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = ref.read(tokenStoreProvider).token;
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        options.headers['Accept-Language'] = ref.read(localeProvider);
        handler.next(options);
      },
      onResponse: (response, handler) async {
        ref
            .read(businessDateProvider.notifier)
            .update(response.headers.value('x-business-date'));
        final hadToken = response.requestOptions.headers.containsKey(
          'Authorization',
        );
        if (response.statusCode == 401 && hadToken) {
          await ref.read(tokenStoreProvider).clear();
          ref.read(sessionExpiredProvider.notifier).fire();
        }
        handler.next(response);
      },
    ),
  );
  return dio;
});

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    ref.watch(dioProvider),
    cache: ref.watch(queryCacheProvider),
    // Cached answers belong to one user and one language.
    cacheScope: () =>
        '${ref.read(tokenStoreProvider).token.hashCode}:${ref.read(localeProvider)}',
    onChanged: (tags) => ref.read(dataChangedProvider.notifier).bump(tags),
  ),
);

/// Thin wrapper over Dio that parses the envelope and throws a [Failure]
/// for anything that is not a success.
///
/// Caching (02-TRD §7.5): GET answers are kept in [cache] by their data tags
/// ([DataTag.of]). A successful write removes the entries it made stale
/// ([DataTag.affectedBy]) and reports those tags through [onChanged], so the
/// screens that show them reload. `QueryCache.fresh` skips the cache.
/// Items per page for every list in the app (the server's default too).
const kPageSize = 20;

class ApiClient {
  ApiClient(this._dio, {this.cache, this.cacheScope, this.onChanged});

  final Dio _dio;
  final QueryCache? cache;

  /// Part of every cache key (user + language).
  final String Function()? cacheScope;

  /// Called after a successful POST / PUT / PATCH / DELETE (not for sign-in
  /// and account calls under `/auth`) with the data tags it changed.
  final void Function(Set<String> tags)? onChanged;

  Future<ApiResponse<T>> get<T>(
    String path, {
    Json? query,
    required T Function(Object? data) parse,
  }) => _send('GET', path, query: query, parse: parse);

  Future<ApiResponse<T>> post<T>(
    String path, {
    Object? body,
    required T Function(Object? data) parse,
  }) => _send('POST', path, body: body, parse: parse);

  Future<ApiResponse<T>> put<T>(
    String path, {
    Object? body,
    required T Function(Object? data) parse,
  }) => _send('PUT', path, body: body, parse: parse);

  Future<ApiResponse<T>> patch<T>(
    String path, {
    Object? body,
    required T Function(Object? data) parse,
  }) => _send('PATCH', path, body: body, parse: parse);

  Future<ApiResponse<T>> delete<T>(
    String path, {
    required T Function(Object? data) parse,
  }) => _send('DELETE', path, parse: parse);

  /// GET a paginated list (`page`, `limit` + filters in [query]).
  Future<Paginated<T>> getPage<T>(
    String path, {
    int page = 1,
    int limit = kPageSize,
    Json? query,
    required T Function(Json item) item,
  }) async {
    final res = await get(
      path,
      query: {'page': page, 'limit': limit, ...?query},
      parse: (data) => Paginated.fromJson(data, item),
    );
    return res.data;
  }

  Future<ApiResponse<T>> _send<T>(
    String method,
    String path, {
    Object? body,
    Json? query,
    required T Function(Object? data) parse,
  }) async {
    final cleanQuery = query == null ? null : _cleanQuery(query);
    final tags = method == 'GET' ? DataTag.of(path) : const <String>{};
    final key = tags.isEmpty ? null : _cacheKey(path, cleanQuery);
    if (key != null && !QueryCache.isFresh) {
      final hit = cache?.read(key);
      if (hit != null) return ApiResponse.fromJson(hit, parse);
    }

    final Response<Object?> res;
    try {
      res = await _dio.request<Object?>(
        path,
        data: body,
        queryParameters: cleanQuery,
        options: Options(method: method),
      );
    } on DioException catch (e) {
      throw _networkFailure(e);
    }

    final json = res.data;
    if (json is! Json) {
      throw ServerFailure(
        'Unexpected response from the server',
        statusCode: res.statusCode ?? 0,
      );
    }

    final status =
        (json['status_code'] as num?)?.toInt() ?? res.statusCode ?? 0;
    final message = json['message'] as String? ?? '';
    if (json['success'] == true) {
      final result = ApiResponse.fromJson(json, parse);
      if (key != null) cache?.write(key, tags, json);
      if (method != 'GET' && !path.startsWith('/auth')) {
        final changed = DataTag.affectedBy(path);
        cache?.invalidate(changed);
        onChanged?.call(changed);
      }
      return result;
    }

    final data = json['data'];
    throw switch (status) {
      401 => UnauthorizedFailure(message),
      422 => ValidationFailure(
        message,
        fieldErrors: _fieldErrors(data),
        data: data is Json ? data : null,
      ),
      _ => ServerFailure(message, statusCode: status, data: data),
    };
  }

  String _cacheKey(String path, Json? query) {
    final q = query == null
        ? ''
        : (query.entries.map((e) => '${e.key}=${e.value}').toList()..sort())
              .join('&');
    return '${cacheScope?.call() ?? ''}|$path?$q';
  }

  /// Drops nulls/empty strings and turns bools into true/false strings.
  static Json _cleanQuery(Json query) => {
    for (final e in query.entries)
      if (e.value != null && e.value != '')
        e.key: e.value is bool ? '${e.value}' : e.value,
  };

  static Map<String, String> _fieldErrors(Object? data) {
    final errors = data is Json ? data['errors'] : null;
    if (errors is! List) return const {};
    final result = <String, String>{};
    for (final e in errors.whereType<Json>()) {
      final field = e['field'] as String?;
      if (field == null) continue;
      result.putIfAbsent(field, () => e['message'] as String? ?? '');
    }
    return result;
  }

  static Failure _networkFailure(DioException e) => switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => const NetworkFailure(
      'The server is taking too long. Please try again',
      true,
    ),
    _ => const NetworkFailure(),
  };
}
