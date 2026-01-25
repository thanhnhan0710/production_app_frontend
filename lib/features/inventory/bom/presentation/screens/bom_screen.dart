import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:production_app_frontend/core/widgets/responsive_layout.dart';
import 'package:production_app_frontend/l10n/app_localizations.dart';

// Domain & Bloc
import '../../domain/bom_model.dart';
import '../bloc/bom_cubit.dart';

// Product Feature
import 'package:production_app_frontend/features/inventory/product/domain/product_model.dart';
import 'package:production_app_frontend/features/inventory/product/presentation/bloc/product_cubit.dart';

// Screens
import 'bom_detail_screen.dart'; // Màn hình xem chi tiết
import 'create_bom_screen.dart'; // [MỚI] Màn hình tạo/sửa trọn gói

class BOMScreen extends StatefulWidget {
  final int? filterProductId;
  const BOMScreen({super.key, this.filterProductId});

  @override
  State<BOMScreen> createState() => _BOMScreenState();
}

class _BOMScreenState extends State<BOMScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  final Color _primaryColor = const Color(0xFF003366);
  final Color _bgLight = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _loadData();
    // Load danh sách sản phẩm để map ID -> Name hiển thị
    context.read<ProductCubit>().loadProducts();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    // [FIX 1] Dùng đúng tên hàm: loadBOMHeaders
    context.read<BOMCubit>().loadBOMHeaders(productId: widget.filterProductId);
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      // Hiện tại reload lại list, nếu sau này có search API thì gọi ở đây
      _loadData(); 
    });
  }

  // [UPDATED] Hàm điều hướng sang màn hình Tạo/Sửa BOM (Full màn hình)
  void _navigateToCreateOrEdit({BOMHeader? bom}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateBOMScreen(existingBOM: bom), // Gọi màn hình mới
      ),
    );

    // Reload khi quay lại nếu có thay đổi (kết quả trả về true)
    if (result == true || result != null) {
      _loadData();
    }
  }

  // Hàm điều hướng sang màn hình Chi tiết (Read-only hoặc chỉnh sửa nhanh)
  void _navigateToDetailView(BOMHeader bom) {
     Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BOMDetailScreen(bomId: bom.bomId),
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _bgLight,
      body: SelectionArea(
        child: BlocConsumer<BOMCubit, BOMState>(
          listener: (context, state) {
            if (state is BOMError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.red),
              );
            }
          },
          builder: (context, state) {
            List<BOMHeader> boms = [];
            bool isLoading = false;

            if (state is BOMLoading) {
              isLoading = true;
            } else if (state is BOMListLoaded) { // [FIX 2] Dùng đúng tên State
              boms = state.boms;
              if (widget.filterProductId != null) {
                boms = boms.where((b) => b.productId == widget.filterProductId).toList();
              }
              
              // Filter client-side tạm thời cho search bar
              if (_searchController.text.isNotEmpty) {
                final k = _searchController.text.toLowerCase();
                boms = boms.where((b) => b.bomCode.toLowerCase().contains(k) || b.bomName.toLowerCase().contains(k)).toList();
              }
            } else if (state is BOMDetailViewLoaded) {
               // Fallback state
               return Center(child: CircularProgressIndicator(color: _primaryColor));
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- HEADER SECTION ---
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.layers, color: Colors.indigo.shade800, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.bomTitle, 
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Manage Yarn BOMs & Technical Specs",
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                          const Spacer(),
                          if (isDesktop)
                            ElevatedButton.icon(
                              // [UPDATED] Gọi màn hình Create Mới
                              onPressed: () => _navigateToCreateOrEdit(bom: null),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text("CREATE BOM"), 
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // --- SEARCH BAR ---
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: _bgLight,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: TextField(
                                controller: _searchController,
                                textInputAction: TextInputAction.search,
                                decoration: InputDecoration(
                                  hintText: "Search BOM Code...",
                                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                  suffixIcon: _searchController.text.isNotEmpty 
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          _loadData();
                                        },
                                      ) 
                                    : null,
                                ),
                                onChanged: _onSearchChanged,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: _loadData,
                            icon: const Icon(Icons.refresh, color: Colors.grey),
                            tooltip: "Refresh",
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                Container(height: 1, color: Colors.grey.shade200),

                // --- CONTENT ---
                Expanded(
                  child: isLoading && boms.isEmpty
                      ? Center(child: CircularProgressIndicator(color: _primaryColor))
                      : boms.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.layers_clear, size: 60, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                  Text(loc.noBOMFound, style: TextStyle(color: Colors.grey.shade500)),
                                ],
                              ),
                            )
                          : isDesktop
                              ? _buildDesktopTable(context, boms, loc)
                              : _buildMobileList(context, boms, loc),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: !isDesktop
          ? FloatingActionButton(
              backgroundColor: _primaryColor,
              // [UPDATED] Gọi màn hình Create Mới
              onPressed: () => _navigateToCreateOrEdit(bom: null),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  // --- DESKTOP TABLE ---
  Widget _buildDesktopTable(BuildContext context, List<BOMHeader> items, AppLocalizations loc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(const Color(0xFFF9FAFB)),
                    horizontalMargin: 24,
                    columnSpacing: 24,
                    dataRowMinHeight: 60,
                    dataRowMaxHeight: 60,
                    columns: [
                      DataColumn(label: Text(loc.bomCode.toUpperCase(), style: _headerStyle)),
                      DataColumn(label: Text("PRODUCT", style: _headerStyle)),
                      DataColumn(label: Text("TARGET (g/m)", style: _headerStyle)),
                      DataColumn(label: Text("WIDTH (mm)", style: _headerStyle)),
                      DataColumn(label: Text(loc.version.toUpperCase(), style: _headerStyle)),
                      DataColumn(label: Text(loc.status.toUpperCase(), style: _headerStyle)),
                      DataColumn(label: Text("UPDATED", style: _headerStyle)),
                      DataColumn(label: Text(loc.actions.toUpperCase(), style: _headerStyle)),
                    ],
                    rows: items.map((bom) {
                      return DataRow(
                        // Nhấn vào hàng thì xem chi tiết
                        onSelectChanged: (_) => _navigateToDetailView(bom),
                        cells: [
                          DataCell(Text(bom.bomCode, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                          // Product Name
                          DataCell(
                            BlocBuilder<ProductCubit, ProductState>(
                              builder: (context, pState) {
                                if (pState is ProductLoaded) {
                                  // [FIX 3] Tìm sản phẩm an toàn
                                  final p = pState.products.where((e) => e.id == bom.productId).firstOrNull;
                                  if (p != null) {
                                    return Text(p.itemCode, style: const TextStyle(fontWeight: FontWeight.w500));
                                  }
                                }
                                return Text("ID: ${bom.productId}");
                              },
                            ),
                          ),
                          DataCell(Text(bom.targetWeightGm.toStringAsFixed(2))),
                          DataCell(Text(bom.widthBehindLoom?.toString() ?? "-")),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                              child: Text("v${bom.version}", style: TextStyle(color: Colors.blue.shade800, fontSize: 12, fontWeight: FontWeight.bold)),
                            )
                          ),
                          DataCell(_buildStatusBadge(bom.isActive, loc)),
                          DataCell(Text(
                            bom.updatedAt != null ? DateFormat('dd/MM/yyyy').format(bom.updatedAt!) : "-",
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          )),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: Colors.orange, size: 20),
                                  tooltip: "Edit BOM",
                                  // [UPDATED] Nút Sửa gọi màn hình CreateBOMScreen để sửa toàn bộ
                                  onPressed: () => _navigateToCreateOrEdit(bom: bom),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                  onPressed: () => _confirmDelete(context, bom),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  TextStyle get _headerStyle => TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5);

  Widget _buildStatusBadge(bool isActive, AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isActive ? Colors.green.shade200 : Colors.grey.shade300),
      ),
      child: Text(
        isActive ? loc.active : loc.inactive,
        style: TextStyle(
          color: isActive ? Colors.green.shade700 : Colors.grey.shade600,
          fontSize: 11, fontWeight: FontWeight.bold
        ),
      ),
    );
  }

  // --- MOBILE LIST ---
  Widget _buildMobileList(BuildContext context, List<BOMHeader> items, AppLocalizations loc) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final bom = items[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _navigateToDetailView(bom),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(bom.bomCode, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      _buildStatusBadge(bom.isActive, loc),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  BlocBuilder<ProductCubit, ProductState>(
                    builder: (context, pState) {
                      String pName = "PID: ${bom.productId}";
                      if (pState is ProductLoaded) {
                        final p = pState.products.where((e) => e.id == bom.productId).firstOrNull;
                        if (p != null) pName = p.itemCode;
                      }
                      return Row(
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 16, color: Colors.grey.shade500),
                          const SizedBox(width: 6),
                          Text(pName, style: const TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      );
                    },
                  ),
                  
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.scale, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Text("Target: ${bom.targetWeightGm} g/m", style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                      const SizedBox(width: 12),
                      Icon(Icons.straighten, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Text("Width: ${bom.widthBehindLoom ?? '-'} mm", style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                    ],
                  ),
                  
                  if (bom.bomName.isNotEmpty) ...[
                    const Divider(height: 16),
                    Text(bom.bomName, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
                  ]
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, BOMHeader item) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.deleteBOM),
        content: Text("Confirm delete BOM ${item.bomCode}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.cancel)),
          TextButton(
            onPressed: () {
              context.read<BOMCubit>().deleteBOMHeader(item.bomId);
              Navigator.pop(ctx);
            }, 
            child: Text(loc.delete, style: const TextStyle(color: Colors.red))
          )
        ],
      )
    );
  }
}