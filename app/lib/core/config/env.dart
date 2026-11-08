/// Build-time configuration.
///
/// Pass values with `--dart-define`, e.g.
///   flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3333/api/v1
///
/// Android emulator: http://10.0.2.2:3333/api/v1
/// Real phone:       http://PC-LAN-IP:3333/api/v1
abstract final class Env {
  static const String appName = 'FlyAsh';

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3333/api/v1',
  );
}
