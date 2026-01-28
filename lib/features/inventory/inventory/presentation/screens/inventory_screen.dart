import 'dart:async'; // [MỚI] Import để dùng Timer cho Debounce
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

// Imports Core & Shared
import '../../../../../core/widgets/responsive_layout.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../domain/inventory_model.dart';
import '../bloc/inventory_cubit.dart';

// Import Feature khác để hiển thị badge màu đẹp hơn
import 'package:production_app_frontend/features/inventory/warehouse/presentation/bloc/warehouse_cubit.dart';
import 'package:production_app_frontend/features/inventory/warehouse/domain/warehouse_model.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();
  final Color _primaryColor = const Color(0xFF003366);
  final Color _accentColor = const Color(0xFFC2185B);
  final Color _bgLight = const Color(0xFFF5F7FA);

  // Filter state
  int? _selectedWarehouseId;
  
  // [MỚI] Timer dùng cho Debounce search
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Load initial data
    context.read<InventoryCubit>().loadInventories();
    context.read<WarehouseCubit>().loadWarehouses();
  }

  @override
  void dispose() {
    // [MỚI] Hủy timer khi widget bị hủy để tránh memory leak
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // Helper trigger search
  void _triggerSearch() {
    context.read<InventoryCubit>().loadInventories(
      search: _searchController.text,
      warehouseId: _selectedWarehouseId,
    );
  }

  // [MỚI] Hàm xử lý khi người dùng gõ phím
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _triggerSearch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: _bgLight,
      body: BlocConsumer<InventoryCubit, InventoryState>(
        listener: (context, state) {
          if (state is InventoryAdjustmentSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Stock adjusted successfully!"), backgroundColor: Colors.green),
            );
          }
          if (state is InventoryError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        buildWhen: (previous, current) => current is InventoryListLoaded || current is InventoryLoading,
        builder: (context, state) {
          int totalItems = 0;
          List<InventoryStock> stocks = [];
          if (state is InventoryListLoaded) {
            stocks = state.stocks;
            totalItems = stocks.length;
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
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.warehouse, color: Colors.amber.shade800, size: 24),
                        ),
                        const SizedBox(width: 16),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Inventory Stock", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                            SizedBox(height: 2),
                            Text("Manage stock levels & batches", style: TextStyle(fontSize: 13, color: Colors.grey)),
                          ],
                        ),
                        const Spacer(),
                        if (isDesktop)
                          ElevatedButton.icon(
                            onPressed: () => context.read<InventoryCubit>().loadInventories(),
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text("REFRESH"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.grey.shade700,
                              elevation: 0,
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // --- FILTER & SEARCH BAR ---
                    Row(
                      children: [
                        if (isDesktop) ...[
                          _buildStatBadge(Icons.layers, "Total Items", "$totalItems", Colors.blue),
                          const SizedBox(width: 16),
                          const Spacer(),
                        ],
                        // Warehouse Filter
                        _buildWarehouseFilter(isDesktop),
                        const SizedBox(width: 12),
                        // Search Input
                        Expanded(
                          flex: isDesktop ? 0 : 1,
                          child: Container(
                            width: isDesktop ? 300 : double.infinity,
                            decoration: BoxDecoration(
                              color: _bgLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: TextField(
                              controller: _searchController,
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                hintText: "Search Material, Batch...",
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.arrow_forward, color: Colors.blue),
                                  onPressed: () => _triggerSearch(),
                                ),
                              ),
                              // [MỚI] Thêm onChanged để tìm kiếm tức thì (Debounce 500ms)
                              onChanged: _onSearchChanged,
                              onSubmitted: (value) => _triggerSearch(),
                            ),
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
                    if (state is InventoryLoading) {
                      return Center(child: CircularProgressIndicator(color: _primaryColor));
                    }
                    if (stocks.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            const Text("No stock records found", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    }
                    return isDesktop
                        ? _buildDesktopTable(stocks)
                        : _buildMobileList(stocks);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWarehouseFilter(bool isDesktop) {
    return BlocBuilder<WarehouseCubit, WarehouseState>(
      builder: (context, state) {
        List<Warehouse> warehouses = [];
        if (state is WarehouseLoaded) warehouses = state.warehouses;

        return Container(
          width: isDesktop ? 200 : 120,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedWarehouseId,
              hint: const Text("Warehouse", style: TextStyle(fontSize: 13)),
              icon: const Icon(Icons.arrow_drop_down, size: 20),
              isExpanded: true,
              items: [
                const DropdownMenuItem<int>(value: null, child: Text("All Warehouses")),
                ...warehouses.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name, overflow: TextOverflow.ellipsis))),
              ],
              onChanged: (val) {
                setState(() => _selectedWarehouseId = val);
                _triggerSearch();
              },
            ),
          ),
        );
      },
    );
  }

  // --- DESKTOP TABLE ---
  Widget _buildDesktopTable(List<InventoryStock> stocks) {
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
            columnSpacing: 24,
            dataRowMinHeight: 60,
            dataRowMaxHeight: 60,
            columns: [
              _col("Material"),
              _col("Supplier"), 
              _col("Sys Batch / Origin"), 
              _col("Location"), 
              _col("Rolls"), 
              _col("Pallets"),
              _col("Warehouse"),
              _col("On Hand"),
              _col("Reserved"),
              _col("Available"),
              _col("Action"),
            ],
            rows: stocks.map((item) {
              return DataRow(
                cells: [
                  // Material
                  DataCell(Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item.material?.materialCode ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      
                    ],
                  )),
                  // Supplier
                  DataCell(Text(item.supplierShortName ?? '--', style: const TextStyle(fontWeight: FontWeight.w500))),
                  // Batch
                  DataCell(Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item.batch?.internalBatchCode ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (item.batch?.originCountry != null)
                        Text(item.batch!.originCountry!, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    ],
                  )),
                  // Location
                  DataCell(
                    item.batch?.location != null 
                    ? Row(children: [
                        const Icon(Icons.place, size: 14, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(item.batch!.location!, style: const TextStyle(fontWeight: FontWeight.bold))
                      ])
                    : const Text("--", style: TextStyle(color: Colors.grey))
                  ),
                  // Rolls
                  DataCell(Text("${item.receivedQuantityCones ?? 0}")),
                  // Pallets
                  DataCell(Text("${item.numberOfPallets ?? 0}")),
                  // Warehouse
                  DataCell(Text(item.warehouse?.name ?? 'Unknown')),
                  // Qty On Hand
                  DataCell(Text(
                    NumberFormat("#,##0.##").format(item.quantityOnHand), 
                    style: const TextStyle(fontWeight: FontWeight.bold)
                  )),
                  // Qty Reserved
                  DataCell(Text(
                    NumberFormat("#,##0.##").format(item.quantityReserved), 
                    style: TextStyle(color: Colors.orange.shade800)
                  )),
                  // Qty Available
                  DataCell(Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.availableQuantity > 0 ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      NumberFormat("#,##0.##").format(item.availableQuantity),
                      style: TextStyle(fontWeight: FontWeight.bold, color: item.availableQuantity > 0 ? Colors.green.shade800 : Colors.red.shade800),
                    ),
                  )),
                  // Action
                  DataCell(
                    OutlinedButton.icon(
                      onPressed: () => _showAdjustmentDialog(context, item),
                      icon: const Icon(Icons.tune, size: 14),
                      label: const Text("Adjust"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // --- MOBILE LIST ---
  Widget _buildMobileList(List<InventoryStock> stocks) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: stocks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = stocks[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Align left
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.material?.materialCode ?? 'Unknown', style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor)),
                         
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                      child: Text(item.warehouse?.name ?? '-', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                
                const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                
                // Dòng thông tin Nhà cung cấp
                if (item.supplierShortName != null)
                   Padding(
                     padding: const EdgeInsets.only(bottom: 8),
                     child: Row(
                       children: [
                         Icon(Icons.store, size: 14, color: Colors.grey.shade600),
                         const SizedBox(width: 4),
                         Text(item.supplierShortName!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                       ],
                     ),
                   ),

                // Sys Batch & Location
                Row(
                  children: [
                    _mobileInfoCol("Sys Batch", item.batch?.internalBatchCode ?? '-', icon: Icons.qr_code),
                    const SizedBox(width: 16),
                    _mobileInfoCol("Location", item.batch?.location ?? '--', icon: Icons.place, valueColor: Colors.orange.shade800),
                  ],
                ),
                const SizedBox(height: 8),

                // Rolls & Pallets & Origin
                Row(
                   children: [
                      _mobileInfoCol("Rolls", "${item.receivedQuantityCones ?? 0}"),
                      const SizedBox(width: 16),
                      _mobileInfoCol("Pallets", "${item.numberOfPallets ?? 0}"),
                      const Spacer(),
                      _mobileInfoCol("Origin", item.batch?.originCountry ?? '--', icon: Icons.flag),
                   ],
                ),
                const SizedBox(height: 8),

                // Quantity
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _mobileInfoCol("On Hand (Kg)", NumberFormat("#,##0.##").format(item.quantityOnHand)),
                    _mobileInfoCol("Avail (Kg)", NumberFormat("#,##0.##").format(item.availableQuantity), isHighlight: true),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showAdjustmentDialog(context, item),
                    icon: const Icon(Icons.tune, size: 16),
                    label: const Text("Stock Adjustment"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primaryColor,
                      side: BorderSide(color: _primaryColor.withOpacity(0.5)),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _mobileInfoCol(String label, String value, {bool isHighlight = false, Color? valueColor, IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 12, color: Colors.grey.shade500), const SizedBox(width: 4)],
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value, 
          style: TextStyle(
            fontSize: 14, 
            fontWeight: FontWeight.bold, 
            color: valueColor ?? (isHighlight ? Colors.green.shade700 : Colors.black87)
          )
        ),
      ],
    );
  }

  // --- ADJUSTMENT DIALOG ---
  void _showAdjustmentDialog(BuildContext context, InventoryStock stock) {
    final qtyCtrl = TextEditingController(text: stock.quantityOnHand.toString());
    final reasonCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit_note, color: Colors.orange),
            SizedBox(width: 8),
            Text("Adjust Stock", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Material: ${stock.material?.materialCode}", style: const TextStyle(fontSize: 13, color: Colors.grey)),
              Text("Batch: ${stock.batch?.internalBatchCode}", style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 16),
              TextFormField(
                controller: qtyCtrl,
                decoration: _inputDeco("New Quantity (Real Count)"),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Bắt buộc nhập";
                  if (double.tryParse(v) == null) return "Phải là số";
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonCtrl,
                decoration: _inputDeco("Reason (e.g. Broken, Found...)"),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final newQty = double.parse(qtyCtrl.text);
                // Gọi API điều chỉnh
                context.read<InventoryCubit>().adjustStock(InventoryAdjustment(
                  materialId: stock.materialId,
                  warehouseId: stock.warehouseId,
                  batchId: stock.batchId,
                  newQuantity: newQty,
                  reason: reasonCtrl.text,
                ));
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
            child: const Text("Confirm Adjustment"),
          )
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      isDense: true,
    );
  }

  DataColumn _col(String label) => DataColumn(label: Text(label.toUpperCase(), style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 12)));

  Widget _buildStatBadge(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ])
      ]),
    );
  }
}