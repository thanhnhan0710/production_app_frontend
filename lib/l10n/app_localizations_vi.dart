// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get loginTitle => 'Đăng nhập';

  @override
  String get username => 'Tên đăng nhập';

  @override
  String get password => 'Mật khẩu';

  @override
  String get btnLogin => 'ĐĂNG NHẬP';

  @override
  String welcome(String name) {
    return 'Xin chào $name';
  }

  @override
  String get companyName => 'CÔNG TY TNHH OPPERMANN VIỆT NAM';

  @override
  String get erpSystemName => 'Hệ thống Quản trị Nguồn lực Doanh nghiệp';

  @override
  String get loginSystemHeader => 'Đăng nhập Hệ thống';

  @override
  String get loginSubtitle => 'Vui lòng đăng nhập để truy cập ERP';

  @override
  String get copyright => '© 2026 Oppermann Việt Nam';

  @override
  String get errorRequired => 'Vui lòng không để trống';

  @override
  String get errorLoginFailed =>
      'Đăng nhập thất bại. Vui lòng kiểm tra lại tài khoản.';

  @override
  String get errorNetwork => 'Lỗi kết nối. Vui lòng kiểm tra mạng hoặc Server.';

  @override
  String get errorGeneric => 'Đã xảy ra lỗi hệ thống.';

  @override
  String get dashboard => 'Tổng quan';

  @override
  String get production => 'Sản xuất';

  @override
  String get inventory => 'Kho vận';

  @override
  String get sales => 'Bán hàng';

  @override
  String get hr => 'Nhân sự';

  @override
  String get reports => 'Báo cáo';

  @override
  String get settings => 'Cài đặt';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get totalOrders => 'Tổng đơn hàng';

  @override
  String get activePlans => 'Kế hoạch đang chạy';

  @override
  String get lowStock => 'Sắp hết hàng';

  @override
  String get revenue => 'Doanh thu';

  @override
  String get recentActivities => 'Hoạt động gần đây';

  @override
  String get viewAll => 'Xem tất cả';

  @override
  String get departmentTitle => 'Quản lý Bộ phận';

  @override
  String get deptName => 'Tên bộ phận';

  @override
  String get deptDesc => 'Mô tả';

  @override
  String get searchDept => 'Tìm kiếm bộ phận...';

  @override
  String get addDept => 'Thêm bộ phận';

  @override
  String get editDept => 'Sửa bộ phận';

  @override
  String get deleteDept => 'Xóa bộ phận';

  @override
  String confirmDelete(Object name) {
    return 'Bạn có chắc muốn xóa bộ phận $name không?';
  }

  @override
  String get employeeTitle => 'Nhân viên';

  @override
  String get fullName => 'Họ và tên';

  @override
  String get email => 'Email';

  @override
  String get phone => 'Số điện thoại';

  @override
  String get address => 'Địa chỉ';

  @override
  String get position => 'Chức vụ';

  @override
  String get department => 'Phòng ban';

  @override
  String get note => 'Ghi chú';

  @override
  String get searchEmployee => 'Tìm nhân viên...';

  @override
  String get addEmployee => 'Thêm nhân viên';

  @override
  String get editEmployee => 'Sửa nhân viên';

  @override
  String get deleteEmployee => 'Xóa nhân viên';

  @override
  String confirmDeleteEmployee(Object name) {
    return 'Xóa nhân viên $name?';
  }

  @override
  String get selectDept => 'Chọn phòng ban';

  @override
  String get totalDepartments => 'Tổng số bộ phận';

  @override
  String get status => 'Trạng thái';

  @override
  String get active => 'Hoạt động';

  @override
  String get members => 'Thành viên';

  @override
  String get supplierTitle => 'Nhà cung cấp';

  @override
  String get supplierName => 'Tên nhà cung cấp';

  @override
  String get searchSupplier => 'Tìm nhà cung cấp...';

  @override
  String get addSupplier => 'Thêm nhà cung cấp';

  @override
  String get editSupplier => 'Sửa nhà cung cấp';

  @override
  String get deleteSupplier => 'Xóa nhà cung cấp';

  @override
  String confirmDeleteSupplier(Object name) {
    return 'Bạn có chắc muốn xóa $name không?';
  }

  @override
  String get contact => 'Liên hệ';

  @override
  String get save => 'Lưu';

  @override
  String get cancel => 'Hủy';

  @override
  String get actions => 'Hành động';

  @override
  String get successAdded => 'Thêm thành công';

  @override
  String get successUpdated => 'Cập nhật thành công';

  @override
  String get successDeleted => 'Xóa thành công';

  @override
  String get yarnTitle => 'Kho Sợi';

  @override
  String get yarnName => 'Tên sợi';

  @override
  String get itemCode => 'Mã sản phẩm';

  @override
  String get yarnType => 'Loại sợi';

  @override
  String get color => 'Màu sắc';

  @override
  String get origin => 'Xuất xứ';

  @override
  String get supplier => 'Nhà cung cấp';

  @override
  String get searchYarn => 'Tìm sợi (tên, mã)...';

  @override
  String get addYarn => 'Thêm sợi';

  @override
  String get editYarn => 'Sửa sợi';

  @override
  String get deleteYarn => 'Xóa sợi';

  @override
  String confirmDeleteYarn(Object name) {
    return 'Xóa sợi $name?';
  }

  @override
  String get selectSupplier => 'Chọn nhà cung cấp';

  @override
  String get noYarnFound => 'Không tìm thấy dữ liệu sợi';

  @override
  String get yarnLotTitle => 'Lô Sợi';

  @override
  String get lotCode => 'Mã lô';

  @override
  String get importDate => 'Ngày nhập';

  @override
  String get totalKg => 'Tổng kg';

  @override
  String get rollCount => 'Số cuộn';

  @override
  String get warehouseLoc => 'Vị trí kho';

  @override
  String get containerCode => 'Số container';

  @override
  String get driver => 'Tài xế';

  @override
  String get receiver => 'Người nhận';

  @override
  String get searchYarnLot => 'Tìm mã lô...';

  @override
  String get addYarnLot => 'Nhập lô sợi';

  @override
  String get editYarnLot => 'Sửa lô sợi';

  @override
  String get deleteYarnLot => 'Xóa lô sợi';

  @override
  String confirmDeleteYarnLot(Object code) {
    return 'Xóa lô $code?';
  }

  @override
  String get selectYarn => 'Chọn loại sợi';

  @override
  String get selectEmployee => 'Chọn nhân viên';

  @override
  String get materialTitle => 'Nguyên vật liệu';

  @override
  String get materialName => 'Tên vật liệu';

  @override
  String get quantity => 'Số lượng';

  @override
  String get unit => 'Đơn vị';

  @override
  String get importedBy => 'Người nhập';

  @override
  String get searchMaterial => 'Tìm vật liệu...';

  @override
  String get addMaterial => 'Thêm vật liệu';

  @override
  String get editMaterial => 'Sửa vật liệu';

  @override
  String get deleteMaterial => 'Xóa vật liệu';

  @override
  String confirmDeleteMaterial(Object name) {
    return 'Xóa vật liệu $name?';
  }

  @override
  String get noMaterialFound => 'Không tìm thấy vật liệu';

  @override
  String get selectImporter => 'Chọn người nhập';

  @override
  String get selectUnit => 'Chọn đơn vị';

  @override
  String get unitTitle => 'Đơn vị tính';

  @override
  String get unitName => 'Tên đơn vị';

  @override
  String get searchUnit => 'Tìm đơn vị...';

  @override
  String get addUnit => 'Thêm đơn vị';

  @override
  String get editUnit => 'Sửa đơn vị';

  @override
  String get deleteUnit => 'Xóa đơn vị';

  @override
  String confirmDeleteUnit(Object name) {
    return 'Xóa đơn vị $name?';
  }

  @override
  String get noUnitFound => 'Không tìm thấy đơn vị nào';

  @override
  String get machineTitle => 'Máy móc thiết bị';

  @override
  String get machineName => 'Tên máy';

  @override
  String get totalLines => 'Số dây/line';

  @override
  String get purpose => 'Mục đích sử dụng';

  @override
  String get searchMachine => 'Tìm máy...';

  @override
  String get addMachine => 'Thêm máy';

  @override
  String get editMachine => 'Sửa thông tin máy';

  @override
  String get deleteMachine => 'Xóa máy';

  @override
  String confirmDeleteMachine(Object name) {
    return 'Xóa máy $name?';
  }

  @override
  String get noMachineFound => 'Không tìm thấy máy nào';

  @override
  String get running => 'Đang chạy';

  @override
  String get stopped => 'Đang dừng';

  @override
  String get maintenance => 'Bảo trì';

  @override
  String get shiftTitle => 'Ca làm việc';

  @override
  String get shiftName => 'Tên ca';

  @override
  String get searchShift => 'Tìm ca làm việc...';

  @override
  String get addShift => 'Thêm ca';

  @override
  String get editShift => 'Sửa ca';

  @override
  String get deleteShift => 'Xóa ca';

  @override
  String confirmDeleteShift(Object name) {
    return 'Xóa ca $name?';
  }

  @override
  String get noShiftFound => 'Không tìm thấy ca làm việc';

  @override
  String get basketTitle => 'Rổ chứa';

  @override
  String get basketCode => 'Mã rổ';

  @override
  String get basketTitleVS2 => 'Rổ';

  @override
  String get tareWeight => 'Trọng lượng bì (kg)';

  @override
  String get searchBasket => 'Tìm mã rổ...';

  @override
  String get addBasket => 'Thêm rổ';

  @override
  String get editBasket => 'Sửa rổ';

  @override
  String get deleteBasket => 'Xóa rổ';

  @override
  String confirmDeleteBasket(Object code) {
    return 'Xóa rổ $code?';
  }

  @override
  String get noBasketFound => 'Không tìm thấy rổ nào';

  @override
  String get stReady => 'Sẵn sàng';

  @override
  String get stInUse => 'Đang sử dụng';

  @override
  String get stHolding => 'Đang lưu kho';

  @override
  String get stDamaged => 'Hư hỏng';

  @override
  String get dyeColorTitle => 'Màu nhuộm';

  @override
  String get colorName => 'Tên màu';

  @override
  String get hexCode => 'Mã màu (Hex)';

  @override
  String get searchColor => 'Tìm màu...';

  @override
  String get addColor => 'Thêm màu';

  @override
  String get editColor => 'Sửa màu';

  @override
  String get deleteColor => 'Xóa màu';

  @override
  String confirmDeleteColor(Object name) {
    return 'Xóa màu $name?';
  }

  @override
  String get noColorFound => 'Không tìm thấy màu nào';

  @override
  String get invalidHex => 'Mã màu không hợp lệ (VD: #FF0000)';

  @override
  String get productTitle => 'Sản phẩm';

  @override
  String get productImage => 'Hình ảnh';

  @override
  String get searchProduct => 'Tìm sản phẩm...';

  @override
  String get addProduct => 'Thêm sản phẩm';

  @override
  String get editProduct => 'Sửa sản phẩm';

  @override
  String get deleteProduct => 'Xóa sản phẩm';

  @override
  String confirmDeleteProduct(Object code) {
    return 'Xóa sản phẩm $code?';
  }

  @override
  String get noProductFound => 'Không tìm thấy sản phẩm';

  @override
  String get uploadImage => 'Tải ảnh lên';

  @override
  String get standardTitle => 'Tiêu chuẩn';

  @override
  String get standardCode => 'Mã tiêu chuẩn';

  @override
  String get product => 'Sản phẩm';

  @override
  String get dyeColor => 'Màu nhuộm';

  @override
  String get width => 'Khổ (mm)';

  @override
  String get thickness => 'Độ dày (mm)';

  @override
  String get strength => 'Lực đứt (daN)';

  @override
  String get elongation => 'Độ giãn (%)';

  @override
  String get colorFastDry => 'Bền màu (Khô)';

  @override
  String get colorFastWet => 'Bền màu (Ướt)';

  @override
  String get deltaE => 'Sai lệch màu (Delta E)';

  @override
  String get appearance => 'Ngoại quan';

  @override
  String get weftDensity => 'Mật độ ngang (pick/10cm)';

  @override
  String get weight => 'Trọng lượng (g/m)';

  @override
  String get searchStandard => 'Tìm tiêu chuẩn...';

  @override
  String get addStandard => 'Thêm tiêu chuẩn';

  @override
  String get editStandard => 'Sửa tiêu chuẩn';

  @override
  String get deleteStandard => 'Xóa tiêu chuẩn';

  @override
  String confirmDeleteStandard(Object code) {
    return 'Xóa tiêu chuẩn $code?';
  }

  @override
  String get noStandardFound => 'Không tìm thấy tiêu chuẩn';

  @override
  String get specs => 'Thông số kỹ thuật';

  @override
  String get scheduleTitle => 'Lịch làm việc';

  @override
  String get workDate => 'Ngày làm việc';

  @override
  String get employee => 'Nhân viên';

  @override
  String get shift => 'Ca làm việc';

  @override
  String get startTime => 'Giờ bắt đầu';

  @override
  String get endTime => 'Giờ kết thúc';

  @override
  String get searchSchedule => 'Tìm lịch...';

  @override
  String get addSchedule => 'Xếp lịch';

  @override
  String get editSchedule => 'Sửa lịch';

  @override
  String get deleteSchedule => 'Xóa lịch';

  @override
  String confirmDeleteSchedule(Object date, Object name) {
    return 'Xóa lịch của $name ngày $date?';
  }

  @override
  String get noScheduleFound => 'Không tìm thấy lịch làm việc';

  @override
  String get filterDate => 'Lọc theo ngày';

  @override
  String get errorDuplicateSchedule =>
      'Xung đột: Nhân viên này đã có ca làm việc trong ngày này rồi.';

  @override
  String get errorUnknown => 'Đã xảy ra lỗi không xác định';

  @override
  String get weavingTicketTitle => 'Phiếu Rổ Dệt';

  @override
  String get ticketCode => 'Mã phiếu';

  @override
  String get loadDate => 'Ngày lên sợi';

  @override
  String get date => 'Ngày';

  @override
  String get timeIn => 'Thời gian vào';

  @override
  String get empIn => 'Người vào';

  @override
  String get timeOut => 'Thời gian ra';

  @override
  String get empOut => 'Người ra';

  @override
  String get tage => 'Trọng lượng rổ';

  @override
  String get machineInfo => 'Máy / Line';

  @override
  String get yarnInfo => 'Lô sợi / Ngày nạp';

  @override
  String get standardData => 'Standard Specifications';

  @override
  String get weightInfo => 'Tổng / Tịnh / Bì (kg)';

  @override
  String get lengthKnots => 'Dài (m) / Số nối';

  @override
  String get employees => 'Nhân viên vận hành';

  @override
  String get timeInOut => 'Giờ Vào / Ra';

  @override
  String get inspections => 'Kết quả kiểm tra QC';

  @override
  String get addTicket => 'Tạo phiếu mới';

  @override
  String get stageName => 'Công đoạn';

  @override
  String get gross => 'Tổng trọng lượng';

  @override
  String get density => 'Mật độ sợi ngang';

  @override
  String get tension => 'Lực căng';

  @override
  String get bowing => 'Độ lệch (Bowing)';

  @override
  String get inspector => 'Người kiểm tra';

  @override
  String get noTicketSelected => 'Chọn một phiếu để xem chi tiết';

  @override
  String get deleteTicket => 'Xóa phiếu';

  @override
  String confirmDeleteTicket(Object code) {
    return 'Xóa phiếu $code?';
  }

  @override
  String get deleteInspection => 'Xóa kiểm tra';

  @override
  String get machineAndMaterial => 'Máy & Nguyên vật liệu';

  @override
  String get generalInfo => 'Thông tin chung';

  @override
  String get personnel => 'Nhân sự';

  @override
  String get resultsUpdateOnly => 'Kết quả (chỉ cập nhật)';

  @override
  String get machineOperation => 'Vận hành Máy dệt';

  @override
  String get selectProductBefore => 'Chọn sản phẩm trước';

  @override
  String get line => 'Trục';

  @override
  String get assignBasket => 'Gán rổ';

  @override
  String get selectBasket => 'Chọn rổ sẵn sàng';

  @override
  String get scanBarcode => 'Quét mã vạch / Nhập mã';

  @override
  String get scanBarcodeSubline => 'Quét mã rổ tại đây để tự chọn';

  @override
  String get addInspection => 'Thêm kiểm tra';

  @override
  String get viewTicket => 'Xem phiếu';

  @override
  String get editTicket => 'Sửa phiếu';

  @override
  String get currentBasket => 'Rổ hiện tại';

  @override
  String get noActiveBasket => 'Trống';

  @override
  String get confirmRelease => 'Kết thúc phiếu và tháo rổ?';

  @override
  String get basketAssigned => 'Đã gán rổ thành công';

  @override
  String get releaseBasket => 'Tháo rổ / Kết thúc phiếu';

  @override
  String get finishTicket => 'Kết thúc phiếu';

  @override
  String get grossWeight => 'Trọng lượng cả bì (kg)';

  @override
  String get netWeight => 'Trọng lượng tịnh (kg)';

  @override
  String get length => 'Chiều dài (m)';

  @override
  String get knots => 'Số mối nối';

  @override
  String get bow => 'Cong';

  @override
  String get employeeOut => 'Người nhận / NV Tháo';

  @override
  String get ticketDetails => 'Chi tiết Phiếu';

  @override
  String get inspectionHistory => 'Lịch sử kiểm tra';

  @override
  String get newInspection => 'Kiểm tra mới';

  @override
  String get confirmReleaseTitle => 'Xác nhận kết thúc';

  @override
  String get confirmReleaseMsg =>
      'Bạn có chắc muốn kết thúc phiếu này và tháo rổ ra không?';

  @override
  String get required => 'Bắt buộc';

  @override
  String get saveSuccess => 'Lưu thành công';

  @override
  String get noTicketsFoundForThisDate =>
      'Không có phiếu sản xuất nào trong ngày này';

  @override
  String get noBasket => 'Không có rổ';

  @override
  String get productionInfo => 'Thông tin sản xuất';

  @override
  String get timeAndPersonnel => 'Thời gian & nhân sự';

  @override
  String get output => 'Sản lượng';

  @override
  String get noInspectionsRecorded => 'Chưa có dữ liệu kiểm tra';

  @override
  String get inspection => 'Kiểm tra chất lượng';

  @override
  String get measurements => 'Thông số đo đạc';

  @override
  String get userManagementTitle => 'Quản lý Tài khoản';

  @override
  String get searchUser => 'Tìm tài khoản (tên, email)...';

  @override
  String get noUserFound => 'Không tìm thấy tài khoản nào.';

  @override
  String get lastLogin => 'Đăng nhập cuối';

  @override
  String get notLinked => 'Chưa liên kết';

  @override
  String get superuser => 'SUPERUSER';

  @override
  String get inactive => 'Ngưng hoạt động';

  @override
  String get never => 'Chưa từng';

  @override
  String get addUser => 'Thêm tài khoản';

  @override
  String get editUser => 'Sửa tài khoản';

  @override
  String get addNewUser => 'Thêm tài khoản mới';

  @override
  String get linkToEmployee => 'Liên kết Nhân viên';

  @override
  String get linkEmployeeHelper =>
      'Chọn nhân viên để liên kết với tài khoản này';

  @override
  String get noEmployeeLinkedOption => '--- Không liên kết ---';

  @override
  String get passwordRequiredNew => 'Bắt buộc đối với tài khoản mới';

  @override
  String get newPasswordPlaceholder => 'Mật khẩu mới (Để trống nếu giữ nguyên)';

  @override
  String get role => 'Vai trò';

  @override
  String get isActiveSwitch => 'Đang hoạt động';

  @override
  String get isSuperuserSwitch => 'Là Superuser';

  @override
  String get confirmDeleteTitle => 'Xác nhận xóa';

  @override
  String get delete => 'Xóa';

  @override
  String confirmDeleteUserMsg(Object name) {
    return 'Bạn có chắc muốn xóa tài khoản $name?';
  }
}
