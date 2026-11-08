// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTagline => 'Brick factory management';

  @override
  String get navHome => 'Home';

  @override
  String get navSales => 'Sales';

  @override
  String get navAttendance => 'Attendance';

  @override
  String get navExpenses => 'Expenses';

  @override
  String get navCustomers => 'Customers';

  @override
  String get navProducts => 'Products';

  @override
  String get navLabours => 'Labours';

  @override
  String get navWages => 'Wages';

  @override
  String get navReports => 'Reports';

  @override
  String get navUsers => 'Users';

  @override
  String get navSettings => 'Settings';

  @override
  String get menu => 'Menu';

  @override
  String get collapseMenu => 'Collapse menu';

  @override
  String get expandMenu => 'Expand menu';

  @override
  String get openApp => 'Open app';

  @override
  String apiUrl(String url) {
    return 'API: $url';
  }

  @override
  String get serverTitle => 'Server';

  @override
  String serverConnected(String date) {
    return 'Connected · factory date $date';
  }

  @override
  String get serverChecking => 'Checking…';

  @override
  String get serverOnline => 'Online';

  @override
  String get serverUnreachable => 'Cannot reach the server';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String placeholderStep(String step) {
    return 'This screen is built in step $step.';
  }

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageBengali => 'বাংলা';

  @override
  String get networkError => 'No internet connection';

  @override
  String get networkTimeout =>
      'The server is taking too long. Please try again';
}
