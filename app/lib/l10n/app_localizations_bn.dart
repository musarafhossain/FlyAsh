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

  @override
  String get account => 'অ্যাকাউন্ট';

  @override
  String get moreAppearanceSettings => 'চেহারার আরও সেটিংস';

  @override
  String get filterAll => 'সব';

  @override
  String get delete => 'ডিলিট';

  @override
  String get notesOptional => 'নোট (ঐচ্ছিক)';

  @override
  String get invalidAmount => 'টাকার পরিমাণ লিখুন, যেমন 4.50';

  @override
  String get addProduct => 'প্রোডাক্ট যোগ করুন';

  @override
  String get editProduct => 'প্রোডাক্ট এডিট';

  @override
  String get searchProducts => 'প্রোডাক্ট খুঁজুন';

  @override
  String get productsEmptyTitle => 'এখনো কোনো প্রোডাক্ট নেই';

  @override
  String get productsEmptyMessage =>
      'যে ইট বিক্রি করেন সেগুলো খরচ আর দামসহ যোগ করুন। বিক্রিতে এই দাম ব্যবহার হবে।';

  @override
  String get productName => 'প্রোডাক্টের নাম';

  @override
  String get productNameHint => 'যেমন Fly Ash Brick 9×4×3';

  @override
  String get unitField => 'একক';

  @override
  String get unitPiece => 'পিস';

  @override
  String get unitThousand => '1000 পিস';

  @override
  String get unitTruck => 'ট্রাক';

  @override
  String get unitOther => 'অন্য';

  @override
  String get unitLabel => 'এককের নাম';

  @override
  String get unitLabelHint => 'যেমন cft';

  @override
  String perUnit(String unit) {
    return 'প্রতি $unit';
  }

  @override
  String get defaultCost => 'খরচ';

  @override
  String get defaultPrice => 'দাম';

  @override
  String get margin => 'লাভ';

  @override
  String get marginPerUnit => 'প্রতি এককে লাভ';

  @override
  String get lossPerUnit => 'প্রতি এককে ক্ষতি';

  @override
  String get productCreated => 'প্রোডাক্ট যোগ হয়েছে';

  @override
  String get productUpdated => 'প্রোডাক্ট আপডেট হয়েছে';

  @override
  String get inactiveProductHint =>
      'বিক্রির ফর্মে দেখাবে না। আগের বিক্রিতে থেকে যাবে।';

  @override
  String activateProductTitle(String name) {
    return '$name সক্রিয় করবেন?';
  }

  @override
  String deactivateProductTitle(String name) {
    return '$name নিষ্ক্রিয় করবেন?';
  }

  @override
  String get activateProductMessage => 'এটা আবার বিক্রির ফর্মে দেখাবে।';

  @override
  String get deactivateProductMessage =>
      'এটা বিক্রির ফর্মে আর দেখাবে না। আগের বিক্রি বদলাবে না।';

  @override
  String deleteProductTitle(String name) {
    return '$name ডিলিট করবেন?';
  }

  @override
  String get deleteProductMessage =>
      'কোনো বিক্রিতে ব্যবহার না হয়ে থাকলেই ডিলিট করা যাবে।';

  @override
  String get moreActions => 'আরও অপশন';

  @override
  String get couldNotOpen => 'এই ডিভাইসে খোলা গেল না';

  @override
  String get addressOptional => 'ঠিকানা (ঐচ্ছিক)';

  @override
  String get call => 'কল করুন';

  @override
  String get whatsApp => 'WhatsApp';

  @override
  String get date => 'তারিখ';

  @override
  String get type => 'ধরন';

  @override
  String get total => 'মোট';

  @override
  String get paid => 'পরিশোধ';

  @override
  String get due => 'বাকি';

  @override
  String get noDue => 'বাকি নেই';

  @override
  String get sales => 'বিক্রি';

  @override
  String get invoiceNo => 'ইনভয়েস';

  @override
  String get paymentPaid => 'পরিশোধিত';

  @override
  String get paymentPartial => 'আংশিক';

  @override
  String get paymentDue => 'বাকি';

  @override
  String get saleBooked => 'বুকড';

  @override
  String get saleDelivered => 'ডেলিভারি হয়েছে';

  @override
  String get saleCancelled => 'বাতিল';

  @override
  String get saleTypeInstant => 'তাৎক্ষণিক';

  @override
  String get saleTypeBooking => 'বুকিং';

  @override
  String get addCustomer => 'কাস্টমার যোগ করুন';

  @override
  String get editCustomer => 'কাস্টমার এডিট';

  @override
  String get customerDetails => 'কাস্টমার';

  @override
  String get filterHasDue => 'বাকি আছে';

  @override
  String get customersEmptyTitle => 'এখনো কোনো কাস্টমার নেই';

  @override
  String get customersEmptyMessage =>
      'যাঁরা আপনার কাছ থেকে কেনেন তাঁদের যোগ করুন। তাঁদের বাকি এখানে দেখাবে।';

  @override
  String get customerNameHint => 'যেমন Rahim Traders';

  @override
  String get customerPhoneHint =>
      'একটা ফোন নম্বর শুধু একজন কাস্টমারের হতে পারে।';

  @override
  String get openExistingCustomer => 'সেই কাস্টমার খুলুন';

  @override
  String get customerCreated => 'কাস্টমার যোগ হয়েছে';

  @override
  String get customerUpdated => 'কাস্টমার আপডেট হয়েছে';

  @override
  String get purchases => 'মোট কেনা';

  @override
  String get noSalesYet => 'এখনো কোনো বিক্রি নেই';

  @override
  String get noSalesYetMessage => 'এই কাস্টমারের কাছে বিক্রি এখানে দেখাবে।';

  @override
  String activateCustomerTitle(String name) {
    return '$name-কে সক্রিয় করবেন?';
  }

  @override
  String deactivateCustomerTitle(String name) {
    return '$name-কে নিষ্ক্রিয় করবেন?';
  }

  @override
  String get activateCustomerMessage => 'নতুন বিক্রিতে আবার বেছে নেওয়া যাবে।';

  @override
  String get deactivateCustomerMessage =>
      'নতুন বিক্রিতে আর দেখাবে না। আগের বিক্রি আর বাকি থেকে যাবে।';

  @override
  String deleteCustomerTitle(String name) {
    return '$name-কে ডিলিট করবেন?';
  }

  @override
  String get deleteCustomerMessage => 'কোনো বিক্রি না থাকলেই ডিলিট করা যাবে।';

  @override
  String get reset => 'রিসেট';

  @override
  String get apply => 'প্রয়োগ করুন';

  @override
  String get saleDetails => 'বিক্রি';

  @override
  String get searchSales => 'ইনভয়েস নং, কাস্টমার বা ফোন';

  @override
  String get filterSales => 'বিক্রি ফিল্টার';

  @override
  String get salesEmptyMessage => 'আপনার বিক্রি এখানে দেখাবে।';

  @override
  String get anyDate => 'যেকোনো তারিখ';

  @override
  String get presetToday => 'আজ';

  @override
  String get presetYesterday => 'গতকাল';

  @override
  String get presetThisWeek => 'এই সপ্তাহ';

  @override
  String get presetThisMonth => 'এই মাস';

  @override
  String get presetLastMonth => 'গত মাস';

  @override
  String get presetCustom => 'নিজে বাছুন…';

  @override
  String get upcomingDeliveries => 'সামনের ডেলিভারি';

  @override
  String get noUpcomingDeliveries => 'কোনো ডেলিভারি বাকি নেই';

  @override
  String get noUpcomingDeliveriesMessage =>
      'ডেলিভারির অপেক্ষায় থাকা বুকিং এখানে দেখাবে।';

  @override
  String get overdue => 'দেরি হয়েছে';

  @override
  String deliverOn(String date) {
    return 'ডেলিভারি $date';
  }

  @override
  String get saleDate => 'বিক্রির তারিখ';

  @override
  String get deliveryDate => 'ডেলিভারির তারিখ';

  @override
  String get deliveredOn => 'ডেলিভারি হয়েছে';

  @override
  String createdBy(String name) {
    return '$name এন্ট্রি করেছেন';
  }

  @override
  String byUser(String name) {
    return '$name';
  }

  @override
  String itemsCount(String count) {
    return 'আইটেম ($count)';
  }

  @override
  String paymentsCount(String count) {
    return 'পেমেন্ট ($count)';
  }

  @override
  String get noPaymentsYet => 'এখনো কোনো টাকা পাওয়া যায়নি';

  @override
  String get amountSummary => 'হিসাব';

  @override
  String get subtotal => 'উপমোট';

  @override
  String get transport => 'গাড়িভাড়া';

  @override
  String get discount => 'ছাড়';

  @override
  String get productionCost => 'উৎপাদন খরচ';

  @override
  String get profit => 'লাভ';

  @override
  String get methodCash => 'নগদ';

  @override
  String get methodUpi => 'UPI';

  @override
  String get methodBank => 'ব্যাংক';

  @override
  String get methodCheque => 'চেক';

  @override
  String get methodOther => 'অন্য';

  @override
  String get ok => 'ঠিক আছে';

  @override
  String get discard => 'বাদ দিন';

  @override
  String get keepEditing => 'এডিট চালিয়ে যান';

  @override
  String get amount => 'টাকার পরিমাণ';

  @override
  String get amountOptional => 'টাকার পরিমাণ (ঐচ্ছিক)';

  @override
  String dueAmount(String amount) {
    return 'বাকি $amount';
  }

  @override
  String get invalidQuantity => '0-এর বেশি পরিমাণ লিখুন';

  @override
  String get newSale => 'নতুন বিক্রি';

  @override
  String get newBooking => 'নতুন বুকিং';

  @override
  String get editSale => 'বিক্রি এডিট';

  @override
  String get saveSale => 'বিক্রি সেভ করুন';

  @override
  String get instantHint => 'আজই মাল কারখানা থেকে যাবে।';

  @override
  String get bookingHint =>
      'এখন অর্ডার, পরে নির্দিষ্ট তারিখে ডেলিভারি। অগ্রিম নেওয়া যায়।';

  @override
  String get selectCustomer => 'কাস্টমার বাছুন';

  @override
  String get selectCustomerError => 'একজন কাস্টমার বাছুন বা নতুন যোগ করুন';

  @override
  String get newCustomer => 'নতুন কাস্টমার';

  @override
  String get pickExistingCustomer => 'তার বদলে পুরোনো কাস্টমার বাছুন';

  @override
  String get useThisCustomer => 'এই কাস্টমারকেই নিন';

  @override
  String get deliveryAddressOptional => 'ডেলিভারির ঠিকানা (ঐচ্ছিক)';

  @override
  String get selectProduct => 'প্রোডাক্ট বাছুন';

  @override
  String get selectProductError => 'একটা প্রোডাক্ট বাছুন';

  @override
  String get addItem => 'আইটেম যোগ করুন';

  @override
  String get removeItem => 'আইটেম সরান';

  @override
  String get quantity => 'পরিমাণ';

  @override
  String get unitPriceLabel => 'দাম / একক';

  @override
  String get unitCostLabel => 'খরচ / একক';

  @override
  String get lineTotal => 'মোট';

  @override
  String get discountTooHigh => 'উপমোট + গাড়িভাড়ার বেশি হতে পারে না';

  @override
  String get alreadyPaid => 'আগে পরিশোধ';

  @override
  String get paymentReceived => 'এখন পাওয়া টাকা';

  @override
  String get advanceReceived => 'অগ্রিম পাওয়া টাকা';

  @override
  String get paymentNoteOptional => 'পেমেন্টের নোট (ঐচ্ছিক)';

  @override
  String cannotExceedTotal(String amount) {
    return 'মোট $amount-এর বেশি হতে পারে না';
  }

  @override
  String get saleNotesHint => 'যেমন দুপুরের আগে ডেলিভারি';

  @override
  String get discardSaleTitle => 'এই বিক্রি বাদ দেবেন?';

  @override
  String get discardChangesTitle => 'পরিবর্তনগুলো বাদ দেবেন?';

  @override
  String get discardSaleMessage => 'যা লিখেছেন তা মুছে যাবে।';

  @override
  String get addPayment => 'পেমেন্ট যোগ করুন';

  @override
  String get paymentDate => 'পেমেন্টের তারিখ';

  @override
  String cannotExceedDue(String amount) {
    return 'বাকি $amount-এর বেশি হতে পারে না';
  }

  @override
  String get paymentActions => 'পেমেন্টের অপশন';

  @override
  String get deletePayment => 'পেমেন্ট মুছুন';

  @override
  String deletePaymentTitle(String amount) {
    return '$amount-এর পেমেন্ট মুছবেন?';
  }

  @override
  String get deletePaymentMessage => 'বাকি টাকা আবার বেড়ে যাবে।';

  @override
  String get markDelivered => 'ডেলিভারি হয়েছে';

  @override
  String markDeliveredTitle(String invoice) {
    return '$invoice ডেলিভারি';
  }

  @override
  String get cancelBooking => 'বুকিং বাতিল';

  @override
  String get keepBooking => 'বুকিং রাখুন';

  @override
  String cancelBookingTitle(String invoice) {
    return '$invoice বাতিল করবেন?';
  }

  @override
  String get cancelBookingMessage =>
      'বুকিংটা তালিকায় \"বাতিল\" হিসেবে থাকবে, হিসাবে ধরা হবে না।';

  @override
  String get removePaymentsFirst =>
      'এই বুকিংয়ে পেমেন্ট আছে। আগে সেগুলো মুছুন (টাকা ফেরত দিন), তারপর বাতিল করুন।';

  @override
  String get deleteSale => 'বিক্রি ডিলিট';

  @override
  String deleteSaleTitle(String invoice) {
    return '$invoice ডিলিট করবেন?';
  }

  @override
  String get deleteSaleMessage => 'সব তালিকা আর রিপোর্ট থেকে সরে যাবে।';

  @override
  String get previous => 'আগের';

  @override
  String get next => 'পরের';

  @override
  String get today => 'আজ';

  @override
  String get phoneOptional => 'ফোন (ঐচ্ছিক)';

  @override
  String get addLabour => 'শ্রমিক যোগ করুন';

  @override
  String get editLabour => 'শ্রমিক এডিট';

  @override
  String get labourDetails => 'শ্রমিক';

  @override
  String get laboursEmptyTitle => 'এখনো কোনো শ্রমিক নেই';

  @override
  String get laboursEmptyMessage =>
      'কারখানায় যাঁরা কাজ করেন তাঁদের দৈনিক বা মাসিক মজুরিসহ যোগ করুন।';

  @override
  String get labourCreated => 'শ্রমিক যোগ হয়েছে';

  @override
  String get labourUpdated => 'শ্রমিক আপডেট হয়েছে';

  @override
  String get wage => 'মজুরি';

  @override
  String get wageDaily => 'দৈনিক';

  @override
  String get wageMonthly => 'মাসিক';

  @override
  String get wagePerDay => 'প্রতিদিনের মজুরি';

  @override
  String get wagePerMonth => 'মাসিক মজুরি';

  @override
  String get dailyWageHint => 'উপস্থিত প্রতিদিনের জন্য; অর্ধদিনে অর্ধেক।';

  @override
  String get monthlyWageHint =>
      'মাসের দিন দিয়ে ভাগ করে উপস্থিত দিন অনুযায়ী হিসাব।';

  @override
  String get wageChangeHint =>
      'নতুন মজুরি এখন থেকে সেভ করা হাজিরায় লাগবে। আগের দিনের মজুরি বদলাবে না।';

  @override
  String perDay(String amount) {
    return '$amount / দিন';
  }

  @override
  String perMonth(String amount) {
    return '$amount / মাস';
  }

  @override
  String get joiningDate => 'যোগদানের তারিখ';

  @override
  String get leavingDate => 'কাজ ছাড়ার তারিখ';

  @override
  String get joined => 'যোগদান';

  @override
  String get attendanceThisMonth => 'হাজিরা';

  @override
  String activateLabourTitle(String name) {
    return '$name-কে সক্রিয় করবেন?';
  }

  @override
  String get activateLabourMessage => 'হাজিরার তালিকায় আবার দেখাবে।';

  @override
  String deactivateLabourTitle(String name) {
    return '$name কাজ ছেড়েছেন?';
  }

  @override
  String get deactivateLabourMessage =>
      'শেষ কাজের দিনটা বাছুন। তার পরে হাজিরার তালিকায় থাকবেন না। মজুরির হিসাব থেকে যাবে।';

  @override
  String get wkMon => 'সোম';

  @override
  String get wkTue => 'মঙ্গল';

  @override
  String get wkWed => 'বুধ';

  @override
  String get wkThu => 'বৃহঃ';

  @override
  String get wkFri => 'শুক্র';

  @override
  String get wkSat => 'শনি';

  @override
  String get wkSun => 'রবি';

  @override
  String get attPresent => 'উপস্থিত';

  @override
  String get attHalfDay => 'অর্ধদিন';

  @override
  String get attAbsent => 'অনুপস্থিত';

  @override
  String get attNotMarked => 'হাজিরা হয়নি';

  @override
  String get attPresentShort => 'উ';

  @override
  String get attHalfDayShort => 'অর্ধ';

  @override
  String get attAbsentShort => 'অনু';

  @override
  String get markAllPresent => 'সবাই উপস্থিত';

  @override
  String get saveAttendance => 'হাজিরা সেভ করুন';

  @override
  String get noChanges => 'কোনো পরিবর্তন নেই';

  @override
  String changesCount(String count) {
    return '$countটি পরিবর্তন';
  }

  @override
  String attendanceSaved(String date) {
    return '$date-এর হাজিরা সেভ হয়েছে';
  }

  @override
  String saveChangesFor(String date) {
    return '$date-এর পরিবর্তন সেভ করবেন?';
  }

  @override
  String unsavedAttendance(String count) {
    return '$count জনের হাজিরা বদলেছে, এখনো সেভ হয়নি।';
  }

  @override
  String todayWithDate(String date) {
    return 'আজ, $date';
  }

  @override
  String yesterdayWithDate(String date) {
    return 'গতকাল, $date';
  }

  @override
  String get noLaboursOnDate => 'এই তারিখে কোনো শ্রমিক নেই';

  @override
  String get noLaboursOnDateMessage =>
      'যাঁরা এই তারিখে কাজে যোগ দিয়েছিলেন এবং ছাড়েননি, শুধু তাঁরাই দেখাবেন।';
}
