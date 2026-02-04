import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:production_app_frontend/core/widgets/responsive_layout.dart';
import 'package:production_app_frontend/l10n/app_localizations.dart';

// Import 3 màn hình con
import 'package:production_app_frontend/features/production/weaving/presentation/screens/weaving_screen.dart';
import 'package:production_app_frontend/features/production/weaving_daily_production/presentation/screens/weaving_production_screen.dart';
import 'package:production_app_frontend/features/production/weaving_record/presentation/screens/weaving_record_screen.dart';

class WeavingManagementScreen extends StatefulWidget {
  const WeavingManagementScreen({super.key});

  @override
  State<WeavingManagementScreen> createState() => _WeavingManagementScreenState();
}

class _WeavingManagementScreenState extends State<WeavingManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color _primaryColor = const Color(0xFF003366);

  @override
  void initState() {
    super.initState();
    // Khởi tạo TabController với 3 tab
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        // Tiêu đề trang quản lý chung
        title: Row(
          children: [
            Icon(Icons.dashboard_customize, color: _primaryColor),
            const SizedBox(width: 12),
            Text(
              "QUẢN LÝ SẢN XUẤT DỆT", 
              style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold, fontSize: 20)
            ),
          ],
        ),
        // TabBar nằm ngay dưới AppBar
        bottom: TabBar(
          controller: _tabController,
          labelColor: _primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _primaryColor,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
          tabs: const [
            Tab(
              icon: Icon(Icons.receipt_long),
              text: "PHIẾU RỔ DỆT (TICKETS)",
            ),
            Tab(
              icon: Icon(Icons.bar_chart),
              text: "SẢN LƯỢNG NGÀY",
            ),
            Tab(
              icon: Icon(Icons.history),
              text: "LỊCH SỬ CÂN & THỐNG KÊ",
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        // Tắt chức năng vuốt ngang để chuyển tab nếu muốn tránh xung đột với các list view con
        physics: const NeverScrollableScrollPhysics(), 
        children: const [
          // Tab 1: Màn hình quản lý phiếu dệt (WeavingScreen)
          // Lưu ý: Trong WeavingScreen bạn đã có AppBar riêng, 
          // nên cần sửa WeavingScreen một chút để ẩn AppBar đi nếu được nhúng vào đây
          // hoặc bọc nó trong một Widget để xử lý UI cho đẹp.
          // Ở đây tôi giả định bạn sẽ dùng trực tiếp.
          _KeepAliveWrapper(child: WeavingScreen()),

          // Tab 2: Màn hình sản lượng hàng ngày (WeavingProductionScreen)
          _KeepAliveWrapper(child: WeavingProductionScreen()),

          // Tab 3: Màn hình lịch sử chi tiết (WeavingRecordScreen)
          _KeepAliveWrapper(child: WeavingRecordScreen()),
        ],
      ),
    );
  }
}

// Widget Wrapper giúp giữ trạng thái của Tab khi chuyển qua lại (không bị load lại API)
class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const _KeepAliveWrapper({required this.child});

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}