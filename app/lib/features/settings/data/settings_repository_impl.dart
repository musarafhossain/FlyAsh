import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../domain/factory_settings.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._api);

  final ApiClient _api;

  static FactorySettings _parse(Object? d) =>
      FactorySettings.fromJson(d as Json);

  @override
  Future<FactorySettings> getFactory() async =>
      (await _api.get('/settings/factory', parse: _parse)).data;

  @override
  Future<(FactorySettings, String)> saveFactory(FactorySettings s) async {
    final res = await _api.put(
      '/settings/factory',
      body: s.toJson(),
      parse: _parse,
    );
    return (res.data, res.message);
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepositoryImpl(ref.watch(apiClientProvider)),
);

/// The factory profile (loaded once; invalidated after saving).
final factorySettingsProvider = FutureProvider<FactorySettings>(
  (ref) => ref.watch(settingsRepositoryProvider).getFactory(),
);
