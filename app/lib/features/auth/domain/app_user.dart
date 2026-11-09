import 'package:flutter/foundation.dart';

import '../../../core/network/api_response.dart';

/// A user account (07-API: User object): the logged-in user and the
/// other users in the Users section.
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
    this.isActive = true,
    this.lastLoginAt,
    this.raw = const {},
  });

  final String id;
  final String name;
  final String phone;
  final String? email;
  final String locale;
  final String themeMode;
  final String accentColor;
  final bool isActive;

  /// ISO time in UTC (`2026-11-08T14:55:46.000Z`), null if never logged in.
  final String? lastLoginAt;

  /// The full JSON, e.g. for applying preferences.
  final Json raw;

  factory AppUser.fromJson(Json json) => AppUser(
    id: idOf(json['id']),
    name: json['name'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    email: json['email'] as String?,
    locale: json['locale'] as String? ?? 'en',
    themeMode: json['theme_mode'] as String? ?? 'system',
    accentColor: json['accent_color'] as String? ?? 'blue',
    isActive: json['is_active'] as bool? ?? true,
    lastLoginAt: json['last_login_at'] as String?,
    raw: json,
  );
}
