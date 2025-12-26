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
}
