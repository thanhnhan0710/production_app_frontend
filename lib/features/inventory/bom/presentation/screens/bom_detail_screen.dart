// D:\AppHeThong\production_app_frontend\lib\features\inventory\bom\presentation\screens\bom_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:production_app_frontend/core/widgets/responsive_layout.dart';
import 'package:production_app_frontend/l10n/app_localizations.dart';

// Models
import '../../domain/bom_model.dart';
import '../../../product/presentation/bloc/product_cubit.dart';

// Cubits
import '../bloc/bom_cubit.dart';
import '../../../material/presentation/bloc/material_cubit.dart' as mat_bloc;

// Import file dialog
import 'material_detail_dialog.dart';

class BOMDetailScreen extends StatefulWidget {
  final int? bomId;

  const BOMDetailScreen({super.key, required this.bomId});

  @override
  State<BOMDetailScreen> createState() => _BOMDetailScreenState();
}

class _BOMDetailScreenState extends State<BOMDetailScreen> {
  final _numberFormat = NumberFormat("#,##0.00");
  final _percentFormat = NumberFormat("#,##0.00'%'");

  @override
  void initState() {
    super.initState();
    // Load dữ liệu ban đầu
    if (widget.bomId != null) {
      context.read<BOMCubit>().loadBOMDetailView(widget.bomId!);
    }
    context.read<mat_bloc.MaterialCubit>().loadMaterials();
    context.read<ProductCubit>().loadProducts();
  }

  // --- HELPER: MÀU SẮC CHO TỪNG LOẠI COMPONENT ---
  Color _getComponentColor(BOMComponentType type) {
    switch (type) {
      case BOMComponentType.ground: return Colors.blue.shade700;
      case BOMComponentType.grdMarker: return Colors.blue.shade300;
      case BOMComponentType.filling: return Colors.orange.shade800;
      case BOMComponentType.secondFilling: return Colors.orange.shade400;
      case BOMComponentType.edge: return Colors.green.shade600;
      case BOMComponentType.binder: return Colors.purple.shade600;
      case BOMComponentType.stuffer: return Colors.grey.shade700;
      case BOMComponentType.stufferMaker: return Colors.blueGrey.shade400;
      case BOMComponentType.lock: return Colors.lightGreen.shade400;
      case BOMComponentType.catchCord: return Colors.teal;
      }
  }

  // --- LOGIC: HIỂN THỊ DIALOG THÊM/SỬA ---
  void _showAddEditDetailDialog(BuildContext context, BOMDetail? detail, BOMHeader header) async {
    final BOMDetail? result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MaterialDetailDialog(
        detail: detail, 
        bomId: header.bomId, // Truyền bomId chính xác
      ),
    );

    if (result != null && mounted) {
      // Gọi Cubit để lưu
      context.read<BOMCubit>().saveBOMDetail(result, detail != null);
    }
  }

  // --- LOGIC: XÓA ---
  void _confirmDeleteDetail(BuildContext context, BOMDetail detail, int bomId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Remove component '${detail.yarnTypeName}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text("Cancel")
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<BOMCubit>().deleteBOMDetail(detail.detailId, bomId);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final loc = AppLocalizations.of(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("BOM Configuration"),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, true),
        ),
      ),
      body: BlocConsumer<BOMCubit, BOMState>(
        listener: (context, state) {
          if (state is BOMError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red)
            );
          }
          if (state is BOMOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green)
            );
          }
        },
        builder: (context, state) {
          if (state is BOMLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          BOMHeader? bom;
          if (state is BOMDetailViewLoaded) {
            bom = state.bom;
          }

          if (bom == null) return const Center(child: Text("BOM not found or Loading..."));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 1. HEADER INFO ---
              _buildHeaderInfo(context, bom),

              // --- 2. DETAILS LIST/TABLE ---
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Components (${bom.bomDetails.length})",
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF003366)),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _showAddEditDetailDialog(context, null, bom!),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text("Add Component"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE3F2FD),
                                foregroundColor: const Color(0xFF0055AA),
                              ),
                            )
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: isDesktop
                            ? _buildDesktopTable(bom.bomDetails, bom)
                            : _buildMobileList(bom.bomDetails, bom),
                      ),
                    ],
                  ),
                ),
              ),

              // --- 3. FOOTER SUMMARY ---
              _buildFooterSummary(bom),
            ],
          );
        },
      ),
    );
  }

  // === 1. HEADER INFO WIDGET ===
  Widget _buildHeaderInfo(BuildContext context, BOMHeader bom) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                          // [UPDATE] Dùng applicableYear từ model mới
                          child: Text(
                            "Year ${bom.applicableYear}",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16)
                          ),
                        ),
                        const SizedBox(width: 12),
                        // [UPDATE] Dùng displayName từ model mới
                        Expanded(
                          child: Text(
                            bom.displayName ?? 'Production BOM', 
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    BlocBuilder<ProductCubit, ProductState>(
                      builder: (context, state) {
                        String pName = "PID: ${bom.productId}";
                        if (state is ProductLoaded) {
                          final p = state.products.where((e) => e.id == bom.productId).firstOrNull;
                          if (p != null) {
                            pName = p.itemCode; // Chỉ hiện ItemCode
                          }
                        }
                        return Text("Product Code: $pName", style: TextStyle(color: Colors.grey.shade600));
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Wrap( // Dùng Wrap để tránh overflow trên màn hình nhỏ
                  spacing: 20,
                  runSpacing: 10,
                  alignment: WrapAlignment.end,
                  children: [
                    _buildStatItem("Target", "${_numberFormat.format(bom.targetWeightGm)} g/m"),
                    _buildStatItem("Width", bom.widthBehindLoom != null ? "${bom.widthBehindLoom} mm" : "-"),
                    _buildStatItem("Picks", "${bom.picks ?? '-'}"),
                    _buildStatItem("Scrap", _percentFormat.format(bom.totalScrapRate)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }

  // === 2. DESKTOP TABLE ===
  Widget _buildDesktopTable(List<BOMDetail> details, BOMHeader bom) {
    // [UPDATE] Sort an toàn
    final sortedDetails = List<BOMDetail>.from(details)
      ..sort((a, b) => a.componentType.index.compareTo(b.componentType.index));

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
          columnSpacing: 24,
          dataRowMinHeight: 50,
          dataRowMaxHeight: 60,
          columns: const [
            DataColumn(label: Text("Type", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Material / Yarn", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Threads", style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(label: Text("Dtex", style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(label: Text("Twist", style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(label: Text("Actual Len (cm)", style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(label: Text("Actual (g/m) cal", style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(label: Text("Weight (g/m)", style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(label: Text("% Ratio", style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(label: Text("BOM (g/m)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)), numeric: true),
            DataColumn(label: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: sortedDetails.map((d) {
            final typeColor = _getComponentColor(d.componentType);
            
            return DataRow(cells: [
              // [FIX] Sử dụng .value thay vì .name
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: typeColor.withOpacity(0.3))
                  ),
                  child: Text(
                    d.componentType.value, 
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: typeColor)
                  ),
                )
              ),
              DataCell(Text(d.yarnTypeName, style: const TextStyle(fontWeight: FontWeight.w500))),
              DataCell(Text("${d.threads}")),
              DataCell(Text(d.yarnDtex.toStringAsFixed(0))),
              DataCell(Text(d.twisted.toString())),
              DataCell(Text(d.actualLengthCm.toString())),
              DataCell(Text(d.actualWeightCal.toString())),
              DataCell(Text(d.weightPerYarnGm.toString())),
              DataCell(Text(_percentFormat.format(d.weightPercentage))),
              DataCell(Text(_numberFormat.format(d.bomGm), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: Colors.orange),
                    onPressed: () => _showAddEditDetailDialog(context, d, bom),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                    onPressed: () => _confirmDeleteDetail(context, d, bom.bomId),
                  ),
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  // === 3. MOBILE LIST ===
  Widget _buildMobileList(List<BOMDetail> details, BOMHeader bom) {
    // [UPDATE] Sort an toàn
    final sortedDetails = List<BOMDetail>.from(details)
      ..sort((a, b) => a.componentType.index.compareTo(b.componentType.index));

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: sortedDetails.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final d = sortedDetails[index];
        final typeColor = _getComponentColor(d.componentType);

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade200)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(d.yarnTypeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                // [FIX] Hiển thị Type bằng chip màu
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(d.componentType.value, style: TextStyle(fontSize: 10, color: typeColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text("${d.threads} ends | ${d.yarnDtex.toInt()} dtex", style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Len: ${d.actualLengthCm} cm"),
                    Text("BOM: ${_numberFormat.format(d.bomGm)} g/m", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            ),
            trailing: PopupMenuButton(
              onSelected: (val) {
                if (val == 'edit') _showAddEditDetailDialog(context, d, bom);
                if (val == 'delete') _confirmDeleteDetail(context, d, bom.bomId);
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'edit', child: Text("Edit")),
                const PopupMenuItem(value: 'delete', child: Text("Delete", style: TextStyle(color: Colors.red))),
              ],
            ),
          ),
        );
      },
    );
  }

  // === 4. FOOTER SUMMARY ===
  Widget _buildFooterSummary(BOMHeader bom) {
    // Tính tổng bomGm từ danh sách chi tiết
    double totalBOM = bom.bomDetails.fold(0.0, (sum, item) => sum + item.bomGm);
    double ratio = bom.targetWeightGm > 0 ? (totalBOM / bom.targetWeightGm) : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black12))
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Calculated Total:", style: TextStyle(color: Colors.grey)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${_numberFormat.format(totalBOM)} g/m",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF003366)),
              ),
              if (bom.targetWeightGm > 0)
                Text(
                  "vs Target: ${_numberFormat.format(bom.targetWeightGm)} (${_percentFormat.format(ratio)})",
                  style: TextStyle(
                    fontSize: 12, 
                    fontWeight: FontWeight.bold,
                    color: totalBOM > bom.targetWeightGm ? Colors.red : Colors.green
                  ),
                )
            ],
          )
        ],
      ),
    );
  }
}