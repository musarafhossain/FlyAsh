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

  @override
  String get save => 'সেভ করুন';

  @override
  String get edit => 'এডিট';

  @override
  String get clear => 'মুছুন';

  @override
  String get status => 'অবস্থা';

  @override
  String get active => 'সক্রিয়';

  @override
  String get inactive => 'নিষ্ক্রিয়';

  @override
  String get never => 'কখনো না';

  @override
  String get noResults => 'কিছু পাওয়া যায়নি';

  @override
  String showingCount(String shown, String total) {
    return '$totalটির মধ্যে $shownটি দেখানো হচ্ছে';
  }

  @override
  String get nameField => 'নাম';

  @override
  String get phoneField => 'ফোন';

  @override
  String get emailOptional => 'ইমেইল (ঐচ্ছিক)';

  @override
  String get addressField => 'ঠিকানা';

  @override
  String get invalidPhone => '6–9 দিয়ে শুরু হওয়া 10 সংখ্যার মোবাইল নম্বর দিন';

  @override
  String get passwordTooLong => 'সর্বোচ্চ 64 অক্ষর';

  @override
  String get searchNamePhone => 'নাম বা ফোন দিয়ে খুঁজুন';

  @override
  String get addUser => 'ইউজার যোগ করুন';

  @override
  String get editUser => 'ইউজার এডিট';

  @override
  String get userDetails => 'ইউজারের বিবরণ';

  @override
  String get usersEmptyTitle => 'এখন পর্যন্ত শুধু আপনি';

  @override
  String get usersEmptyMessage =>
      'যাঁরা আপনার সাথে FlyAsh ব্যবহার করবেন তাঁদের যোগ করুন। সবার একই অ্যাক্সেস থাকবে।';

  @override
  String lastLogin(String time) {
    return 'শেষ লগইন: $time';
  }

  @override
  String get lastLoginColumn => 'শেষ লগইন';

  @override
  String get userCreated => 'ইউজার যোগ হয়েছে';

  @override
  String get userUpdated => 'ইউজার আপডেট হয়েছে';

  @override
  String get emailForgotHint => 'পাসওয়ার্ড ভুলে গেলে রিসেট করতে লাগবে';

  @override
  String get noEmailHintUser =>
      'ইমেইল না থাকলে এই ইউজার “পাসওয়ার্ড ভুলে গেছেন” ব্যবহার করতে পারবেন না। আপনি এখান থেকে তাঁর পাসওয়ার্ড রিসেট করতে পারেন।';

  @override
  String resetPasswordFor(String name) {
    return '$name-এর পাসওয়ার্ড রিসেট';
  }

  @override
  String get resetUserPasswordHint =>
      'নতুন পাসওয়ার্ড দিন। তাঁর সব ডিভাইস থেকে লগআউট হয়ে যাবে।';

  @override
  String get activate => 'সক্রিয় করুন';

  @override
  String get deactivate => 'নিষ্ক্রিয় করুন';

  @override
  String activateUserTitle(String name) {
    return '$name-কে সক্রিয় করবেন?';
  }

  @override
  String deactivateUserTitle(String name) {
    return '$name-কে নিষ্ক্রিয় করবেন?';
  }

  @override
  String get activateUserMessage => 'তিনি আবার লগইন করতে পারবেন।';

  @override
  String get deactivateUserMessage =>
      'তাঁর সব ডিভাইস থেকে লগআউট হয়ে যাবে এবং আবার সক্রিয় না করা পর্যন্ত লগইন করতে পারবেন না।';

  @override
  String get myProfile => 'আমার প্রোফাইল';

  @override
  String get viewProfile => 'প্রোফাইল দেখুন';

  @override
  String get editProfile => 'প্রোফাইল এডিট';

  @override
  String get profileUpdated => 'প্রোফাইল আপডেট হয়েছে';

  @override
  String get emailForgotHintSelf =>
      'ইমেইল দিলে পাসওয়ার্ড ভুলে গেলে নিজেই রিসেট করতে পারবেন';

  @override
  String get noEmailHintSelf =>
      '“পাসওয়ার্ড ভুলে গেছেন” ব্যবহার করতে একটি ইমেইল যোগ করুন।';

  @override
  String get changePassword => 'পাসওয়ার্ড পরিবর্তন';

  @override
  String get changePasswordHint =>
      'অন্য সব ডিভাইস থেকে লগআউট হবে। এই ডিভাইসে লগইন থাকবে।';

  @override
  String get currentPassword => 'বর্তমান পাসওয়ার্ড';

  @override
  String get settingsAccount => 'অ্যাকাউন্ট';

  @override
  String get settingsFactory => 'কারখানা';

  @override
  String get settingsApp => 'অ্যাপ';

  @override
  String get factoryProfile => 'কারখানার প্রোফাইল';

  @override
  String get factoryName => 'কারখানার নাম';

  @override
  String get ownerName => 'মালিকের নাম';

  @override
  String get invoicePrefix => 'ইনভয়েস প্রিফিক্স';

  @override
  String get invoicePrefixHint =>
      'নতুন বিক্রির নম্বরে ব্যবহার হবে, যেমন INV-0001';

  @override
  String get invoicePrefixRule => '1–10 অক্ষর: A–Z, 0–9 এবং -';

  @override
  String get appearance => 'চেহারা';

  @override
  String get themeMode => 'থিম মোড';

  @override
  String get themeSystem => 'সিস্টেম';

  @override
  String get themeLight => 'লাইট';

  @override
  String get themeDark => 'ডার্ক';

  @override
  String get accentColor => 'থিমের রং';

  @override
  String get accentBlue => 'নীল';

  @override
  String get accentBrick => 'ইট-লাল';

  @override
  String get accentEmerald => 'সবুজ';

  @override
  String get accentViolet => 'বেগুনি';

  @override
  String get accentSlate => 'ধূসর';

  @override
  String get fontSize => 'লেখার আকার';

  @override
  String get fontSmall => 'ছোট';

  @override
  String get fontDefault => 'সাধারণ';

  @override
  String get fontLarge => 'বড়';

  @override
  String get fontExtraLarge => 'অনেক বড়';

  @override
  String get preview => 'প্রিভিউ';

  @override
  String get previewHeroLabel => 'আজকের বিক্রি';

  @override
  String get previewHeroCaption => 'আজ 6টি বিক্রি';

  @override
  String get previewPaid => 'পরিশোধিত';

  @override
  String get previewPartial => 'আংশিক';

  @override
  String get previewDue => 'বাকি';

  @override
  String get previewButton => 'নতুন বিক্রি';

  @override
  String get resetToDefault => 'আগের মতো করুন';

  @override
  String get languageHint =>
      'অ্যাপের লেখা ও সার্ভারের বার্তা বদলাবে। আপনার অ্যাকাউন্টে সেভ থাকবে।';

  @override
  String get aboutApp => 'অ্যাপ সম্পর্কে';

  @override
  String get version => 'ভার্সন';

  @override
  String get buildNumber => 'বিল্ড';

  @override
  String get server => 'সার্ভার';

  @override
  String get navGroupDaily => 'প্রতিদিনের কাজ';

  @override
  String get navGroupBusiness => 'ব্যবসা';

  @override
  String get navGroupAdmin => 'অ্যাডমিন';
}
