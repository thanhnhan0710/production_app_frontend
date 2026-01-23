import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:production_app_frontend/l10n/app_localizations.dart'; // [MỚI] Import l10n

// Import các Bloc/Repository
import 'package:production_app_frontend/features/inventory/import_declaration/data/import_declaration_repository.dart';
import 'package:production_app_frontend/features/inventory/import_declaration/presentation/bloc/import_declaration_cubit.dart';
import 'package:production_app_frontend/features/inventory/purchase_order/data/purchase_order_repository.dart';
import 'package:production_app_frontend/features/inventory/purchase_order/presentation/bloc/purchase_order_cubit.dart';
import 'package:production_app_frontend/features/inventory/supplier/data/supplier_repository.dart';
import 'package:production_app_frontend/features/inventory/supplier/presentation/bloc/supplier_cubit.dart';
import 'package:production_app_frontend/features/inventory/warehouse/data/warehouse_repository.dart';
import 'package:production_app_frontend/features/inventory/warehouse/presentation/bloc/warehouse_cubit.dart';

import '../../data/material_receipt_repository.dart';
import '../../../../../core/widgets/responsive_layout.dart';
import '../../domain/material_receipt_model.dart';
import '../bloc/material_receipt_cubit.dart';
import 'material_receipt_form_screen.dart';

class MaterialStockInPage extends StatefulWidget {
  const MaterialStockInPage({super.key});

  @override
  State<MaterialStockInPage> createState() => _MaterialStockInPageState();
}

class _MaterialStockInPageState extends State<MaterialStockInPage> with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();
  
  // [MỚI] State quản lý bộ lọc ngày
  DateTime? _fromDate;
  DateTime? _toDate;
  String _dateFilterKey = "filter7Days"; // Mặc định 7 ngày

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // [MỚI] Áp dụng bộ lọc mặc định
    _applyQuickFilter('7_days', reload: false); 

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onSearch(); // Gọi hàm search thay vì load trực tiếp
    });
  }

  // [MỚI] Hàm tìm kiếm chung
  void _onSearch() {
    context.read<MaterialReceiptCubit>().loadReceipts(
      search: _searchController.text,
      fromDate: _fromDate,
      toDate: _toDate,
    );
  }

  // [MỚI] Logic áp dụng bộ lọc nhanh (Hôm nay, Hôm qua, Tháng này...)
  void _applyQuickFilter(String type, {bool reload = true}) {
    final now = DateTime.now();
    DateTime start;
    DateTime end = now;
    String filterKey = "";

    switch (type) {
      case 'today':
        start = now;
        filterKey = "filterToday";
        break;
      case 'yesterday':
        start = now.subtract(const Duration(days: 1));
        end = now.subtract(const Duration(days: 1));
        filterKey = "filterYesterday";
        break;
      case '7_days':
        start = now.subtract(const Duration(days: 7));
        filterKey = "filter7Days";
        break;
      case 'this_month':
        start = DateTime(now.year, now.month, 1);
        filterKey = "filterThisMonth";
        break;
      case 'last_month':
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 0); 
        filterKey = "filterLastMonth";
        break;
      case 'this_quarter':
        int quarter = ((now.month - 1) / 3).floor() + 1;
        int firstMonthOfQuarter = (quarter - 1) * 3 + 1;
        start = DateTime(now.year, firstMonthOfQuarter, 1);
        filterKey = "filterThisQuarter"; 
        break;
      case 'this_year':
        start = DateTime(now.year, 1, 1);
        filterKey = "filterThisYear";
        break;
      default:
        start = now;
        filterKey = "filterToday";
    }

    setState(() {
      _fromDate = start;
      _toDate = end;
      _dateFilterKey = filterKey;
    });
    
    if (reload) _onSearch();
  }

  // [MỚI] Chọn khoảng ngày tùy chỉnh
  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: (_fromDate != null && _toDate != null) 
          ? DateTimeRange(start: _fromDate!, end: _toDate!) 
          : null,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFF003366),
            colorScheme: const ColorScheme.light(primary: Color(0xFF003366)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
        _dateFilterKey = "filterCustom";
      });
      _onSearch();
    }
  }

  // [MỚI] Helper lấy label hiển thị
  String _getFilterLabel(AppLocalizations l10n) {
    switch (_dateFilterKey) {
      case "filterToday": return l10n.filterToday;
      case "filterYesterday": return l10n.filterYesterday;
      case "filter7Days": return l10n.filter7Days;
      case "filterThisMonth": return l10n.filterThisMonth;
      case "filterLastMonth": return l10n.filterLastMonth;
      case "filterThisQuarter": return l10n.filterThisQuarter;
      case "filterThisYear": return l10n.filterThisYear;
      case "filterCustom": return l10n.filterCustom;
      default: return l10n.filter7Days;
    }
  }

  void _navigateToForm(BuildContext context, {MaterialReceipt? receipt}) {
    // final currentCubit = context.read<MaterialReceiptCubit>();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => MaterialReceiptCubit(MaterialReceiptRepository())),
            BlocProvider(create: (context) => WarehouseCubit(WarehouseRepository())..loadWarehouses()),
            BlocProvider(create: (context) => PurchaseOrderCubit(PurchaseOrderRepository())..loadPurchaseOrders()),
            BlocProvider(create: (context) => SupplierCubit(SupplierRepository())..loadSuppliers()),
            BlocProvider(create: (context) => ImportDeclarationCubit(ImportDeclarationRepository())..loadDeclarations()),
          ],
          child: MaterialReceiptFormScreen(receiptId: receipt?.id),
        ),
      ),
    ).then((_) {
      if (mounted) {
        // Reload lại danh sách với bộ lọc hiện tại
        _onSearch();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final l10n = AppLocalizations.of(context)!; // Lấy localization

    return Column(
      children: [
        // --- TOOLBAR & FILTER ---
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.black12)),
          ),
          child: Column(
            children: [
              // Hàng 1: Search + Add Button
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: l10n.searchStockInHint,
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      ),
                      onSubmitted: (val) => _onSearch(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToForm(context),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.createStockIn),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Hàng 2: Date Filters
              Row(
                children: [
                  // Dropdown chọn nhanh
                  PopupMenuButton<String>(
                    onSelected: _applyQuickFilter,
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'today', child: Text(l10n.filterToday)),
                      PopupMenuItem(value: 'yesterday', child: Text(l10n.filterYesterday)),
                      PopupMenuItem(value: '7_days', child: Text(l10n.filter7Days)),
                      const PopupMenuDivider(),
                      PopupMenuItem(value: 'this_month', child: Text(l10n.filterThisMonth)),
                      PopupMenuItem(value: 'last_month', child: Text(l10n.filterLastMonth)),
                      PopupMenuItem(value: 'this_quarter', child: Text(l10n.filterThisQuarter)),
                      PopupMenuItem(value: 'this_year', child: Text(l10n.filterThisYear)),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.filter_list, size: 18, color: Color(0xFF003366)),
                          const SizedBox(width: 8),
                          Text(_getFilterLabel(l10n), style: const TextStyle(color: Color(0xFF003366), fontWeight: FontWeight.bold)),
                          const Icon(Icons.arrow_drop_down, color: Color(0xFF003366)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Date Range Picker Display
                  Expanded(
                    child: InkWell(
                      onTap: _pickDateRange,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month, size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                (_fromDate != null && _toDate != null)
                                    ? "${DateFormat('dd/MM/yyyy').format(_fromDate!)} - ${DateFormat('dd/MM/yyyy').format(_toDate!)}"
                                    : l10n.filterCustom,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Nút Refresh
                  IconButton(
                    onPressed: _onSearch,
                    icon: const Icon(Icons.refresh, color: Colors.grey),
                    tooltip: l10n.reload,
                  ),
                ],
              ),
            ],
          ),
        ),

        // --- LIST CONTENT ---
        Expanded(
          child: BlocBuilder<MaterialReceiptCubit, MaterialReceiptState>(
            builder: (context, state) {
              if (state is MaterialReceiptLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is MaterialReceiptListLoaded) {
                if (state.receipts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(l10n.noStockInFound, style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }
                return isDesktop
                    ? _buildDesktopTable(state.receipts, l10n)
                    : _buildMobileList(state.receipts, l10n);
              } else if (state is MaterialReceiptError) {
                return Center(child: Text(l10n.errorLabel(state.message), style: const TextStyle(color: Colors.red)));
              }
              return const SizedBox();
            },
          ),
        ),
      ],
    );
  }

  // --- DESKTOP TABLE ---
  Widget _buildDesktopTable(List<MaterialReceipt> receipts, AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth), 
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade200)),
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(const Color(0xFFF9FAFB)),
                showCheckboxColumn: false, 
                columnSpacing: 20,
                columns: [
                  DataColumn(label: Text(l10n.receiptNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text(l10n.importDate, style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text(l10n.receivingWarehouse, style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text(l10n.poNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text(l10n.declarationNo, style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text(l10n.containerSeal, style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text(l10n.createdBy, style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text(l10n.actions, style: const TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: receipts.map((r) {
                  return DataRow(
                    onSelectChanged: (_) => _navigateToForm(context, receipt: r),
                    cells: [
                      DataCell(Text(r.receiptNumber, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003366)))),
                      DataCell(Text(DateFormat('dd/MM/yyyy').format(r.receiptDate))),
                      DataCell(Text(r.warehouse?.name ?? "---")),
                      DataCell(Text(r.poHeader?.poNumber ?? "---", style: const TextStyle(fontWeight: FontWeight.w500))),
                      DataCell(Text(r.declaration?.declarationNo ?? "---")), 
                      DataCell(Text("${r.containerNo ?? ''} ${r.sealNo != null ? '/ ${r.sealNo}' : ''}")),
                      DataCell(Text(r.createdBy ?? "---")),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(r, l10n),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- MOBILE LIST ---
  Widget _buildMobileList(List<MaterialReceipt> receipts, AppLocalizations l10n) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: receipts.length,
      itemBuilder: (context, index) {
        final r = receipts[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: InkWell(
            onTap: () => _navigateToForm(context, receipt: r),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(r.receiptNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF003366))),
                      Text(DateFormat('dd/MM/yyyy').format(r.receiptDate), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                  const Divider(height: 16),
                  _buildMobileRow(Icons.store, "${l10n.receivingWarehouse}:", r.warehouse?.name ?? "---"),
                  const SizedBox(height: 6),
                  if (r.poHeader != null) 
                    _buildMobileRow(Icons.shopping_cart, "${l10n.poNumber}:", r.poHeader!.poNumber),
                  if (r.declaration != null)
                    _buildMobileRow(Icons.description, "${l10n.declarationNo}:", r.declaration!.declarationNo),
                  if (r.containerNo != null && r.containerNo!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _buildMobileRow(Icons.local_shipping, "${l10n.containerSeal}:", "${r.containerNo} / ${r.sealNo ?? ''}"),
                  ],
                  const SizedBox(height: 6),
                  _buildMobileRow(Icons.person, "${l10n.createdBy}:", r.createdBy ?? "---"),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(width: 4),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  void _confirmDelete(MaterialReceipt r, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmDeleteTitle),
        content: Text(l10n.confirmDeleteStockIn(r.receiptNumber)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<MaterialReceiptCubit>().deleteReceipt(r.id!);
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}