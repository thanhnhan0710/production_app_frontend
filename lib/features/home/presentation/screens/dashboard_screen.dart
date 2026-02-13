import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:production_app_frontend/l10n/app_localizations.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/bloc/language_cubit.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
// [QUAN TRỌNG] Import AuthState để lấy user info

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
    if (route == '#') {
      _showUnderDevelopmentDialog();
    } else {
      context.go(route);
      if (ResponsiveLayout.isMobile(context)) {
        Navigator.pop(context);
      }
    }
  }

  void _showUnderDevelopmentDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.construction, color: Colors.orange),
            const SizedBox(width: 10),
            Text(l10n.notice),
          ],
        ),
        content: Text(l10n.featureUnderDevelopment),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    // [NEW] Lấy thông tin user hiện tại từ AuthCubit
    final authState = context.watch<AuthCubit>().state;
    String userRole = 'Staff';
    String userName = 'User';
    bool isAdmin = false;

    if (authState is AuthAuthenticated) {
      userRole = authState.user.role;
      userName = authState.user.fullName;
      // Kiểm tra quyền Admin (role = admin hoặc superuser = true)
      isAdmin = (userRole == 'admin' || authState.user.isSuperuser);
    }

    String currentPath = '/dashboard';
    try {
      currentPath = GoRouterState.of(context).uri.path;
    } catch (e) {
      // Fallback
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _backgroundColor,
      // [UPDATED] AppBar cho Mobile có nút đổi ngôn ngữ
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: _primaryColor,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              title: Text(l10n.erpSystemShort,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              centerTitle: false,
              actions: [
                // [NEW] Nút đổi ngôn ngữ trên Mobile
                Center(
                  child: _buildLanguageIcon(context),
                ),
                const SizedBox(width: 12),

                IconButton(
                  icon: const CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, size: 16, color: Colors.white),
                  ),
                  onPressed: () {
                    // Có thể thêm hành động mở profile ở đây
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
      drawer: isDesktop
          ? null
          // Truyền quyền vào hàm build Sidebar
          : Drawer(child: _buildSidebar(context, l10n, currentPath, isAdmin)),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            SizedBox(
              width: 280,
              // Truyền quyền vào hàm build Sidebar
              child: _buildSidebar(context, l10n, currentPath, isAdmin),
            ),
          Expanded(
            child: Column(
              children: [
                if (isDesktop)
                  _buildDesktopTopBar(context, l10n, userName, userRole),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (currentPath == '/dashboard') ...[
                          // Banner chào mừng
                          _buildWelcomeBanner(l10n, userName),
                          const SizedBox(height: 32),

                          // Grid truy cập nhanh
                          Text(
                            l10n.quickAccess,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildQuickAccessGrid(context, l10n, isAdmin),
                        ] else ...[
                          // Placeholder cho các trang chưa có
                          Container(
                            height: 500,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.build_circle_outlined,
                                    size: 64, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text(l10n.pageContent(currentPath),
                                    style: TextStyle(
                                        color: Colors.grey[500], fontSize: 18)),
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

  // --- WIDGETS GIAO DIỆN ---

  Widget _buildWelcomeBanner(AppLocalizations l10n, String userName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryColor, _primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.welcome(userName),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Oppermann ERP System",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessGrid(
      BuildContext context, AppLocalizations l10n, bool isAdmin) {
    // Danh sách các module truy cập nhanh theo yêu cầu
    final List<Map<String, dynamic>> modules = [
      {
        'title': l10n.machineBasketInfo, // Thông tin máy và rổ dệt
        'icon': Icons.precision_manufacturing,
        'color': Colors.orange.shade700,
        'route': '/machine-operation',
      },
      {
        'title': l10n.stockInTitle, // Danh sách sản phẩm nhập kho NVL
        'icon': Icons.move_to_inbox,
        'color': Colors.blue.shade700,
        'route': '/stock-in',
      },
      {
        'title': l10n.materialExport, // Xuất kho nguyên vật liệu
        'icon': Icons.output,
        'color': Colors.teal.shade700,
        'route': '/material-exports',
      },
      {
        'title': l10n.scheduleTitle, // Lịch làm việc
        'icon': Icons.calendar_month,
        'color': Colors.green.shade700,
        'route': '/schedules',
      },
      {
        'title': l10n.materialTitle, // Danh sách nguyên vật liệu
        'icon': Icons.layers,
        'color': Colors.purple.shade700,
        'route': '/materials',
      },
    ];

    // Chỉ Admin mới thấy Nhật ký hoạt động
    if (isAdmin) {
      modules.add({
        'title': l10n.activityLog, // Nhật ký hoạt động
        'icon': Icons.history,
        'color': Colors.grey.shade700,
        'route': '/logs',
      });
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Điều chỉnh số cột dựa trên kích thước màn hình
        int crossAxisCount = 4;
        if (constraints.maxWidth < 600) {
          crossAxisCount = 2;
          // ignore: curly_braces_in_flow_control_structures
        } else if (constraints.maxWidth < 1000) crossAxisCount = 3;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16, // Giảm spacing 1 chút cho mobile
            mainAxisSpacing: 16,
            childAspectRatio: 1.3, // Card hình chữ nhật ngang
          ),
          itemCount: modules.length,
          itemBuilder: (context, index) {
            final item = modules[index];
            return _buildModuleCard(
              title: item['title'],
              icon: item['icon'],
              color: item['color'],
              onTap: () => _onNavigate(item['route']),
            );
          },
        );
      },
    );
  }

  Widget _buildModuleCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16), // Padding vừa phải
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: color), // Icon size 28
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- SIDEBAR & MENU ---
  // [UPDATED] Thêm tham số isAdmin
  Widget _buildSidebar(BuildContext context, AppLocalizations l10n,
      String currentPath, bool isAdmin) {
    return Container(
      color: _primaryColor,
      child: Column(
        children: [
          // HEADER
          Container(
            height: 130,
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
            color: Colors.black12,
            child: Row(
              children: [
                const Icon(Icons.apartment, color: Colors.white, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.oppermannHeader,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(l10n.erpSystemShort,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                          overflow: TextOverflow.ellipsis),
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
                  _buildMenuItem(Icons.dashboard, l10n.dashboard, '/dashboard',
                      currentPath),

                  // ================= KHO (INVENTORY) =================
                  _buildExpansionGroup(
                    icon: Icons.inventory_2,
                    title: l10n.inventory,
                    currentPath: currentPath,
                    childrenRoutes: [
                      '/warehouses',
                      '/materials',
                      '/suppliers',
                      '/products',
                      '/units',
                      '/dye-colors',
                      '/import-declarations',
                      '/purchase-orders',
                      '/stock-in',
                      '/material-exports',
                      '/inventorys',
                      '/batches'
                    ],
                    children: [
                      // 1. Thông tin chung
                      _buildSubExpansionGroup(
                          title: l10n.generalInfo,
                          currentPath: currentPath,
                          childrenRoutes: [
                            '/warehouses',
                            '/materials',
                            '/suppliers',
                            '/products',
                            '/units',
                            '/dye-colors'
                          ],
                          children: [
                            _buildLevel3MenuItem(
                                Icons.store_mall_directory,
                                l10n.warehouseTitle,
                                '/warehouses',
                                currentPath),
                            _buildLevel3MenuItem(Icons.layers,
                                l10n.materialTitle, '/materials', currentPath),
                            _buildLevel3MenuItem(Icons.local_shipping,
                                l10n.supplierTitle, '/suppliers', currentPath),
                            _buildLevel3MenuItem(Icons.shopping_bag,
                                l10n.productTitle, '/products', currentPath),
                            _buildLevel3MenuItem(Icons.straighten,
                                l10n.unitTitle, '/units', currentPath),
                            _buildLevel3MenuItem(Icons.color_lens,
                                l10n.dyeColorTitle, '/dye-colors', currentPath),
                          ]),

                      // 2. Đơn mua NVL
                      _buildSubExpansionGroup(
                          title: l10n.materialPurchaseOrders,
                          currentPath: currentPath,
                          childrenRoutes: [
                            '/import-declarations',
                            '/purchase-orders'
                          ],
                          children: [
                            _buildLevel3MenuItem(
                                Icons.receipt_long,
                                l10n.importDeclarationTitle,
                                '/import-declarations',
                                currentPath),
                            _buildLevel3MenuItem(
                                Icons.shopping_cart_checkout,
                                l10n.purchaseOrderTitle,
                                '/purchase-orders',
                                currentPath),
                          ]),

                      // 3. Nhập Xuất kho
                      _buildSubExpansionGroup(
                          title: l10n.importExport,
                          currentPath: currentPath,
                          childrenRoutes: [
                            '/stock-in',
                            '/material-exports'
                          ],
                          children: [
                            _buildLevel3MenuItem(Icons.move_to_inbox,
                                l10n.stockInTitle, '/stock-in', currentPath),

                            // Header giả lập cho Xuất kho
                            _buildSubHeader(l10n.stockOutHeader),
                            _buildLevel3MenuItem(
                                Icons.output,
                                l10n.materialExport,
                                '/material-exports',
                                currentPath),
                            _buildLevel3MenuItem(Icons.output,
                                l10n.semiFinishedExport, '#', currentPath),
                            _buildLevel3MenuItem(Icons.output,
                                l10n.finishedProductExport, '#', currentPath),
                          ]),

                      // 4. Tồn kho
                      _buildSubExpansionGroup(
                          title: l10n.inventoryStock,
                          currentPath: currentPath,
                          childrenRoutes: [
                            '/inventorys'
                          ],
                          children: [
                            _buildLevel3MenuItem(Icons.grid_view,
                                l10n.materialTitle, '/inventorys', currentPath),
                            _buildLevel3MenuItem(Icons.grid_view,
                                l10n.semiFinishedProducts, '#', currentPath),
                            _buildLevel3MenuItem(Icons.grid_view,
                                l10n.finishedProducts, '#', currentPath),
                          ]),

                      // 5. Quản lý lô
                      _buildSubExpansionGroup(
                          title: l10n.batchManagement,
                          currentPath: currentPath,
                          childrenRoutes: [
                            '/batches'
                          ],
                          children: [
                            _buildLevel3MenuItem(Icons.fact_check,
                                l10n.materialBatches, '/batches', currentPath),
                          ]),
                    ],
                  ),

                  // ================= SẢN XUẤT (PRODUCTION) =================
                  _buildExpansionGroup(
                      icon: Icons.precision_manufacturing,
                      title: l10n.production,
                      currentPath: currentPath,
                      childrenRoutes: [
                        '/machines',
                        '/baskets',
                        '/machine-operation',
                        '/weaving',
                        '/weaving-productions',
                        '/boms',
                        '/standards'
                      ],
                      children: [
                        // 1. Thông tin chung
                        _buildSubExpansionGroup(
                            title: l10n.generalInfo,
                            currentPath: currentPath,
                            childrenRoutes: [
                              '/machines',
                              '/baskets'
                            ],
                            children: [
                              _buildLevel3MenuItem(
                                  Icons.settings_input_component,
                                  l10n.machineTitle,
                                  '/machines',
                                  currentPath),
                              _buildLevel3MenuItem(Icons.all_inbox,
                                  l10n.basketTitle, '/baskets', currentPath),
                            ]),
                        // 2. Dệt
                        _buildSubExpansionGroup(
                            title: l10n.weaving,
                            currentPath: currentPath,
                            // [CẬP NHẬT] Danh sách route con để highlight menu cha
                            childrenRoutes: [
                              '/machine-operation',
                              '/weaving-management'
                            ],
                            children: [
                              _buildLevel3MenuItem(
                                  Icons.precision_manufacturing,
                                  l10n.machineBasketInfo,
                                  '/machine-operation',
                                  currentPath),

                              // [MỚI] Menu tổng hợp trỏ về trang Management
                              _buildLevel3MenuItem(
                                  Icons.dashboard_customize,
                                  l10n.weavingManagement, // Tên mới
                                  '/weaving-management', // Route mới
                                  currentPath),
                            ]),
                        // Các mục đơn (Level 2)
                        _buildSubMenuItem(Icons.format_color_fill, l10n.dyeing,
                            '#', currentPath),
                        _buildSubMenuItem(
                            Icons.print, l10n.printing, '#', currentPath),
                        _buildSubMenuItem(Icons.shield,
                            l10n.safeFinishedProducts, '#', currentPath),

                        // Đóng gói Group
                        _buildSubExpansionGroup(
                            title: l10n.packing,
                            currentPath: currentPath,
                            childrenRoutes: [],
                            children: [
                              _buildLevel3MenuItem(
                                  Icons.album, l10n.rolling, '#', currentPath),
                              _buildLevel3MenuItem(Icons.content_cut,
                                  l10n.cutting, '#', currentPath),
                            ]),
                      ]),

                  // ================= QC =================
                  _buildExpansionGroup(
                      icon: Icons.check_circle_outline,
                      title: "QC",
                      currentPath: currentPath,
                      childrenRoutes: [
                        '/boms',
                        '/standards'
                      ],
                      children: [
                        _buildSubMenuItem(Icons.account_tree, l10n.bomTitle,
                            '/boms', currentPath),
                        _buildSubMenuItem(Icons.assignment, l10n.standardTitle,
                            '/standards', currentPath),
                      ]),

                  // ================= SALE (CHƯA PHÁT TRIỂN) =================
                  _buildMenuItem(
                      Icons.shopping_cart, l10n.sales, '#', currentPath),

                  // ================= NHÂN SỰ (HR) =================
                  _buildExpansionGroup(
                      icon: Icons.people,
                      title: l10n.hr,
                      currentPath: currentPath,
                      childrenRoutes: [
                        '/departments',
                        '/employees',
                        '/shifts',
                        '/schedules'
                      ],
                      children: [
                        _buildSubMenuItem(Icons.domain, l10n.departmentTitle,
                            '/departments', currentPath),
                        _buildSubMenuItem(Icons.badge, l10n.employeeTitle,
                            '/employees', currentPath),
                        _buildSubMenuItem(Icons.access_time, l10n.shiftTitle,
                            '/shifts', currentPath),
                        _buildSubMenuItem(Icons.calendar_month,
                            l10n.scheduleTitle, '/schedules', currentPath),
                      ]),

                  // ================= REPORT (CHƯA PHÁT TRIỂN) =================
                  _buildMenuItem(
                      Icons.bar_chart, l10n.reports, '#', currentPath),

                  // ================= ADMINISTRATOR (CHỈ HIỂN THỊ VỚI ADMIN) =================
                  // [LOGIC] Ẩn hiện menu Admin
                  if (isAdmin)
                    _buildExpansionGroup(
                        icon: Icons.admin_panel_settings,
                        title: l10n.adminTitle,
                        currentPath: currentPath,
                        childrenRoutes: [
                          '/users',
                          '/logs'
                        ],
                        children: [
                          _buildSubMenuItem(Icons.manage_accounts,
                              l10n.userManagementTitle, '/users', currentPath),
                          _buildSubMenuItem(Icons.history, l10n.activityLog,
                              '/logs', currentPath),
                        ]),

                  // ================= SETTING (CHƯA PHÁT TRIỂN) =================
                  _buildMenuItem(
                      Icons.settings, l10n.settings, '#', currentPath),
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

  Widget _buildMenuItem(
      IconData icon, String title, String route, String currentPath) {
    final bool isActive = route != '#' && currentPath == route;

    return ListTile(
      leading:
          Icon(icon, color: isActive ? Colors.white : Colors.white70, size: 20),
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

  Widget _buildExpansionGroup({
    required IconData icon,
    required String title,
    required String currentPath,
    required List<String> childrenRoutes,
    required List<Widget> children,
  }) {
    final bool isExpanded =
        childrenRoutes.any((r) => currentPath.startsWith(r) && r != '/');

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

  Widget _buildSubExpansionGroup({
    required String title,
    required String currentPath,
    required List<String> childrenRoutes,
    required List<Widget> children,
  }) {
    final bool isExpanded =
        childrenRoutes.any((r) => currentPath.startsWith(r) && r != '/');

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        title: Text(title,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        tilePadding: const EdgeInsets.only(left: 32, right: 16),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white70,
        childrenPadding: EdgeInsets.zero,
        backgroundColor: Colors.black12,
        children: children,
      ),
    );
  }

  Widget _buildSubMenuItem(
      IconData icon, String title, String route, String currentPath) {
    final bool isActive = route != '#' &&
        currentPath.startsWith(route) &&
        (route != '/' || currentPath == '/');
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 32, right: 16),
      leading:
          Icon(icon, color: isActive ? Colors.white : Colors.white70, size: 18),
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

  Widget _buildSubHeader(String title) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 48, right: 16),
      title: Text(title,
          style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontStyle: FontStyle.italic)),
      dense: true,
    );
  }

  Widget _buildLevel3MenuItem(
      IconData icon, String title, String route, String currentPath) {
    final bool isActive = route != '#' && currentPath.startsWith(route);

    return ListTile(
      contentPadding: const EdgeInsets.only(left: 48, right: 16),
      leading:
          Icon(icon, color: isActive ? Colors.white : Colors.white70, size: 16),
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
  // [UPDATED] Hiển thị tên user và role thực tế
  Widget _buildDesktopTopBar(BuildContext context, AppLocalizations l10n,
      String userName, String userRole) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8)),
              child: TextField(
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: l10n.searchPlaceholder,
                  icon: const Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          _buildLanguageIcon(context),
          const SizedBox(width: 20),
          Row(
            children: [
              CircleAvatar(
                  backgroundColor: _primaryColor.withOpacity(0.1),
                  child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : "U",
                      style: TextStyle(color: _primaryColor))),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(userName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(userRole.toUpperCase(),
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12)),
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
        decoration:
            BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade100),
        child: Text(currentLocale.languageCode == 'vi' ? "🇻🇳" : "🇺🇸",
            style: const TextStyle(fontSize: 20)),
      ),
    );
  }
}
