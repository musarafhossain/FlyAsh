import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flyash/app.dart';
import 'package:flyash/core/l10n/locale_controller.dart';
import 'package:flyash/core/router/app_router.dart';
import 'package:flyash/features/update/data/update_installer.dart';
import 'package:flyash/features/update/domain/app_update.dart';
import 'package:flyash/features/update/presentation/update_controller.dart';

import '../fake_api.dart';
import '../helpers.dart';

Reply _ok(Object? data) => (200, envelope(200, 'ok', data), {});

const _optional = {
  'latest_version': '1.1.0',
  'latest_build': 2,
  'update_available': true,
  'force_update': false,
  'download_url': 'https://flyash.test/downloads/flyash-1.1.0.apk',
  'release_notes': 'Reports and receipts',
};
const _none = {
  'latest_version': '1.0.0',
  'latest_build': 1,
  'update_available': false,
  'force_update': false,
  'download_url': null,
  'release_notes': null,
};

late List<RequestOptions> requests;

/// What the installer was asked to do.
final calls = <String>[];
Completer<String>? downloadGate;
void Function(double)? reportProgress;

Future<void> start(
  WidgetTester tester, {
  Object? version = _none,
  UpdatePlatform platform = UpdatePlatform.android,
  bool check = true,
  Size size = const Size(400, 900),
}) async {
  requests = [];
  setScreenSize(tester, size);
  await tester.pumpWidget(
    await testApp(
      const FlyAshApp(),
      prefs: {'business.date': '2026-11-16'},
      token: 'oat_saved',
      requests: requests,
      updateCheck: check,
      overrides: [
        updatePlatformProvider.overrideWithValue(platform),
        installedBuildProvider.overrideWith((ref) async => 1),
      ],
      api: signedInRoutes({
        if (version != null) 'GET /app/version': (_) => _ok(version),
      }),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    calls.clear();
    downloadGate = null;
    UpdateInstaller.download = (url, onProgress, cancel) {
      calls.add('download $url');
      reportProgress = onProgress;
      final gate = downloadGate = Completer<String>();
      cancel.whenCancel.then((e) {
        if (!gate.isCompleted) gate.completeError(e);
      });
      return gate.future;
    };
    UpdateInstaller.install = (path, platform) async =>
        calls.add('install $path ${platform.name}');
    UpdateInstaller.reload = () => calls.add('reload');
  });

  testWidgets('no update: nothing shown; asks with platform and build', (
    tester,
  ) async {
    await start(tester);
    final ask = requests.singleWhere((r) => r.path == '/app/version');
    expect(ask.queryParameters, {'platform': 'android', 'build': 1});
    expect(find.byKey(const Key('updateDialog')), findsNothing);
  });

  testWidgets('optional: dialog with version, notes, hint; Later closes', (
    tester,
  ) async {
    await start(tester, version: _optional);
    expect(find.byKey(const Key('updateDialog')), findsOneWidget);
    expect(find.text('Version 1.1.0'), findsOneWidget);
    expect(find.text('Reports and receipts'), findsOneWidget);
    expect(find.textContaining('Android asks to allow installs'), findsOne);
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('updateDialog')), findsNothing);
    expect(calls, isEmpty);
  });

  testWidgets('Update now: progress, then the installer opens', (tester) async {
    await start(tester, version: _optional);
    await tester.tap(find.text('Update now'));
    await tester.pump();
    expect(calls, ['download https://flyash.test/downloads/flyash-1.1.0.apk']);
    reportProgress!(0.42);
    await tester.pump();
    expect(find.text('Downloading… 42%'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget, reason: 'optional: can stop');
    downloadGate!.complete('/tmp/flyash-1.1.0.apk');
    await tester.pumpAndSettle();
    expect(calls.last, 'install /tmp/flyash-1.1.0.apk android');
  });

  testWidgets('download fails → error and Retry; Cancel stops quietly', (
    tester,
  ) async {
    await start(tester, version: _optional);
    await tester.tap(find.text('Update now'));
    await tester.pump();
    downloadGate!.completeError(
      DioException(requestOptions: RequestOptions(), message: 'offline'),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('updateError')), findsOneWidget);
    // (The home page behind has its own Retry: no dashboard in this fake.)
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('updateDialog')),
        matching: find.text('Retry'),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('updateProgress')), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('updateError')), findsNothing);
    expect(find.text('Update now'), findsOneWidget);
  });

  testWidgets('forced: the app is replaced; back does not leave; Update', (
    tester,
  ) async {
    await start(tester, version: {..._optional, 'force_update': true});
    expect(find.byKey(const Key('updateRequired')), findsOneWidget);
    expect(find.text('Update required'), findsOneWidget);
    // Back does nothing: the page stays.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('updateRequired')), findsOneWidget);
    await tester.tap(find.byKey(const Key('updateRequiredButton')));
    await tester.pump();
    expect(find.text('Cancel'), findsNothing, reason: 'forced: no way out');
    downloadGate!.complete('/tmp/a.apk');
    await tester.pumpAndSettle();
    expect(calls.last, 'install /tmp/a.apk android');
  });

  testWidgets('web: "Reload" reloads the page (nothing to download)', (
    tester,
  ) async {
    await start(
      tester,
      platform: UpdatePlatform.web,
      version: {..._optional, 'download_url': null},
    );
    expect(find.textContaining('Android'), findsNothing);
    await tester.tap(find.text('Reload'));
    await tester.pumpAndSettle();
    expect(calls, ['reload']);
  });

  testWidgets('a failed check is ignored', (tester) async {
    await start(tester, version: null); // 404
    expect(find.byKey(const Key('updateDialog')), findsNothing);
    expect(find.byKey(const Key('updateRequired')), findsNothing);
  });

  testWidgets('About: Check for updates → up to date, or the dialog', (
    tester,
  ) async {
    await start(tester, check: false);
    testContainer.read(routerProvider).go('/settings/about');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('checkForUpdates')));
    await tester.pumpAndSettle();
    expect(find.text('You have the latest version'), findsOneWidget);
  });

  testWidgets('About: an update found opens the dialog', (tester) async {
    await start(tester, check: false, version: _optional);
    testContainer.read(routerProvider).go('/settings/about');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('checkForUpdates')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('updateDialog')), findsOneWidget);
  });

  for (final width in [320.0, 1280.0]) {
    testWidgets('no overflow at ${width.toInt()} px (Bengali)', (tester) async {
      await start(
        tester,
        size: Size(width, 640),
        version: {..._optional, 'force_update': true},
      );
      await testContainer.read(localeProvider.notifier).setLocale('bn');
      await tester.pumpAndSettle();
      expect(find.text('আপডেট করা দরকার'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
