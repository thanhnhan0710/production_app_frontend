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
  /// **'Yarn Name'**
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

  /// No description provided for @machineTitle.
  ///
  /// In en, this message translates to:
  /// **'Machines'**
  String get machineTitle;

  /// No description provided for @machineName.
  ///
  /// In en, this message translates to:
  /// **'Machine Name'**
  String get machineName;

  /// No description provided for @totalLines.
  ///
  /// In en, this message translates to:
  /// **'Total Lines'**
  String get totalLines;

  /// No description provided for @purpose.
  ///
  /// In en, this message translates to:
  /// **'Purpose'**
  String get purpose;

  /// No description provided for @searchMachine.
  ///
  /// In en, this message translates to:
  /// **'Search machine...'**
  String get searchMachine;

  /// No description provided for @addMachine.
  ///
  /// In en, this message translates to:
  /// **'Add Machine'**
  String get addMachine;

  /// No description provided for @editMachine.
  ///
  /// In en, this message translates to:
  /// **'Edit Machine'**
  String get editMachine;

  /// No description provided for @deleteMachine.
  ///
  /// In en, this message translates to:
  /// **'Delete Machine'**
  String get deleteMachine;

  /// No description provided for @confirmDeleteMachine.
  ///
  /// In en, this message translates to:
  /// **'Delete machine {name}?'**
  String confirmDeleteMachine(Object name);

  /// No description provided for @noMachineFound.
  ///
  /// In en, this message translates to:
  /// **'No machines found'**
  String get noMachineFound;

  /// No description provided for @running.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get running;

  /// No description provided for @stopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get stopped;

  /// No description provided for @maintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenance;

  /// No description provided for @shiftTitle.
  ///
  /// In en, this message translates to:
  /// **'Work Shifts'**
  String get shiftTitle;

  /// No description provided for @shiftName.
  ///
  /// In en, this message translates to:
  /// **'Shift Name'**
  String get shiftName;

  /// No description provided for @searchShift.
  ///
  /// In en, this message translates to:
  /// **'Search shift...'**
  String get searchShift;

  /// No description provided for @addShift.
  ///
  /// In en, this message translates to:
  /// **'Add Shift'**
  String get addShift;

  /// No description provided for @editShift.
  ///
  /// In en, this message translates to:
  /// **'Edit Shift'**
  String get editShift;

  /// No description provided for @deleteShift.
  ///
  /// In en, this message translates to:
  /// **'Delete Shift'**
  String get deleteShift;

  /// No description provided for @confirmDeleteShift.
  ///
  /// In en, this message translates to:
  /// **'Delete shift {name}?'**
  String confirmDeleteShift(Object name);

  /// No description provided for @noShiftFound.
  ///
  /// In en, this message translates to:
  /// **'No shifts found'**
  String get noShiftFound;

  /// No description provided for @basketTitle.
  ///
  /// In en, this message translates to:
  /// **'Baskets'**
  String get basketTitle;

  /// No description provided for @basketCode.
  ///
  /// In en, this message translates to:
  /// **'Basket Code'**
  String get basketCode;

  /// No description provided for @basketTitleVS2.
  ///
  /// In en, this message translates to:
  /// **'Basket'**
  String get basketTitleVS2;

  /// No description provided for @tareWeight.
  ///
  /// In en, this message translates to:
  /// **'Tare Weight (kg)'**
  String get tareWeight;

  /// No description provided for @searchBasket.
  ///
  /// In en, this message translates to:
  /// **'Search basket...'**
  String get searchBasket;

  /// No description provided for @addBasket.
  ///
  /// In en, this message translates to:
  /// **'Add Basket'**
  String get addBasket;

  /// No description provided for @editBasket.
  ///
  /// In en, this message translates to:
  /// **'Edit Basket'**
  String get editBasket;

  /// No description provided for @deleteBasket.
  ///
  /// In en, this message translates to:
  /// **'Delete Basket'**
  String get deleteBasket;

  /// No description provided for @confirmDeleteBasket.
  ///
  /// In en, this message translates to:
  /// **'Delete basket {code}?'**
  String confirmDeleteBasket(Object code);

  /// No description provided for @noBasketFound.
  ///
  /// In en, this message translates to:
  /// **'No baskets found'**
  String get noBasketFound;

  /// No description provided for @stReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get stReady;

  /// No description provided for @stInUse.
  ///
  /// In en, this message translates to:
  /// **'In Use'**
  String get stInUse;

  /// No description provided for @stHolding.
  ///
  /// In en, this message translates to:
  /// **'Holding'**
  String get stHolding;

  /// No description provided for @stDamaged.
  ///
  /// In en, this message translates to:
  /// **'Damaged'**
  String get stDamaged;

  /// No description provided for @dyeColorTitle.
  ///
  /// In en, this message translates to:
  /// **'Dye Colors'**
  String get dyeColorTitle;

  /// No description provided for @colorName.
  ///
  /// In en, this message translates to:
  /// **'Color Name'**
  String get colorName;

  /// No description provided for @hexCode.
  ///
  /// In en, this message translates to:
  /// **'Hex Code'**
  String get hexCode;

  /// No description provided for @searchColor.
  ///
  /// In en, this message translates to:
  /// **'Search color...'**
  String get searchColor;

  /// No description provided for @addColor.
  ///
  /// In en, this message translates to:
  /// **'Add Color'**
  String get addColor;

  /// No description provided for @editColor.
  ///
  /// In en, this message translates to:
  /// **'Edit Color'**
  String get editColor;

  /// No description provided for @deleteColor.
  ///
  /// In en, this message translates to:
  /// **'Delete Color'**
  String get deleteColor;

  /// No description provided for @confirmDeleteColor.
  ///
  /// In en, this message translates to:
  /// **'Delete color {name}?'**
  String confirmDeleteColor(Object name);

  /// No description provided for @noColorFound.
  ///
  /// In en, this message translates to:
  /// **'No colors found'**
  String get noColorFound;

  /// No description provided for @invalidHex.
  ///
  /// In en, this message translates to:
  /// **'Invalid Hex Code (e.g., #FF0000)'**
  String get invalidHex;

  /// No description provided for @productTitle.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get productTitle;

  /// No description provided for @productImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get productImage;

  /// No description provided for @searchProduct.
  ///
  /// In en, this message translates to:
  /// **'Search product...'**
  String get searchProduct;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProduct;

  /// No description provided for @editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get editProduct;

  /// No description provided for @deleteProduct.
  ///
  /// In en, this message translates to:
  /// **'Delete Product'**
  String get deleteProduct;

  /// No description provided for @confirmDeleteProduct.
  ///
  /// In en, this message translates to:
  /// **'Delete product {code}?'**
  String confirmDeleteProduct(Object code);

  /// No description provided for @noProductFound.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get noProductFound;

  /// No description provided for @uploadImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Image'**
  String get uploadImage;

  /// No description provided for @standardTitle.
  ///
  /// In en, this message translates to:
  /// **'Standards'**
  String get standardTitle;

  /// No description provided for @standardCode.
  ///
  /// In en, this message translates to:
  /// **'Standard Code'**
  String get standardCode;

  /// No description provided for @product.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get product;

  /// No description provided for @dyeColor.
  ///
  /// In en, this message translates to:
  /// **'Dye Color'**
  String get dyeColor;

  /// No description provided for @width.
  ///
  /// In en, this message translates to:
  /// **'Width (mm)'**
  String get width;

  /// No description provided for @thickness.
  ///
  /// In en, this message translates to:
  /// **'Thickness (mm)'**
  String get thickness;

  /// No description provided for @strength.
  ///
  /// In en, this message translates to:
  /// **'Strength (daN)'**
  String get strength;

  /// No description provided for @elongation.
  ///
  /// In en, this message translates to:
  /// **'Elongation (%)'**
  String get elongation;

  /// No description provided for @colorFastDry.
  ///
  /// In en, this message translates to:
  /// **'Color Fastness (Dry)'**
  String get colorFastDry;

  /// No description provided for @colorFastWet.
  ///
  /// In en, this message translates to:
  /// **'Color Fastness (Wet)'**
  String get colorFastWet;

  /// No description provided for @deltaE.
  ///
  /// In en, this message translates to:
  /// **'Delta E'**
  String get deltaE;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @weftDensity.
  ///
  /// In en, this message translates to:
  /// **'Weft Density (pick/10cm)'**
  String get weftDensity;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight (g/m)'**
  String get weight;

  /// No description provided for @searchStandard.
  ///
  /// In en, this message translates to:
  /// **'Search standard...'**
  String get searchStandard;

  /// No description provided for @addStandard.
  ///
  /// In en, this message translates to:
  /// **'Add Standard'**
  String get addStandard;

  /// No description provided for @editStandard.
  ///
  /// In en, this message translates to:
  /// **'Edit Standard'**
  String get editStandard;

  /// No description provided for @deleteStandard.
  ///
  /// In en, this message translates to:
  /// **'Delete Standard'**
  String get deleteStandard;

  /// No description provided for @confirmDeleteStandard.
  ///
  /// In en, this message translates to:
  /// **'Delete standard {code}?'**
  String confirmDeleteStandard(Object code);

  /// No description provided for @noStandardFound.
  ///
  /// In en, this message translates to:
  /// **'No standards found'**
  String get noStandardFound;

  /// No description provided for @specs.
  ///
  /// In en, this message translates to:
  /// **'Specifications'**
  String get specs;

  /// No description provided for @scheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Work Schedules'**
  String get scheduleTitle;

  /// No description provided for @workDate.
  ///
  /// In en, this message translates to:
  /// **'Work Date'**
  String get workDate;

  /// No description provided for @employee.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get employee;

  /// No description provided for @shift.
  ///
  /// In en, this message translates to:
  /// **'Shift'**
  String get shift;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTime;

  /// No description provided for @searchSchedule.
  ///
  /// In en, this message translates to:
  /// **'Search schedule...'**
  String get searchSchedule;

  /// No description provided for @addSchedule.
  ///
  /// In en, this message translates to:
  /// **'Assign Schedule'**
  String get addSchedule;

  /// No description provided for @editSchedule.
  ///
  /// In en, this message translates to:
  /// **'Edit Schedule'**
  String get editSchedule;

  /// No description provided for @deleteSchedule.
  ///
  /// In en, this message translates to:
  /// **'Delete Schedule'**
  String get deleteSchedule;

  /// No description provided for @confirmDeleteSchedule.
  ///
  /// In en, this message translates to:
  /// **'Delete schedule for {name} on {date}?'**
  String confirmDeleteSchedule(Object date, Object name);

  /// No description provided for @noScheduleFound.
  ///
  /// In en, this message translates to:
  /// **'No schedules found'**
  String get noScheduleFound;

  /// No description provided for @filterDate.
  ///
  /// In en, this message translates to:
  /// **'Filter by Date'**
  String get filterDate;

  /// No description provided for @errorDuplicateSchedule.
  ///
  /// In en, this message translates to:
  /// **'Conflict: This employee already has a shift on this date.'**
  String get errorDuplicateSchedule;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred'**
  String get errorUnknown;

  /// No description provided for @weavingTicketTitle.
  ///
  /// In en, this message translates to:
  /// **'Weaving Tickets'**
  String get weavingTicketTitle;

  /// No description provided for @ticketCode.
  ///
  /// In en, this message translates to:
  /// **'Ticket Code'**
  String get ticketCode;

  /// No description provided for @loadDate.
  ///
  /// In en, this message translates to:
  /// **'Load date'**
  String get loadDate;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @timeIn.
  ///
  /// In en, this message translates to:
  /// **'Time In'**
  String get timeIn;

  /// No description provided for @empIn.
  ///
  /// In en, this message translates to:
  /// **'Emp In'**
  String get empIn;

  /// No description provided for @timeOut.
  ///
  /// In en, this message translates to:
  /// **'Time Out'**
  String get timeOut;

  /// No description provided for @empOut.
  ///
  /// In en, this message translates to:
  /// **'Emp Out'**
  String get empOut;

  /// No description provided for @tage.
  ///
  /// In en, this message translates to:
  /// **'Tage weight'**
  String get tage;

  /// No description provided for @machineInfo.
  ///
  /// In en, this message translates to:
  /// **'Machine / Line'**
  String get machineInfo;

  /// No description provided for @yarnInfo.
  ///
  /// In en, this message translates to:
  /// **'Yarn Lot / Date'**
  String get yarnInfo;

  /// No description provided for @standardData.
  ///
  /// In en, this message translates to:
  /// **'Standard Specifications'**
  String get standardData;

  /// No description provided for @weightInfo.
  ///
  /// In en, this message translates to:
  /// **'Gross / Net / Tare'**
  String get weightInfo;

  /// No description provided for @lengthKnots.
  ///
  /// In en, this message translates to:
  /// **'Length (m) / Knots'**
  String get lengthKnots;

  /// No description provided for @employees.
  ///
  /// In en, this message translates to:
  /// **'Operators'**
  String get employees;

  /// No description provided for @timeInOut.
  ///
  /// In en, this message translates to:
  /// **'Time In / Out'**
  String get timeInOut;

  /// No description provided for @inspections.
  ///
  /// In en, this message translates to:
  /// **'QC Inspections'**
  String get inspections;

  /// No description provided for @addTicket.
  ///
  /// In en, this message translates to:
  /// **'New Ticket'**
  String get addTicket;

  /// No description provided for @stageName.
  ///
  /// In en, this message translates to:
  /// **'Stage'**
  String get stageName;

  /// No description provided for @gross.
  ///
  /// In en, this message translates to:
  /// **'Gross Weight'**
  String get gross;

  /// No description provided for @density.
  ///
  /// In en, this message translates to:
  /// **'Density'**
  String get density;

  /// No description provided for @tension.
  ///
  /// In en, this message translates to:
  /// **'Tension'**
  String get tension;

  /// No description provided for @bowing.
  ///
  /// In en, this message translates to:
  /// **'Bowing'**
  String get bowing;

  /// No description provided for @inspector.
  ///
  /// In en, this message translates to:
  /// **'Inspector'**
  String get inspector;

  /// No description provided for @noTicketSelected.
  ///
  /// In en, this message translates to:
  /// **'Select a ticket to view details'**
  String get noTicketSelected;

  /// No description provided for @deleteTicket.
  ///
  /// In en, this message translates to:
  /// **'Delete Ticket'**
  String get deleteTicket;

  /// No description provided for @confirmDeleteTicket.
  ///
  /// In en, this message translates to:
  /// **'Delete ticket {code}?'**
  String confirmDeleteTicket(Object code);

  /// No description provided for @deleteInspection.
  ///
  /// In en, this message translates to:
  /// **'Delete Inspection'**
  String get deleteInspection;

  /// No description provided for @machineAndMaterial.
  ///
  /// In en, this message translates to:
  /// **'Machine & Material'**
  String get machineAndMaterial;

  /// No description provided for @generalInfo.
  ///
  /// In en, this message translates to:
  /// **'General Info'**
  String get generalInfo;

  /// No description provided for @personnel.
  ///
  /// In en, this message translates to:
  /// **'Personnel'**
  String get personnel;

  /// No description provided for @resultsUpdateOnly.
  ///
  /// In en, this message translates to:
  /// **'Results (Update Only)'**
  String get resultsUpdateOnly;

  /// No description provided for @machineOperation.
  ///
  /// In en, this message translates to:
  /// **'Machine Operation'**
  String get machineOperation;

  /// No description provided for @selectProductBefore.
  ///
  /// In en, this message translates to:
  /// **'Select the product first'**
  String get selectProductBefore;

  /// No description provided for @line.
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get line;

  /// No description provided for @assignBasket.
  ///
  /// In en, this message translates to:
  /// **'Assign Basket'**
  String get assignBasket;

  /// No description provided for @selectBasket.
  ///
  /// In en, this message translates to:
  /// **'Select Ready Basket'**
  String get selectBasket;

  /// No description provided for @scanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan Barcode / Input Code'**
  String get scanBarcode;

  /// No description provided for @scanBarcodeSubline.
  ///
  /// In en, this message translates to:
  /// **'Scan the basket code here to select your own items'**
  String get scanBarcodeSubline;

  /// No description provided for @addInspection.
  ///
  /// In en, this message translates to:
  /// **'Add QC'**
  String get addInspection;

  /// No description provided for @viewTicket.
  ///
  /// In en, this message translates to:
  /// **'View Ticket'**
  String get viewTicket;

  /// No description provided for @editTicket.
  ///
  /// In en, this message translates to:
  /// **'Edit ticket'**
  String get editTicket;

  /// No description provided for @currentBasket.
  ///
  /// In en, this message translates to:
  /// **'Current Basket'**
  String get currentBasket;

  /// No description provided for @noActiveBasket.
  ///
  /// In en, this message translates to:
  /// **'No active basket'**
  String get noActiveBasket;

  /// No description provided for @confirmRelease.
  ///
  /// In en, this message translates to:
  /// **'Finish this ticket and release basket?'**
  String get confirmRelease;

  /// No description provided for @basketAssigned.
  ///
  /// In en, this message translates to:
  /// **'Basket assigned successfully'**
  String get basketAssigned;

  /// No description provided for @releaseBasket.
  ///
  /// In en, this message translates to:
  /// **'Release Basket / Finish Ticket'**
  String get releaseBasket;

  /// No description provided for @finishTicket.
  ///
  /// In en, this message translates to:
  /// **'Finish Ticket'**
  String get finishTicket;

  /// No description provided for @grossWeight.
  ///
  /// In en, this message translates to:
  /// **'Gross Weight (kg)'**
  String get grossWeight;

  /// No description provided for @netWeight.
  ///
  /// In en, this message translates to:
  /// **'Net Weight (kg)'**
  String get netWeight;

  /// No description provided for @length.
  ///
  /// In en, this message translates to:
  /// **'Length (m)'**
  String get length;

  /// No description provided for @knots.
  ///
  /// In en, this message translates to:
  /// **'Knots'**
  String get knots;

  /// No description provided for @bow.
  ///
  /// In en, this message translates to:
  /// **'Bow'**
  String get bow;

  /// No description provided for @employeeOut.
  ///
  /// In en, this message translates to:
  /// **'Receiver / Operator Out'**
  String get employeeOut;

  /// No description provided for @ticketDetails.
  ///
  /// In en, this message translates to:
  /// **'Ticket Details'**
  String get ticketDetails;

  /// No description provided for @inspectionHistory.
  ///
  /// In en, this message translates to:
  /// **'Inspection History'**
  String get inspectionHistory;

  /// No description provided for @newInspection.
  ///
  /// In en, this message translates to:
  /// **'New Inspection'**
  String get newInspection;

  /// No description provided for @confirmReleaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Finish'**
  String get confirmReleaseTitle;

  /// No description provided for @confirmReleaseMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to finish this ticket and release the basket?'**
  String get confirmReleaseMsg;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @saveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully'**
  String get saveSuccess;

  /// No description provided for @noTicketsFoundForThisDate.
  ///
  /// In en, this message translates to:
  /// **'No tickets found for this date'**
  String get noTicketsFoundForThisDate;

  /// No description provided for @noBasket.
  ///
  /// In en, this message translates to:
  /// **'No Basket'**
  String get noBasket;

  /// No description provided for @productionInfo.
  ///
  /// In en, this message translates to:
  /// **'Production Info'**
  String get productionInfo;

  /// No description provided for @timeAndPersonnel.
  ///
  /// In en, this message translates to:
  /// **'Time & Personnel'**
  String get timeAndPersonnel;

  /// No description provided for @output.
  ///
  /// In en, this message translates to:
  /// **'Output'**
  String get output;

  /// No description provided for @noInspectionsRecorded.
  ///
  /// In en, this message translates to:
  /// **'No inspections recorded'**
  String get noInspectionsRecorded;

  /// No description provided for @inspection.
  ///
  /// In en, this message translates to:
  /// **'Inspection'**
  String get inspection;

  /// No description provided for @measurements.
  ///
  /// In en, this message translates to:
  /// **'Measurements'**
  String get measurements;

  /// No description provided for @userManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get userManagementTitle;

  /// No description provided for @searchUser.
  ///
  /// In en, this message translates to:
  /// **'Search users (name, email)...'**
  String get searchUser;

  /// No description provided for @noUserFound.
  ///
  /// In en, this message translates to:
  /// **'No users found.'**
  String get noUserFound;

  /// No description provided for @lastLogin.
  ///
  /// In en, this message translates to:
  /// **'Last Login'**
  String get lastLogin;

  /// No description provided for @notLinked.
  ///
  /// In en, this message translates to:
  /// **'Not Linked'**
  String get notLinked;

  /// No description provided for @superuser.
  ///
  /// In en, this message translates to:
  /// **'SUPERUSER'**
  String get superuser;

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

  /// No description provided for @addUser.
  ///
  /// In en, this message translates to:
  /// **'Add User'**
  String get addUser;

  /// No description provided for @editUser.
  ///
  /// In en, this message translates to:
  /// **'Edit User'**
  String get editUser;

  /// No description provided for @addNewUser.
  ///
  /// In en, this message translates to:
  /// **'Add New User'**
  String get addNewUser;

  /// No description provided for @linkToEmployee.
  ///
  /// In en, this message translates to:
  /// **'Link to Employee'**
  String get linkToEmployee;

  /// No description provided for @linkEmployeeHelper.
  ///
  /// In en, this message translates to:
  /// **'Select an employee to link with this account'**
  String get linkEmployeeHelper;

  /// No description provided for @noEmployeeLinkedOption.
  ///
  /// In en, this message translates to:
  /// **'--- No Employee Linked ---'**
  String get noEmployeeLinkedOption;

  /// No description provided for @passwordRequiredNew.
  ///
  /// In en, this message translates to:
  /// **'Required for new user'**
  String get passwordRequiredNew;

  /// No description provided for @newPasswordPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'New Password (Leave blank to keep)'**
  String get newPasswordPlaceholder;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @isActiveSwitch.
  ///
  /// In en, this message translates to:
  /// **'Is Active'**
  String get isActiveSwitch;

  /// No description provided for @isSuperuserSwitch.
  ///
  /// In en, this message translates to:
  /// **'Is Superuser'**
  String get isSuperuserSwitch;

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDeleteTitle;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @confirmDeleteUserMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}?'**
  String confirmDeleteUserMsg(Object name);
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
