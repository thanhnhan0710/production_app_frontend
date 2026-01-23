import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

// [IMPORT] Các module liên quan
import 'package:production_app_frontend/features/inventory/import_declaration/domain/import_declaration_model.dart';
import 'package:production_app_frontend/features/inventory/import_declaration/presentation/bloc/import_declaration_cubit.dart';
import 'package:production_app_frontend/features/inventory/purchase_order/domain/purchase_order_model.dart';
import 'package:production_app_frontend/features/inventory/purchase_order/presentation/bloc/purchase_order_cubit.dart';
import 'package:production_app_frontend/features/inventory/supplier/domain/supplier_model.dart';
import 'package:production_app_frontend/features/inventory/supplier/presentation/bloc/supplier_cubit.dart';
import 'package:production_app_frontend/features/inventory/warehouse/domain/warehouse_model.dart';
import 'package:production_app_frontend/features/inventory/warehouse/presentation/bloc/warehouse_cubit.dart';

import '../../../../../core/widgets/responsive_layout.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../domain/material_receipt_model.dart';
import '../bloc/material_receipt_cubit.dart';
import '../../../../auth/presentation/bloc/auth_cubit.dart';
import 'material_detail_dialog.dart';

class MaterialReceiptFormScreen extends StatefulWidget {
  final int? receiptId;

  const MaterialReceiptFormScreen({super.key, this.receiptId});

  @override
  State<MaterialReceiptFormScreen> createState() => _MaterialReceiptFormScreenState();
}

class _MaterialReceiptFormScreenState extends State<MaterialReceiptFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _receiptNumberCtrl = TextEditingController();
  final _dateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
  final _containerCtrl = TextEditingController();
  final _sealCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _createdByCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();
  
  int? _selectedWarehouseId;
  int? _selectedPoId;
  int? _selectedDeclarationId;

  List<MaterialReceiptDetail> _details = [];
  bool _isFetchingNumber = false; // [MỚI] Loading state cho số phiếu
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      if (widget.receiptId != null) {
        context.read<MaterialReceiptCubit>().getReceiptDetail(widget.receiptId!);
      } else {
        // [MỚI] Gọi API lấy số phiếu từ Backend
        _fetchAndSetNextNumber();
        
        try {
          final authState = context.read<AuthCubit>().state;
          if (authState is AuthAuthenticated) {
            _createdByCtrl.text = authState.user.employeeName ?? authState.user.fullName;
          }
        } catch (_) {}
      }
    });
  }

  // [MỚI] Hàm riêng để lấy số phiếu
  Future<void> _fetchAndSetNextNumber() async {
    setState(() => _isFetchingNumber = true);
    final nextNumber = await context.read<MaterialReceiptCubit>().fetchNextReceiptNumber();
    if (mounted) {
      setState(() {
        _receiptNumberCtrl.text = nextNumber;
        _isFetchingNumber = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<MaterialReceiptCubit, MaterialReceiptState>(
      listener: (context, state) {
        if (state is MaterialReceiptOperationSuccess) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(child: Text("Đã lưu phiếu nhập & Tự động khởi tạo Lô hàng (Batches).")),
                ],
              ),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
            )
          );
          Navigator.of(context).pop(); 
        } else if (state is MaterialReceiptDetailLoaded) {
          final r = state.receipt;
          _receiptNumberCtrl.text = r.receiptNumber;
          _dateCtrl.text = DateFormat('yyyy-MM-dd').format(r.receiptDate);
          _containerCtrl.text = r.containerNo ?? "";
          _sealCtrl.text = r.sealNo ?? "";
          _noteCtrl.text = r.note ?? "";
          _createdByCtrl.text = r.createdBy ?? ""; 
          
          _selectedWarehouseId = r.warehouseId;
          _selectedPoId = r.poHeaderId;
          _selectedDeclarationId = r.declarationId;
          
          if (r.poHeader != null) {
             _supplierCtrl.text = r.poHeader!.vendorName;
          }

          _details = r.details;
          if (mounted) setState(() {});
        } else if (state is MaterialReceiptError) {
           if (!context.mounted) return;
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
        }
      },
      builder: (context, state) {
        final isLoading = state is MaterialReceiptLoading && widget.receiptId != null && _details.isEmpty;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 1,
            title: Text(
              widget.receiptId == null ? l10n.createReceiptTitle : l10n.editReceiptTitle,
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
            ),
            actions: [
              if (!isLoading)
                TextButton.icon(
                  onPressed: _saveHeader,
                  icon: const Icon(Icons.save, color: Color(0xFF003366)),
                  label: Text(l10n.saveReceipt, style: const TextStyle(color: Color(0xFF003366), fontWeight: FontWeight.bold)),
                )
            ],
          ),
          body: isLoading 
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --- SECTION 1: THÔNG TIN CHUNG ---
                        _buildSectionCard(
                          title: l10n.generalInfoTitle(""), 
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _receiptNumberCtrl,
                                      decoration: _inputDeco(
                                        l10n.receiptNumber,
                                        // [MỚI] Hiển thị spinner nhỏ nếu đang load số
                                        suffixIcon: _isFetchingNumber 
                                          ? const Padding(padding: EdgeInsets.all(10), child: SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2))) 
                                          : null
                                      ),
                                      validator: (v) => v!.isEmpty ? l10n.required : null,
                                      readOnly: _isFetchingNumber, // Chặn sửa khi đang load
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _dateCtrl,
                                      decoration: _inputDeco(l10n.importDate, icon: Icons.calendar_today),
                                      readOnly: true,
                                      onTap: () async {
                                        DateTime? picked = await showDatePicker(
                                          context: context,
                                          initialDate: DateTime.now(),
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime(2100),
                                        );
                                        if (picked != null) {
                                          _dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                                          // [OPTIONAL] Nếu muốn đổi ngày thì sinh lại số phiếu (vì số phiếu theo tháng)
                                          // _fetchAndSetNextNumber(); 
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: BlocBuilder<WarehouseCubit, WarehouseState>(
                                      builder: (context, whState) {
                                        List<Warehouse> warehouses = [];
                                        if (whState is WarehouseLoaded) warehouses = whState.warehouses;
                                        return DropdownButtonFormField<int>(
                                          value: _selectedWarehouseId,
                                          decoration: _inputDeco(l10n.receivingWarehouse),
                                          items: warehouses.map((w) => DropdownMenuItem<int>(
                                            value: w.id,
                                            child: Text(w.name, overflow: TextOverflow.ellipsis),
                                          )).toList(),
                                          onChanged: (val) => setState(() => _selectedWarehouseId = val),
                                          validator: (v) => v == null ? l10n.selectWarehouse : null,
                                          isExpanded: true,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: BlocBuilder<PurchaseOrderCubit, PurchaseOrderState>(
                                      builder: (context, poState) {
                                        return BlocBuilder<SupplierCubit, SupplierState>(
                                          builder: (context, supState) {
                                            List<PurchaseOrderHeader> pos = [];
                                            if (poState is POListLoaded) pos = poState.list;
                                            List<Supplier> suppliers = [];
                                            if (supState is SupplierLoaded) suppliers = supState.suppliers;

                                            return DropdownButtonFormField<int>(
                                              value: _selectedPoId,
                                              decoration: _inputDeco(l10n.byPO),
                                              items: pos.map((p) {
                                                String vendorName = p.vendor?.name ?? '';
                                                if (vendorName.isEmpty) {
                                                   final s = suppliers.where((sup) => sup.id == p.vendorId).firstOrNull;
                                                   if (s != null) vendorName = s.name;
                                                }
                                                if (vendorName.isEmpty) vendorName = "Unknown";

                                                return DropdownMenuItem<int>(
                                                  value: p.poId,
                                                  child: Text("${p.poNumber} ($vendorName)", overflow: TextOverflow.ellipsis),
                                                );
                                              }).toList(),
                                              onChanged: (val) {
                                                setState(() => _selectedPoId = val);
                                                if (val != null) {
                                                  final selectedPO = pos.firstWhere((element) => element.poId == val, orElse: () => pos.first);
                                                  String vName = selectedPO.vendor?.name ?? '';
                                                  if (vName.isEmpty) {
                                                     final s = suppliers.where((sup) => sup.id == selectedPO.vendorId).firstOrNull;
                                                     if (s != null) vName = s.name;
                                                  }
                                                  _supplierCtrl.text = vName;
                                                } else {
                                                  _supplierCtrl.clear();
                                                }
                                              },
                                              isExpanded: true,
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Tờ khai hải quan
                              Row(
                                children: [
                                  Expanded(
                                    child: BlocBuilder<ImportDeclarationCubit, ImportDeclState>(
                                      builder: (context, decState) {
                                        List<ImportDeclaration> declarations = [];
                                        if (decState is ImportDeclListLoaded) {
                                          declarations = decState.list;
                                        } 
                                        
                                        int? safeValue = _selectedDeclarationId;
                                        if (safeValue != null && declarations.isNotEmpty && !declarations.any((d) => d.id == safeValue)) {
                                          safeValue = null;
                                        }

                                        return DropdownButtonFormField<int>(
                                          value: safeValue,
                                          decoration: _inputDeco(l10n.customsDeclarationOptional),
                                          items: [
                                            DropdownMenuItem<int>(value: null, child: Text(l10n.noSelection)),
                                            ...declarations.map((d) => DropdownMenuItem<int>(
                                              value: d.id,
                                              child: Text(d.declarationNo, overflow: TextOverflow.ellipsis),
                                            ))
                                          ],
                                          onChanged: (val) => setState(() => _selectedDeclarationId = val),
                                          isExpanded: true,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _supplierCtrl,
                                      decoration: _inputDeco(l10n.supplierTitle, icon: Icons.store),
                                      readOnly: true,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _createdByCtrl,
                                      decoration: _inputDeco(l10n.createdBy, icon: Icons.person_outline),
                                      readOnly: true,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),

                        // --- SECTION 2: LOGISTICS ---
                        _buildSectionCard(
                          title: l10n.logisticsInfo,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(child: TextFormField(controller: _containerCtrl, decoration: _inputDeco(l10n.containerNumber))),
                                  const SizedBox(width: 16),
                                  Expanded(child: TextFormField(controller: _sealCtrl, decoration: _inputDeco(l10n.sealNumber))),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _noteCtrl,
                                decoration: _inputDeco(l10n.note),
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // --- SECTION 3: CHI TIẾT HÀNG HÓA ---
                        _buildDetailsSection(isDesktop, l10n),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF003366))),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection(bool isDesktop, AppLocalizations l10n) {
    // Sắp xếp các dòng bị lệch số lượng lên đầu
    final sortedEntries = _details.asMap().entries.toList()
      ..sort((a, b) {
        final aMismatch = (a.value.receivedQuantityKg - a.value.poQuantityKg).abs() > 0.01;
        final bMismatch = (b.value.receivedQuantityKg - b.value.poQuantityKg).abs() > 0.01;
        if (aMismatch && !bMismatch) return -1; 
        if (!aMismatch && bMismatch) return 1;
        return 0;
      });

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.goodsList, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF003366))),
                ElevatedButton.icon(
                  onPressed: _openAddDetailDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(l10n.addRow),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue,
                    elevation: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_details.isEmpty)
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text(l10n.noMaterialsYet, style: TextStyle(color: Colors.grey.shade500))),
              )
            else if (isDesktop)
              // [DESKTOP TABLE]
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                        columnSpacing: 20,
                        columns: [
                          DataColumn(label: Text(l10n.materialCode, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(l10n.materialName, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(l10n.poQtyKg, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(l10n.actualQtyKg, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(l10n.pallets, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Row(
                            children: [
                              const Icon(Icons.qr_code_2, size: 16, color: Colors.blueGrey),
                              const SizedBox(width: 4),
                              Text(l10n.supplierBatch, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                            ],
                          )),
                          DataColumn(label: Text(l10n.actions, style: const TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: sortedEntries.map((entry) {
                          final index = entry.key; 
                          final item = entry.value;
                          
                          final isMismatch = (item.receivedQuantityKg - item.poQuantityKg).abs() > 0.01;
                          const mismatchColor = Colors.red;
                          final normalColor = Colors.green.shade700;
                          
                          return DataRow(
                            color: isMismatch ? MaterialStateProperty.all(Colors.red.shade50) : null,
                            cells: [
                              DataCell(Text(item.material?.code ?? "${item.materialId}")),
                              DataCell(ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 200),
                                child: Text(item.material?.name ?? "---", overflow: TextOverflow.ellipsis),
                              )),
                              DataCell(Text(NumberFormat("#,##0.00").format(item.poQuantityKg))),
                              DataCell(
                                Row(
                                  children: [
                                    Text(
                                      NumberFormat("#,##0.00").format(item.receivedQuantityKg),
                                      style: TextStyle(fontWeight: FontWeight.bold, color: isMismatch ? mismatchColor : normalColor),
                                    ),
                                    if (isMismatch)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 4),
                                        child: Icon(Icons.warning_amber_rounded, size: 16, color: Colors.red),
                                      ),
                                  ],
                                )
                              ),
                              DataCell(Text("${item.numberOfPallets}")),
                              DataCell(
                                item.supplierBatchNo != null && item.supplierBatchNo!.isNotEmpty
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.blueGrey.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                    child: Text(item.supplierBatchNo!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  )
                                : const Text("--", style: TextStyle(color: Colors.grey)),
                              ),
                              DataCell(Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                                    onPressed: () => _openEditDetailDialog(item, index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                    onPressed: () => _deleteDetail(index, item, l10n),
                                  ),
                                ],
                              )),
                            ]);
                        }).toList(),
                      ),
                    ),
                  );
                }
              )
            else
              // [MOBILE LIST]
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: sortedEntries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final index = sortedEntries[i].key; 
                  final item = sortedEntries[i].value;
                  final isMismatch = (item.receivedQuantityKg - item.poQuantityKg).abs() > 0.01;

                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: isMismatch ? Colors.red.shade200 : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                      color: isMismatch ? Colors.red.shade50 : Colors.white,
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isMismatch) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.warning, size: 16, color: Colors.red)),
                            Expanded(
                              child: Text(
                                item.material?.name ?? "Material #${item.materialId}",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                            PopupMenuButton(
                              icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                              padding: EdgeInsets.zero,
                              onSelected: (val) {
                                if (val == 'edit') _openEditDetailDialog(item, index);
                                if (val == 'delete') _deleteDetail(index, item, l10n);
                              },
                              itemBuilder: (ctx) => [
                                PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit, size: 18), const SizedBox(width: 8), Text(l10n.edit)])),
                                PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete, size: 18, color: Colors.red), const SizedBox(width: 8), Text(l10n.delete)])),
                              ],
                            ),
                          ],
                        ),
                        Text(item.material?.code ?? "", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMobileStat(l10n.poQtyKg, NumberFormat("#,##0").format(item.poQuantityKg)),
                            Container(width: 1, height: 30, color: Colors.grey.shade300),
                            _buildMobileStat(l10n.actualQtyKg, NumberFormat("#,##0.0").format(item.receivedQuantityKg), valueColor: isMismatch ? Colors.red : Colors.green.shade700),
                          ],
                        ),
                        if (item.supplierBatchNo != null && item.supplierBatchNo!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.qr_code_2, size: 14, color: Colors.blueGrey),
                              const SizedBox(width: 4),
                              Text("${l10n.supplierBatch}: ", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              Text(item.supplierBatchNo!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                            ],
                          )
                        ]
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileStat(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: valueColor ?? Colors.black87)),
      ],
    );
  }

  InputDecoration _inputDeco(String label, {IconData? icon, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      suffixIcon: suffixIcon ?? (icon != null ? Icon(icon, color: Colors.grey) : null),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      isDense: true,
    );
  }

  // --- LOGIC ---

  void _saveHeader() {
    if (_formKey.currentState!.validate()) {
      final header = MaterialReceipt(
        id: widget.receiptId,
        receiptNumber: _receiptNumberCtrl.text,
        receiptDate: DateTime.parse(_dateCtrl.text),
        warehouseId: _selectedWarehouseId!,
        poHeaderId: _selectedPoId,
        declarationId: _selectedDeclarationId,
        containerNo: _containerCtrl.text,
        sealNo: _sealCtrl.text,
        note: _noteCtrl.text,
        createdBy: _createdByCtrl.text,
        details: _details, 
      );

      if (widget.receiptId == null) {
        context.read<MaterialReceiptCubit>().createReceipt(header);
      } else {
        context.read<MaterialReceiptCubit>().updateReceipt(header);
      }
    }
  }

  Future<void> _openAddDetailDialog() async {
    final MaterialReceiptDetail? result = await showDialog(
      context: context,
      builder: (_) => const MaterialDetailDialog(),
    );

    if (result != null) {
      if (widget.receiptId != null) {
        context.read<MaterialReceiptCubit>().addDetailItem(widget.receiptId!, result);
      } else {
        setState(() {
          _details.add(result);
        });
      }
    }
  }

  Future<void> _openEditDetailDialog(MaterialReceiptDetail item, int index) async {
    final MaterialReceiptDetail? result = await showDialog(
      context: context,
      builder: (_) => MaterialDetailDialog(detail: item),
    );

    if (result != null) {
      if (widget.receiptId != null) {
        context.read<MaterialReceiptCubit>().updateDetailItem(widget.receiptId!, result);
      } else {
        setState(() {
          _details[index] = result;
        });
      }
    }
  }

  void _deleteDetail(int index, MaterialReceiptDetail item, AppLocalizations l10n) {
    if (widget.receiptId != null && item.detailId != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.confirmDeleteTitle), 
          content: Text(l10n.confirmDeleteDetailMsg), 
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)), 
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.read<MaterialReceiptCubit>().deleteDetailItem(widget.receiptId!, item.detailId!);
              }, 
              child: Text(l10n.delete) 
            )
          ],
        )
      );
    } else {
      setState(() {
        _details.removeAt(index);
      });
    }
  }
}