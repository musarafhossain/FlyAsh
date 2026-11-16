import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/query_cache.dart';
import '../domain/app_update.dart';

class UpdateRepositoryImpl implements UpdateRepository {
  UpdateRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<AppUpdate> check(UpdatePlatform platform, int build) =>
      // Never from the 60 s cache: a release must show at once.
      QueryCache.fresh(() async {
        final res = await _api.get(
          '/app/version',
          query: {'platform': platform.name, 'build': build},
          parse: (d) => AppUpdate.fromJson(d as Json),
        );
        return res.data;
      });
}

final updateRepositoryProvider = Provider<UpdateRepository>(
  (ref) => UpdateRepositoryImpl(ref.watch(apiClientProvider)),
);
