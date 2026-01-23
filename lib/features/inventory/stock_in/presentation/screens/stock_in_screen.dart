import 'package:flutter/material.dart';
import '../../../../../core/widgets/responsive_layout.dart';
import '../../../../../l10n/app_localizations.dart'; // Import localization
import 'stock_in_tabs.dart'; 

class StockInScreen extends StatefulWidget {
  const StockInScreen({super.key});

  @override
  State<StockInScreen> createState() => _StockInScreenState();
}

class _StockInScreenState extends State<StockInScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Theme Colors
  final Color _primaryColor = const Color(0xFF003366);
  final Color _bgLight = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final l10n = AppLocalizations.of(context)!; 

    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // [FIX] Tăng chiều cao Toolbar lên 80 để không bị che title khi có subtitle
        toolbarHeight: 80, 
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.input, color: Colors.green, size: 24),
            ),
            const SizedBox(width: 12),
            // [FIX] Thêm Expanded để text không bị lỗi layout nếu quá dài
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center, // Canh giữa dọc
                children: [
                  Text(
                    l10n.stockInTitle, 
                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4), // Thêm khoảng cách nhỏ giữa 2 dòng
                  Text(
                    l10n.stockInSubtitle, 
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Colors.white,
            alignment: Alignment.centerLeft,
            child: TabBar(
              controller: _tabController,
              isScrollable: !isDesktop, 
              labelColor: _primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: _primaryColor,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: [
                Tab(text: l10n.tabMaterial, icon: const Icon(Icons.layers)),
                Tab(text: l10n.tabSemiFinished, icon: const Icon(Icons.build_circle)),
                Tab(text: l10n.tabFinished, icon: const Icon(Icons.check_circle)), 
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // Tắt vuốt ngang
        children: const [
          // 1. Nhập nguyên vật liệu (Logic thật)
          MaterialStockInTab(),
          
          // 2. Nhập bán thành phẩm (Mẫu)
          SemiFinishedStockInTab(),
          
          // 3. Nhập thành phẩm (Mẫu)
          FinishedProductStockInTab(),
        ],
      ),
    );
  }
}