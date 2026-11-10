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

  /// No description provided for @otpSentHint.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit OTP to this email. Enter it below.'**
  String get otpSentHint;

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
  /// **'Change'**
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

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResults;

  /// No description provided for @showingCount.
  ///
  /// In en, this message translates to:
  /// **'Showing {shown} of {total}'**
  String showingCount(String shown, String total);

  /// No description provided for @nameField.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameField;

  /// No description provided for @phoneField.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneField;

  /// No description provided for @emailOptional.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get emailOptional;

  /// No description provided for @addressField.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressField;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a 10-digit mobile number starting with 6–9'**
  String get invalidPhone;

  /// No description provided for @passwordTooLong.
  ///
  /// In en, this message translates to:
  /// **'At most 64 characters'**
  String get passwordTooLong;

  /// No description provided for @searchNamePhone.
  ///
  /// In en, this message translates to:
  /// **'Search by name or phone'**
  String get searchNamePhone;

  /// No description provided for @addUser.
  ///
  /// In en, this message translates to:
  /// **'Add user'**
  String get addUser;

  /// No description provided for @editUser.
  ///
  /// In en, this message translates to:
  /// **'Edit user'**
  String get editUser;

  /// No description provided for @userDetails.
  ///
  /// In en, this message translates to:
  /// **'User details'**
  String get userDetails;

  /// No description provided for @usersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Only you so far'**
  String get usersEmptyTitle;

  /// No description provided for @usersEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add the people who will use FlyAsh with you. Everyone has the same access.'**
  String get usersEmptyMessage;

  /// No description provided for @lastLogin.
  ///
  /// In en, this message translates to:
  /// **'Last login: {time}'**
  String lastLogin(String time);

  /// No description provided for @lastLoginColumn.
  ///
  /// In en, this message translates to:
  /// **'Last login'**
  String get lastLoginColumn;

  /// No description provided for @userCreated.
  ///
  /// In en, this message translates to:
  /// **'User added'**
  String get userCreated;

  /// No description provided for @userUpdated.
  ///
  /// In en, this message translates to:
  /// **'User updated'**
  String get userUpdated;

  /// No description provided for @emailForgotHint.
  ///
  /// In en, this message translates to:
  /// **'Needed for Forgot password'**
  String get emailForgotHint;

  /// No description provided for @noEmailHintUser.
  ///
  /// In en, this message translates to:
  /// **'Without an email this user cannot use Forgot password. You can reset their password here.'**
  String get noEmailHintUser;

  /// No description provided for @resetPasswordFor.
  ///
  /// In en, this message translates to:
  /// **'Reset password for {name}'**
  String resetPasswordFor(String name);

  /// No description provided for @resetUserPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Set a new password. They will be logged out on all devices.'**
  String get resetUserPasswordHint;

  /// No description provided for @activate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get activate;

  /// No description provided for @deactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivate;

  /// No description provided for @activateUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Activate {name}?'**
  String activateUserTitle(String name);

  /// No description provided for @deactivateUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate {name}?'**
  String deactivateUserTitle(String name);

  /// No description provided for @activateUserMessage.
  ///
  /// In en, this message translates to:
  /// **'They will be able to log in again.'**
  String get activateUserMessage;

  /// No description provided for @deactivateUserMessage.
  ///
  /// In en, this message translates to:
  /// **'They will be logged out everywhere and cannot log in until activated again.'**
  String get deactivateUserMessage;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get myProfile;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get viewProfile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @emailForgotHintSelf.
  ///
  /// In en, this message translates to:
  /// **'Add an email so you can reset a forgotten password yourself'**
  String get emailForgotHintSelf;

  /// No description provided for @noEmailHintSelf.
  ///
  /// In en, this message translates to:
  /// **'Add an email to be able to use Forgot password.'**
  String get noEmailHintSelf;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @changePasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Other devices will be logged out. This device stays logged in.'**
  String get changePasswordHint;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsFactory.
  ///
  /// In en, this message translates to:
  /// **'Factory'**
  String get settingsFactory;

  /// No description provided for @settingsApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get settingsApp;

  /// No description provided for @factoryProfile.
  ///
  /// In en, this message translates to:
  /// **'Factory profile'**
  String get factoryProfile;

  /// No description provided for @factoryName.
  ///
  /// In en, this message translates to:
  /// **'Factory name'**
  String get factoryName;

  /// No description provided for @ownerName.
  ///
  /// In en, this message translates to:
  /// **'Owner name'**
  String get ownerName;

  /// No description provided for @invoicePrefix.
  ///
  /// In en, this message translates to:
  /// **'Invoice prefix'**
  String get invoicePrefix;

  /// No description provided for @invoicePrefixHint.
  ///
  /// In en, this message translates to:
  /// **'Used for new sale numbers, e.g. INV-0001'**
  String get invoicePrefixHint;

  /// No description provided for @invoicePrefixRule.
  ///
  /// In en, this message translates to:
  /// **'1–10 characters: A–Z, 0–9 and -'**
  String get invoicePrefixRule;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme mode'**
  String get themeMode;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @accentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get accentColor;

  /// No description provided for @accentBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get accentBlue;

  /// No description provided for @accentBrick.
  ///
  /// In en, this message translates to:
  /// **'Brick'**
  String get accentBrick;

  /// No description provided for @accentEmerald.
  ///
  /// In en, this message translates to:
  /// **'Emerald'**
  String get accentEmerald;

  /// No description provided for @accentViolet.
  ///
  /// In en, this message translates to:
  /// **'Violet'**
  String get accentViolet;

  /// No description provided for @accentSlate.
  ///
  /// In en, this message translates to:
  /// **'Slate'**
  String get accentSlate;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get fontSize;

  /// No description provided for @fontSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get fontSmall;

  /// No description provided for @fontDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get fontDefault;

  /// No description provided for @fontLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get fontLarge;

  /// No description provided for @fontExtraLarge.
  ///
  /// In en, this message translates to:
  /// **'Extra large'**
  String get fontExtraLarge;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @previewHeroLabel.
  ///
  /// In en, this message translates to:
  /// **'Today\'s sales'**
  String get previewHeroLabel;

  /// No description provided for @previewHeroCaption.
  ///
  /// In en, this message translates to:
  /// **'6 sales today'**
  String get previewHeroCaption;

  /// No description provided for @previewPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get previewPaid;

  /// No description provided for @previewPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get previewPartial;

  /// No description provided for @previewDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get previewDue;

  /// No description provided for @previewButton.
  ///
  /// In en, this message translates to:
  /// **'New sale'**
  String get previewButton;

  /// No description provided for @resetToDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get resetToDefault;

  /// No description provided for @languageHint.
  ///
  /// In en, this message translates to:
  /// **'App text and server messages'**
  String get languageHint;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutApp;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @buildNumber.
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get buildNumber;

  /// No description provided for @server.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get server;

  /// No description provided for @navGroupDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily work'**
  String get navGroupDaily;

  /// No description provided for @navGroupBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get navGroupBusiness;

  /// No description provided for @navGroupAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get navGroupAdmin;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @moreAppearanceSettings.
  ///
  /// In en, this message translates to:
  /// **'More appearance settings'**
  String get moreAppearanceSettings;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptional;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount, e.g. 4.50'**
  String get invalidAmount;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add product'**
  String get addProduct;

  /// No description provided for @editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit product'**
  String get editProduct;

  /// No description provided for @searchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search products'**
  String get searchProducts;

  /// No description provided for @productsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No products yet'**
  String get productsEmptyTitle;

  /// No description provided for @productsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add the bricks you sell with their cost and price. Sales use these prices.'**
  String get productsEmptyMessage;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get productName;

  /// No description provided for @productNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Fly Ash Brick 9×4×3'**
  String get productNameHint;

  /// No description provided for @unitField.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unitField;

  /// No description provided for @unitPiece.
  ///
  /// In en, this message translates to:
  /// **'Piece'**
  String get unitPiece;

  /// No description provided for @unitThousand.
  ///
  /// In en, this message translates to:
  /// **'1000 pieces'**
  String get unitThousand;

  /// No description provided for @unitTruck.
  ///
  /// In en, this message translates to:
  /// **'Truck'**
  String get unitTruck;

  /// No description provided for @unitOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get unitOther;

  /// No description provided for @unitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit name'**
  String get unitLabel;

  /// No description provided for @unitLabelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. cft'**
  String get unitLabelHint;

  /// No description provided for @perUnit.
  ///
  /// In en, this message translates to:
  /// **'per {unit}'**
  String perUnit(String unit);

  /// No description provided for @defaultCost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get defaultCost;

  /// No description provided for @defaultPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get defaultPrice;

  /// No description provided for @margin.
  ///
  /// In en, this message translates to:
  /// **'Margin'**
  String get margin;

  /// No description provided for @marginPerUnit.
  ///
  /// In en, this message translates to:
  /// **'Margin per unit'**
  String get marginPerUnit;

  /// No description provided for @lossPerUnit.
  ///
  /// In en, this message translates to:
  /// **'Loss per unit'**
  String get lossPerUnit;

  /// No description provided for @productCreated.
  ///
  /// In en, this message translates to:
  /// **'Product added'**
  String get productCreated;

  /// No description provided for @productUpdated.
  ///
  /// In en, this message translates to:
  /// **'Product updated'**
  String get productUpdated;

  /// No description provided for @inactiveProductHint.
  ///
  /// In en, this message translates to:
  /// **'Hidden from the sale form. Old sales keep it.'**
  String get inactiveProductHint;

  /// No description provided for @activateProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Activate {name}?'**
  String activateProductTitle(String name);

  /// No description provided for @deactivateProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate {name}?'**
  String deactivateProductTitle(String name);

  /// No description provided for @activateProductMessage.
  ///
  /// In en, this message translates to:
  /// **'It will show in the sale form again.'**
  String get activateProductMessage;

  /// No description provided for @deactivateProductMessage.
  ///
  /// In en, this message translates to:
  /// **'It will be hidden from the sale form. Old sales are not changed.'**
  String get deactivateProductMessage;

  /// No description provided for @deleteProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteProductTitle(String name);

  /// No description provided for @deleteProductMessage.
  ///
  /// In en, this message translates to:
  /// **'Only possible if it was never used in a sale.'**
  String get deleteProductMessage;

  /// No description provided for @moreActions.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get moreActions;

  /// No description provided for @couldNotOpen.
  ///
  /// In en, this message translates to:
  /// **'Could not open it on this device'**
  String get couldNotOpen;

  /// No description provided for @addressOptional.
  ///
  /// In en, this message translates to:
  /// **'Address (optional)'**
  String get addressOptional;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @whatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsApp;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @due.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get due;

  /// No description provided for @noDue.
  ///
  /// In en, this message translates to:
  /// **'No due'**
  String get noDue;

  /// No description provided for @sales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get sales;

  /// No description provided for @invoiceNo.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoiceNo;

  /// No description provided for @paymentPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paymentPaid;

  /// No description provided for @paymentPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get paymentPartial;

  /// No description provided for @paymentDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get paymentDue;

  /// No description provided for @saleBooked.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get saleBooked;

  /// No description provided for @saleDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get saleDelivered;

  /// No description provided for @saleCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get saleCancelled;

  /// No description provided for @saleTypeInstant.
  ///
  /// In en, this message translates to:
  /// **'Instant'**
  String get saleTypeInstant;

  /// No description provided for @saleTypeBooking.
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get saleTypeBooking;

  /// No description provided for @addCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add customer'**
  String get addCustomer;

  /// No description provided for @editCustomer.
  ///
  /// In en, this message translates to:
  /// **'Edit customer'**
  String get editCustomer;

  /// No description provided for @customerDetails.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customerDetails;

  /// No description provided for @filterHasDue.
  ///
  /// In en, this message translates to:
  /// **'Has due'**
  String get filterHasDue;

  /// No description provided for @customersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No customers yet'**
  String get customersEmptyTitle;

  /// No description provided for @customersEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add the people and shops who buy from you. Their dues show here.'**
  String get customersEmptyMessage;

  /// No description provided for @customerNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Rahim Traders'**
  String get customerNameHint;

  /// No description provided for @customerPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Each phone number can belong to one customer only.'**
  String get customerPhoneHint;

  /// No description provided for @openExistingCustomer.
  ///
  /// In en, this message translates to:
  /// **'Open that customer'**
  String get openExistingCustomer;

  /// No description provided for @customerCreated.
  ///
  /// In en, this message translates to:
  /// **'Customer added'**
  String get customerCreated;

  /// No description provided for @customerUpdated.
  ///
  /// In en, this message translates to:
  /// **'Customer updated'**
  String get customerUpdated;

  /// No description provided for @purchases.
  ///
  /// In en, this message translates to:
  /// **'Purchases'**
  String get purchases;

  /// No description provided for @noSalesYet.
  ///
  /// In en, this message translates to:
  /// **'No sales yet'**
  String get noSalesYet;

  /// No description provided for @noSalesYetMessage.
  ///
  /// In en, this message translates to:
  /// **'Sales to this customer will show here.'**
  String get noSalesYetMessage;

  /// No description provided for @activateCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Activate {name}?'**
  String activateCustomerTitle(String name);

  /// No description provided for @deactivateCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate {name}?'**
  String deactivateCustomerTitle(String name);

  /// No description provided for @activateCustomerMessage.
  ///
  /// In en, this message translates to:
  /// **'They can be chosen in new sales again.'**
  String get activateCustomerMessage;

  /// No description provided for @deactivateCustomerMessage.
  ///
  /// In en, this message translates to:
  /// **'They will not be offered in new sales. Old sales and dues stay.'**
  String get deactivateCustomerMessage;

  /// No description provided for @deleteCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteCustomerTitle(String name);

  /// No description provided for @deleteCustomerMessage.
  ///
  /// In en, this message translates to:
  /// **'Only possible if they have no sales.'**
  String get deleteCustomerMessage;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @saleDetails.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get saleDetails;

  /// No description provided for @searchSales.
  ///
  /// In en, this message translates to:
  /// **'Invoice no., customer or phone'**
  String get searchSales;

  /// No description provided for @filterSales.
  ///
  /// In en, this message translates to:
  /// **'Filter sales'**
  String get filterSales;

  /// No description provided for @salesEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Sales you make will show here.'**
  String get salesEmptyMessage;

  /// No description provided for @anyDate.
  ///
  /// In en, this message translates to:
  /// **'Any date'**
  String get anyDate;

  /// No description provided for @presetToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get presetToday;

  /// No description provided for @presetYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get presetYesterday;

  /// No description provided for @presetThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get presetThisWeek;

  /// No description provided for @presetThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get presetThisMonth;

  /// No description provided for @presetLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get presetLastMonth;

  /// No description provided for @presetCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get presetCustom;

  /// No description provided for @upcomingDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Upcoming deliveries'**
  String get upcomingDeliveries;

  /// No description provided for @noUpcomingDeliveries.
  ///
  /// In en, this message translates to:
  /// **'No deliveries pending'**
  String get noUpcomingDeliveries;

  /// No description provided for @noUpcomingDeliveriesMessage.
  ///
  /// In en, this message translates to:
  /// **'Bookings waiting for delivery will show here.'**
  String get noUpcomingDeliveriesMessage;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @deliverOn.
  ///
  /// In en, this message translates to:
  /// **'Deliver {date}'**
  String deliverOn(String date);

  /// No description provided for @saleDate.
  ///
  /// In en, this message translates to:
  /// **'Sale date'**
  String get saleDate;

  /// No description provided for @deliveryDate.
  ///
  /// In en, this message translates to:
  /// **'Delivery date'**
  String get deliveryDate;

  /// No description provided for @deliveredOn.
  ///
  /// In en, this message translates to:
  /// **'Delivered on'**
  String get deliveredOn;

  /// No description provided for @createdBy.
  ///
  /// In en, this message translates to:
  /// **'Entered by {name}'**
  String createdBy(String name);

  /// No description provided for @byUser.
  ///
  /// In en, this message translates to:
  /// **'by {name}'**
  String byUser(String name);

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'Items ({count})'**
  String itemsCount(String count);

  /// No description provided for @paymentsCount.
  ///
  /// In en, this message translates to:
  /// **'Payments ({count})'**
  String paymentsCount(String count);

  /// No description provided for @noPaymentsYet.
  ///
  /// In en, this message translates to:
  /// **'No payment received yet'**
  String get noPaymentsYet;

  /// No description provided for @amountSummary.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountSummary;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @transport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get transport;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @productionCost.
  ///
  /// In en, this message translates to:
  /// **'Production cost'**
  String get productionCost;

  /// No description provided for @profit.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get profit;

  /// No description provided for @methodCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get methodCash;

  /// No description provided for @methodUpi.
  ///
  /// In en, this message translates to:
  /// **'UPI'**
  String get methodUpi;

  /// No description provided for @methodBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get methodBank;

  /// No description provided for @methodCheque.
  ///
  /// In en, this message translates to:
  /// **'Cheque'**
  String get methodCheque;

  /// No description provided for @methodOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get methodOther;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get keepEditing;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @amountOptional.
  ///
  /// In en, this message translates to:
  /// **'Amount (optional)'**
  String get amountOptional;

  /// No description provided for @dueAmount.
  ///
  /// In en, this message translates to:
  /// **'Due {amount}'**
  String dueAmount(String amount);

  /// No description provided for @invalidQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter a quantity more than 0'**
  String get invalidQuantity;

  /// No description provided for @newSale.
  ///
  /// In en, this message translates to:
  /// **'New sale'**
  String get newSale;

  /// No description provided for @newBooking.
  ///
  /// In en, this message translates to:
  /// **'New booking'**
  String get newBooking;

  /// No description provided for @editSale.
  ///
  /// In en, this message translates to:
  /// **'Edit sale'**
  String get editSale;

  /// No description provided for @saveSale.
  ///
  /// In en, this message translates to:
  /// **'Save sale'**
  String get saveSale;

  /// No description provided for @instantHint.
  ///
  /// In en, this message translates to:
  /// **'Goods leave the factory today.'**
  String get instantHint;

  /// No description provided for @bookingHint.
  ///
  /// In en, this message translates to:
  /// **'Order now, deliver on a later date. You can take an advance.'**
  String get bookingHint;

  /// No description provided for @selectCustomer.
  ///
  /// In en, this message translates to:
  /// **'Select customer'**
  String get selectCustomer;

  /// No description provided for @selectCustomerError.
  ///
  /// In en, this message translates to:
  /// **'Select a customer or add a new one'**
  String get selectCustomerError;

  /// No description provided for @newCustomer.
  ///
  /// In en, this message translates to:
  /// **'New customer'**
  String get newCustomer;

  /// No description provided for @pickExistingCustomer.
  ///
  /// In en, this message translates to:
  /// **'Pick an existing customer instead'**
  String get pickExistingCustomer;

  /// No description provided for @useThisCustomer.
  ///
  /// In en, this message translates to:
  /// **'Use this customer'**
  String get useThisCustomer;

  /// No description provided for @deliveryAddressOptional.
  ///
  /// In en, this message translates to:
  /// **'Delivery address (optional)'**
  String get deliveryAddressOptional;

  /// No description provided for @selectProduct.
  ///
  /// In en, this message translates to:
  /// **'Select product'**
  String get selectProduct;

  /// No description provided for @selectProductError.
  ///
  /// In en, this message translates to:
  /// **'Select a product'**
  String get selectProductError;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItem;

  /// No description provided for @removeItem.
  ///
  /// In en, this message translates to:
  /// **'Remove item'**
  String get removeItem;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @unitPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price / unit'**
  String get unitPriceLabel;

  /// No description provided for @unitCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Cost / unit'**
  String get unitCostLabel;

  /// No description provided for @lineTotal.
  ///
  /// In en, this message translates to:
  /// **'Line total'**
  String get lineTotal;

  /// No description provided for @discountTooHigh.
  ///
  /// In en, this message translates to:
  /// **'Cannot be more than subtotal + transport'**
  String get discountTooHigh;

  /// No description provided for @alreadyPaid.
  ///
  /// In en, this message translates to:
  /// **'Already paid'**
  String get alreadyPaid;

  /// No description provided for @paymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Payment received now'**
  String get paymentReceived;

  /// No description provided for @advanceReceived.
  ///
  /// In en, this message translates to:
  /// **'Advance received'**
  String get advanceReceived;

  /// No description provided for @paymentNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Payment note (optional)'**
  String get paymentNoteOptional;

  /// No description provided for @cannotExceedTotal.
  ///
  /// In en, this message translates to:
  /// **'Cannot be more than total {amount}'**
  String cannotExceedTotal(String amount);

  /// No description provided for @saleNotesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Deliver before noon'**
  String get saleNotesHint;

  /// No description provided for @discardSaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this sale?'**
  String get discardSaleTitle;

  /// No description provided for @discardChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard your changes?'**
  String get discardChangesTitle;

  /// No description provided for @discardSaleMessage.
  ///
  /// In en, this message translates to:
  /// **'What you entered will be lost.'**
  String get discardSaleMessage;

  /// No description provided for @addPayment.
  ///
  /// In en, this message translates to:
  /// **'Add payment'**
  String get addPayment;

  /// No description provided for @paymentDate.
  ///
  /// In en, this message translates to:
  /// **'Payment date'**
  String get paymentDate;

  /// No description provided for @cannotExceedDue.
  ///
  /// In en, this message translates to:
  /// **'Cannot be more than the due {amount}'**
  String cannotExceedDue(String amount);

  /// No description provided for @paymentActions.
  ///
  /// In en, this message translates to:
  /// **'Payment actions'**
  String get paymentActions;

  /// No description provided for @deletePayment.
  ///
  /// In en, this message translates to:
  /// **'Delete payment'**
  String get deletePayment;

  /// No description provided for @deletePaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete payment of {amount}?'**
  String deletePaymentTitle(String amount);

  /// No description provided for @deletePaymentMessage.
  ///
  /// In en, this message translates to:
  /// **'The due amount goes up again.'**
  String get deletePaymentMessage;

  /// No description provided for @markDelivered.
  ///
  /// In en, this message translates to:
  /// **'Mark delivered'**
  String get markDelivered;

  /// No description provided for @markDeliveredTitle.
  ///
  /// In en, this message translates to:
  /// **'Deliver {invoice}'**
  String markDeliveredTitle(String invoice);

  /// No description provided for @cancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get cancelBooking;

  /// No description provided for @keepBooking.
  ///
  /// In en, this message translates to:
  /// **'Keep booking'**
  String get keepBooking;

  /// No description provided for @cancelBookingTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel {invoice}?'**
  String cancelBookingTitle(String invoice);

  /// No description provided for @cancelBookingMessage.
  ///
  /// In en, this message translates to:
  /// **'The booking stays in the list as Cancelled and is left out of totals.'**
  String get cancelBookingMessage;

  /// No description provided for @removePaymentsFirst.
  ///
  /// In en, this message translates to:
  /// **'This booking has payments. Delete them first (refund the money), then cancel.'**
  String get removePaymentsFirst;

  /// No description provided for @deleteSale.
  ///
  /// In en, this message translates to:
  /// **'Delete sale'**
  String get deleteSale;

  /// No description provided for @deleteSaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {invoice}?'**
  String deleteSaleTitle(String invoice);

  /// No description provided for @deleteSaleMessage.
  ///
  /// In en, this message translates to:
  /// **'It will be removed from all lists and reports.'**
  String get deleteSaleMessage;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @phoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get phoneOptional;

  /// No description provided for @addLabour.
  ///
  /// In en, this message translates to:
  /// **'Add labour'**
  String get addLabour;

  /// No description provided for @editLabour.
  ///
  /// In en, this message translates to:
  /// **'Edit labour'**
  String get editLabour;

  /// No description provided for @labourDetails.
  ///
  /// In en, this message translates to:
  /// **'Labour'**
  String get labourDetails;

  /// No description provided for @laboursEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No labours yet'**
  String get laboursEmptyTitle;

  /// No description provided for @laboursEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add the people who work at the factory with their daily or monthly wage.'**
  String get laboursEmptyMessage;

  /// No description provided for @labourCreated.
  ///
  /// In en, this message translates to:
  /// **'Labour added'**
  String get labourCreated;

  /// No description provided for @labourUpdated.
  ///
  /// In en, this message translates to:
  /// **'Labour updated'**
  String get labourUpdated;

  /// No description provided for @wage.
  ///
  /// In en, this message translates to:
  /// **'Wage'**
  String get wage;

  /// No description provided for @wageDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get wageDaily;

  /// No description provided for @wageMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get wageMonthly;

  /// No description provided for @wagePerDay.
  ///
  /// In en, this message translates to:
  /// **'Wage per day'**
  String get wagePerDay;

  /// No description provided for @wagePerMonth.
  ///
  /// In en, this message translates to:
  /// **'Wage per month'**
  String get wagePerMonth;

  /// No description provided for @dailyWageHint.
  ///
  /// In en, this message translates to:
  /// **'Paid for each day present; half for a half day.'**
  String get dailyWageHint;

  /// No description provided for @monthlyWageHint.
  ///
  /// In en, this message translates to:
  /// **'Divided by the days in the month, then counted per day present.'**
  String get monthlyWageHint;

  /// No description provided for @wageChangeHint.
  ///
  /// In en, this message translates to:
  /// **'The new wage applies to attendance saved from now on. Past days keep their wage.'**
  String get wageChangeHint;

  /// No description provided for @perDay.
  ///
  /// In en, this message translates to:
  /// **'{amount} / day'**
  String perDay(String amount);

  /// No description provided for @perMonth.
  ///
  /// In en, this message translates to:
  /// **'{amount} / month'**
  String perMonth(String amount);

  /// No description provided for @joiningDate.
  ///
  /// In en, this message translates to:
  /// **'Joining date'**
  String get joiningDate;

  /// No description provided for @leavingDate.
  ///
  /// In en, this message translates to:
  /// **'Leaving date'**
  String get leavingDate;

  /// No description provided for @joined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get joined;

  /// No description provided for @attendanceThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendanceThisMonth;

  /// No description provided for @activateLabourTitle.
  ///
  /// In en, this message translates to:
  /// **'Activate {name}?'**
  String activateLabourTitle(String name);

  /// No description provided for @activateLabourMessage.
  ///
  /// In en, this message translates to:
  /// **'They will show on the attendance sheet again.'**
  String get activateLabourMessage;

  /// No description provided for @deactivateLabourTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} left?'**
  String deactivateLabourTitle(String name);

  /// No description provided for @deactivateLabourMessage.
  ///
  /// In en, this message translates to:
  /// **'Choose the last working day. After it they are not on the attendance sheet. Their wages stay.'**
  String get deactivateLabourMessage;

  /// No description provided for @wkMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get wkMon;

  /// No description provided for @wkTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get wkTue;

  /// No description provided for @wkWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wkWed;

  /// No description provided for @wkThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get wkThu;

  /// No description provided for @wkFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get wkFri;

  /// No description provided for @wkSat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get wkSat;

  /// No description provided for @wkSun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get wkSun;

  /// No description provided for @attPresent.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get attPresent;

  /// No description provided for @attAbsent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get attAbsent;

  /// No description provided for @todayWithDate.
  ///
  /// In en, this message translates to:
  /// **'Today, {date}'**
  String todayWithDate(String date);

  /// No description provided for @yesterdayWithDate.
  ///
  /// In en, this message translates to:
  /// **'Yesterday, {date}'**
  String yesterdayWithDate(String date);

  /// No description provided for @noLaboursOnDate.
  ///
  /// In en, this message translates to:
  /// **'No labours on this date'**
  String get noLaboursOnDate;

  /// No description provided for @noLaboursOnDateMessage.
  ///
  /// In en, this message translates to:
  /// **'Only labours who had joined and not left on this date are listed.'**
  String get noLaboursOnDateMessage;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get days;

  /// No description provided for @earned.
  ///
  /// In en, this message translates to:
  /// **'Earned'**
  String get earned;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @daysWorked.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String daysWorked(String count);

  /// No description provided for @earnedAmount.
  ///
  /// In en, this message translates to:
  /// **'earned {amount}'**
  String earnedAmount(String amount);

  /// No description provided for @earnedInMonth.
  ///
  /// In en, this message translates to:
  /// **'Earned in {month}'**
  String earnedInMonth(String month);

  /// No description provided for @balanceAmount.
  ///
  /// In en, this message translates to:
  /// **'Balance {amount}'**
  String balanceAmount(String amount);

  /// No description provided for @searchLabour.
  ///
  /// In en, this message translates to:
  /// **'Search labour'**
  String get searchLabour;

  /// No description provided for @noWagesThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No wages this month'**
  String get noWagesThisMonth;

  /// No description provided for @noWagesThisMonthMessage.
  ///
  /// In en, this message translates to:
  /// **'Labours employed in this month and their attendance make the wage sheet.'**
  String get noWagesThisMonthMessage;

  /// No description provided for @wageDetails.
  ///
  /// In en, this message translates to:
  /// **'Wage'**
  String get wageDetails;

  /// No description provided for @wageBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Wage for the month'**
  String get wageBreakdown;

  /// No description provided for @workedDaysLine.
  ///
  /// In en, this message translates to:
  /// **'Present {present} · Absent {absent}'**
  String workedDaysLine(String present, String absent);

  /// No description provided for @payWage.
  ///
  /// In en, this message translates to:
  /// **'Pay wage'**
  String get payWage;

  /// No description provided for @payWageTitle.
  ///
  /// In en, this message translates to:
  /// **'Pay {name} for {month}'**
  String payWageTitle(String name, String month);

  /// No description provided for @noWagePayments.
  ///
  /// In en, this message translates to:
  /// **'Nothing paid for this month yet'**
  String get noWagePayments;

  /// No description provided for @balanceRecalculated.
  ///
  /// In en, this message translates to:
  /// **'The balance is worked out again.'**
  String get balanceRecalculated;

  /// No description provided for @dayByDay.
  ///
  /// In en, this message translates to:
  /// **'Day by day'**
  String get dayByDay;

  /// No description provided for @wageThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Wage this month'**
  String get wageThisMonth;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @icon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get icon;

  /// No description provided for @enteredByColumn.
  ///
  /// In en, this message translates to:
  /// **'Entered by'**
  String get enteredByColumn;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get addExpense;

  /// No description provided for @editExpense.
  ///
  /// In en, this message translates to:
  /// **'Edit expense'**
  String get editExpense;

  /// No description provided for @spentIn.
  ///
  /// In en, this message translates to:
  /// **'Spent: {period}'**
  String spentIn(String period);

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allCategories;

  /// No description provided for @searchNote.
  ///
  /// In en, this message translates to:
  /// **'Search notes'**
  String get searchNote;

  /// No description provided for @noExpenses.
  ///
  /// In en, this message translates to:
  /// **'No expenses in this period'**
  String get noExpenses;

  /// No description provided for @noExpensesMessage.
  ///
  /// In en, this message translates to:
  /// **'Record tiffin, repairs, diesel, electricity and other costs here.'**
  String get noExpensesMessage;

  /// No description provided for @expenseNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Tiffin for 15 labours'**
  String get expenseNoteHint;

  /// No description provided for @deleteExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this expense?'**
  String get deleteExpenseTitle;

  /// No description provided for @deleteExpenseMessage.
  ///
  /// In en, this message translates to:
  /// **'It is removed from the totals and reports.'**
  String get deleteExpenseMessage;

  /// No description provided for @totalDue.
  ///
  /// In en, this message translates to:
  /// **'Total due'**
  String get totalDue;

  /// No description provided for @deliveriesToday.
  ///
  /// In en, this message translates to:
  /// **'Deliveries today'**
  String get deliveriesToday;

  /// No description provided for @deliveriesTodayOverdue.
  ///
  /// In en, this message translates to:
  /// **'Deliveries · {count} late'**
  String deliveriesTodayOverdue(String count);

  /// No description provided for @presentToday.
  ///
  /// In en, this message translates to:
  /// **'Present today'**
  String get presentToday;

  /// No description provided for @monthExpenses.
  ///
  /// In en, this message translates to:
  /// **'Month expenses'**
  String get monthExpenses;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActions;

  /// No description provided for @recentSales.
  ///
  /// In en, this message translates to:
  /// **'Recent sales'**
  String get recentSales;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @todaysSales.
  ///
  /// In en, this message translates to:
  /// **'Today\'s sales'**
  String get todaysSales;

  /// No description provided for @todaysSalesCaption.
  ///
  /// In en, this message translates to:
  /// **'{count} sales · profit {profit}'**
  String todaysSalesCaption(String count, String profit);

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @attendanceCount.
  ///
  /// In en, this message translates to:
  /// **'{present} present · {absent} absent'**
  String attendanceCount(String present, String absent);

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @filterExpenses.
  ///
  /// In en, this message translates to:
  /// **'Filter expenses'**
  String get filterExpenses;

  /// No description provided for @categoryHint.
  ///
  /// In en, this message translates to:
  /// **'Type or pick one, e.g. Labour Tiffin'**
  String get categoryHint;

  /// No description provided for @taxPercentField.
  ///
  /// In en, this message translates to:
  /// **'Tax (%)'**
  String get taxPercentField;

  /// No description provided for @taxLine.
  ///
  /// In en, this message translates to:
  /// **'Tax ({percent}%)'**
  String taxLine(String percent);

  /// No description provided for @invalidTaxPercent.
  ///
  /// In en, this message translates to:
  /// **'Enter 0 to 100, e.g. 5 or 12.5'**
  String get invalidTaxPercent;
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
