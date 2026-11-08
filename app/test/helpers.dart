import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flyash/core/config/preferences.dart';
import 'package:flyash/core/network/session.dart';
import 'package:flyash/features/splash/presentation/widgets/api_status_card.dart';

/// Creates a ProviderScope with in-memory storage and no real network
/// (the start screen's health check answers "ok").
Future<Widget> testApp(
  Widget child, {
  Map<String, Object> prefs = const {},
  List<Override> overrides = const [],
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  FlutterSecureStorage.setMockInitialValues({});
  final instance = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(instance),
      tokenStoreProvider.overrideWithValue(
        TokenStore(const FlutterSecureStorage()),
      ),
      healthProvider.overrideWith((ref) async => {'status': 'ok'}),
      ...overrides,
    ],
    child: child,
  );
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
