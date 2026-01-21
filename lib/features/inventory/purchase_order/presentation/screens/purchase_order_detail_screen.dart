import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

// Import Models & Cubits
import '../../domain/purchase_order_model.dart';
import '../bloc/purchase_order_cubit.dart';
import '../../../material/domain/material_model.dart';
import '../../../material/presentation/bloc/material_cubit.dart' as mat_bloc;
import '../../../unit/domain/unit_model.dart';
import '../../../unit/presentation/bloc/unit_cubit.dart';
import '../../../supplier/domain/supplier_model.dart';

// L10n
import '../../../../../l10n/app_localizations.dart';

class PurchaseOrderDetailScreen extends StatefulWidget {
  final int poId;
  const PurchaseOrderDetailScreen({super.key, required this.poId});

  @override
  State<PurchaseOrderDetailScreen> createState() => _PurchaseOrderDetailScreenState();
}

class _PurchaseOrderDetailScreenState extends State<PurchaseOrderDetailScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '');
  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    context.read<PurchaseOrderCubit>().loadPurchaseOrderDetail(widget.poId);
    context.read<mat_bloc.MaterialCubit>().loadMaterials();
    context.read<UnitCubit>().loadUnits();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(l10n.poDetailTitle), // "Purchase Order Detail"
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocBuilder<PurchaseOrderCubit, PurchaseOrderState>(
        builder: (context, state) {
          if (state is POLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is PODetailLoaded) {
            final po = state.po;
            return Column(
              children: [
                _buildHeaderInfo(po, l10n),
                
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
                                  "${l10n.orderItems} (${po.details.length})", 
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF003366))
                                ),
                              ],
                            ),
                            if (po.details.isNotEmpty)
                              Text(
                                "${l10n.totalAmount}: ${_currencyFormat.format(po.totalAmount)} ${po.currency}",
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                              )
                          ],
                        ),
                      ),
                      Expanded(
                        child: po.details.isEmpty 
                          ? _buildEmptyState(l10n)
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: po.details.length,
                              separatorBuilder: (_,__) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                return _buildDetailItem(po.details[index], po.currency);
                              },
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          if (state is POError) {
            return Center(child: Text(l10n.exportError(state.message), style: const TextStyle(color: Colors.red)));
          }

          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemDialog(context, l10n),
        backgroundColor: const Color(0xFF0055AA),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(l10n.addMaterial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // --- HEADER INFO ---
  Widget _buildHeaderInfo(PurchaseOrderHeader po, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(po.poNumber, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF003366))),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.store, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            po.vendor?.name ?? "${l10n.vendor} #${po.vendorId}",
                            style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(po.status),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F9FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.withOpacity(0.1))
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoColumn(l10n.date, _dateFormat.format(po.orderDate), Icons.calendar_today),
                _buildInfoColumn("ETA", po.expectedArrivalDate != null ? _dateFormat.format(po.expectedArrivalDate!) : "--/--", Icons.local_shipping),
                _buildInfoColumn("Term", po.incoterm.name, Icons.handshake),
                _buildInfoColumn(l10n.currency, po.currency, Icons.attach_money),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
      ],
    );
  }

  // --- ITEM CARD (PROFESSIONAL LOOK) ---
  Widget _buildDetailItem(PurchaseOrderDetail item, String currency) {
    final mat = item.material;
    
    List<String> subInfos = [];
    if (mat != null) {
      if (mat.materialCode.isNotEmpty) subInfos.add(mat.materialCode);
      if (mat.materialType != null) subInfos.add(mat.materialType!);
      String specs = "";
      if (mat.specDenier != null) specs += mat.specDenier!;
      if (mat.specFilament != null && mat.specFilament! > 0) specs += "/${mat.specFilament}F";
      if (specs.isNotEmpty) subInfos.add(specs);
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
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(child: Icon(Icons.layers, color: Color(0xFF0055AA), size: 24)),
            ),
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mat?.materialName ?? "Unknown Item",
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  
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
                ],
              ),
            ),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${_currencyFormat.format(item.lineTotal)} $currency",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF003366)),
                ),
                const SizedBox(height: 4),
                Text(
                  "${_currencyFormat.format(item.quantity)} ${item.uom?.name ?? 'Unit'}",
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                const SizedBox(height: 2),
                Text(
                  "@ ${_currencyFormat.format(item.unitPrice)}",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade100),
            child: Icon(Icons.add_shopping_cart, size: 40, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          Text(l10n.noItemsPO, style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          const SizedBox(height: 8),
          Text(l10n.addMaterialPrompt, style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(POStatus status) {
    Color bg, text;
    switch (status) {
      case POStatus.Draft: bg = Colors.grey.shade200; text = Colors.grey.shade700; break;
      case POStatus.Sent: bg = Colors.blue.shade100; text = Colors.blue.shade800; break;
      case POStatus.Confirmed: bg = Colors.indigo.shade100; text = Colors.indigo.shade800; break;
      case POStatus.Partial: bg = Colors.orange.shade100; text = Colors.orange.shade800; break;
      case POStatus.Completed: bg = Colors.green.shade100; text = Colors.green.shade800; break;
      case POStatus.Cancelled: bg = Colors.red.shade100; text = Colors.red.shade800; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status.name.toUpperCase(), style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  // --- DIALOG THÊM CHI TIẾT ---
  void _showAddItemDialog(BuildContext context, AppLocalizations l10n) {
    int? selectedMaterialId;
    int? selectedUomId;
    final qtyCtrl = TextEditingController(text: '');
    final priceCtrl = TextEditingController(text: '');
    
    MaterialModel? selectedMaterial;

    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            
            double qty = double.tryParse(qtyCtrl.text) ?? 0;
            double price = double.tryParse(priceCtrl.text) ?? 0;
            double total = qty * price;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.all(24),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              title: Row(
                children: [
                  const Icon(Icons.library_add, color: Color(0xFF003366)),
                  const SizedBox(width: 12),
                  Text(l10n.addItem, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003366))),
                ],
              ),
              content: SizedBox(
                width: 550,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // MATERIAL
                      Text(l10n.materialInfo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 8),
                      
                      BlocBuilder<mat_bloc.MaterialCubit, mat_bloc.MaterialState>(
                        builder: (context, state) {
                          List<MaterialModel> materials = [];
                          if (state is mat_bloc.MaterialLoaded) materials = state.materials;

                          return InkWell(
                            onTap: () async {
                              final result = await _showMaterialSearch(context, materials, l10n);
                              if (result != null) {
                                setState(() {
                                  selectedMaterial = result;
                                  selectedMaterialId = result.id;
                                  selectedUomId = result.uomBaseId; 
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: selectedMaterial != null ? const Color(0xFF003366) : Colors.grey.shade300),
                              ),
                              child: selectedMaterial == null 
                                ? Row(
                                    children: [
                                      Icon(Icons.search, color: Colors.grey.shade400),
                                      const SizedBox(width: 8),
                                      Text(l10n.tapToSearch, style: TextStyle(color: Colors.grey.shade500)),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                                        child: const Icon(Icons.check_circle, color: Colors.blue, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(selectedMaterial!.materialName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                            Text(
                                              "${selectedMaterial!.materialCode} • ${selectedMaterial!.materialType ?? 'Raw'} • ${selectedMaterial!.specDenier ?? '-'}", 
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.edit, size: 18, color: Colors.grey),
                                    ],
                                  ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // DETAILS
                      Text(l10n.transactionDetails, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 8),
                      
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: qtyCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: l10n.quantity,
                                    hintText: "0.0",
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  ),
                                  onChanged: (_) => setState((){}), 
                                ),
                                const SizedBox(height: 12),
                                BlocBuilder<UnitCubit, UnitState>(
                                  builder: (context, state) {
                                    List<ProductUnit> units = [];
                                    if (state is UnitLoaded) units = state.units;
                                    return DropdownButtonFormField<int>(
                                      value: selectedUomId,
                                      decoration: InputDecoration(
                                        labelText: l10n.unit,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                      ),
                                      items: units.map((u) => DropdownMenuItem(value: u.id, child: Text(u.name))).toList(),
                                      onChanged: (val) => setState(() => selectedUomId = val),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: priceCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: l10n.unitPrice,
                                hintText: "0.0",
                                prefixText: "\$ ",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              ),
                              onChanged: (_) => setState((){}),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // SUMMARY
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F7FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("${l10n.estimatedTotal}:", style: const TextStyle(color: Color(0xFF003366), fontWeight: FontWeight.w600)),
                            Text(
                              _currencyFormat.format(total),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF003366)),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.all(24),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx), 
                  child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey))
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    if (selectedMaterialId != null) {
                      final detail = PurchaseOrderDetail(
                        poId: widget.poId,
                        materialId: selectedMaterialId!,
                        quantity: double.tryParse(qtyCtrl.text) ?? 0,
                        unitPrice: double.tryParse(priceCtrl.text) ?? 0,
                        uomId: selectedUomId,
                        // [FIX TEMPORARY] Gán object material để hiển thị ngay
                        material: selectedMaterial, 
                      );
                      context.read<PurchaseOrderCubit>().addDetailItem(widget.poId, detail);
                      Navigator.pop(ctx);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${l10n.required}: Material"), backgroundColor: Colors.red));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003366), 
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                  ),
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(l10n.confirmAdd),
                )
              ],
            );
          },
        );
      },
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(l10n.searchMaterial),
              content: SizedBox(
                width: 500, height: 400,
                child: Column(
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search), 
                        hintText: l10n.searchMaterialPlaceholder,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.all(12)
                      ),
                      onChanged: (val) {
                        setState(() {
                          if (val.isEmpty) {
                            filtered = List.from(list);
                          } else {
                            final k = val.toLowerCase();
                            filtered = list.where((m) => 
                              m.materialName.toLowerCase().contains(k) || 
                              m.materialCode.toLowerCase().contains(k) ||
                              (m.materialType?.toLowerCase().contains(k) ?? false)
                            ).toList();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_,__) => Divider(height: 1, color: Colors.grey.shade200),
                        itemBuilder: (context, index) {
                          final m = filtered[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            title: Text(m.materialName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text("${m.materialCode} • ${m.materialType ?? 'Raw'}"),
                            trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                            onTap: () => Navigator.pop(ctx, m),
                          );
                        },
                      ),
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.close))
              ],
            );
          },
        );
      },
    );
  }
}