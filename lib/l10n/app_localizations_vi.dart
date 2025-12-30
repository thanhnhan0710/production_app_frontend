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
  String get departmentTitle => 'Bộ phận';

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
  String get yarnName => 'Loại sợi';

  @override
  String get itemCode => 'Mã hàng';

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
}
