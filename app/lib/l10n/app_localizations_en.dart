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

  @override
  String get signIn => 'Sign in';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get loginField => 'Phone or email';

  @override
  String get passwordField => 'Password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get sessionEnded => 'Your session ended. Please sign in again';

  @override
  String get forgotTitle => 'Forgot password';

  @override
  String get forgotHint =>
      'Enter the email linked to your account. We will send a 6-digit OTP.';

  @override
  String get emailField => 'Email';

  @override
  String get invalidEmail => 'Enter a valid email';

  @override
  String get sendOtp => 'Send OTP';

  @override
  String get noEmailHint =>
      'No email? Ask another user to reset your password.';

  @override
  String get verifyTitle => 'Verify OTP';

  @override
  String get otpSentHint =>
      'We sent a 6-digit OTP to this email. Enter it below.';

  @override
  String get otpLabel => '6-digit OTP';

  @override
  String get verify => 'Verify';

  @override
  String get changeEmail => 'Change';

  @override
  String resendIn(String seconds) {
    return 'Resend OTP in ${seconds}s';
  }

  @override
  String get resendOtp => 'Resend OTP';

  @override
  String get resetTitle => 'Set new password';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get passwordRule => 'At least 6 characters';

  @override
  String get passwordsDontMatch => 'Passwords do not match';

  @override
  String get resetPassword => 'Reset password';

  @override
  String get cancelResetTitle => 'Cancel password reset?';

  @override
  String get cancelResetMessage => 'You will need a new OTP to start again.';

  @override
  String get keepGoing => 'Continue';

  @override
  String get leave => 'Leave';

  @override
  String get startAgain => 'Start again';

  @override
  String get logout => 'Log out';

  @override
  String get logoutConfirmTitle => 'Log out?';

  @override
  String get logoutConfirmMessage =>
      'You will need to sign in again on this device.';

  @override
  String get loading => 'Loading…';

  @override
  String get save => 'Save';

  @override
  String get edit => 'Edit';

  @override
  String get clear => 'Clear';

  @override
  String get status => 'Status';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get never => 'Never';

  @override
  String get noResults => 'No results found';

  @override
  String showingCount(String shown, String total) {
    return 'Showing $shown of $total';
  }

  @override
  String get nameField => 'Name';

  @override
  String get phoneField => 'Phone';

  @override
  String get emailOptional => 'Email (optional)';

  @override
  String get addressField => 'Address';

  @override
  String get invalidPhone => 'Enter a 10-digit mobile number starting with 6–9';

  @override
  String get passwordTooLong => 'At most 64 characters';

  @override
  String get searchNamePhone => 'Search by name or phone';

  @override
  String get addUser => 'Add user';

  @override
  String get editUser => 'Edit user';

  @override
  String get userDetails => 'User details';

  @override
  String get usersEmptyTitle => 'Only you so far';

  @override
  String get usersEmptyMessage =>
      'Add the people who will use FlyAsh with you. Everyone has the same access.';

  @override
  String lastLogin(String time) {
    return 'Last login: $time';
  }

  @override
  String get lastLoginColumn => 'Last login';

  @override
  String get userCreated => 'User added';

  @override
  String get userUpdated => 'User updated';

  @override
  String get emailForgotHint => 'Needed for Forgot password';

  @override
  String get noEmailHintUser =>
      'Without an email this user cannot use Forgot password. You can reset their password here.';

  @override
  String resetPasswordFor(String name) {
    return 'Reset password for $name';
  }

  @override
  String get resetUserPasswordHint =>
      'Set a new password. They will be logged out on all devices.';

  @override
  String get activate => 'Activate';

  @override
  String get deactivate => 'Deactivate';

  @override
  String activateUserTitle(String name) {
    return 'Activate $name?';
  }

  @override
  String deactivateUserTitle(String name) {
    return 'Deactivate $name?';
  }

  @override
  String get activateUserMessage => 'They will be able to log in again.';

  @override
  String get deactivateUserMessage =>
      'They will be logged out everywhere and cannot log in until activated again.';

  @override
  String get myProfile => 'My profile';

  @override
  String get viewProfile => 'View profile';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get emailForgotHintSelf =>
      'Add an email so you can reset a forgotten password yourself';

  @override
  String get noEmailHintSelf =>
      'Add an email to be able to use Forgot password.';

  @override
  String get changePassword => 'Change password';

  @override
  String get changePasswordHint =>
      'Other devices will be logged out. This device stays logged in.';

  @override
  String get currentPassword => 'Current password';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsFactory => 'Factory';

  @override
  String get settingsApp => 'App';

  @override
  String get factoryProfile => 'Factory profile';

  @override
  String get factoryName => 'Factory name';

  @override
  String get ownerName => 'Owner name';

  @override
  String get invoicePrefix => 'Invoice prefix';

  @override
  String get invoicePrefixHint => 'Used for new sale numbers, e.g. INV-0001';

  @override
  String get invoicePrefixRule => '1–10 characters: A–Z, 0–9 and -';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeMode => 'Theme mode';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get accentColor => 'Accent color';

  @override
  String get accentBlue => 'Blue';

  @override
  String get accentBrick => 'Brick';

  @override
  String get accentEmerald => 'Emerald';

  @override
  String get accentViolet => 'Violet';

  @override
  String get accentSlate => 'Slate';

  @override
  String get fontSize => 'Font size';

  @override
  String get fontSmall => 'Small';

  @override
  String get fontDefault => 'Default';

  @override
  String get fontLarge => 'Large';

  @override
  String get fontExtraLarge => 'Extra large';

  @override
  String get preview => 'Preview';

  @override
  String get previewHeroLabel => 'Today\'s sales';

  @override
  String get previewHeroCaption => '6 sales today';

  @override
  String get previewPaid => 'Paid';

  @override
  String get previewPartial => 'Partial';

  @override
  String get previewDue => 'Due';

  @override
  String get previewButton => 'New sale';

  @override
  String get resetToDefault => 'Reset to default';

  @override
  String get languageHint =>
      'Changes the app text and server messages. Saved to your account.';

  @override
  String get aboutApp => 'About';

  @override
  String get version => 'Version';

  @override
  String get buildNumber => 'Build';

  @override
  String get server => 'Server';

  @override
  String get navGroupDaily => 'Daily work';

  @override
  String get navGroupBusiness => 'Business';

  @override
  String get navGroupAdmin => 'Admin';
}
