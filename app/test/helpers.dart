import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flyash/core/config/preferences.dart';
import 'package:flyash/core/network/api_client.dart';
import 'package:flyash/core/network/session.dart';

import 'fake_api.dart';

/// A fake API answering by "METHOD /path" (e.g. 'GET /auth/me').
/// Unknown requests answer 404.
typedef FakeRoutes = Map<String, Reply Function(RequestOptions request)>;

/// Sample logged-in user returned by the fake API.
const sampleUser = {
  'id': 1,
  'name': 'Test Owner',
  'phone': '9876543210',
  'email': 'owner@test.com',
  'locale': 'en',
  'theme_mode': 'system',
  'accent_color': 'blue',
};

/// Routes for a logged-in session (GET /auth/me → [sampleUser]).
FakeRoutes signedInRoutes([FakeRoutes extra = const {}]) => {
  'GET /auth/me': (_) =>
      (200, envelope(200, 'Profile fetched successfully', sampleUser), {}),
  'POST /auth/logout': (_) =>
      (200, envelope(200, 'Logged out successfully', null), {}),
  ...extra,
};

/// The container behind the last [testApp] (to inspect providers in tests).
late ProviderContainer testContainer;

/// The app with in-memory storage and a fake API (no real network).
/// [token] starts logged in (pair it with [signedInRoutes]).
Future<Widget> testApp(
  Widget child, {
  Map<String, Object> prefs = const {},
  List<Override> overrides = const [],
  String? token,
  FakeRoutes api = const {},
  List<RequestOptions>? requests,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  FlutterSecureStorage.setMockInitialValues({'auth.token': ?token});
  final instance = await SharedPreferences.getInstance();
  final tokens = TokenStore(const FlutterSecureStorage());
  await tokens.load();

  testContainer = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(instance),
      tokenStoreProvider.overrideWithValue(tokens),
      ...overrides,
    ],
  );
  addTearDown(testContainer.dispose);
  testContainer.read(dioProvider).httpClientAdapter = FakeAdapter((o) {
    requests?.add(o);
    final route = api['${o.method} ${o.path}'];
    return route != null
        ? route(o)
        : (404, envelope(404, 'Route not found', null), {});
  });
  return UncontrolledProviderScope(container: testContainer, child: child);
}

/// Sets the test window to a logical size (e.g. 360×800 phone, 1440×900 desktop).
void setScreenSize(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

/// WCAG contrast ratio between two colors.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}
