import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('en'),
    Locale('vi')
  ];

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @btnLogin.
  ///
  /// In en, this message translates to:
  /// **'LOGIN'**
  String get btnLogin;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome {name}'**
  String welcome(String name);

  /// No description provided for @companyName.
  ///
  /// In en, this message translates to:
  /// **'OPPERMANN VIETNAM CO., LTD.'**
  String get companyName;

  /// No description provided for @erpSystemName.
  ///
  /// In en, this message translates to:
  /// **'Enterprise Resource Planning System'**
  String get erpSystemName;

  /// No description provided for @loginSystemHeader.
  ///
  /// In en, this message translates to:
  /// **'Login System'**
  String get loginSystemHeader;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue to ERP System'**
  String get loginSubtitle;

  /// No description provided for @copyright.
  ///
  /// In en, this message translates to:
  /// **'© 2026 Oppermann Vietnam'**
  String get copyright;

  /// No description provided for @errorRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get errorRequired;

  /// No description provided for @errorLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please check your credentials.'**
  String get errorLoginFailed;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get errorNetwork;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'A system error occurred.'**
  String get errorGeneric;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @production.
  ///
  /// In en, this message translates to:
  /// **'Production'**
  String get production;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// No description provided for @sales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get sales;

  /// No description provided for @hr.
  ///
  /// In en, this message translates to:
  /// **'Human Resources'**
  String get hr;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @totalOrders.
  ///
  /// In en, this message translates to:
  /// **'Total Orders'**
  String get totalOrders;

  /// No description provided for @activePlans.
  ///
  /// In en, this message translates to:
  /// **'Active Plans'**
  String get activePlans;

  /// No description provided for @lowStock.
  ///
  /// In en, this message translates to:
  /// **'Low Stock Items'**
  String get lowStock;

  /// No description provided for @revenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenue;

  /// No description provided for @recentActivities.
  ///
  /// In en, this message translates to:
  /// **'Recent Activities'**
  String get recentActivities;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @departmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Departments'**
  String get departmentTitle;

  /// No description provided for @deptName.
  ///
  /// In en, this message translates to:
  /// **'Department Name'**
  String get deptName;

  /// No description provided for @deptDesc.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get deptDesc;

  /// No description provided for @searchDept.
  ///
  /// In en, this message translates to:
  /// **'Search Department...'**
  String get searchDept;

  /// No description provided for @addDept.
  ///
  /// In en, this message translates to:
  /// **'Add Department'**
  String get addDept;

  /// No description provided for @editDept.
  ///
  /// In en, this message translates to:
  /// **'Edit Department'**
  String get editDept;

  /// No description provided for @deleteDept.
  ///
  /// In en, this message translates to:
  /// **'Delete Department'**
  String get deleteDept;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}?'**
  String confirmDelete(Object name);

  /// No description provided for @employeeTitle.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get employeeTitle;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @position.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get position;

  /// No description provided for @department.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get department;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @searchEmployee.
  ///
  /// In en, this message translates to:
  /// **'Search employee...'**
  String get searchEmployee;

  /// No description provided for @addEmployee.
  ///
  /// In en, this message translates to:
  /// **'Add Employee'**
  String get addEmployee;

  /// No description provided for @editEmployee.
  ///
  /// In en, this message translates to:
  /// **'Edit Employee'**
  String get editEmployee;

  /// No description provided for @deleteEmployee.
  ///
  /// In en, this message translates to:
  /// **'Delete Employee'**
  String get deleteEmployee;

  /// No description provided for @confirmDeleteEmployee.
  ///
  /// In en, this message translates to:
  /// **'Delete employee {name}?'**
  String confirmDeleteEmployee(Object name);

  /// No description provided for @selectDept.
  ///
  /// In en, this message translates to:
  /// **'Select Department'**
  String get selectDept;

  /// No description provided for @totalDepartments.
  ///
  /// In en, this message translates to:
  /// **'Total Departments'**
  String get totalDepartments;

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

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @supplierTitle.
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get supplierTitle;

  /// No description provided for @supplierName.
  ///
  /// In en, this message translates to:
  /// **'Supplier Name'**
  String get supplierName;

  /// No description provided for @searchSupplier.
  ///
  /// In en, this message translates to:
  /// **'Search supplier...'**
  String get searchSupplier;

  /// No description provided for @addSupplier.
  ///
  /// In en, this message translates to:
  /// **'Add Supplier'**
  String get addSupplier;

  /// No description provided for @editSupplier.
  ///
  /// In en, this message translates to:
  /// **'Edit Supplier'**
  String get editSupplier;

  /// No description provided for @deleteSupplier.
  ///
  /// In en, this message translates to:
  /// **'Delete Supplier'**
  String get deleteSupplier;

  /// No description provided for @confirmDeleteSupplier.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}?'**
  String confirmDeleteSupplier(Object name);

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @successAdded.
  ///
  /// In en, this message translates to:
  /// **'Added successfully'**
  String get successAdded;

  /// No description provided for @successUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated successfully'**
  String get successUpdated;

  /// No description provided for @successDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted successfully'**
  String get successDeleted;

  /// No description provided for @yarnTitle.
  ///
  /// In en, this message translates to:
  /// **'Yarn Inventory'**
  String get yarnTitle;

  /// No description provided for @yarnName.
  ///
  /// In en, this message translates to:
  /// **'Yarn'**
  String get yarnName;

  /// No description provided for @itemCode.
  ///
  /// In en, this message translates to:
  /// **'Item Code'**
  String get itemCode;

  /// No description provided for @yarnType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get yarnType;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @origin.
  ///
  /// In en, this message translates to:
  /// **'Origin'**
  String get origin;

  /// No description provided for @supplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get supplier;

  /// No description provided for @searchYarn.
  ///
  /// In en, this message translates to:
  /// **'Search yarn (name, code)...'**
  String get searchYarn;

  /// No description provided for @addYarn.
  ///
  /// In en, this message translates to:
  /// **'Add Yarn'**
  String get addYarn;

  /// No description provided for @editYarn.
  ///
  /// In en, this message translates to:
  /// **'Edit Yarn'**
  String get editYarn;

  /// No description provided for @deleteYarn.
  ///
  /// In en, this message translates to:
  /// **'Delete Yarn'**
  String get deleteYarn;

  /// No description provided for @confirmDeleteYarn.
  ///
  /// In en, this message translates to:
  /// **'Delete yarn {name}?'**
  String confirmDeleteYarn(Object name);

  /// No description provided for @selectSupplier.
  ///
  /// In en, this message translates to:
  /// **'Select Supplier'**
  String get selectSupplier;

  /// No description provided for @noYarnFound.
  ///
  /// In en, this message translates to:
  /// **'No yarn items found'**
  String get noYarnFound;

  /// No description provided for @yarnLotTitle.
  ///
  /// In en, this message translates to:
  /// **'Yarn Lots'**
  String get yarnLotTitle;

  /// No description provided for @lotCode.
  ///
  /// In en, this message translates to:
  /// **'Lot Code'**
  String get lotCode;

  /// No description provided for @importDate.
  ///
  /// In en, this message translates to:
  /// **'Import Date'**
  String get importDate;

  /// No description provided for @totalKg.
  ///
  /// In en, this message translates to:
  /// **'Total (kg)'**
  String get totalKg;

  /// No description provided for @rollCount.
  ///
  /// In en, this message translates to:
  /// **'Rolls'**
  String get rollCount;

  /// No description provided for @warehouseLoc.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get warehouseLoc;

  /// No description provided for @containerCode.
  ///
  /// In en, this message translates to:
  /// **'Container'**
  String get containerCode;

  /// No description provided for @driver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driver;

  /// No description provided for @receiver.
  ///
  /// In en, this message translates to:
  /// **'Receiver'**
  String get receiver;

  /// No description provided for @searchYarnLot.
  ///
  /// In en, this message translates to:
  /// **'Search lot code...'**
  String get searchYarnLot;

  /// No description provided for @addYarnLot.
  ///
  /// In en, this message translates to:
  /// **'Add Yarn Lot'**
  String get addYarnLot;

  /// No description provided for @editYarnLot.
  ///
  /// In en, this message translates to:
  /// **'Edit Yarn Lot'**
  String get editYarnLot;

  /// No description provided for @deleteYarnLot.
  ///
  /// In en, this message translates to:
  /// **'Delete Yarn Lot'**
  String get deleteYarnLot;

  /// No description provided for @confirmDeleteYarnLot.
  ///
  /// In en, this message translates to:
  /// **'Delete yarn lot {code}?'**
  String confirmDeleteYarnLot(Object code);

  /// No description provided for @selectYarn.
  ///
  /// In en, this message translates to:
  /// **'Select Yarn'**
  String get selectYarn;

  /// No description provided for @selectEmployee.
  ///
  /// In en, this message translates to:
  /// **'Select Employee'**
  String get selectEmployee;

  /// No description provided for @materialTitle.
  ///
  /// In en, this message translates to:
  /// **'Materials'**
  String get materialTitle;

  /// No description provided for @materialName.
  ///
  /// In en, this message translates to:
  /// **'Material Name'**
  String get materialName;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @importedBy.
  ///
  /// In en, this message translates to:
  /// **'Imported By'**
  String get importedBy;

  /// No description provided for @searchMaterial.
  ///
  /// In en, this message translates to:
  /// **'Search material...'**
  String get searchMaterial;

  /// No description provided for @addMaterial.
  ///
  /// In en, this message translates to:
  /// **'Add Material'**
  String get addMaterial;

  /// No description provided for @editMaterial.
  ///
  /// In en, this message translates to:
  /// **'Edit Material'**
  String get editMaterial;

  /// No description provided for @deleteMaterial.
  ///
  /// In en, this message translates to:
  /// **'Delete Material'**
  String get deleteMaterial;

  /// No description provided for @confirmDeleteMaterial.
  ///
  /// In en, this message translates to:
  /// **'Delete material {name}?'**
  String confirmDeleteMaterial(Object name);

  /// No description provided for @noMaterialFound.
  ///
  /// In en, this message translates to:
  /// **'No materials found'**
  String get noMaterialFound;

  /// No description provided for @selectImporter.
  ///
  /// In en, this message translates to:
  /// **'Select Importer'**
  String get selectImporter;

  /// No description provided for @selectUnit.
  ///
  /// In en, this message translates to:
  /// **'Select Unit'**
  String get selectUnit;

  /// No description provided for @unitTitle.
  ///
  /// In en, this message translates to:
  /// **'Units of Measurement'**
  String get unitTitle;

  /// No description provided for @unitName.
  ///
  /// In en, this message translates to:
  /// **'Unit Name'**
  String get unitName;

  /// No description provided for @searchUnit.
  ///
  /// In en, this message translates to:
  /// **'Search unit...'**
  String get searchUnit;

  /// No description provided for @addUnit.
  ///
  /// In en, this message translates to:
  /// **'Add Unit'**
  String get addUnit;

  /// No description provided for @editUnit.
  ///
  /// In en, this message translates to:
  /// **'Edit Unit'**
  String get editUnit;

  /// No description provided for @deleteUnit.
  ///
  /// In en, this message translates to:
  /// **'Delete Unit'**
  String get deleteUnit;

  /// No description provided for @confirmDeleteUnit.
  ///
  /// In en, this message translates to:
  /// **'Delete unit {name}?'**
  String confirmDeleteUnit(Object name);

  /// No description provided for @noUnitFound.
  ///
  /// In en, this message translates to:
  /// **'No units found'**
  String get noUnitFound;
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
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
