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

  @override
  String get account => 'Account';

  @override
  String get moreAppearanceSettings => 'More appearance settings';

  @override
  String get filterAll => 'All';

  @override
  String get delete => 'Delete';

  @override
  String get notesOptional => 'Notes (optional)';

  @override
  String get invalidAmount => 'Enter an amount, e.g. 4.50';

  @override
  String get addProduct => 'Add product';

  @override
  String get editProduct => 'Edit product';

  @override
  String get searchProducts => 'Search products';

  @override
  String get productsEmptyTitle => 'No products yet';

  @override
  String get productsEmptyMessage =>
      'Add the bricks you sell with their cost and price. Sales use these prices.';

  @override
  String get productName => 'Product name';

  @override
  String get productNameHint => 'e.g. Fly Ash Brick 9×4×3';

  @override
  String get unitField => 'Unit';

  @override
  String get unitPiece => 'Piece';

  @override
  String get unitThousand => '1000 pieces';

  @override
  String get unitTruck => 'Truck';

  @override
  String get unitOther => 'Other';

  @override
  String get unitLabel => 'Unit name';

  @override
  String get unitLabelHint => 'e.g. cft';

  @override
  String perUnit(String unit) {
    return 'per $unit';
  }

  @override
  String get defaultCost => 'Cost';

  @override
  String get defaultPrice => 'Price';

  @override
  String get margin => 'Margin';

  @override
  String get marginPerUnit => 'Margin per unit';

  @override
  String get lossPerUnit => 'Loss per unit';

  @override
  String get productCreated => 'Product added';

  @override
  String get productUpdated => 'Product updated';

  @override
  String get inactiveProductHint =>
      'Hidden from the sale form. Old sales keep it.';

  @override
  String activateProductTitle(String name) {
    return 'Activate $name?';
  }

  @override
  String deactivateProductTitle(String name) {
    return 'Deactivate $name?';
  }

  @override
  String get activateProductMessage => 'It will show in the sale form again.';

  @override
  String get deactivateProductMessage =>
      'It will be hidden from the sale form. Old sales are not changed.';

  @override
  String deleteProductTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get deleteProductMessage =>
      'Only possible if it was never used in a sale.';

  @override
  String get moreActions => 'More actions';

  @override
  String get couldNotOpen => 'Could not open it on this device';

  @override
  String get addressOptional => 'Address (optional)';

  @override
  String get call => 'Call';

  @override
  String get whatsApp => 'WhatsApp';

  @override
  String get date => 'Date';

  @override
  String get type => 'Type';

  @override
  String get total => 'Total';

  @override
  String get paid => 'Paid';

  @override
  String get due => 'Due';

  @override
  String get noDue => 'No due';

  @override
  String get sales => 'Sales';

  @override
  String get invoiceNo => 'Invoice';

  @override
  String get paymentPaid => 'Paid';

  @override
  String get paymentPartial => 'Partial';

  @override
  String get paymentDue => 'Due';

  @override
  String get saleBooked => 'Booked';

  @override
  String get saleDelivered => 'Delivered';

  @override
  String get saleCancelled => 'Cancelled';

  @override
  String get saleTypeInstant => 'Instant';

  @override
  String get saleTypeBooking => 'Booking';

  @override
  String get addCustomer => 'Add customer';

  @override
  String get editCustomer => 'Edit customer';

  @override
  String get customerDetails => 'Customer';

  @override
  String get filterHasDue => 'Has due';

  @override
  String get customersEmptyTitle => 'No customers yet';

  @override
  String get customersEmptyMessage =>
      'Add the people and shops who buy from you. Their dues show here.';

  @override
  String get customerNameHint => 'e.g. Rahim Traders';

  @override
  String get customerPhoneHint =>
      'Each phone number can belong to one customer only.';

  @override
  String get openExistingCustomer => 'Open that customer';

  @override
  String get customerCreated => 'Customer added';

  @override
  String get customerUpdated => 'Customer updated';

  @override
  String get purchases => 'Purchases';

  @override
  String get noSalesYet => 'No sales yet';

  @override
  String get noSalesYetMessage => 'Sales to this customer will show here.';

  @override
  String activateCustomerTitle(String name) {
    return 'Activate $name?';
  }

  @override
  String deactivateCustomerTitle(String name) {
    return 'Deactivate $name?';
  }

  @override
  String get activateCustomerMessage =>
      'They can be chosen in new sales again.';

  @override
  String get deactivateCustomerMessage =>
      'They will not be offered in new sales. Old sales and dues stay.';

  @override
  String deleteCustomerTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get deleteCustomerMessage => 'Only possible if they have no sales.';

  @override
  String get reset => 'Reset';

  @override
  String get apply => 'Apply';

  @override
  String get saleDetails => 'Sale';

  @override
  String get searchSales => 'Invoice no., customer or phone';

  @override
  String get filterSales => 'Filter sales';

  @override
  String get salesEmptyMessage => 'Sales you make will show here.';

  @override
  String get anyDate => 'Any date';

  @override
  String get presetToday => 'Today';

  @override
  String get presetYesterday => 'Yesterday';

  @override
  String get presetThisWeek => 'This week';

  @override
  String get presetThisMonth => 'This month';

  @override
  String get presetLastMonth => 'Last month';

  @override
  String get presetCustom => 'Custom…';

  @override
  String get upcomingDeliveries => 'Upcoming deliveries';

  @override
  String get noUpcomingDeliveries => 'No deliveries pending';

  @override
  String get noUpcomingDeliveriesMessage =>
      'Bookings waiting for delivery will show here.';

  @override
  String get overdue => 'Overdue';

  @override
  String deliverOn(String date) {
    return 'Deliver $date';
  }

  @override
  String get saleDate => 'Sale date';

  @override
  String get deliveryDate => 'Delivery date';

  @override
  String get deliveredOn => 'Delivered on';

  @override
  String createdBy(String name) {
    return 'Entered by $name';
  }

  @override
  String byUser(String name) {
    return 'by $name';
  }

  @override
  String itemsCount(String count) {
    return 'Items ($count)';
  }

  @override
  String paymentsCount(String count) {
    return 'Payments ($count)';
  }

  @override
  String get noPaymentsYet => 'No payment received yet';

  @override
  String get amountSummary => 'Amount';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get transport => 'Transport';

  @override
  String get discount => 'Discount';

  @override
  String get productionCost => 'Production cost';

  @override
  String get profit => 'Profit';

  @override
  String get methodCash => 'Cash';

  @override
  String get methodUpi => 'UPI';

  @override
  String get methodBank => 'Bank';

  @override
  String get methodCheque => 'Cheque';

  @override
  String get methodOther => 'Other';

  @override
  String get ok => 'OK';

  @override
  String get discard => 'Discard';

  @override
  String get keepEditing => 'Keep editing';

  @override
  String get amount => 'Amount';

  @override
  String get amountOptional => 'Amount (optional)';

  @override
  String dueAmount(String amount) {
    return 'Due $amount';
  }

  @override
  String get invalidQuantity => 'Enter a quantity more than 0';

  @override
  String get newSale => 'New sale';

  @override
  String get newBooking => 'New booking';

  @override
  String get editSale => 'Edit sale';

  @override
  String get saveSale => 'Save sale';

  @override
  String get instantHint => 'Goods leave the factory today.';

  @override
  String get bookingHint =>
      'Order now, deliver on a later date. You can take an advance.';

  @override
  String get selectCustomer => 'Select customer';

  @override
  String get selectCustomerError => 'Select a customer or add a new one';

  @override
  String get newCustomer => 'New customer';

  @override
  String get pickExistingCustomer => 'Pick an existing customer instead';

  @override
  String get useThisCustomer => 'Use this customer';

  @override
  String get deliveryAddressOptional => 'Delivery address (optional)';

  @override
  String get selectProduct => 'Select product';

  @override
  String get selectProductError => 'Select a product';

  @override
  String get addItem => 'Add item';

  @override
  String get removeItem => 'Remove item';

  @override
  String get quantity => 'Quantity';

  @override
  String get unitPriceLabel => 'Price / unit';

  @override
  String get unitCostLabel => 'Cost / unit';

  @override
  String get lineTotal => 'Line total';

  @override
  String get discountTooHigh => 'Cannot be more than subtotal + transport';

  @override
  String get alreadyPaid => 'Already paid';

  @override
  String get paymentReceived => 'Payment received now';

  @override
  String get advanceReceived => 'Advance received';

  @override
  String get paymentNoteOptional => 'Payment note (optional)';

  @override
  String cannotExceedTotal(String amount) {
    return 'Cannot be more than total $amount';
  }

  @override
  String get saleNotesHint => 'e.g. Deliver before noon';

  @override
  String get discardSaleTitle => 'Discard this sale?';

  @override
  String get discardChangesTitle => 'Discard your changes?';

  @override
  String get discardSaleMessage => 'What you entered will be lost.';

  @override
  String get addPayment => 'Add payment';

  @override
  String get paymentDate => 'Payment date';

  @override
  String cannotExceedDue(String amount) {
    return 'Cannot be more than the due $amount';
  }

  @override
  String get paymentActions => 'Payment actions';

  @override
  String get deletePayment => 'Delete payment';

  @override
  String deletePaymentTitle(String amount) {
    return 'Delete payment of $amount?';
  }

  @override
  String get deletePaymentMessage => 'The due amount goes up again.';

  @override
  String get markDelivered => 'Mark delivered';

  @override
  String markDeliveredTitle(String invoice) {
    return 'Deliver $invoice';
  }

  @override
  String get cancelBooking => 'Cancel booking';

  @override
  String get keepBooking => 'Keep booking';

  @override
  String cancelBookingTitle(String invoice) {
    return 'Cancel $invoice?';
  }

  @override
  String get cancelBookingMessage =>
      'The booking stays in the list as Cancelled and is left out of totals.';

  @override
  String get removePaymentsFirst =>
      'This booking has payments. Delete them first (refund the money), then cancel.';

  @override
  String get deleteSale => 'Delete sale';

  @override
  String deleteSaleTitle(String invoice) {
    return 'Delete $invoice?';
  }

  @override
  String get deleteSaleMessage =>
      'It will be removed from all lists and reports.';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Next';

  @override
  String get today => 'Today';

  @override
  String get phoneOptional => 'Phone (optional)';

  @override
  String get addLabour => 'Add labour';

  @override
  String get editLabour => 'Edit labour';

  @override
  String get labourDetails => 'Labour';

  @override
  String get laboursEmptyTitle => 'No labours yet';

  @override
  String get laboursEmptyMessage =>
      'Add the people who work at the factory with their daily or monthly wage.';

  @override
  String get labourCreated => 'Labour added';

  @override
  String get labourUpdated => 'Labour updated';

  @override
  String get wage => 'Wage';

  @override
  String get wageDaily => 'Daily';

  @override
  String get wageMonthly => 'Monthly';

  @override
  String get wagePerDay => 'Wage per day';

  @override
  String get wagePerMonth => 'Wage per month';

  @override
  String get dailyWageHint => 'Paid for each day present; half for a half day.';

  @override
  String get monthlyWageHint =>
      'Divided by the days in the month, then counted per day present.';

  @override
  String get wageChangeHint =>
      'The new wage applies to attendance saved from now on. Past days keep their wage.';

  @override
  String perDay(String amount) {
    return '$amount / day';
  }

  @override
  String perMonth(String amount) {
    return '$amount / month';
  }

  @override
  String get joiningDate => 'Joining date';

  @override
  String get leavingDate => 'Leaving date';

  @override
  String get joined => 'Joined';

  @override
  String get attendanceThisMonth => 'Attendance';

  @override
  String activateLabourTitle(String name) {
    return 'Activate $name?';
  }

  @override
  String get activateLabourMessage =>
      'They will show on the attendance sheet again.';

  @override
  String deactivateLabourTitle(String name) {
    return '$name left?';
  }

  @override
  String get deactivateLabourMessage =>
      'Choose the last working day. After it they are not on the attendance sheet. Their wages stay.';

  @override
  String get wkMon => 'Mon';

  @override
  String get wkTue => 'Tue';

  @override
  String get wkWed => 'Wed';

  @override
  String get wkThu => 'Thu';

  @override
  String get wkFri => 'Fri';

  @override
  String get wkSat => 'Sat';

  @override
  String get wkSun => 'Sun';

  @override
  String get attPresent => 'Present';

  @override
  String get attHalfDay => 'Half day';

  @override
  String get attAbsent => 'Absent';

  @override
  String get attNotMarked => 'Not marked';

  @override
  String get attPresentShort => 'P';

  @override
  String get attHalfDayShort => 'H';

  @override
  String get attAbsentShort => 'A';

  @override
  String get markAllPresent => 'Mark all present';

  @override
  String get saveAttendance => 'Save attendance';

  @override
  String get noChanges => 'No changes';

  @override
  String changesCount(String count) {
    return '$count changed';
  }

  @override
  String attendanceSaved(String date) {
    return 'Attendance saved for $date';
  }

  @override
  String saveChangesFor(String date) {
    return 'Save changes for $date?';
  }

  @override
  String unsavedAttendance(String count) {
    return '$count labours changed and not saved yet.';
  }

  @override
  String todayWithDate(String date) {
    return 'Today, $date';
  }

  @override
  String yesterdayWithDate(String date) {
    return 'Yesterday, $date';
  }

  @override
  String get noLaboursOnDate => 'No labours on this date';

  @override
  String get noLaboursOnDateMessage =>
      'Only labours who had joined and not left on this date are listed.';

  @override
  String get days => 'Days';

  @override
  String get earned => 'Earned';

  @override
  String get advances => 'Advances';

  @override
  String get balance => 'Balance';

  @override
  String daysWorked(String count) {
    return '$count days';
  }

  @override
  String earnedAmount(String amount) {
    return 'earned $amount';
  }

  @override
  String earnedInMonth(String month) {
    return 'Earned in $month';
  }

  @override
  String balanceAmount(String amount) {
    return 'Balance $amount';
  }

  @override
  String get searchLabour => 'Search labour';

  @override
  String get noWagesThisMonth => 'No wages this month';

  @override
  String get noWagesThisMonthMessage =>
      'Labours employed in this month and their attendance make the wage sheet.';

  @override
  String get wageDetails => 'Wage';

  @override
  String get wageBreakdown => 'Wage for the month';

  @override
  String workedDaysLine(String present, String half, String absent) {
    return 'Worked (P $present · H $half · A $absent)';
  }

  @override
  String get payWage => 'Pay wage';

  @override
  String payWageTitle(String name, String month) {
    return 'Pay $name for $month';
  }

  @override
  String get giveAdvance => 'Give advance';

  @override
  String giveAdvanceTo(String name) {
    return 'Advance to $name';
  }

  @override
  String get advanceHint =>
      'It is taken off the wage of the month of its date.';

  @override
  String advancesCount(String count) {
    return 'Advances ($count)';
  }

  @override
  String get noAdvances => 'No advance this month';

  @override
  String get noWagePayments => 'Nothing paid for this month yet';

  @override
  String get deleteAdvance => 'Delete advance';

  @override
  String deleteAdvanceTitle(String amount) {
    return 'Delete advance of $amount?';
  }

  @override
  String get balanceRecalculated => 'The balance is worked out again.';

  @override
  String get dayByDay => 'Day by day';

  @override
  String get wageThisMonth => 'Wage this month';

  @override
  String get advanceOrPay => 'Advance / pay';

  @override
  String get note => 'Note';

  @override
  String get category => 'Category';

  @override
  String get icon => 'Icon';

  @override
  String get enteredByColumn => 'Entered by';

  @override
  String get addExpense => 'Add expense';

  @override
  String get editExpense => 'Edit expense';

  @override
  String spentIn(String period) {
    return 'Spent: $period';
  }

  @override
  String get allCategories => 'All';

  @override
  String get searchNote => 'Search notes';

  @override
  String get noExpenses => 'No expenses in this period';

  @override
  String get noExpensesMessage =>
      'Record tiffin, repairs, diesel, electricity and other costs here.';

  @override
  String get expenseNoteHint => 'e.g. Tiffin for 15 labours';

  @override
  String get selectCategory => 'Select category';

  @override
  String get selectCategoryError => 'Select a category';

  @override
  String get newCategory => 'New category';

  @override
  String get editCategory => 'Edit category';

  @override
  String get manageCategories => 'Manage categories';

  @override
  String get categoryNameHint => 'e.g. Gate pass';

  @override
  String get inactiveCategoryHint =>
      'Turn off to hide it from new expenses. Old expenses keep it.';

  @override
  String get categoriesHint =>
      'Categories are never deleted. Turn one off to hide it from new expenses.';

  @override
  String get categoryCreated => 'Category added';

  @override
  String get categoryUpdated => 'Category updated';

  @override
  String get deleteExpenseTitle => 'Delete this expense?';

  @override
  String get deleteExpenseMessage =>
      'It is removed from the totals and reports.';

  @override
  String get totalDue => 'Total due';

  @override
  String get deliveriesToday => 'Deliveries today';

  @override
  String deliveriesTodayOverdue(String count) {
    return 'Deliveries · $count late';
  }

  @override
  String get presentToday => 'Present today';

  @override
  String get monthExpenses => 'Month expenses';

  @override
  String get quickActions => 'Quick actions';

  @override
  String get recentSales => 'Recent sales';

  @override
  String get viewAll => 'View all';

  @override
  String get todaysSales => 'Today\'s sales';

  @override
  String todaysSalesCaption(String count, String profit) {
    return '$count sales · profit $profit';
  }

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';
}
