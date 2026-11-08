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
  String otpSentTo(String email) {
    return 'Enter the OTP sent to $email';
  }

  @override
  String get otpLabel => '6-digit OTP';

  @override
  String get verify => 'Verify';

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
}
