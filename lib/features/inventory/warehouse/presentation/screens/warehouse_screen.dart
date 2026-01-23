import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

// --- IMPORTS ---
// Điều chỉnh lại đường dẫn import tùy theo cấu trúc project thực tế của bạn
import '../../../../../core/widgets/responsive_layout.dart';
import '../../../../../l10n/app_localizations.dart'; 
import '../../domain/warehouse_model.dart';
import '../bloc/warehouse_cubit.dart';

class WarehouseScreen extends StatefulWidget {
  const WarehouseScreen({super.key});

  @override
  State<WarehouseScreen> createState() => _WarehouseScreenState();
}

class _WarehouseScreenState extends State<WarehouseScreen> {
  final _searchController = TextEditingController();
  
  // Theme Colors (Giữ đồng bộ với EmployeeScreen)
  final Color _primaryColor = const Color(0xFF003366);
  final Color _accentColor = const Color(0xFF0055AA);
  final Color _bgLight = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    // Load danh sách kho khi vào màn hình
    context.read<WarehouseCubit>().loadWarehouses();
  }

  // --- ACTIONS ---
  Future<void> _openMap(String location, AppLocalizations l10n) async {
    if (location.isEmpty) return;
    // Encode địa chỉ để mở trên Google Maps
    final Uri launchUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location)}');
    try {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.cannotOpenMap)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; 
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: _bgLight,
      body: BlocBuilder<WarehouseCubit, WarehouseState>(
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
                            color: Colors.orange.withOpacity(0.1), // Màu cam cho kho để khác employee
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.store_mall_directory, color: Colors.orange, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.warehouseTitle,
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.warehouseSubtitle,
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (isDesktop)
                          ElevatedButton.icon(
                            onPressed: () => _showEditDialog(context, null, l10n),
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(l10n.addWarehouse.toUpperCase()),
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
                                hintText: l10n.searchWarehouseHint,
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.arrow_forward, color: Colors.blue),
                                  onPressed: () {
                                    context.read<WarehouseCubit>().searchWarehouses(_searchController.text);
                                  },
                                ),
                              ),
                              onSubmitted: (value) => context.read<WarehouseCubit>().searchWarehouses(value),
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
                    if (state is WarehouseLoading) {
                      return Center(child: CircularProgressIndicator(color: _primaryColor));
                    } else if (state is WarehouseError) {
                      return Center(child: Text("Error: ${state.message}", style: const TextStyle(color: Colors.red)));
                    } else if (state is WarehouseLoaded) {
                      if (state.warehouses.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.domain_disabled, size: 60, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(l10n.noWarehouseFound, style: TextStyle(color: Colors.grey.shade500)),
                            ],
                          ),
                        );
                      }
                      return isDesktop
                          ? _buildDesktopGrid(context, state.warehouses, l10n)
                          : _buildMobileList(context, state.warehouses, l10n);
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
              child: const Icon(Icons.add_business, color: Colors.white),
            )
          : null,
    );
  }

  // --- DESKTOP GRID ---
  Widget _buildDesktopGrid(BuildContext context, List<Warehouse> warehouses, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(const Color(0xFFF9FAFB)),
                    horizontalMargin: 24,
                    columnSpacing: 30,
                    dataRowMinHeight: 72,
                    dataRowMaxHeight: 72,
                    columns: [
                      DataColumn(label: Text(l10n.warehouseName.toUpperCase(), style: _headerStyle)),
                      DataColumn(label: Text(l10n.location.toUpperCase(), style: _headerStyle)),
                      DataColumn(label: Text(l10n.description.toUpperCase(), style: _headerStyle)),
                      DataColumn(label: Text(l10n.actions.toUpperCase(), style: _headerStyle)),
                    ],
                    rows: warehouses.map((wh) {
                      return DataRow(
                        cells: [
                          DataCell(Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.inventory_2_outlined, size: 20, color: Colors.blueGrey),
                              ),
                              const SizedBox(width: 16),
                              Text(wh.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14)),
                            ],
                          )),
                          DataCell(
                            InkWell(
                              onTap: () => _openMap(wh.location, l10n),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 16, color: Colors.redAccent),
                                  const SizedBox(width: 4),
                                  Text(wh.location, style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                                ],
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 200, 
                              child: Text(
                                wh.description.isNotEmpty ? wh.description : l10n.noDescription, 
                                style: TextStyle(color: Colors.grey.shade600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_note, color: Colors.grey), 
                                onPressed: () => _showEditDialog(context, wh, l10n),
                                tooltip: l10n.edit,
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent), 
                                onPressed: () => _confirmDelete(context, wh, l10n),
                                tooltip: l10n.delete,
                              ),
                            ],
                          )),
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
  Widget _buildMobileList(BuildContext context, List<Warehouse> warehouses, AppLocalizations l10n) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: warehouses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final wh = warehouses[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.store, color: Colors.orange, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(wh.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () => _openMap(wh.location, l10n),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on, size: 14, color: Colors.redAccent),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    wh.location, 
                                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton(
                      icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
                      onSelected: (val) {
                        if (val == 'edit') _showEditDialog(context, wh, l10n);
                        if (val == 'delete') _confirmDelete(context, wh, l10n);
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit, size: 18), const SizedBox(width: 8), Text(l10n.edit)])),
                        PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete, size: 18, color: Colors.red), const SizedBox(width: 8), Text(l10n.delete)])),
                      ],
                    ),
                  ],
                ),
              ),
              if (wh.description.isNotEmpty) ...[
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Divider(height: 1, color: Colors.grey.shade100)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.description_outlined, size: 16, color: Colors.grey.shade400),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          wh.description, 
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ]
            ],
          ),
        );
      },
    );
  }

  // --- DIALOG THÊM / SỬA ---
  void _showEditDialog(BuildContext context, Warehouse? wh, AppLocalizations l10n) {
    final nameCtrl = TextEditingController(text: wh?.name ?? '');
    final locationCtrl = TextEditingController(text: wh?.location ?? '');
    final descCtrl = TextEditingController(text: wh?.description ?? '');
    
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.all(24),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        title: Text(
          wh == null ? l10n.addWarehouse : l10n.editWarehouse, 
          style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)
        ),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 450, // Nhỏ hơn form Employee chút vì ít field hơn
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: nameCtrl, 
                    decoration: _inputDeco(l10n.warehouseName), 
                    validator: (v) => v!.isEmpty ? l10n.required : null
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: locationCtrl, 
                    decoration: _inputDeco(l10n.location, icon: Icons.location_on_outlined), 
                    validator: (v) => v!.isEmpty ? l10n.required : null
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descCtrl, 
                    decoration: _inputDeco(l10n.description, icon: Icons.description_outlined), 
                    maxLines: 3
                  ),
                ],
              ),
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.all(24),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final newWh = Warehouse(
                  id: wh?.id ?? 0, // ID 0 cho tạo mới
                  name: nameCtrl.text,
                  location: locationCtrl.text,
                  description: descCtrl.text,
                );
                
                context.read<WarehouseCubit>().saveWarehouse(
                  warehouse: newWh, 
                  isEdit: wh != null
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    // [FIX] Changed from warehouseAddedSuccess/warehouseUpdatedSuccess to generic success keys
                    content: Text(wh == null ? l10n.successAdded : l10n.successUpdated), 
                    backgroundColor: Colors.green
                  )
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor, 
              foregroundColor: Colors.white, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
            ),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      suffixIcon: icon != null ? Icon(icon, color: Colors.grey.shade400) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  void _confirmDelete(BuildContext context, Warehouse wh, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [const Icon(Icons.warning_amber_rounded, color: Colors.red), const SizedBox(width: 8), Text(l10n.deleteWarehouse)]),
        content: Text(l10n.confirmDeleteWarehouse(wh.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              context.read<WarehouseCubit>().deleteWarehouse(wh.id);
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