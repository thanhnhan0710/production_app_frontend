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
  String get yarnName => 'Yarn Name';

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

  @override
  String get machineTitle => 'Machines';

  @override
  String get machineName => 'Machine Name';

  @override
  String get totalLines => 'Total Lines';

  @override
  String get purpose => 'Purpose';

  @override
  String get area => 'AREA';

  @override
  String get searchMachine => 'Search machine...';

  @override
  String get addMachine => 'Add Machine';

  @override
  String get editMachine => 'Edit Machine';

  @override
  String get deleteMachine => 'Delete Machine';

  @override
  String confirmDeleteMachine(Object name) {
    return 'Delete machine $name?';
  }

  @override
  String get noMachineFound => 'No machines found';

  @override
  String get running => 'Running';

  @override
  String get stopped => 'Stopped';

  @override
  String get maintenance => 'Maintenance';

  @override
  String get shiftTitle => 'Work Shifts';

  @override
  String get shiftName => 'Shift Name';

  @override
  String get searchShift => 'Search shift...';

  @override
  String get addShift => 'Add Shift';

  @override
  String get editShift => 'Edit Shift';

  @override
  String get deleteShift => 'Delete Shift';

  @override
  String confirmDeleteShift(Object name) {
    return 'Delete shift $name?';
  }

  @override
  String get noShiftFound => 'No shifts found';

  @override
  String get basketTitle => 'Baskets';

  @override
  String get basketCode => 'Basket Code';

  @override
  String get basketTitleVS2 => 'Basket';

  @override
  String get tareWeight => 'Tare Weight (kg)';

  @override
  String get searchBasket => 'Search basket...';

  @override
  String get addBasket => 'Add Basket';

  @override
  String get editBasket => 'Edit Basket';

  @override
  String get deleteBasket => 'Delete Basket';

  @override
  String confirmDeleteBasket(Object code) {
    return 'Delete basket $code?';
  }

  @override
  String get noBasketFound => 'No baskets found';

  @override
  String get stReady => 'Ready';

  @override
  String get stInUse => 'In Use';

  @override
  String get stHolding => 'Holding';

  @override
  String get stDamaged => 'Damaged';

  @override
  String get dyeColorTitle => 'Dye Colors';

  @override
  String get colorName => 'Color Name';

  @override
  String get hexCode => 'Hex Code';

  @override
  String get searchColor => 'Search color...';

  @override
  String get addColor => 'Add Color';

  @override
  String get editColor => 'Edit Color';

  @override
  String get deleteColor => 'Delete Color';

  @override
  String confirmDeleteColor(Object name) {
    return 'Delete color $name?';
  }

  @override
  String get noColorFound => 'No colors found';

  @override
  String get invalidHex => 'Invalid Hex Code (e.g., #FF0000)';

  @override
  String get productTitle => 'Products';

  @override
  String get productImage => 'Image';

  @override
  String get searchProduct => 'Search product...';

  @override
  String get addProduct => 'Add Product';

  @override
  String get editProduct => 'Edit Product';

  @override
  String get deleteProduct => 'Delete Product';

  @override
  String confirmDeleteProduct(Object code) {
    return 'Delete product $code?';
  }

  @override
  String get noProductFound => 'No products found';

  @override
  String get uploadImage => 'Upload Image';

  @override
  String get standardTitle => 'Standards';

  @override
  String get standardCode => 'Standard Code';

  @override
  String get product => 'Product';

  @override
  String get dyeColor => 'Dye Color';

  @override
  String get width => 'Width (mm)';

  @override
  String get thickness => 'Thickness (mm)';

  @override
  String get strength => 'Strength (daN)';

  @override
  String get elongation => 'Elongation (%)';

  @override
  String get colorFastDry => 'Color Fastness (Dry)';

  @override
  String get colorFastWet => 'Color Fastness (Wet)';

  @override
  String get deltaE => 'Delta E';

  @override
  String get appearance => 'Appearance';

  @override
  String get weftDensity => 'Weft Density (pick/10cm)';

  @override
  String get weight => 'Weight (g/m)';

  @override
  String get searchStandard => 'Search standard...';

  @override
  String get addStandard => 'Add Standard';

  @override
  String get editStandard => 'Edit Standard';

  @override
  String get deleteStandard => 'Delete Standard';

  @override
  String confirmDeleteStandard(Object code) {
    return 'Delete standard $code?';
  }

  @override
  String get noStandardFound => 'No standards found';

  @override
  String get specs => 'Specifications';

  @override
  String get scheduleTitle => 'Work Schedules';

  @override
  String get workDate => 'Work Date';

  @override
  String get employee => 'Employee';

  @override
  String get shift => 'Shift';

  @override
  String get startTime => 'Start Time';

  @override
  String get endTime => 'End Time';

  @override
  String get searchSchedule => 'Search schedule...';

  @override
  String get addSchedule => 'Assign Schedule';

  @override
  String get editSchedule => 'Edit Schedule';

  @override
  String get deleteSchedule => 'Delete Schedule';

  @override
  String confirmDeleteSchedule(Object date, Object name) {
    return 'Delete schedule for $name on $date?';
  }

  @override
  String get noScheduleFound => 'No schedules found';

  @override
  String get filterDate => 'Filter by Date';

  @override
  String get errorDuplicateSchedule =>
      'Conflict: This employee already has a shift on this date.';

  @override
  String get errorUnknown => 'An unknown error occurred';

  @override
  String get weavingTicketTitle => 'Weaving Tickets';

  @override
  String get ticketCode => 'Ticket Code';

  @override
  String get loadDate => 'Load date';

  @override
  String get date => 'Date';

  @override
  String get timeIn => 'Time In';

  @override
  String get empIn => 'Emp In';

  @override
  String get timeOut => 'Time Out';

  @override
  String get empOut => 'Emp Out';

  @override
  String get tage => 'Tage weight';

  @override
  String get machineInfo => 'Machine / Line';

  @override
  String get yarnInfo => 'Yarn Lot / Date';

  @override
  String get standardData => 'Standard Specifications';

  @override
  String get weightInfo => 'Gross / Net / Tare';

  @override
  String get lengthKnots => 'Length (m) / Knots';

  @override
  String get employees => 'Operators';

  @override
  String get timeInOut => 'Time In / Out';

  @override
  String get inspections => 'QC Inspections';

  @override
  String get addTicket => 'New Ticket';

  @override
  String get stageName => 'Stage';

  @override
  String get gross => 'Gross Weight';

  @override
  String get density => 'Density';

  @override
  String get tension => 'Tension';

  @override
  String get bowing => 'Bowing';

  @override
  String get inspector => 'Inspector';

  @override
  String get noTicketSelected => 'Select a ticket to view details';

  @override
  String get deleteTicket => 'Delete Ticket';

  @override
  String confirmDeleteTicket(Object code) {
    return 'Delete ticket $code?';
  }

  @override
  String get deleteInspection => 'Delete Inspection';

  @override
  String get machineAndMaterial => 'Machine & Material';

  @override
  String get generalInfo => 'General Info';

  @override
  String get personnel => 'Personnel';

  @override
  String get resultsUpdateOnly => 'Results (Update Only)';

  @override
  String get machineOperation => 'Machine Operation';

  @override
  String get selectProductBefore => 'Select the product first';

  @override
  String get line => 'Line';

  @override
  String get assignBasket => 'Assign Basket';

  @override
  String get selectBasket => 'Select Ready Basket';

  @override
  String get scanBarcode => 'Scan Barcode / Input Code';

  @override
  String get scanBarcodeSubline =>
      'Scan the basket code here to select your own items';

  @override
  String get addInspection => 'Add QC';

  @override
  String get viewTicket => 'View Ticket';

  @override
  String get editTicket => 'Edit ticket';

  @override
  String get currentBasket => 'Current Basket';

  @override
  String get noActiveBasket => 'No active basket';

  @override
  String get confirmRelease => 'Finish this ticket and release basket?';

  @override
  String get basketAssigned => 'Basket assigned successfully';

  @override
  String get releaseBasket => 'Release Basket / Finish Ticket';

  @override
  String get finishTicket => 'Finish Ticket';

  @override
  String get grossWeight => 'Gross Weight (kg)';

  @override
  String get netWeight => 'Net Weight (kg)';

  @override
  String get length => 'Length (m)';

  @override
  String get knots => 'Knots';

  @override
  String get bow => 'Bow';

  @override
  String get employeeOut => 'Receiver / Operator Out';

  @override
  String get ticketDetails => 'Ticket Details';

  @override
  String get inspectionHistory => 'Inspection History';

  @override
  String get newInspection => 'New Inspection';

  @override
  String get confirmReleaseTitle => 'Confirm Finish';

  @override
  String get confirmReleaseMsg =>
      'Are you sure you want to finish this ticket and release the basket?';

  @override
  String get required => 'Required';

  @override
  String get saveSuccess => 'Saved successfully';

  @override
  String get noTicketsFoundForThisDate => 'No tickets found for this date';

  @override
  String get noBasket => 'No Basket';

  @override
  String get productionInfo => 'Production Info';

  @override
  String get timeAndPersonnel => 'Time & Personnel';

  @override
  String get output => 'Output';

  @override
  String get noInspectionsRecorded => 'No inspections recorded';

  @override
  String get inspection => 'Inspection';

  @override
  String get measurements => 'Measurements';

  @override
  String get userManagementTitle => 'User Management';

  @override
  String get searchUser => 'Search users (name, email)...';

  @override
  String get noUserFound => 'No users found.';

  @override
  String get lastLogin => 'Last Login';

  @override
  String get notLinked => 'Not Linked';

  @override
  String get superuser => 'SUPERUSER';

  @override
  String get inactive => 'Inactive';

  @override
  String get never => 'Never';

  @override
  String get addUser => 'Add User';

  @override
  String get editUser => 'Edit User';

  @override
  String get addNewUser => 'Add New User';

  @override
  String get linkToEmployee => 'Link to Employee';

  @override
  String get linkEmployeeHelper =>
      'Select an employee to link with this account';

  @override
  String get noEmployeeLinkedOption => '--- No Employee Linked ---';

  @override
  String get passwordRequiredNew => 'Required for new user';

  @override
  String get newPasswordPlaceholder => 'New Password (Leave blank to keep)';

  @override
  String get role => 'Role';

  @override
  String get isActiveSwitch => 'Is Active';

  @override
  String get isSuperuserSwitch => 'Is Superuser';

  @override
  String get confirmDeleteTitle => 'Confirm Delete';

  @override
  String get delete => 'Delete';

  @override
  String confirmDeleteUserMsg(Object name) {
    return 'Are you sure you want to delete $name?';
  }

  @override
  String get prodStatsTitle => 'Production Statistics';

  @override
  String get exportExcel => 'Export Excel';

  @override
  String get refreshData => 'Refresh Data';

  @override
  String get recalculateToday => 'Recalculate (Today)';

  @override
  String get searchProductHint => 'Search product code, note...';

  @override
  String get filterToday => 'Today';

  @override
  String get filterYesterday => 'Yesterday';

  @override
  String get filter7Days => 'Last 7 Days';

  @override
  String get filterThisMonth => 'This Month';

  @override
  String get filterLastMonth => 'Last Month';

  @override
  String get filterThisQuarter => 'This Quarter';

  @override
  String get filterThisYear => 'This Year';

  @override
  String get filterCustom => 'Custom Date';

  @override
  String get selectDate => 'Select Date';

  @override
  String get totalProduction => 'TOTAL PRODUCTION';

  @override
  String get totalLength => 'TOTAL LENGTH';

  @override
  String get itemCount => 'ITEMS';

  @override
  String get noStatsData => 'No data for this period';

  @override
  String get machines => 'Machines';

  @override
  String get copySuccess => 'Copied to clipboard!';

  @override
  String get exporting => 'Creating Excel file...';

  @override
  String exportError(Object error) {
    return 'Export error: $error';
  }
}
