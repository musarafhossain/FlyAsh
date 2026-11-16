import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/app_update.dart';
import 'page_reload_stub.dart'
    if (dart.library.js_interop) 'page_reload_web.dart';

/// The platform this build updates as; null where there is no updater
/// (iOS, macOS, Linux).
UpdatePlatform? currentUpdatePlatform() {
  if (kIsWeb) return UpdatePlatform.web;
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => UpdatePlatform.android,
    TargetPlatform.windows => UpdatePlatform.windows,
    _ => null,
  };
}

/// Download and install steps (02-TRD §8.2). Tests replace the functions.
abstract final class UpdateInstaller {
  /// Downloads [url] into the app's temporary folder; returns the file path.
  /// [onProgress] gets 0..1 (or -1 when the size is unknown).
  static Future<String> Function(
    String url,
    void Function(double progress) onProgress,
    CancelToken cancel,
  )
  download = _download;

  /// Android: opens the system installer for the APK (the first time the
  /// system asks to allow installs from FlyAsh). Windows: starts the
  /// installer and closes the app so it can replace the files.
  static Future<void> Function(String path, UpdatePlatform platform) install =
      _install;

  /// Web: reloads the page.
  static void Function() reload = reloadPage;
}

/// Finished downloads of this session (url → file). After the first-time
/// "allow installs" step Android returns to the app without installing;
/// the next "Update now" then opens the installer at once.
final _downloaded = <String, String>{};

Future<String> _download(
  String url,
  void Function(double progress) onProgress,
  CancelToken cancel,
) async {
  final done = _downloaded[url];
  if (done != null && File(done).existsSync()) {
    onProgress(1);
    return done;
  }
  final dir = await getTemporaryDirectory();
  final name = Uri.parse(
    url,
  ).pathSegments.lastWhere((s) => s.isNotEmpty, orElse: () => 'flyash-update');
  final path = '${dir.path}${Platform.pathSeparator}$name';
  await Dio().download(
    url,
    path,
    cancelToken: cancel,
    onReceiveProgress: (got, total) => onProgress(total > 0 ? got / total : -1),
  );
  return _downloaded[url] = path;
}

Future<void> _install(String path, UpdatePlatform platform) async {
  switch (platform) {
    case UpdatePlatform.android:
      final result = await OpenFilex.open(
        path,
        type: 'application/vnd.android.package-archive',
      );
      if (result.type != ResultType.done) {
        throw StateError('installer: ${result.type} ${result.message}');
      }
    case UpdatePlatform.windows:
      await Process.start(path, const [], mode: ProcessStartMode.detached);
      exit(0);
    case UpdatePlatform.web:
      reloadPage();
  }
}
