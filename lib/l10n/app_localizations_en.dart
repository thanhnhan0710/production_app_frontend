// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get loginTitle => 'Login';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get btnLogin => 'LOGIN';

  @override
  String welcome(String name) {
    return 'Welcome $name';
  }

  @override
  String get companyName => 'OPPERMANN VIETNAM CO., LTD.';

  @override
  String get erpSystemName => 'Enterprise Resource Planning System';

  @override
  String get loginSystemHeader => 'Login System';

  @override
  String get loginSubtitle => 'Sign in to continue to ERP System';

  @override
  String get copyright => '© 2026 Oppermann Vietnam';

  @override
  String get errorRequired => 'This field is required';

  @override
  String get errorLoginFailed => 'Login failed. Please check your credentials.';

  @override
  String get errorNetwork => 'Network error. Please check your connection.';

  @override
  String get errorGeneric => 'A system error occurred.';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get production => 'Production';

  @override
  String get inventory => 'Inventory';

  @override
  String get sales => 'Sales';

  @override
  String get hr => 'Human Resources';

  @override
  String get reports => 'Reports';

  @override
  String get settings => 'Settings';

  @override
  String get logout => 'Logout';

  @override
  String get totalOrders => 'Total Orders';

  @override
  String get activePlans => 'Active Plans';

  @override
  String get lowStock => 'Low Stock Items';

  @override
  String get revenue => 'Revenue';

  @override
  String get recentActivities => 'Recent Activities';

  @override
  String get viewAll => 'View All';
}
