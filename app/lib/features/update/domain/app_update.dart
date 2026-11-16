import 'package:flutter/foundation.dart';

import '../../../core/network/api_response.dart';

/// Which release channel this build checks (07-API `GET /app/version`).
enum UpdatePlatform { android, windows, web }

/// The answer of `GET /app/version?platform=…&build=…`.
@immutable
class AppUpdate {
  const AppUpdate({
    required this.updateAvailable,
    required this.forceUpdate,
    this.latestVersion,
    this.latestBuild,
    this.downloadUrl,
    this.releaseNotes,
  });

  final bool updateAvailable;

  /// The installed build is below `min_supported_build`: the app is blocked
  /// until it is updated.
  final bool forceUpdate;
  final String? latestVersion;
  final int? latestBuild;

  /// APK / EXE on our server (`/downloads/…`); null for web.
  final String? downloadUrl;
  final String? releaseNotes;

  static const none = AppUpdate(updateAvailable: false, forceUpdate: false);

  factory AppUpdate.fromJson(Json json) => AppUpdate(
    updateAvailable: json['update_available'] as bool? ?? false,
    forceUpdate: json['force_update'] as bool? ?? false,
    latestVersion: json['latest_version'] as String?,
    latestBuild: (json['latest_build'] as num?)?.toInt(),
    downloadUrl: json['download_url'] as String?,
    releaseNotes: json['release_notes'] as String?,
  );
}

abstract interface class UpdateRepository {
  /// Throws a `Failure` on error.
  Future<AppUpdate> check(UpdatePlatform platform, int build);
}
