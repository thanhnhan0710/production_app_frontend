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

// [FIX 1] Import file dialog vừa tạo
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
    if (widget.bomId != null) {
      context.read<BOMCubit>().loadBOMDetailView(widget.bomId!);
    }
    context.read<mat_bloc.MaterialCubit>().loadMaterials();
    context.read<ProductCubit>().loadProducts();
  }

  // [FIX 2] Hàm hiển thị Dialog, nhận kết quả trả về và gọi Cubit save
  void _showAddEditDetailDialog(BuildContext context, BOMDetail? detail, BOMHeader header) async {
    final BOMDetail? result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MaterialDetailDialog(detail: detail),
    );

    if (result != null && mounted) {
      // Gọi Cubit để lưu (Logic update header đã nằm trong cubit)
      context.read<BOMCubit>().saveBOMDetail(result, detail != null);
    }
  }

  void _confirmDeleteDetail(BuildContext context, BOMDetail detail, int bomId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Remove this component?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
               Navigator.pop(ctx);
               context.read<BOMCubit>().deleteBOMDetail(detail.detailId, bomId);
            }, 
            child: const Text("Delete", style: TextStyle(color: Colors.red))
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context); // Có thể null nếu chưa setup kỹ
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("BOM Detail Config"), 
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
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
          if (state is BOMOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.green));
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
                              // [FIX 3] Truyền bom vào đây, đảm bảo bom không null
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                          child: Text(bom.bomCode, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16)),
                        ),
                        const SizedBox(width: 12),
                        Text(bom.bomName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    BlocBuilder<ProductCubit, ProductState>(
                      builder: (context, state) {
                        String pName = "PID: ${bom.productId}";
                        if (state is ProductLoaded) {
                          final p = state.products.where((e) => e.id == bom.productId).firstOrNull;
                          if (p != null) pName = p.itemCode;
                        }
                        return Text("Product: $pName", style: TextStyle(color: Colors.grey.shade600));
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem("Target", "${bom.targetWeightGm} g/m"),
                    _buildStatItem("Width", "${bom.widthBehindLoom ?? '-'} mm"),
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
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }

  // === 2. DESKTOP TABLE ===
  Widget _buildDesktopTable(List<BOMDetail> details, BOMHeader bom) {
    final sortedDetails = List.from(details)..sort((a, b) => a.componentType.index.compareTo(b.componentType.index));

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
          columnSpacing: 24,
          dataRowMinHeight: 50,
          columns: const [
            DataColumn(label: Text("Type", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Material / Yarn", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Threads", style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(label: Text("Dtex", style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(label: Text("Twist", style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(label: Text("Len (cm)", style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(label: Text("Weight (g/m)", style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(label: Text("% Ratio", style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(label: Text("BOM (g/m)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)), numeric: true),
            DataColumn(label: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: sortedDetails.map((d) {
            return DataRow(cells: [
              DataCell(Text(d.componentType.name.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
              DataCell(Text(d.yarnTypeName, style: const TextStyle(fontWeight: FontWeight.w500))),
              DataCell(Text("${d.threads}")),
              DataCell(Text(d.yarnDtex.toStringAsFixed(0))),
              DataCell(Text(d.twisted.toString())),
              DataCell(Text(d.actualLengthCm.toString())),
              DataCell(Text(_numberFormat.format(d.actualWeightCal))),
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
    final sortedDetails = List.from(details)..sort((a, b) => a.componentType.index.compareTo(b.componentType.index));
    
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: sortedDetails.length,
      separatorBuilder: (_,__) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final d = sortedDetails[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade200)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            title: Text(d.yarnTypeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                      child: Text(d.componentType.name, style: const TextStyle(fontSize: 11)),
                    ),
                    const SizedBox(width: 8),
                    Text("${d.threads} ends | ${d.yarnDtex.toInt()} dtex"),
                  ],
                ),
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
    double totalBOM = bom.bomDetails.fold(0, (sum, item) => sum + item.bomGm);

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
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
                  "vs Target: ${_numberFormat.format(bom.targetWeightGm)} (${_percentFormat.format(totalBOM/bom.targetWeightGm)})",
                  style: TextStyle(fontSize: 12, color: totalBOM > bom.targetWeightGm ? Colors.red : Colors.green),
                )
            ],
          )
        ],
      ),
    );
  }
}