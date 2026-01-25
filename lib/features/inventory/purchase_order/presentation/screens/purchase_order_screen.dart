import 'dart:async'; // Import để dùng Timer cho Debounce
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
import 'create_purchase_order_screen.dart'; // [NEW] Import trang Form

class PurchaseOrderScreen extends StatefulWidget {
  const PurchaseOrderScreen({super.key});

  @override
  State<PurchaseOrderScreen> createState() => _PurchaseOrderScreenState();
}

class _PurchaseOrderScreenState extends State<PurchaseOrderScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce; 

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
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<PurchaseOrderCubit>().loadPurchaseOrders(search: query);
    });
  }

  // [NEW] Điều hướng sang form (Tạo mới nếu po=null, Sửa nếu po!=null)
  void _navigateToForm({PurchaseOrderHeader? po}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreatePurchaseOrderScreen(existingPO: po)),
    ).then((_) {
      context.read<PurchaseOrderCubit>().loadPurchaseOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: _bgLight,
      body: SelectionArea(
        child: BlocConsumer<PurchaseOrderCubit, PurchaseOrderState>(
          listener: (context, state) {
            if (state is POError) {
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text(state.message), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
               );
            }
          },
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
                            decoration: BoxDecoration(color: _primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                            child: Icon(Icons.shopping_cart_outlined, color: _primaryColor, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.purchaseOrderTitle, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                              const SizedBox(height: 2),
                              Text(l10n.purchaseOrderSubtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                            ],
                          ),
                          const Spacer(),
                          if (isDesktop)
                            ElevatedButton.icon(
                              onPressed: () => _navigateToForm(), // Tạo mới
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
                      
                      // --- SEARCH ---
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(color: _bgLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
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
                                    ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchController.clear(); context.read<PurchaseOrderCubit>().loadPurchaseOrders(); })
                                    : null,
                                ),
                                onChanged: _onSearchChanged,
                                onSubmitted: (value) {
                                   if (_debounce?.isActive ?? false) _debounce!.cancel();
                                   context.read<PurchaseOrderCubit>().loadPurchaseOrders(search: value);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                            child: const Icon(Icons.filter_list, color: Colors.grey, size: 20),
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
                      if (state is POLoading) return Center(child: CircularProgressIndicator(color: _primaryColor));
                      if (state is POListLoaded) {
                        if (state.list.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.remove_shopping_cart_outlined, size: 60, color: Colors.grey.shade300), const SizedBox(height: 16), Text(l10n.noStatsData, style: TextStyle(color: Colors.grey.shade500))]));
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
      ),
      floatingActionButton: !isDesktop
          ? FloatingActionButton(
              backgroundColor: _accentColor,
              onPressed: () => _navigateToForm(), // Tạo mới (Mobile)
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal, 
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    showCheckboxColumn: false, 
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
                    horizontalMargin: 24,
                    columnSpacing: 24,
                    dataRowMinHeight: 64, 
                    dataRowMaxHeight: double.infinity, 
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
                        onSelectChanged: (_) => _navigateToDetail(po.poId),
                        cells: [
                          DataCell(Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(po.poNumber, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)))),
                          DataCell(_VendorName(vendorId: po.vendorId, vendorObj: po.vendor)),
                          DataCell(Text(_dateFormat.format(po.orderDate))),
                          DataCell(Text(po.expectedArrivalDate != null ? _dateFormat.format(po.expectedArrivalDate!) : "-")),
                          DataCell(Text(po.incoterm.name)),
                          DataCell(Container(width: 220, padding: const EdgeInsets.symmetric(vertical: 12), child: Text(po.note ?? '', style: TextStyle(color: Colors.grey.shade700, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis))),
                          
                          // Hiển thị tiền theo VND (đã quy đổi nếu cần)
                          DataCell(Text(
                            NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(po.totalAmount * po.exchangeRate),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          )),
                          
                          DataCell(_buildStatusBadge(po.status)),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Tooltip(
                                  message: l10n.edit,
                                  child: IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Colors.orange, size: 20),
                                    onPressed: () => _navigateToForm(po: po), // Sửa
                                    splashRadius: 20,
                                  ),
                                ),
                                if (po.status == POStatus.Draft)
                                  Tooltip(
                                    message: l10n.delete,
                                    child: IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                      onPressed: () => _confirmDelete(context, po, l10n),
                                      splashRadius: 20,
                                    ),
                                  )
                                else 
                                  const SizedBox(width: 40),
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
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
                        padding: EdgeInsets.zero,
                        onSelected: (value) {
                          if (value == 'edit') _navigateToForm(po: po); 
                          if (value == 'delete') _confirmDelete(context, po, l10n);
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit, size: 18), const SizedBox(width: 8), Text(l10n.edit)])),
                          if (po.status == POStatus.Draft)
                            PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete_outline, size: 18, color: Colors.red), const SizedBox(width: 8), Text(l10n.delete, style: const TextStyle(color: Colors.red))])),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildStatusBadge(po.status)]),
                  const SizedBox(height: 8),
                  Row(children: [Icon(Icons.store, size: 16, color: Colors.grey.shade500), const SizedBox(width: 6), Expanded(child: _VendorName(vendorId: po.vendorId, vendorObj: po.vendor, style: const TextStyle(fontWeight: FontWeight.w500)))]),
                  const SizedBox(height: 4),
                  Row(children: [Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade400), const SizedBox(width: 6), Text("${l10n.date}: ${_dateFormat.format(po.orderDate)}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600))]),
                  const Divider(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text("${po.incoterm.name} - ${po.currency}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                    // Hiển thị VND
                    Text(NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(po.totalAmount * po.exchangeRate), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _primaryColor)),
                  ]),
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
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withOpacity(0.2))),
      child: Text(status.name.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _navigateToDetail(int poId) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => PurchaseOrderDetailScreen(poId: poId))).then((_) => context.read<PurchaseOrderCubit>().loadPurchaseOrders());
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
              context.read<PurchaseOrderCubit>().deletePurchaseOrder(po.poId);
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
    if (vendorObj != null) return Text(vendorObj!.name, style: style ?? const TextStyle(fontWeight: FontWeight.w500));
    return BlocBuilder<SupplierCubit, SupplierState>(builder: (context, state) {
      String name = "ID: $vendorId";
      if (state is SupplierLoaded) {
        final s = state.suppliers.where((e) => e.id == vendorId).firstOrNull;
        if (s != null) name = s.name;
      }
      return Text(name, style: style ?? const TextStyle(fontWeight: FontWeight.w500));
    });
  }
}