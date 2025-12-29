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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    // Lấy đường dẫn hiện tại để highlight menu
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
          : Drawer(child: _buildSidebar(context, l10n, isMobile: true, currentPath: currentPath)),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            SizedBox(
              width: 280,
              child: _buildSidebar(context, l10n, isMobile: false, currentPath: currentPath),
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
  Widget _buildSidebar(BuildContext context, AppLocalizations l10n, {required bool isMobile, required String currentPath}) {
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
                  _buildMenuItem(context, Icons.dashboard, l10n.dashboard, '/dashboard', isMobile, currentPath),
                  _buildMenuItem(context, Icons.precision_manufacturing, l10n.production, '/production', isMobile, currentPath),
                  
                  // --- INVENTORY GROUP (Kho + Vật liệu + Sợi + Lô Sợi + Nhà cung cấp) ---
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: currentPath.startsWith('/inventory') || 
                                       currentPath.startsWith('/materials') ||
                                       currentPath.startsWith('/yarns') || 
                                       currentPath.startsWith('/yarn-lots') ||
                                       currentPath.startsWith('/suppliers')||
                                       currentPath.startsWith('/units'),
                      leading: const Icon(Icons.inventory_2, color: Colors.white70),
                      title: Text(l10n.inventory, style: const TextStyle(color: Colors.white70)),
                      iconColor: Colors.white,
                      collapsedIconColor: Colors.white70,
                      childrenPadding: const EdgeInsets.only(left: 20),
                      children: [
                        _buildSubMenuItem(context, "Items", '/inventory', isMobile, currentPath),
                        // [MỚI] Nguyên vật liệu
                        _buildSubMenuItem(context, l10n.materialTitle, '/materials', isMobile, currentPath),
                        // Sợi
                        _buildSubMenuItem(context, l10n.yarnTitle, '/yarns', isMobile, currentPath),
                        // Lô Sợi
                        _buildSubMenuItem(context, l10n.yarnLotTitle, '/yarn-lots', isMobile, currentPath),
                        // Nhà cung cấp
                        _buildSubMenuItem(context, l10n.supplierTitle, '/suppliers', isMobile, currentPath),
                        _buildSubMenuItem(context, l10n.unitTitle, '/units', isMobile, currentPath),
                      ],
                    ),
                  ),
                  
                  // --- HR GROUP (Bộ phận + Nhân viên) ---
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: currentPath.startsWith('/departments') || currentPath.startsWith('/employees'),
                      leading: const Icon(Icons.people, color: Colors.white70),
                      title: Text(l10n.hr, style: const TextStyle(color: Colors.white70)),
                      iconColor: Colors.white,
                      collapsedIconColor: Colors.white70,
                      childrenPadding: const EdgeInsets.only(left: 20),
                      children: [
                        _buildSubMenuItem(context, l10n.departmentTitle, '/departments', isMobile, currentPath),
                        _buildSubMenuItem(context, l10n.employeeTitle, '/employees', isMobile, currentPath),
                      ],
                    ),
                  ),

                  _buildMenuItem(context, Icons.shopping_cart, l10n.sales, '/sales', isMobile, currentPath),
                  _buildMenuItem(context, Icons.bar_chart, l10n.reports, '/reports', isMobile, currentPath),
                  _buildMenuItem(context, Icons.settings, l10n.settings, '/settings', isMobile, currentPath),
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

  // Item cấp 1
  Widget _buildMenuItem(BuildContext context, IconData icon, String title, String route, bool isMobile, String currentPath) {
    final bool isActive = currentPath == route;
    
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
      onTap: () {
        context.go(route);
        if (isMobile) Navigator.pop(context);
      },
    );
  }

  // Item cấp 2 (Sub-menu)
  Widget _buildSubMenuItem(BuildContext context, String title, String route, bool isMobile, String currentPath) {
    final bool isActive = currentPath.startsWith(route) && (route != '/' || currentPath == '/');

    return Container(
      color: Colors.black12,
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 54, right: 16),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
        dense: true,
        onTap: () {
          context.go(route);
          if (isMobile) Navigator.pop(context);
        },
      ),
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