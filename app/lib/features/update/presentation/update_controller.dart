import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/presentation/pages/about_page.dart';
import '../data/update_installer.dart';
import '../data/update_repository_impl.dart';
import '../domain/app_update.dart';

/// Off in widget tests that are not about updates (helpers turn it off).
final updateCheckEnabledProvider = Provider<bool>((_) => true);

/// The channel this build updates on (null: no updater on this platform).
final updatePlatformProvider = Provider<UpdatePlatform?>(
  (_) => currentUpdatePlatform(),
);

/// The installed build number (`+N` of `version:` in pubspec.yaml).
final installedBuildProvider = FutureProvider<int>((ref) async {
  final info = await ref.watch(packageInfoProvider.future);
  return int.tryParse(info.buildNumber) ?? 0;
});

/// The newer release found by the last check (null: none, or not checked).
class UpdateController extends Notifier<AppUpdate?> {
  @override
  AppUpdate? build() => null;

  /// Asks the server. Throws a `Failure` when it cannot be reached.
  Future<AppUpdate> check() async {
    final platform = ref.read(updatePlatformProvider);
    if (platform == null) return AppUpdate.none;
    final build = await ref.read(installedBuildProvider.future);
    final update = await ref
        .read(updateRepositoryProvider)
        .check(platform, build);
    state = update.updateAvailable ? update : null;
    return update;
  }
}

final updateControllerProvider = NotifierProvider<UpdateController, AppUpdate?>(
  UpdateController.new,
);

/// One download + install run, shown by the dialog and the forced screen.
class UpdateRun extends ChangeNotifier {
  UpdateRun(this.update, this.platform);

  final AppUpdate update;
  final UpdatePlatform platform;

  bool busy = false;

  /// 0..1, or -1 while the size is unknown.
  double progress = 0;
  bool failed = false;
  CancelToken? _cancel;
  bool _disposed = false;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  Future<void> start() async {
    if (platform == UpdatePlatform.web) {
      UpdateInstaller.reload();
      return;
    }
    final url = update.downloadUrl;
    busy = true;
    failed = false;
    progress = 0;
    notifyListeners();
    try {
      if (url == null || url.isEmpty) throw StateError('no download url');
      final cancel = _cancel = CancelToken();
      final path = await UpdateInstaller.download(url, (p) {
        progress = p;
        notifyListeners();
      }, cancel);
      await UpdateInstaller.install(path, platform);
      busy = false;
    } on DioException catch (e) {
      busy = false;
      failed = !CancelToken.isCancel(e);
    } catch (_) {
      busy = false;
      failed = true;
    }
    _cancel = null;
    notifyListeners();
  }

  void cancel() => _cancel?.cancel();

  @override
  void dispose() {
    _disposed = true;
    cancel();
    super.dispose();
  }
}
