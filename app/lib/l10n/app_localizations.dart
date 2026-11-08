import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
  ];

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Brick factory management'**
  String get appTagline;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get navSales;

  /// No description provided for @navAttendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get navAttendance;

  /// No description provided for @navExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get navExpenses;

  /// No description provided for @navCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get navCustomers;

  /// No description provided for @navProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get navProducts;

  /// No description provided for @navLabours.
  ///
  /// In en, this message translates to:
  /// **'Labours'**
  String get navLabours;

  /// No description provided for @navWages.
  ///
  /// In en, this message translates to:
  /// **'Wages'**
  String get navWages;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @navUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get navUsers;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @collapseMenu.
  ///
  /// In en, this message translates to:
  /// **'Collapse menu'**
  String get collapseMenu;

  /// No description provided for @expandMenu.
  ///
  /// In en, this message translates to:
  /// **'Expand menu'**
  String get expandMenu;

  /// No description provided for @serverUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the server'**
  String get serverUnreachable;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @placeholderStep.
  ///
  /// In en, this message translates to:
  /// **'This screen is built in step {step}.'**
  String placeholderStep(String step);

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageBengali.
  ///
  /// In en, this message translates to:
  /// **'বাংলা'**
  String get languageBengali;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get networkError;

  /// No description provided for @networkTimeout.
  ///
  /// In en, this message translates to:
  /// **'The server is taking too long. Please try again'**
  String get networkTimeout;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @loginField.
  ///
  /// In en, this message translates to:
  /// **'Phone or email'**
  String get loginField;

  /// No description provided for @passwordField.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordField;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @sessionEnded.
  ///
  /// In en, this message translates to:
  /// **'Your session ended. Please sign in again'**
  String get sessionEnded;

  /// No description provided for @forgotTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get forgotTitle;

  /// No description provided for @forgotHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the email linked to your account. We will send a 6-digit OTP.'**
  String get forgotHint;

  /// No description provided for @emailField.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailField;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get invalidEmail;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @noEmailHint.
  ///
  /// In en, this message translates to:
  /// **'No email? Ask another user to reset your password.'**
  String get noEmailHint;

  /// No description provided for @verifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyTitle;

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'Enter the OTP sent to {email}'**
  String otpSentTo(String email);

  /// No description provided for @otpLabel.
  ///
  /// In en, this message translates to:
  /// **'6-digit OTP'**
  String get otpLabel;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @changeEmail.
  ///
  /// In en, this message translates to:
  /// **'Wrong email? Change it'**
  String get changeEmail;

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP in {seconds}s'**
  String resendIn(String seconds);

  /// No description provided for @resendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtp;

  /// No description provided for @resetTitle.
  ///
  /// In en, this message translates to:
  /// **'Set new password'**
  String get resetTitle;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @passwordRule.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get passwordRule;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDontMatch;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPassword;

  /// No description provided for @cancelResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel password reset?'**
  String get cancelResetTitle;

  /// No description provided for @cancelResetMessage.
  ///
  /// In en, this message translates to:
  /// **'You will need a new OTP to start again.'**
  String get cancelResetMessage;

  /// No description provided for @keepGoing.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get keepGoing;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @startAgain.
  ///
  /// In en, this message translates to:
  /// **'Start again'**
  String get startAgain;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'You will need to sign in again on this device.'**
  String get logoutConfirmMessage;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
