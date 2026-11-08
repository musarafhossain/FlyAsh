import 'package:flutter/foundation.dart';

import '../../../core/network/api_response.dart';

/// The logged-in user (07-API: User object).
@immutable
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.locale = 'en',
    this.themeMode = 'system',
    this.accentColor = 'blue',
    this.raw = const {},
  });

  final int id;
  final String name;
  final String phone;
  final String? email;
  final String locale;
  final String themeMode;
  final String accentColor;

  /// The full JSON, e.g. for applying preferences.
  final Json raw;

  factory AppUser.fromJson(Json json) => AppUser(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    email: json['email'] as String?,
    locale: json['locale'] as String? ?? 'en',
    themeMode: json['theme_mode'] as String? ?? 'system',
    accentColor: json['accent_color'] as String? ?? 'blue',
    raw: json,
  );
}
