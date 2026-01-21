import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:production_app_frontend/features/inventory/supplier/domain/supplier_model.dart';
import 'package:production_app_frontend/features/inventory/supplier/presentation/bloc/supplier_cubit.dart';

// --- IMPORTS ---
import '../../../../../core/widgets/responsive_layout.dart';
import '../../../../../l10n/app_localizations.dart';

import '../../domain/purchase_order_model.dart';
import '../bloc/purchase_order_cubit.dart';

import 'purchase_order_detail_screen.dart';

class PurchaseOrderScreen extends StatefulWidget {
  const PurchaseOrderScreen({super.key});

  @override
  State<PurchaseOrderScreen> createState() => _PurchaseOrderScreenState();
}

class _PurchaseOrderScreenState extends State<PurchaseOrderScreen> {
  final _searchController = TextEditingController();
  final Color _primaryColor = const Color(0xFF003366);
  final Color _accentColor = const Color(0xFF0055AA);
  final Color _bgLight = const Color(0xFFF5F7FA);

  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    context.read<PurchaseOrderCubit>().loadPurchaseOrders();
    context.read<SupplierCubit>().loadSuppliers();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: _bgLight,
      body: BlocBuilder<PurchaseOrderCubit, PurchaseOrderState>(
        builder: (context, state) {
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
                            color: _primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.shopping_cart_outlined, color: _primaryColor, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.purchaseOrderTitle,
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.purchaseOrderSubtitle,
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (isDesktop)
                          ElevatedButton.icon(
                            onPressed: () => _showEditDialog(context, null, l10n),
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(l10n.createPO),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              elevation: 2,
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
                                hintText: l10n.searchPO,
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                suffixIcon: _searchController.text.isNotEmpty 
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        context.read<PurchaseOrderCubit>().loadPurchaseOrders();
                                      },
                                    )
                                  : null,
                              ),
                              onSubmitted: (value) => context.read<PurchaseOrderCubit>().loadPurchaseOrders(search: value),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Icon(Icons.filter_list, color: Colors.grey, size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: Colors.grey.shade200),

              // --- MAIN CONTENT ---
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (state is POLoading) {
                      return Center(child: CircularProgressIndicator(color: _primaryColor));
                    } else if (state is POError) {
                      // ignore: unnecessary_string_interpolations
                      return Center(child: Text("${l10n.exportError(state.message)}", style: const TextStyle(color: Colors.red)));
                    } else if (state is POListLoaded) {
                      if (state.list.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.remove_shopping_cart_outlined, size: 60, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(l10n.noStatsData, style: TextStyle(color: Colors.grey.shade500)),
                            ],
                          ),
                        );
                      }
                      return isDesktop
                          ? _buildDesktopTable(context, state.list, l10n)
                          : _buildMobileList(context, state.list, l10n);
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: !isDesktop
          ? FloatingActionButton(
              backgroundColor: _accentColor,
              onPressed: () => _showEditDialog(context, null, l10n),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  // --- DESKTOP TABLE ---
  Widget _buildDesktopTable(BuildContext context, List<PurchaseOrderHeader> items, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(const Color(0xFFF9FAFB)),
            horizontalMargin: 24,
            columnSpacing: 20,
            
            // [FIXED] Sửa lỗi BoxConstraints: minHeight <= maxHeight
            dataRowMinHeight: 60, 
            dataRowMaxHeight: double.infinity, // Cho phép dãn theo nội dung Note

            columns: [
              DataColumn(label: Text(l10n.poNumber.toUpperCase(), style: _headerStyle)),
              DataColumn(label: Text(l10n.vendor.toUpperCase(), style: _headerStyle)),
              DataColumn(label: Text(l10n.orderDate.toUpperCase(), style: _headerStyle)),
              DataColumn(label: Text(l10n.eta.toUpperCase(), style: _headerStyle)),
              DataColumn(label: Text(l10n.incoterm.toUpperCase(), style: _headerStyle)),
              DataColumn(label: Text(l10n.note.toUpperCase(), style: _headerStyle)),
              DataColumn(label: Text(l10n.totalAmount.toUpperCase(), style: _headerStyle)),
              DataColumn(label: Text(l10n.status.toUpperCase(), style: _headerStyle)),
              DataColumn(label: Text(l10n.actions.toUpperCase(), style: _headerStyle)),
            ],
            rows: items.map((po) {
              return DataRow(
                cells: [
                  DataCell(
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(po.poNumber, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                    ),
                    onTap: () => _navigateToDetail(po.poId),
                  ),
                  DataCell(_VendorName(vendorId: po.vendorId, vendorObj: po.vendor)),
                  DataCell(Text(_dateFormat.format(po.orderDate))),
                  DataCell(Text(po.expectedArrivalDate != null ? _dateFormat.format(po.expectedArrivalDate!) : "-")),
                  DataCell(Text(po.incoterm.name)),
                  // Hiển thị Note đầy đủ, tự xuống dòng
                  DataCell(
                    Container(
                      width: 250, // Chiều rộng cố định để text wrap
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        po.note ?? '', 
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      ),
                    ),
                  ),
                  DataCell(Text(
                    "${NumberFormat.currency(locale: 'en_US', symbol: '').format(po.totalAmount)} ${po.currency}",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  )),
                  DataCell(_buildStatusBadge(po.status)),
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min, 
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blue),
                        onPressed: () => _navigateToDetail(po.poId),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_note, color: Colors.grey),
                        onPressed: () => _showEditDialog(context, po, l10n),
                      ),
                      if (po.status == POStatus.Draft)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _confirmDelete(context, po, l10n),
                        ),
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

  TextStyle get _headerStyle => TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5);

  // --- MOBILE LIST ---
  Widget _buildMobileList(BuildContext context, List<PurchaseOrderHeader> items, AppLocalizations l10n) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final po = items[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _navigateToDetail(po.poId),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(po.poNumber, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      _buildStatusBadge(po.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.store, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Expanded(child: _VendorName(vendorId: po.vendorId, vendorObj: po.vendor, style: const TextStyle(fontWeight: FontWeight.w500))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 6),
                      Text("${l10n.date}: ${_dateFormat.format(po.orderDate)}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      if (po.expectedArrivalDate != null) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.local_shipping_outlined, size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 6),
                        Text("ETA: ${_dateFormat.format(po.expectedArrivalDate!)}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ]
                    ],
                  ),
                  if (po.note != null && po.note!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade200)
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.note, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              po.note!,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${po.incoterm.name} - ${po.currency}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                      Text(
                        NumberFormat.currency(locale: 'en_US', symbol: po.currency).format(po.totalAmount),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _primaryColor),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(POStatus status) {
    Color color;
    switch (status) {
      case POStatus.Draft: color = Colors.grey; break;
      case POStatus.Sent: color = Colors.blue; break;
      case POStatus.Confirmed: color = Colors.indigo; break;
      case POStatus.Partial: color = Colors.orange; break;
      case POStatus.Completed: color = Colors.green; break;
      case POStatus.Cancelled: color = Colors.red; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _navigateToDetail(int poId) {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => PurchaseOrderDetailScreen(poId: poId))
    ).then((_) {
      context.read<PurchaseOrderCubit>().loadPurchaseOrders();
    });
  }

  // --- DIALOG THÊM / SỬA ---
  void _showEditDialog(BuildContext context, PurchaseOrderHeader? po, AppLocalizations l10n) {
    final poNumberCtrl = TextEditingController(text: po?.poNumber ?? '');
    final currencyCtrl = TextEditingController(text: po?.currency ?? 'VND');
    final rateCtrl = TextEditingController(text: po?.exchangeRate.toString() ?? '1.0');
    final noteCtrl = TextEditingController(text: po?.note ?? '');
    
    int? selectedVendorId = po?.vendorId;
    DateTime selectedDate = po?.orderDate ?? DateTime.now();
    DateTime? selectedEta = po?.expectedArrivalDate;
    IncotermType selectedIncoterm = po?.incoterm ?? IncotermType.EXW;
    POStatus selectedStatus = po?.status ?? POStatus.Draft;

    final formKey = GlobalKey<FormState>();

    Future<void> selectDate(BuildContext ctx, bool isEta, Function(DateTime?) onPicked) async {
      final picked = await showDatePicker(
        context: ctx,
        initialDate: isEta ? (selectedEta ?? DateTime.now()) : selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
      );
      if (picked != null) onPicked(picked);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final width = MediaQuery.of(ctx).size.width;
        final isSmallScreen = width < 600;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.all(24),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          title: Text(po == null ? l10n.createPO : "Edit PO", style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: isSmallScreen ? double.maxFinite : 600,
              child: SingleChildScrollView(
                child: StatefulBuilder(
                  builder: (context, setState) {
                    Widget responsiveRow({required Widget child1, required Widget child2}) {
                      if (isSmallScreen) {
                        return Column(children: [child1, const SizedBox(height: 16), child2]);
                      }
                      return Row(children: [Expanded(child: child1), const SizedBox(width: 16), Expanded(child: child2)]);
                    }

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- Row 1: PO Number & Vendor ---
                        responsiveRow(
                          child1: TextFormField(
                            controller: poNumberCtrl,
                            decoration: _inputDeco(l10n.poNumber, icon: Icons.tag),
                            validator: (v) => v!.isEmpty ? l10n.required : null,
                            enabled: po == null,
                          ),
                          child2: BlocBuilder<SupplierCubit, SupplierState>(
                            builder: (context, state) {
                              List<Supplier> suppliers = [];
                              if (state is SupplierLoaded) suppliers = state.suppliers;
                              
                              return DropdownButtonFormField<int>(
                                value: suppliers.any((s) => s.id == selectedVendorId) ? selectedVendorId : null,
                                isExpanded: true,
                                decoration: _inputDeco(l10n.vendor, icon: Icons.store),
                                items: suppliers.map((s) => DropdownMenuItem(
                                  value: s.id, 
                                  child: Text(s.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
                                )).toList(),
                                onChanged: (val) => setState(() => selectedVendorId = val),
                                validator: (v) => v == null ? l10n.required : null,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // --- Row 2: Dates ---
                        responsiveRow(
                          child1: InkWell(
                            onTap: () => selectDate(context, false, (d) => setState(() => selectedDate = d!)),
                            child: InputDecorator(
                              decoration: _inputDeco(l10n.orderDate, icon: Icons.calendar_today),
                              child: Text(_dateFormat.format(selectedDate)),
                            ),
                          ),
                          child2: InkWell(
                            onTap: () => selectDate(context, true, (d) => setState(() => selectedEta = d)),
                            child: InputDecorator(
                              decoration: _inputDeco(l10n.eta, icon: Icons.local_shipping),
                              child: Text(selectedEta != null ? _dateFormat.format(selectedEta!) : l10n.selectDate),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // --- Row 3: Incoterm & Status ---
                        responsiveRow(
                          child1: DropdownButtonFormField<IncotermType>(
                            value: selectedIncoterm,
                            decoration: _inputDeco(l10n.incoterm, icon: Icons.local_offer),
                            items: IncotermType.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
                            onChanged: (val) => setState(() => selectedIncoterm = val!),
                          ),
                          child2: DropdownButtonFormField<POStatus>(
                            value: selectedStatus,
                            decoration: _inputDeco(l10n.status, icon: Icons.info_outline),
                            items: POStatus.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
                            onChanged: (val) => setState(() => selectedStatus = val!),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // --- Row 4: Currency & Exchange Rate ---
                        responsiveRow(
                          child1: TextFormField(
                            controller: currencyCtrl,
                            decoration: _inputDeco(l10n.currency, icon: Icons.monetization_on),
                          ),
                          child2: TextFormField(
                            controller: rateCtrl,
                            decoration: _inputDeco(l10n.exchangeRate, icon: Icons.currency_exchange),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // --- Row 5: Note ---
                        TextFormField(
                          controller: noteCtrl,
                          decoration: _inputDeco(l10n.note, icon: Icons.note),
                          maxLines: 2,
                        ),
                      ],
                    );
                  }
                ),
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.all(24),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate() && selectedVendorId != null) {
                  final newPO = PurchaseOrderHeader(
                    poId: po?.poId ?? 0,
                    poNumber: poNumberCtrl.text,
                    vendorId: selectedVendorId!,
                    orderDate: selectedDate,
                    expectedArrivalDate: selectedEta,
                    incoterm: selectedIncoterm,
                    currency: currencyCtrl.text,
                    exchangeRate: double.tryParse(rateCtrl.text) ?? 1.0,
                    status: selectedStatus,
                    note: noteCtrl.text,
                    totalAmount: po?.totalAmount ?? 0.0,
                    details: po?.details ?? [],
                  );
                  
                  context.read<PurchaseOrderCubit>().savePurchaseOrder(po: newPO, isEdit: po != null);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.processing), backgroundColor: Colors.blue));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: Text(l10n.save),
            ),
          ],
        );
      }
    );
  }

  InputDecoration _inputDeco(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, size: 18, color: Colors.grey) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  void _confirmDelete(BuildContext context, PurchaseOrderHeader po, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [const Icon(Icons.warning_amber_rounded, color: Colors.red), const SizedBox(width: 8), Text(l10n.deletePO)]),
        content: Text(l10n.confirmDeletePO(po.poNumber)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}

class _VendorName extends StatelessWidget {
  final int vendorId;
  final Supplier? vendorObj;
  final TextStyle? style;

  const _VendorName({required this.vendorId, this.vendorObj, this.style});

  @override
  Widget build(BuildContext context) {
    if (vendorObj != null) {
      return Text(vendorObj!.name, style: style ?? const TextStyle(fontWeight: FontWeight.w500));
    }
    
    return BlocBuilder<SupplierCubit, SupplierState>(
      builder: (context, state) {
        String name = "ID: $vendorId";
        if (state is SupplierLoaded) {
          final s = state.suppliers.where((e) => e.id == vendorId).firstOrNull;
          if (s != null) name = s.name;
        }
        return Text(name, style: style ?? const TextStyle(fontWeight: FontWeight.w500));
      },
    );
  }
}