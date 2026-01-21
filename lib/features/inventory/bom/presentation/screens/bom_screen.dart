import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:production_app_frontend/core/widgets/responsive_layout.dart';
import 'package:production_app_frontend/l10n/app_localizations.dart';
import '../../domain/bom_model.dart';
import '../bloc/bom_cubit.dart';

// Import Product features
import 'package:production_app_frontend/features/inventory/product/domain/product_model.dart';
import 'package:production_app_frontend/features/inventory/product/presentation/bloc/product_cubit.dart';

// Import Material features
import 'package:production_app_frontend/features/inventory/material/domain/material_model.dart';
// Alias để tránh trùng tên MaterialState
import 'package:production_app_frontend/features/inventory/material/presentation/bloc/material_cubit.dart' as mat_bloc;


class BOMScreen extends StatefulWidget {
  final int? filterProductId;
  const BOMScreen({super.key, this.filterProductId});

  @override
  State<BOMScreen> createState() => _BOMScreenState();
}

class _BOMScreenState extends State<BOMScreen> {
  final Color _primaryColor = const Color(0xFF003366);
  final Color _bgLight = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    // Load BOM headers khi màn hình khởi tạo
    _loadData();
    context.read<ProductCubit>().loadProducts();
  }

  void _loadData() {
    context.read<BOMCubit>().loadBOMHeaders(productId: widget.filterProductId);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final loc = AppLocalizations.of(context)!; // Access localization

    return Scaffold(
      backgroundColor: _bgLight,
      body: SelectionArea(
        child: BlocBuilder<BOMCubit, BOMState>(
          builder: (context, state) {
            List<BOMHeader> boms = [];
            // Chỉ hiển thị danh sách khi state là Loaded hoặc Loading (giữ danh sách cũ nếu có)
            if (state is BOMListLoaded) {
              boms = state.boms;
            } else if (state is BOMDetailViewLoaded) {
               // [FIX]: Nếu Cubit đang ở DetailState (do vừa back lại mà chưa kịp load),
               // ta ép reload lại danh sách ngay lập tức để tránh màn hình trắng.
               // Tuy nhiên tốt nhất là xử lý ở hàm _showDetailScreen (bên dưới).
               // Ở đây ta có thể hiển thị loading tạm thời.
               return Center(child: CircularProgressIndicator(color: _primaryColor));
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- HEADER ---
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
                            child: Icon(Icons.layers,
                                color: Colors.indigo.shade800, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(loc.bomTitle,
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade800)),
                              const SizedBox(height: 2),
                              Text(loc.bomSubtitle,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade500)),
                            ],
                          ),
                          const Spacer(),
                          if (isDesktop)
                            ElevatedButton.icon(
                              onPressed: () => _showEditHeaderDialog(context, null),
                              icon: const Icon(Icons.add, size: 18),
                              label: Text(loc.addBOM),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(height: 1, color: Colors.grey.shade200),

                // --- CONTENT ---
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (state is BOMLoading) {
                        return Center(child: CircularProgressIndicator(color: _primaryColor));
                      }
                      if (state is BOMError) {
                        // ignore: unnecessary_string_interpolations
                        return Center(child: Text("${loc.exportError(state.message)}", style: const TextStyle(color: Colors.red)));
                      }
                      
                      if (boms.isEmpty && state is BOMListLoaded) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.assignment_outlined, size: 60, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(loc.noBOMFound, style: TextStyle(color: Colors.grey.shade500)),
                            ],
                          ),
                        );
                      }

                      // Nếu đang có data (kể cả khi loading lại ngầm), hiển thị list
                      if (boms.isNotEmpty) {
                         return isDesktop
                          ? _buildDesktopTable(context, boms, loc)
                          : _buildMobileList(context, boms, loc);
                      }
                      
                      return const SizedBox();
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: !isDesktop
          ? FloatingActionButton(
              backgroundColor: _primaryColor,
              onPressed: () => _showEditHeaderDialog(context, null),
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
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200)),
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(const Color(0xFFF9FAFB)),
            horizontalMargin: 24,
            columnSpacing: 30,
            columns: [
              DataColumn(label: Text(loc.bomCode.toUpperCase(), style: _headerStyle)),
              DataColumn(label: Text(loc.product.toUpperCase(), style: _headerStyle)),
              DataColumn(label: Text(loc.bomName.toUpperCase(), style: _headerStyle)),
              DataColumn(label: Text(loc.baseQty.toUpperCase(), style: _headerStyle)),
              DataColumn(label: Text(loc.version.toUpperCase(), style: _headerStyle)),
              DataColumn(label: Text(loc.status.toUpperCase(), style: _headerStyle)),
              DataColumn(label: Text(loc.actions.toUpperCase(), style: _headerStyle)),
            ],
            rows: items.map((item) {
              return DataRow(
                cells: [
                  DataCell(Text(item.bomCode, style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(
                    BlocBuilder<ProductCubit, ProductState>(
                      builder: (context, state) {
                        if (state is ProductLoaded) {
                          final product = state.products.where((p) => p.id == item.productId).firstOrNull;
                          if (product != null) {
                            return Text(product.itemCode, style: const TextStyle(fontWeight: FontWeight.w500));
                          }
                        }
                        return Text("ID: ${item.productId}", style: const TextStyle(color: Colors.grey));
                      },
                    ),
                  ),
                  DataCell(Text(item.bomName)),
                  DataCell(Text(item.baseQuantity.toString())),
                  DataCell(Text("v${item.version}")),
                  DataCell(_buildStatusBadge(item.isActive, loc)),
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          icon: const Icon(Icons.visibility, color: Colors.blue),
                          tooltip: loc.viewIngredients,
                          onPressed: () => _showDetailScreen(context, item.bomId)),
                      IconButton(
                          icon: const Icon(Icons.edit_note, color: Colors.grey),
                          onPressed: () => _showEditHeaderDialog(context, item)),
                      IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _confirmDelete(context, item)),
                    ],
                  )),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  TextStyle get _headerStyle => TextStyle(
      color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 12);

  Widget _buildStatusBadge(bool isActive, AppLocalizations loc) {
     return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isActive ? Colors.green.shade200 : Colors.grey.shade300)
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

  Widget _buildMobileList(BuildContext context, List<BOMHeader> items, AppLocalizations loc) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200)
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            title: Text(item.bomCode, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.bomName),
                const SizedBox(height: 4),
                Text("PID: ${item.productId} | ${loc.baseQty}: ${item.baseQuantity} | v${item.version}", style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                _buildStatusBadge(item.isActive, loc)
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _showDetailScreen(context, item.bomId),
            ),
          ),
        );
      },
    );
  }


  // --- DIALOGS & ACTIONS ---
  
  // 1. Dialog Edit/Add BOM Header
  void _showEditHeaderDialog(BuildContext context, BOMHeader? item) {
    final loc = AppLocalizations.of(context)!;
    int? selectedProductId = item?.productId ?? widget.filterProductId;
    
    final codeCtrl = TextEditingController(text: item?.bomCode ?? '');
    final nameCtrl = TextEditingController(text: item?.bomName ?? '');
    final baseQtyCtrl = TextEditingController(text: item?.baseQuantity.toString() ?? '1.0');
    final versionCtrl = TextEditingController(text: item?.version.toString() ?? '1');
    bool isActive = item?.isActive ?? true;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item == null ? loc.newBOM : loc.editBOM),
        content: SizedBox(
          width: 400,
          child: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BlocBuilder<ProductCubit, ProductState>(
                      builder: (context, state) {
                        List<Product> products = [];
                        bool isLoading = false;
                        if (state is ProductLoading) {
                          isLoading = true;
                        } else if (state is ProductLoaded) {
                          products = state.products;
                        }

                        String getSafeProductLabel(int id) {
                          try {
                            final p = products.firstWhere((e) => e.id == id);
                            return "${p.itemCode}${p.note.isNotEmpty ? ' - ${p.note}' : ''}";
                          } catch (e) {
                            return "${loc.product} #$id";
                          }
                        }

                        return DropdownButtonFormField<int>(
                          value: selectedProductId,
                          decoration: InputDecoration(
                            labelText: loc.selectProduct,
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
                          ),
                          hint: isLoading 
                              ? Text(loc.loadingProducts) 
                              : Text(loc.chooseProduct),
                          items: products.map((p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(
                              "${p.itemCode}${p.note.isNotEmpty ? ' - ${p.note}' : ''}",
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                          )).toList(),
                          onChanged: (item != null || widget.filterProductId != null)
                              ? null 
                              : (val) {
                                  setState(() => selectedProductId = val);
                               },
                          disabledHint: selectedProductId != null 
                              ? Text(getSafeProductLabel(selectedProductId!), style: const TextStyle(color: Colors.black87))
                              : null,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: codeCtrl,
                      decoration: InputDecoration(labelText: loc.bomCode, hintText: "e.g. BOM-BELT-01", border: const OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: InputDecoration(labelText: loc.bomName, border: const OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextFormField(controller: baseQtyCtrl, decoration: InputDecoration(labelText: loc.baseQty, border: const OutlineInputBorder()), keyboardType: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(child: TextFormField(controller: versionCtrl, decoration: InputDecoration(labelText: loc.version, border: const OutlineInputBorder()), keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(loc.setActiveVersion),
                      value: isActive,
                      onChanged: (val) => setState(() => isActive = val),
                    )
                  ],
                ),
              );
            }
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.cancel)),
          ElevatedButton(
            onPressed: () {
              if (codeCtrl.text.isEmpty) {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.bomCodeRequired), backgroundColor: Colors.red));
                 return;
              }
              if (selectedProductId == null || selectedProductId == 0) {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.productRequired), backgroundColor: Colors.red));
                 return;
              }
              final newBOM = BOMHeader(
                bomId: item?.bomId ?? 0,
                productId: selectedProductId!,
                bomCode: codeCtrl.text,
                bomName: nameCtrl.text,
                version: int.tryParse(versionCtrl.text) ?? 1,
                isActive: isActive,
                baseQuantity: double.tryParse(baseQtyCtrl.text) ?? 1.0,
                bomDetails: [] 
              );
              context.read<BOMCubit>().saveBOMHeader(bom: newBOM, isEdit: item != null);
              Navigator.pop(ctx);
            },
            child: Text(loc.save),
          )
        ],
      ),
    );
  }

  // --- [FIX] CHUYỂN TRANG VÀ RELOAD KHI QUAY LẠI ---
  void _showDetailScreen(BuildContext context, int bomId) {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => BOMDetailScreen(bomId: bomId))
    ).then((_) {
      // Khi quay lại từ màn hình chi tiết, load lại danh sách BOM headers
      // Điều này rất quan trọng vì BOMCubit hiện tại có thể đang ở state DetailLoaded
      _loadData();
    });
  }

  void _confirmDelete(BuildContext context, BOMHeader item) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.deleteBOM),
        content: Text(loc.confirmDeleteBOM(item.bomCode)),
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

// ==========================================
// MÀN HÌNH CHI TIẾT (BOM DETAILS)
// ==========================================
class BOMDetailScreen extends StatefulWidget {
  final int bomId;
  const BOMDetailScreen({super.key, required this.bomId});

  @override
  State<BOMDetailScreen> createState() => _BOMDetailScreenState();
}

class _BOMDetailScreenState extends State<BOMDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<BOMCubit>().loadBOMDetailView(widget.bomId);
    context.read<mat_bloc.MaterialCubit>().loadMaterials();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(title: Text(loc.bomIngredientsConfig)),
      body: BlocBuilder<BOMCubit, BOMState>(
        builder: (context, state) {
          if (state is BOMLoading) return const Center(child: CircularProgressIndicator());
          if (state is BOMDetailViewLoaded) {
            final bom = state.bom;
            return Column(
              children: [
                // Info Header Block
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${bom.bomCode} (v${bom.version})", 
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF003366))),
                            const SizedBox(height: 4),
                            Text(bom.bomName, style: TextStyle(color: Colors.grey.shade700)),
                            const SizedBox(height: 4),
                             Text("Product ID: ${bom.productId} | ${loc.baseQty}: ${bom.baseQuantity} | ${loc.status}: ${bom.isActive ? loc.active : loc.inactive}"),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(loc.addMaterial),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003366),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _showEditDetailDialog(context, null, bom.bomId),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                
                // List Ingredients
                // [CẬP NHẬT] Wrap bằng BlocBuilder Material để lấy thông tin chi tiết
                Expanded(
                  child: BlocBuilder<mat_bloc.MaterialCubit, mat_bloc.MaterialState>(
                    builder: (context, matState) {
                      List<MaterialModel> materials = [];
                      if (matState is mat_bloc.MaterialLoaded) {
                        materials = matState.materials;
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: bom.bomDetails.length,
                        separatorBuilder: (_,__) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final detail = bom.bomDetails[index];
                          // Tìm material object tương ứng
                          final material = materials.where((m) => m.id == detail.materialId).firstOrNull;
                          return _buildDetailItem(context, detail, material, bom.bomId, loc);
                        },
                      );
                    }
                  ),
                )
              ],
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  // [CẬP NHẬT] Thêm tham số material và hiển thị chi tiết
  Widget _buildDetailItem(BuildContext context, BOMDetail detail, MaterialModel? mat, int bomId, AppLocalizations loc) {
    // Xây dựng chuỗi thông tin phụ (Tags) giống PurchaseOrder
    List<String> subInfos = [];
    if (mat != null) {
      if (mat.materialCode.isNotEmpty) subInfos.add(mat.materialCode);
      if (mat.materialType != null) subInfos.add(mat.materialType!);
      String specs = "";
      if (mat.specDenier != null) specs += mat.specDenier!;
      if (mat.specFilament != null && mat.specFilament! > 0) specs += "/${mat.specFilament}F";
      if (specs.isNotEmpty) subInfos.add(specs);
    } else {
      // Fallback nếu chưa load được
      subInfos.add("${loc.matId}: ${detail.materialId}");
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300)
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  radius: 16,
                  child: Text(detail.componentType.name[0], 
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tên vật tư (Đậm)
                      Text(
                        mat?.materialName ?? "Material #${detail.materialId}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)
                      ),
                      const SizedBox(height: 4),
                      
                      // Thông tin phụ dạng Tag
                      if (subInfos.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: subInfos.map((text) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(text, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                          )).toList(),
                        ),
                        
                      const SizedBox(height: 4),
                      Text("${loc.ends}: ${detail.numberOfEnds}", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("${loc.stdQty}: ${detail.quantityStandard} g/m", style: const TextStyle(fontSize: 13)),
                    Text("${loc.wastage}: ${detail.wastageRate}%", style: const TextStyle(fontSize: 13, color: Colors.orange)),
                    Text("${loc.grossQty}: ${detail.quantityGross.toStringAsFixed(2)}", 
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 14)),
                  ],
                ),
              ],
            ),
            if (detail.note.isNotEmpty) ...[
              const Divider(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(child: Text(detail.note, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontStyle: FontStyle.italic))),
                ],
              )
            ],
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showEditDetailDialog(context, detail, bomId),
                  icon: const Icon(Icons.edit, size: 16),
                  label: Text(loc.edit), 
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(60, 30)),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: () => context.read<BOMCubit>().deleteBOMDetail(detail.detailId, bomId),
                  icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                  label: Text(loc.remove, style: const TextStyle(color: Colors.red)),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(60, 30)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showEditDetailDialog(BuildContext context, BOMDetail? detail, int bomId) {
    final loc = AppLocalizations.of(context)!;
    int? selectedMaterialId = detail?.materialId;
    BOMComponentType selectedType = detail?.componentType ?? BOMComponentType.Warp;
    
    final endsCtrl = TextEditingController(text: detail?.numberOfEnds.toString() ?? '0');
    final stdCtrl = TextEditingController(text: detail?.quantityStandard.toString() ?? '0');
    final wasteCtrl = TextEditingController(text: detail?.wastageRate.toString() ?? '0');
    final grossCtrl = TextEditingController(text: detail?.quantityGross.toString() ?? '0');
    final noteCtrl = TextEditingController(text: detail?.note ?? '');

    void calculateGross() {
      double std = double.tryParse(stdCtrl.text) ?? 0;
      double wst = double.tryParse(wasteCtrl.text) ?? 0;
      double gross = std * (1 + wst/100);
      grossCtrl.text = gross.toStringAsFixed(4); 
    }

    String selectedMaterialNameDisplay = loc.tapToSearch;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(detail == null ? loc.addMaterial : loc.editMaterialDetail),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              width: 600, 
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Row 1: Material (SEARCHABLE DIALOG) & Type ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: BlocBuilder<mat_bloc.MaterialCubit, mat_bloc.MaterialState>(
                            builder: (context, state) {
                              List<MaterialModel> materials = [];
                              if (state is mat_bloc.MaterialLoaded) {
                                materials = state.materials;
                              }
                              
                              if (selectedMaterialId != null && materials.isNotEmpty) {
                                final selected = materials.where((m) => m.id == selectedMaterialId).firstOrNull;
                                if (selected != null) {
                                  selectedMaterialNameDisplay = "${selected.materialName}\n${selected.materialCode} | ${selected.specDenier ?? '-'}/${selected.specFilament ?? '-'}";
                                } else {
                                  selectedMaterialNameDisplay = "${loc.matId}: $selectedMaterialId (Not found)";
                                }
                              }

                              return InkWell(
                                onTap: () async {
                                  final resultId = await _showMaterialSearchDialog(context, materials);
                                  if (resultId != null) {
                                    setState(() {
                                      selectedMaterialId = resultId;
                                    });
                                  }
                                },
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: loc.selectImporter.replaceFirst("Importer", "Material"), // Reuse or use generic
                                    border: const OutlineInputBorder(),
                                    suffixIcon: const Icon(Icons.search),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                                  ),
                                  child: Text(
                                    selectedMaterialNameDisplay,
                                    style: TextStyle(
                                      fontSize: 14, 
                                      color: selectedMaterialId != null ? Colors.black87 : Colors.grey
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<BOMComponentType>(
                            value: selectedType,
                            decoration: const InputDecoration(
                              labelText: "Type",
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)
                            ),
                            items: BOMComponentType.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
                            onChanged: (val) => setState(() => selectedType = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // --- Row 2: Ends & Standard ---
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: endsCtrl,
                            decoration: InputDecoration(labelText: loc.ends, border: const OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: stdCtrl,
                            decoration: InputDecoration(labelText: "${loc.stdQty} (g/m)", border: const OutlineInputBorder()),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => calculateGross(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // --- Row 3: Waste & Gross ---
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: wasteCtrl,
                            decoration: InputDecoration(labelText: "${loc.wastage} (%)", border: const OutlineInputBorder(), suffixText: "%"),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => calculateGross(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: grossCtrl,
                            decoration: InputDecoration(labelText: "${loc.grossQty} (Auto)", border: const OutlineInputBorder(), filled: true, fillColor: const Color(0xFFF0F4F8)),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: noteCtrl,
                      decoration: InputDecoration(labelText: loc.note, border: const OutlineInputBorder(), alignLabelWithHint: true),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            );
          }
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003366), foregroundColor: Colors.white),
            onPressed: () {
              if (selectedMaterialId == null || selectedMaterialId == 0) {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${loc.required}: Material"), backgroundColor: Colors.red));
                 return;
              }

              final newDetail = BOMDetail(
                detailId: detail?.detailId ?? 0,
                bomId: bomId,
                materialId: selectedMaterialId!,
                componentType: selectedType,
                numberOfEnds: int.tryParse(endsCtrl.text) ?? 0,
                quantityStandard: double.tryParse(stdCtrl.text) ?? 0,
                wastageRate: double.tryParse(wasteCtrl.text) ?? 0,
                quantityGross: double.tryParse(grossCtrl.text) ?? 0,
                note: noteCtrl.text.trim()
              );
              context.read<BOMCubit>().saveBOMDetail(newDetail, detail != null);
              Navigator.pop(ctx);
            },
            child: Text(loc.saveDetail),
          )
        ],
      ),
    );
  }

  // === CUSTOM SEARCH DIALOG (FIX OVERFLOW + SEARCH FEATURE) ===
  Future<int?> _showMaterialSearchDialog(BuildContext context, List<MaterialModel> allMaterials) async {
    final loc = AppLocalizations.of(context)!;
    return showDialog<int>(
      context: context,
      builder: (ctx) {
        List<MaterialModel> filteredList = List.from(allMaterials);
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(loc.searchMaterial),
              content: SizedBox(
                width: 500, // Chiều rộng cố định để tránh layout jump
                height: 400, // Chiều cao cố định để scroll
                child: Column(
                  children: [
                    // --- Search Bar ---
                    TextField(
                      decoration: InputDecoration(
                        hintText: loc.searchMaterialHint,
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.all(10)
                      ),
                      onChanged: (keyword) {
                        setState(() {
                          if (keyword.isEmpty) {
                            filteredList = List.from(allMaterials);
                          } else {
                            final k = keyword.toLowerCase();
                            filteredList = allMaterials.where((m) => 
                              m.materialName.toLowerCase().contains(k) || 
                              m.materialCode.toLowerCase().contains(k)
                            ).toList();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    
                    // --- List Result ---
                    Expanded(
                      child: filteredList.isEmpty 
                      ? Center(child: Text(loc.noMaterialFound))
                      : ListView.separated(
                          itemCount: filteredList.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final m = filteredList[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(m.materialName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                "${m.materialCode} | ${m.specDenier ?? '-'}/${m.specFilament ?? '-'}",
                                style: TextStyle(color: Colors.grey.shade700)
                              ),
                              onTap: () {
                                Navigator.pop(ctx, m.id); // Trả về ID khi chọn
                              },
                            );
                          },
                        ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null), 
                  child: Text(loc.close)
                )
              ],
            );
          }
        );
      }
    );
  }
}