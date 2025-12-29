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

  @override
  String get departmentTitle => 'Departments';

  @override
  String get deptName => 'Department Name';

  @override
  String get deptDesc => 'Description';

  @override
  String get searchDept => 'Search Department...';

  @override
  String get addDept => 'Add Department';

  @override
  String get editDept => 'Edit Department';

  @override
  String get deleteDept => 'Delete Department';

  @override
  String confirmDelete(Object name) {
    return 'Are you sure you want to delete $name?';
  }

  @override
  String get employeeTitle => 'Employees';

  @override
  String get fullName => 'Full Name';

  @override
  String get email => 'Email';

  @override
  String get phone => 'Phone';

  @override
  String get address => 'Address';

  @override
  String get position => 'Position';

  @override
  String get department => 'Department';

  @override
  String get note => 'Note';

  @override
  String get searchEmployee => 'Search employee...';

  @override
  String get addEmployee => 'Add Employee';

  @override
  String get editEmployee => 'Edit Employee';

  @override
  String get deleteEmployee => 'Delete Employee';

  @override
  String confirmDeleteEmployee(Object name) {
    return 'Delete employee $name?';
  }

  @override
  String get selectDept => 'Select Department';

  @override
  String get totalDepartments => 'Total Departments';

  @override
  String get status => 'Status';

  @override
  String get active => 'Active';

  @override
  String get members => 'Members';

  @override
  String get supplierTitle => 'Suppliers';

  @override
  String get supplierName => 'Supplier Name';

  @override
  String get searchSupplier => 'Search supplier...';

  @override
  String get addSupplier => 'Add Supplier';

  @override
  String get editSupplier => 'Edit Supplier';

  @override
  String get deleteSupplier => 'Delete Supplier';

  @override
  String confirmDeleteSupplier(Object name) {
    return 'Are you sure you want to delete $name?';
  }

  @override
  String get contact => 'Contact';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get actions => 'Actions';

  @override
  String get successAdded => 'Added successfully';

  @override
  String get successUpdated => 'Updated successfully';

  @override
  String get successDeleted => 'Deleted successfully';

  @override
  String get yarnTitle => 'Yarn Inventory';

  @override
  String get yarnName => 'Yarn';

  @override
  String get itemCode => 'Item Code';

  @override
  String get yarnType => 'Type';

  @override
  String get color => 'Color';

  @override
  String get origin => 'Origin';

  @override
  String get supplier => 'Supplier';

  @override
  String get searchYarn => 'Search yarn (name, code)...';

  @override
  String get addYarn => 'Add Yarn';

  @override
  String get editYarn => 'Edit Yarn';

  @override
  String get deleteYarn => 'Delete Yarn';

  @override
  String confirmDeleteYarn(Object name) {
    return 'Delete yarn $name?';
  }

  @override
  String get selectSupplier => 'Select Supplier';

  @override
  String get noYarnFound => 'No yarn items found';

  @override
  String get yarnLotTitle => 'Yarn Lots';

  @override
  String get lotCode => 'Lot Code';

  @override
  String get importDate => 'Import Date';

  @override
  String get totalKg => 'Total (kg)';

  @override
  String get rollCount => 'Rolls';

  @override
  String get warehouseLoc => 'Location';

  @override
  String get containerCode => 'Container';

  @override
  String get driver => 'Driver';

  @override
  String get receiver => 'Receiver';

  @override
  String get searchYarnLot => 'Search lot code...';

  @override
  String get addYarnLot => 'Add Yarn Lot';

  @override
  String get editYarnLot => 'Edit Yarn Lot';

  @override
  String get deleteYarnLot => 'Delete Yarn Lot';

  @override
  String confirmDeleteYarnLot(Object code) {
    return 'Delete yarn lot $code?';
  }

  @override
  String get selectYarn => 'Select Yarn';

  @override
  String get selectEmployee => 'Select Employee';

  @override
  String get materialTitle => 'Materials';

  @override
  String get materialName => 'Material Name';

  @override
  String get quantity => 'Quantity';

  @override
  String get unit => 'Unit';

  @override
  String get importedBy => 'Imported By';

  @override
  String get searchMaterial => 'Search material...';

  @override
  String get addMaterial => 'Add Material';

  @override
  String get editMaterial => 'Edit Material';

  @override
  String get deleteMaterial => 'Delete Material';

  @override
  String confirmDeleteMaterial(Object name) {
    return 'Delete material $name?';
  }

  @override
  String get noMaterialFound => 'No materials found';

  @override
  String get selectImporter => 'Select Importer';

  @override
  String get selectUnit => 'Select Unit';

  @override
  String get unitTitle => 'Units of Measurement';

  @override
  String get unitName => 'Unit Name';

  @override
  String get searchUnit => 'Search unit...';

  @override
  String get addUnit => 'Add Unit';

  @override
  String get editUnit => 'Edit Unit';

  @override
  String get deleteUnit => 'Delete Unit';

  @override
  String confirmDeleteUnit(Object name) {
    return 'Delete unit $name?';
  }

  @override
  String get noUnitFound => 'No units found';
}
