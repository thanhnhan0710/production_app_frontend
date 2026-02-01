import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:production_app_frontend/l10n/app_localizations.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/bloc/language_cubit.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Color _primaryColor = const Color(0xFF003366);
  final Color _backgroundColor = const Color(0xFFF5F7FA);

  // Hàm xử lý điều hướng
  void _onNavigate(String route) {
    // Nếu route là '#' -> Hiện popup "Đang phát triển"
    if (route == '#') {
      _showUnderDevelopmentDialog();
    } else {
      context.go(route);
      // Nếu đang ở mobile thì đóng drawer sau khi chọn
      if (ResponsiveLayout.isMobile(context)) {
        Navigator.pop(context);
      }
    }
  }

  // Popup thông báo
  void _showUnderDevelopmentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.construction, color: Colors.orange),
            SizedBox(width: 10),
            Text("Thông báo"),
          ],
        ),
        content: const Text("Tính năng này đang được phát triển.\nVui lòng quay lại sau."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Đóng"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    String currentPath = '/dashboard';
    try {
      currentPath = GoRouterState.of(context).uri.path;
    } catch (e) {
      // Fallback
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _backgroundColor,
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: _primaryColor,
              leading: IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              title: const Text("ERP System", style: TextStyle(color: Colors.white)),
              actions: [
                IconButton(
                  icon: const CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, size: 16, color: Colors.white),
                  ),
                  onPressed: () {},
                ),
                const SizedBox(width: 8),
              ],
            ),
      drawer: isDesktop
          ? null
          : Drawer(child: _buildSidebar(context, l10n, currentPath)),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            SizedBox(
              width: 280,
              child: _buildSidebar(context, l10n, currentPath),
            ),
          Expanded(
            child: Column(
              children: [
                if (isDesktop) _buildDesktopTopBar(context, l10n),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (currentPath == '/dashboard') ...[
                          Text(
                            l10n.dashboard,
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: _primaryColor),
                          ),
                          const SizedBox(height: 24),
                          
                          _buildStatCards(l10n),
                          
                          const SizedBox(height: 32),
                          
                          if (isDesktop)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 2, child: _buildProductionChart(l10n)),
                                const SizedBox(width: 24),
                                Expanded(flex: 1, child: _buildRecentActivityList(l10n)),
                              ],
                            )
                          else
                            Column(
                              children: [
                                _buildProductionChart(l10n),
                                const SizedBox(height: 24),
                                _buildRecentActivityList(l10n),
                              ],
                            ),
                        ] else ...[
                          // Placeholder cho các trang nội dung khác để test layout
                           Container(
                            height: 500,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.build_circle_outlined, size: 64, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text("Nội dung trang: $currentPath", style: TextStyle(color: Colors.grey[500], fontSize: 18)),
                              ],
                            ),
                           )
                        ]
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- SIDEBAR & MENU ---
  Widget _buildSidebar(BuildContext context, AppLocalizations l10n, String currentPath) {
    return Container(
      color: _primaryColor,
      child: Column(
        children: [
          // HEADER
          Container(
            height: 120, 
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
            color: Colors.black12,
            child: const Row(
              children: [
                Icon(Icons.apartment, color: Colors.white, size: 40),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min, 
                    children: [
                      Text("OPPERMANN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18), overflow: TextOverflow.ellipsis),
                      SizedBox(height: 4), 
                      Text("ERP System", style: TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                )
              ],
            ),
          ),
          
          // MENU LIST
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildMenuItem(Icons.dashboard, l10n.dashboard, '/dashboard', currentPath),
                  
                  // ================= KHO (INVENTORY) =================
                  _buildExpansionGroup(
                    icon: Icons.inventory_2,
                    title: l10n.inventory,
                    currentPath: currentPath,
                    childrenRoutes: [
                      '/warehouses', '/materials', '/suppliers', '/products', '/units', '/dye-colors',
                      '/import-declarations', '/purchase-orders',
                      '/stock-in', '/material-exports', '/inventorys', '/batches'
                    ],
                    children: [
                      // 1. Thông tin chung
                      _buildSubExpansionGroup(
                        title: l10n.generalInfo,
                        currentPath: currentPath,
                        childrenRoutes: ['/warehouses', '/materials', '/suppliers', '/products', '/units', '/dye-colors'],
                        children: [
                          _buildLevel3MenuItem(Icons.store_mall_directory, "Quản lý kho hàng", '/warehouses', currentPath),
                          _buildLevel3MenuItem(Icons.layers, "Nguyên vật liệu", '/materials', currentPath),
                          _buildLevel3MenuItem(Icons.local_shipping, "Nhà cung cấp", '/suppliers', currentPath),
                          _buildLevel3MenuItem(Icons.shopping_bag, "Sản Phẩm", '/products', currentPath),
                          _buildLevel3MenuItem(Icons.straighten, "Đơn vị tính", '/units', currentPath),
                          _buildLevel3MenuItem(Icons.color_lens, "Màu nhuộm", '/dye-colors', currentPath),
                        ]
                      ),

                      // 2. Đơn mua NVL
                      _buildSubExpansionGroup(
                        title: "Đơn mua NVL",
                        currentPath: currentPath,
                        childrenRoutes: ['/import-declarations', '/purchase-orders'],
                        children: [
                          _buildLevel3MenuItem(Icons.receipt_long, "Tờ khai hải quan", '/import-declarations', currentPath),
                          _buildLevel3MenuItem(Icons.shopping_cart_checkout, "Đơn mua hàng", '/purchase-orders', currentPath),
                        ]
                      ),

                      // 3. Nhập Xuất kho
                      _buildSubExpansionGroup(
                        title: "Nhập Xuất kho",
                        currentPath: currentPath,
                        childrenRoutes: ['/stock-in', '/material-exports'],
                        children: [
                          _buildLevel3MenuItem(Icons.move_to_inbox, "Nhập kho", '/stock-in', currentPath),
                          
                          // Header giả lập cho Xuất kho
                          _buildSubHeader("Xuất kho"),
                          _buildLevel3MenuItem(Icons.output, "Xuất kho NVL", '/material-exports', currentPath),
                          _buildLevel3MenuItem(Icons.output, "Xuất bán thành phẩm", '#', currentPath),
                          _buildLevel3MenuItem(Icons.output, "Xuất thành phẩm", '#', currentPath),
                        ]
                      ),

                      // 4. Tồn kho
                      _buildSubExpansionGroup(
                        title: "Tồn kho",
                        currentPath: currentPath,
                        childrenRoutes: ['/inventorys'],
                        children: [
                          _buildLevel3MenuItem(Icons.grid_view, "Nguyên vật liệu", '/inventorys', currentPath),
                          _buildLevel3MenuItem(Icons.grid_view, "Bán thành phẩm", '#', currentPath),
                          _buildLevel3MenuItem(Icons.grid_view, "Thành phẩm", '#', currentPath),
                        ]
                      ),

                      // 5. Quản lý lô
                       _buildSubExpansionGroup(
                        title: "Quản lý lô",
                        currentPath: currentPath,
                        childrenRoutes: ['/batches'],
                        children: [
                          _buildLevel3MenuItem(Icons.fact_check, "Lô nguyên vật liệu", '/batches', currentPath),
                        ]
                      ),
                    ],
                  ),

                  // ================= SẢN XUẤT (PRODUCTION) =================
                   _buildExpansionGroup(
                    icon: Icons.precision_manufacturing,
                    title: l10n.production,
                    currentPath: currentPath,
                    childrenRoutes: [
                      '/machines', '/baskets',
                      '/machine-operation', '/weaving', '/weaving-productions',
                      '/boms', '/standards'
                    ],
                    children: [
                       // 1. Thông tin chung
                      _buildSubExpansionGroup(
                        title: l10n.generalInfo,
                        currentPath: currentPath,
                        childrenRoutes: ['/machines', '/baskets'],
                        children: [
                          _buildLevel3MenuItem(Icons.settings_input_component, "Máy móc thiết bị", '/machines', currentPath),
                          _buildLevel3MenuItem(Icons.all_inbox, "Rổ chứa", '/baskets', currentPath),
                        ]
                      ),
                      // 2. Dệt
                       _buildSubExpansionGroup(
                        title: "Dệt",
                        currentPath: currentPath,
                        childrenRoutes: ['/machine-operation', '/weaving', '/weaving-productions', 'weaving-records'],
                        children: [
                          _buildLevel3MenuItem(Icons.precision_manufacturing, "Vận hành máy dệt", '/machine-operation', currentPath),
                          _buildLevel3MenuItem(Icons.description, "Phiếu rổ dệt", '/weaving', currentPath),
                          _buildLevel3MenuItem(Icons.bar_chart, "Sản lượng dệt", '/weaving-productions', currentPath),
                          _buildLevel3MenuItem(Icons.bar_chart, "Sản lượng theo ca và phế", '/weaving-records', currentPath),
                        ]
                      ),
                      // Các mục đơn (Level 2)
                      _buildSubMenuItem(Icons.format_color_fill, "Nhuộm", '#', currentPath),
                      _buildSubMenuItem(Icons.print, "In", '#', currentPath),
                      _buildSubMenuItem(Icons.shield, "Thành phẩm an toàn", '#', currentPath),
                      
                      // Đóng gói Group
                       _buildSubExpansionGroup(
                        title: "Đóng gói",
                        currentPath: currentPath,
                        childrenRoutes: [],
                        children: [
                          _buildLevel3MenuItem(Icons.album, "Cuộn", '#', currentPath),
                          _buildLevel3MenuItem(Icons.content_cut, "Cắt", '#', currentPath),
                        ]
                      ),
                    ]
                   ),

                  // ================= QC =================
                  _buildExpansionGroup(
                    icon: Icons.check_circle_outline,
                    title: "QC",
                    currentPath: currentPath,
                    childrenRoutes: ['/boms', '/standards'],
                    children: [
                      _buildSubMenuItem(Icons.account_tree, l10n.bomTitle, '/boms', currentPath),
                      _buildSubMenuItem(Icons.assignment, l10n.standardTitle, '/standards', currentPath),
                    ]
                  ),

                  // ================= SALE (CHƯA PHÁT TRIỂN) =================
                  _buildMenuItem(Icons.shopping_cart, l10n.sales, '#', currentPath),

                  // ================= NHÂN SỰ (HR) =================
                  _buildExpansionGroup(
                    icon: Icons.people,
                    title: l10n.hr,
                    currentPath: currentPath,
                    childrenRoutes: ['/departments', '/employees', '/shifts', '/schedules'],
                    children: [
                      _buildSubMenuItem(Icons.domain, l10n.departmentTitle, '/departments', currentPath),
                      _buildSubMenuItem(Icons.badge, l10n.employeeTitle, '/employees', currentPath),
                      _buildSubMenuItem(Icons.access_time, l10n.shiftTitle, '/shifts', currentPath),
                      _buildSubMenuItem(Icons.calendar_month, l10n.scheduleTitle, '/schedules', currentPath),
                    ]
                  ),

                   // ================= REPORT (CHƯA PHÁT TRIỂN) =================
                  _buildMenuItem(Icons.bar_chart, l10n.reports, '#', currentPath),

                  // ================= ADMINISTRATOR =================
                   _buildExpansionGroup(
                    icon: Icons.admin_panel_settings,
                    title: "Administrator",
                    currentPath: currentPath,
                    childrenRoutes: ['/users', '/logs'],
                    children: [
                      _buildSubMenuItem(Icons.manage_accounts, l10n.userManagementTitle, '/users', currentPath),
                      _buildSubMenuItem(Icons.manage_accounts, "Nhật ký hoạt động", '/logs', currentPath),
                    ]
                  ),

                  // ================= SETTING (CHƯA PHÁT TRIỂN) =================
                  _buildMenuItem(Icons.settings, l10n.settings, '#', currentPath),
                ],
              ),
            ),
          ),
          
          // LOGOUT
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton.icon(
              onPressed: () => context.read<AuthCubit>().logout(),
              icon: const Icon(Icons.logout, size: 18),
              label: Text(l10n.logout),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.shade700,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
              ),
            ),
          )
        ],
      ),
    );
  }

  // --- MENU ITEM HELPERS ---

  // Cấp 1: Mục đơn (VD: Dashboard, Sale, Report)
  Widget _buildMenuItem(IconData icon, String title, String route, String currentPath) {
    final bool isActive = route != '#' && currentPath == route; // Fix: Không active nếu là #
    
    return ListTile(
      leading: Icon(icon, color: isActive ? Colors.white : Colors.white70, size: 20),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.white70,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
      tileColor: isActive ? Colors.white.withOpacity(0.1) : null,
      dense: true,
      onTap: () => _onNavigate(route),
    );
  }

  // Cấp 1: Nhóm (VD: Kho, Sản xuất)
  Widget _buildExpansionGroup({
    required IconData icon,
    required String title,
    required String currentPath,
    required List<String> childrenRoutes,
    required List<Widget> children,
  }) {
    final bool isExpanded = childrenRoutes.any((r) => currentPath.startsWith(r) && r != '/');
    
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        leading: Icon(icon, color: Colors.white70),
        title: Text(title, style: const TextStyle(color: Colors.white70)),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white70,
        childrenPadding: EdgeInsets.zero,
        backgroundColor: Colors.black12,
        children: children,
      ),
    );
  }

  // Cấp 2: Nhóm con (Sub-Group)
  Widget _buildSubExpansionGroup({
    required String title,
    required String currentPath,
    required List<String> childrenRoutes,
    required List<Widget> children,
  }) {
    final bool isExpanded = childrenRoutes.any((r) => currentPath.startsWith(r) && r != '/');

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        title: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
        tilePadding: const EdgeInsets.only(left: 32, right: 16),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white70,
        childrenPadding: EdgeInsets.zero,
        backgroundColor: Colors.black12,
        children: children,
      ),
    );
  }

  // Cấp 2: Mục đơn
  Widget _buildSubMenuItem(IconData icon, String title, String route, String currentPath) {
    final bool isActive = route != '#' && currentPath.startsWith(route) && (route != '/' || currentPath == '/');
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 32, right: 16),
      leading: Icon(icon, color: isActive ? Colors.white : Colors.white70, size: 18),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.white70,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
      dense: true,
      horizontalTitleGap: 8,
      tileColor: isActive ? Colors.white.withOpacity(0.05) : null,
      onTap: () => _onNavigate(route),
    );
  }
  
  // Header hiển thị text
  Widget _buildSubHeader(String title) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 48, right: 16),
      title: Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic)),
      dense: true,
    );
  }

  // Cấp 3: Mục đơn
  Widget _buildLevel3MenuItem(IconData icon, String title, String route, String currentPath) {
    final bool isActive = route != '#' && currentPath.startsWith(route);
    
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 48, right: 16),
      leading: Icon(icon, color: isActive ? Colors.white : Colors.white70, size: 16),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.white70,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
      dense: true,
      horizontalTitleGap: 8,
      tileColor: isActive ? Colors.white.withOpacity(0.1) : null,
      onTap: () => _onNavigate(route),
    );
  }

  // --- TOP BAR ---
  Widget _buildDesktopTopBar(BuildContext context, AppLocalizations l10n) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
              child: const TextField(
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "Search...",
                  icon: Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          _buildLanguageIcon(context),
          const SizedBox(width: 20),
          Row(
            children: [
              CircleAvatar(backgroundColor: _primaryColor.withOpacity(0.1), child: Text("AD", style: TextStyle(color: _primaryColor))),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Admin", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text("Manager", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLanguageIcon(BuildContext context) {
    final currentLocale = context.watch<LanguageCubit>().state;
    return InkWell(
      onTap: () {
        final newCode = currentLocale.languageCode == 'vi' ? 'en' : 'vi';
        context.read<LanguageCubit>().changeLanguage(newCode);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade100),
        child: Text(currentLocale.languageCode == 'vi' ? "🇻🇳" : "🇺🇸", style: const TextStyle(fontSize: 20)),
      ),
    );
  }

  // --- STATS & CHARTS ---
  Widget _buildStatCards(AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 650) {
          return Column(
            children: [
              _buildInfoCard(l10n.totalOrders, "1,240", Icons.shopping_bag, Colors.blue),
              const SizedBox(height: 16),
              _buildInfoCard(l10n.activePlans, "8", Icons.precision_manufacturing, Colors.orange),
              const SizedBox(height: 16),
              _buildInfoCard(l10n.revenue, "\$84K", Icons.attach_money, Colors.green),
              const SizedBox(height: 16),
              _buildInfoCard(l10n.lowStock, "12 Items", Icons.warning, Colors.red),
            ],
          );
        }
        int crossAxisCount = constraints.maxWidth < 1100 ? 2 : 4;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 1.8,
          children: [
            _buildInfoCard(l10n.totalOrders, "1,240", Icons.shopping_bag, Colors.blue),
            _buildInfoCard(l10n.activePlans, "8", Icons.precision_manufacturing, Colors.orange),
            _buildInfoCard(l10n.revenue, "\$84K", Icons.attach_money, Colors.green),
            _buildInfoCard(l10n.lowStock, "12 Items", Icons.warning, Colors.red),
          ],
        );
      },
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, 
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.arrow_upward, color: Colors.green, size: 14),
              SizedBox(width: 4),
              Expanded(
                child: Text("12% vs last month", style: TextStyle(color: Colors.green, fontSize: 12), overflow: TextOverflow.ellipsis),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildProductionChart(AppLocalizations l10n) {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text("Production Output", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryColor), overflow: TextOverflow.ellipsis)),
              const Icon(Icons.more_horiz, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.blue.shade50),
              child: CustomPaint(painter: _DemoChartPainter(color: _primaryColor)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRecentActivityList(AppLocalizations l10n) {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.recentActivities, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryColor)),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(backgroundColor: Colors.grey.shade200, child: Icon(Icons.inventory, color: _primaryColor, size: 18)),
                  title: Text("Order #202${index + 1}", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text("Just now", style: TextStyle(fontSize: 12)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                    child: const Text("Done", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class _DemoChartPainter extends CustomPainter {
  final Color color;
  _DemoChartPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 3..style = PaintingStyle.stroke;
    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(size.width * 0.2, size.height * 0.9, size.width * 0.4, size.height * 0.6);
    path.quadraticBezierTo(size.width * 0.6, size.height * 0.3, size.width * 0.8, size.height * 0.5);
    path.lineTo(size.width, size.height * 0.2);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}