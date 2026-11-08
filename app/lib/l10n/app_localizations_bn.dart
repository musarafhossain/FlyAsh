// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appTagline => 'ইট কারখানার ব্যবস্থাপনা';

  @override
  String get navHome => 'হোম';

  @override
  String get navSales => 'বিক্রি';

  @override
  String get navAttendance => 'হাজিরা';

  @override
  String get navExpenses => 'খরচ';

  @override
  String get navCustomers => 'কাস্টমার';

  @override
  String get navProducts => 'প্রোডাক্ট';

  @override
  String get navLabours => 'শ্রমিক';

  @override
  String get navWages => 'মজুরি';

  @override
  String get navReports => 'রিপোর্ট';

  @override
  String get navUsers => 'ইউজার';

  @override
  String get navSettings => 'সেটিংস';

  @override
  String get menu => 'মেনু';

  @override
  String get collapseMenu => 'মেনু ছোট করুন';

  @override
  String get expandMenu => 'মেনু বড় করুন';

  @override
  String get openApp => 'অ্যাপ খুলুন';

  @override
  String apiUrl(String url) {
    return 'API: $url';
  }

  @override
  String get serverTitle => 'সার্ভার';

  @override
  String serverConnected(String date) {
    return 'সংযুক্ত · কারখানার তারিখ $date';
  }

  @override
  String get serverChecking => 'যাচাই করা হচ্ছে…';

  @override
  String get serverOnline => 'অনলাইন';

  @override
  String get serverUnreachable => 'সার্ভারে পৌঁছানো যাচ্ছে না';

  @override
  String get retry => 'আবার চেষ্টা করুন';

  @override
  String get cancel => 'বাতিল';

  @override
  String placeholderStep(String step) {
    return 'এই স্ক্রিনটি $step ধাপে তৈরি হবে।';
  }

  @override
  String get language => 'ভাষা';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageBengali => 'বাংলা';

  @override
  String get networkError => 'ইন্টারনেট সংযোগ নেই';

  @override
  String get networkTimeout => 'সার্ভার উত্তর দিতে দেরি করছে। আবার চেষ্টা করুন';
}
