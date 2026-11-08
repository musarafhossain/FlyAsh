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

  @override
  String get signIn => 'সাইন ইন';

  @override
  String get welcomeBack => 'আবার স্বাগতম';

  @override
  String get loginField => 'ফোন বা ইমেইল';

  @override
  String get passwordField => 'পাসওয়ার্ড';

  @override
  String get showPassword => 'পাসওয়ার্ড দেখান';

  @override
  String get hidePassword => 'পাসওয়ার্ড লুকান';

  @override
  String get forgotPassword => 'পাসওয়ার্ড ভুলে গেছেন?';

  @override
  String get fieldRequired => 'এই ঘরটি পূরণ করুন';

  @override
  String get sessionEnded => 'আপনার সেশন শেষ হয়েছে। আবার সাইন ইন করুন';

  @override
  String get forgotTitle => 'পাসওয়ার্ড ভুলে গেছেন';

  @override
  String get forgotHint =>
      'আপনার অ্যাকাউন্টের ইমেইল দিন। আমরা 6 সংখ্যার একটি OTP পাঠাব।';

  @override
  String get emailField => 'ইমেইল';

  @override
  String get invalidEmail => 'সঠিক ইমেইল দিন';

  @override
  String get sendOtp => 'OTP পাঠান';

  @override
  String get noEmailHint =>
      'ইমেইল নেই? অন্য একজন ইউজারকে আপনার পাসওয়ার্ড রিসেট করে দিতে বলুন।';

  @override
  String get verifyTitle => 'OTP যাচাই';

  @override
  String get otpSentHint =>
      'এই ইমেইলে 6 সংখ্যার একটি OTP পাঠানো হয়েছে। নিচে লিখুন।';

  @override
  String get otpLabel => '6 সংখ্যার OTP';

  @override
  String get verify => 'যাচাই করুন';

  @override
  String get changeEmail => 'বদলান';

  @override
  String resendIn(String seconds) {
    return '$seconds সেকেন্ড পরে আবার OTP পাঠানো যাবে';
  }

  @override
  String get resendOtp => 'আবার OTP পাঠান';

  @override
  String get resetTitle => 'নতুন পাসওয়ার্ড দিন';

  @override
  String get newPassword => 'নতুন পাসওয়ার্ড';

  @override
  String get confirmPassword => 'পাসওয়ার্ড আবার লিখুন';

  @override
  String get passwordRule => 'কমপক্ষে 6 অক্ষর';

  @override
  String get passwordsDontMatch => 'পাসওয়ার্ড মেলেনি';

  @override
  String get resetPassword => 'পাসওয়ার্ড রিসেট করুন';

  @override
  String get cancelResetTitle => 'পাসওয়ার্ড রিসেট বাতিল করবেন?';

  @override
  String get cancelResetMessage => 'আবার শুরু করতে নতুন OTP লাগবে।';

  @override
  String get keepGoing => 'চালিয়ে যান';

  @override
  String get leave => 'বের হন';

  @override
  String get startAgain => 'আবার শুরু করুন';

  @override
  String get logout => 'লগআউট';

  @override
  String get logoutConfirmTitle => 'লগআউট করবেন?';

  @override
  String get logoutConfirmMessage => 'এই ডিভাইসে আবার সাইন ইন করতে হবে।';

  @override
  String get loading => 'লোড হচ্ছে…';
}
