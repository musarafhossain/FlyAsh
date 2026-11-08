import 'package:flutter/foundation.dart';

import '../../../core/network/api_response.dart';

/// Factory profile (07-API §15): shown in the app header and on receipts.
@immutable
class FactorySettings {
  const FactorySettings({
    required this.factoryName,
    this.ownerName,
    this.phone,
    this.email,
    this.address,
    this.invoicePrefix = 'INV-',
  });

  final String factoryName;
  final String? ownerName;
  final String? phone;
  final String? email;
  final String? address;
  final String invoicePrefix;

  factory FactorySettings.fromJson(Json json) => FactorySettings(
    factoryName: json['factory_name'] as String? ?? '',
    ownerName: json['owner_name'] as String?,
    phone: json['phone'] as String?,
    email: json['email'] as String?,
    address: json['address'] as String?,
    invoicePrefix: json['invoice_prefix'] as String? ?? 'INV-',
  );

  Json toJson() => {
    'factory_name': factoryName,
    'owner_name': ownerName,
    'phone': phone,
    'email': email,
    'address': address,
    'invoice_prefix': invoicePrefix,
  };
}

/// GET / PUT /settings/factory. Methods throw a `Failure` on error.
abstract interface class SettingsRepository {
  Future<FactorySettings> getFactory();

  /// Returns the saved profile and the server message.
  Future<(FactorySettings, String)> saveFactory(FactorySettings settings);
}
