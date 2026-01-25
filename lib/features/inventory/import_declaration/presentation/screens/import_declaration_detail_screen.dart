import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

// --- IMPORTS ---
import '../../../../../l10n/app_localizations.dart';
import '../../domain/import_declaration_model.dart';
import '../bloc/import_declaration_cubit.dart';

// Import Material để chọn vật tư
import '../../../material/domain/material_model.dart';
import '../../../material/presentation/bloc/material_cubit.dart' as mat_bloc;

class ImportDeclarationDetailScreen extends StatefulWidget {
  final int id;
  const ImportDeclarationDetailScreen({super.key, required this.id});

  @override
  State<ImportDeclarationDetailScreen> createState() => _ImportDeclarationDetailScreenState();
}

class _ImportDeclarationDetailScreenState extends State<ImportDeclarationDetailScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '');
  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    context.read<ImportDeclarationCubit>().loadDetail(widget.id);
    context.read<mat_bloc.MaterialCubit>().loadMaterials();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(l10n.declarationDetailTitle),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocBuilder<ImportDeclarationCubit, ImportDeclState>(
        builder: (context, state) {
          if (state is ImportDeclLoading) return const Center(child: CircularProgressIndicator());

          if (state is ImportDeclDetailLoaded) {
            final decl = state.declaration;
            return Column(
              children: [
                _buildHeaderInfo(decl, l10n),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.list_alt, color: Color(0xFF003366), size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  "${l10n.declarationItemsList} (${decl.details.length})", 
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF003366))
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: decl.details.isEmpty
                            ? _buildEmptyState(l10n)
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: decl.details.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  return _buildDetailItem(context, decl.details[index], l10n);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
          if (state is ImportDeclError) return Center(child: Text("${l10n.errorGeneric}: ${state.message}", style: const TextStyle(color: Colors.red)));
          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDetailDialog(context, l10n),
        backgroundColor: const Color(0xFF0055AA),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(l10n.addDeclarationItem, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHeaderInfo(ImportDeclaration decl, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(decl.declarationNo, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF003366))),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                      child: Text("${l10n.declarationType}: ${decl.type.name}", style: TextStyle(fontSize: 12, color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(l10n.totalTax, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text("${_currencyFormat.format(decl.totalTaxAmount)} VND", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF5F9FF), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blue.withOpacity(0.1))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoColumn(l10n.registrationDate, _dateFormat.format(decl.declarationDate), Icons.calendar_today),
                _buildInfoColumn(l10n.invoiceNo, decl.invoiceNo ?? "-", Icons.receipt),
                _buildInfoColumn(l10n.billOfLading, decl.billOfLading ?? "-", Icons.directions_boat),
              ],
            ),
          ),
          if (decl.note != null && decl.note!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.note, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(child: Text(decl.note!, style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))),
            ])
          ]
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // --- ITEM CARD ---
  Widget _buildDetailItem(BuildContext context, ImportDeclarationDetail detail, AppLocalizations l10n) {
    MaterialModel? material = detail.material;
    if (material == null) {
      final matState = context.read<mat_bloc.MaterialCubit>().state;
      if (matState is mat_bloc.MaterialLoaded) {
        material = matState.materials.where((m) => m.id == detail.materialId).firstOrNull;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(10)),
              child: const Center(child: Icon(Icons.inventory_2, color: Colors.teal, size: 24)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(material?.materialCode ?? "${l10n.materialLabel} #${detail.materialId}", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 6),
                  if (material != null) Text("${material.materialCode} • ${material.materialType ?? 'Raw'}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  if (detail.hsCodeActual != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                      child: Text("${l10n.actualHSCode}: ${detail.hsCodeActual}", style: TextStyle(fontSize: 11, color: Colors.grey.shade800, fontWeight: FontWeight.bold)),
                    ),
                  ]
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("${_currencyFormat.format(detail.quantity)} kg", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 2),
                Text("@ \$${_currencyFormat.format(detail.unitPrice)}", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    InkWell(
                      onTap: () => _showAddDetailDialog(context, l10n, detail: detail), // [EDIT] Mở dialog với data cũ
                      child: const Padding(padding: EdgeInsets.all(4.0), child: Icon(Icons.edit, size: 18, color: Colors.grey)),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () => _confirmDeleteDetail(context, detail, l10n), // [DELETE] Gọi hàm xóa
                      child: const Padding(padding: EdgeInsets.all(4.0), child: Icon(Icons.delete_outline, size: 18, color: Colors.redAccent)),
                    ),
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.post_add, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(l10n.noDeclarationItems, style: TextStyle(color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Text(l10n.addDeclarationItemPrompt, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // --- [UPDATED] DIALOG THÊM / SỬA HÀNG ---
  void _showAddDetailDialog(BuildContext context, AppLocalizations l10n, {ImportDeclarationDetail? detail}) {
    final isEdit = detail != null;
    int? selectedMaterialId = detail?.materialId;
    MaterialModel? selectedMaterial = detail?.material; 
    
    final qtyCtrl = TextEditingController(text: detail?.quantity.toString() ?? '');
    final priceCtrl = TextEditingController(text: detail?.unitPrice.toString() ?? '');
    final hsCodeCtrl = TextEditingController(text: detail?.hsCodeActual ?? '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEdit ? l10n.editDeclarationItem : l10n.addDeclarationItemTitle, style: const TextStyle(color: Color(0xFF003366), fontWeight: FontWeight.bold)),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. Chọn Vật tư
                    BlocBuilder<mat_bloc.MaterialCubit, mat_bloc.MaterialState>(
                      builder: (context, state) {
                        List<MaterialModel> materials = [];
                        if (state is mat_bloc.MaterialLoaded) materials = state.materials;
                        
                        // Nếu đang edit mà chưa có object material, thử tìm trong list
                        if (isEdit && selectedMaterial == null && materials.isNotEmpty) {
                           selectedMaterial = materials.where((m) => m.id == selectedMaterialId).firstOrNull;
                        }

                        return InkWell(
                          onTap: () async {
                            final result = await _showMaterialSearch(context, materials, l10n);
                            if (result != null) {
                              setState(() {
                                selectedMaterial = result;
                                selectedMaterialId = result.id;
                                if (result.hsCode != null) hsCodeCtrl.text = result.hsCode!;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(labelText: "${l10n.materialLabel} (Material)", border: const OutlineInputBorder(), suffixIcon: const Icon(Icons.search)),
                            child: Text(
                              selectedMaterial?.materialCode?? (isEdit ? "${l10n.materialLabel} #$selectedMaterialId" : l10n.selectMaterialPlaceholder), 
                              style: TextStyle(color: selectedMaterial != null ? Colors.black : Colors.grey, overflow: TextOverflow.ellipsis)
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: hsCodeCtrl,
                      decoration: InputDecoration(labelText: l10n.actualHSCode, border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.code)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: TextFormField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l10n.quantityLabel, border: const OutlineInputBorder()))),
                        const SizedBox(width: 12),
                        Expanded(child: TextFormField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l10n.unitPriceLabel, border: const OutlineInputBorder(), prefixText: "\$"))),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              if (selectedMaterialId == null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorSelectMaterial), backgroundColor: Colors.red));
                return;
              }
              final newDetail = ImportDeclarationDetail(
                detailId: detail?.detailId ?? 0, // Giữ ID nếu edit
                declarationId: widget.id,
                materialId: selectedMaterialId!,
                quantity: double.tryParse(qtyCtrl.text) ?? 0,
                unitPrice: double.tryParse(priceCtrl.text) ?? 0,
                hsCodeActual: hsCodeCtrl.text.isNotEmpty ? hsCodeCtrl.text : null,
                material: selectedMaterial
              );
              
              if (isEdit) {
                 context.read<ImportDeclarationCubit>().updateDetailItem(widget.id, newDetail);
              } else {
                 context.read<ImportDeclarationCubit>().addDetailItem(widget.id, newDetail);
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003366), foregroundColor: Colors.white),
            child: Text(isEdit ? l10n.updateAction : l10n.save),
          )
        ],
      ),
    );
  }

  Future<MaterialModel?> _showMaterialSearch(BuildContext context, List<MaterialModel> list, AppLocalizations l10n) async {
    return showDialog<MaterialModel>(
      context: context,
      builder: (ctx) {
        List<MaterialModel> filtered = List.from(list);
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.searchMaterialTitle),
              content: SizedBox(
                width: 500, height: 400,
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l10n.searchMaterialHint),
                      onChanged: (val) {
                        setState(() {
                          // ignore: curly_braces_in_flow_control_structures
                          if (val.isEmpty) filtered = List.from(list);
                          // ignore: curly_braces_in_flow_control_structures
                          else filtered = list.where((m) => m.materialCode.toLowerCase().contains(val.toLowerCase())).toList();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_,__) => const Divider(),
                        itemBuilder: (context, index) {
                          final m = filtered[index];
                          return ListTile(
                            title: Text(m.materialCode, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(m.materialType.toString()),
                            onTap: () => Navigator.pop(ctx, m),
                          );
                        },
                      ),
                    )
                  ],
                ),
              ),
              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.close))],
            );
          },
        );
      },
    );
  }

  // [FIX] Xóa dòng hàng
  void _confirmDeleteDetail(BuildContext context, ImportDeclarationDetail detail, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteItemTitle),
        content: Text(l10n.confirmDeleteItemMsg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              // Gọi hàm deleteDetailItem từ Cubit
              context.read<ImportDeclarationCubit>().deleteDetailItem(widget.id, detail.detailId);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(l10n.delete),
          )
        ],
      )
    );
  }
}