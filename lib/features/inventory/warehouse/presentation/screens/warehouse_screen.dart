import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

// --- IMPORTS ---
import '../../../../../core/network/websocket_service.dart';
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
  Timer? _debounce;

  // Theme Colors
  final Color _primaryColor = const Color(0xFF003366);
  final Color _accentColor = const Color(0xFF0055AA);
  final Color _bgLight = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    // 1. Load dữ liệu ban đầu
    context.read<WarehouseCubit>().loadWarehouses();

    // 2. Kết nối WebSocket và đăng ký lắng nghe tín hiệu
    WebSocketService().connect();
    WebSocketService().addListener(_onWebSocketMessage);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    // 3. Hủy lắng nghe WebSocket khi thoát màn hình
    WebSocketService().removeListener(_onWebSocketMessage);
    super.dispose();
  }

  // --- WEBSOCKET HANDLER ---
  void _onWebSocketMessage(String message) {
    if (message == "REFRESH_WAREHOUSES") {
      debugPrint(
          "WebSocket: Phát hiện thay đổi, tự động tải lại danh sách kho.");
      if (mounted) {
        context.read<WarehouseCubit>().loadWarehouses();
      }
    }
  }

  // --- ACTIONS ---
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<WarehouseCubit>().searchWarehouses(query);
    });
  }

  Future<void> _openMap(String location, AppLocalizations l10n) async {
    if (location.isEmpty) return;
    final Uri launchUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location)}');
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $launchUri';
      }
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
          List<Warehouse> displayList = [];
          int total = 0;

          if (state is WarehouseLoaded) {
            // [LOGIC SẮP XẾP] Tạo bản sao danh sách và sắp xếp ID giảm dần (mới nhất lên đầu)
            displayList = List<Warehouse>.from(state.warehouses);
            displayList.sort((a, b) => b.id.compareTo(a.id));
            total = displayList.length;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- HEADER SECTION ---
              Container(
                color: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.store_mall_directory,
                              color: Colors.orange, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.warehouseTitle,
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.warehouseSubtitle,
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (isDesktop)
                          ElevatedButton.icon(
                            onPressed: () =>
                                _showEditDialog(context, null, l10n),
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(l10n.addWarehouse.toUpperCase()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- SEARCH BAR ---
                    Row(
                      children: [
                        if (isDesktop) ...[
                          _buildStatBadge(Icons.grid_view, l10n.totalBaskets,
                              "$total", Colors.blue),
                          const SizedBox(width: 16),
                          const Spacer(),
                        ],
                        Expanded(
                          flex: isDesktop ? 0 : 1,
                          child: Container(
                            width: isDesktop ? 350 : double.infinity,
                            decoration: BoxDecoration(
                              color: _bgLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: TextField(
                              controller: _searchController,
                              textInputAction: TextInputAction.search,
                              onChanged: _onSearchChanged,
                              decoration: InputDecoration(
                                hintText: l10n.searchWarehouseHint,
                                hintStyle: TextStyle(
                                    color: Colors.grey.shade400, fontSize: 14),
                                prefixIcon: Icon(Icons.search,
                                    color: Colors.grey.shade500, size: 20),
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.clear,
                                      color: Colors.grey),
                                  onPressed: () {
                                    _searchController.clear();
                                    context
                                        .read<WarehouseCubit>()
                                        .loadWarehouses();
                                  },
                                ),
                              ),
                              onSubmitted: (value) {
                                if (value.isEmpty) {
                                  context
                                      .read<WarehouseCubit>()
                                      .loadWarehouses();
                                } else {
                                  context
                                      .read<WarehouseCubit>()
                                      .searchWarehouses(value);
                                }
                              },
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
                          child: const Icon(Icons.filter_list,
                              color: Colors.grey, size: 20),
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
                      return Center(
                          child:
                              CircularProgressIndicator(color: _primaryColor));
                    } else if (state is WarehouseError) {
                      return Center(
                          child: Text("Error: ${state.message}",
                              style: const TextStyle(color: Colors.red)));
                    } else if (state is WarehouseLoaded) {
                      if (displayList.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.domain_disabled,
                                  size: 60, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(l10n.noWarehouseFound,
                                  style:
                                      TextStyle(color: Colors.grey.shade500)),
                            ],
                          ),
                        );
                      }
                      return isDesktop
                          ? _buildDesktopGrid(context, displayList, l10n)
                          : _buildMobileList(context, displayList, l10n);
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

  // --- DESKTOP GRID/TABLE ---
  Widget _buildDesktopGrid(
      BuildContext context, List<Warehouse> warehouses, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200)),
        clipBehavior: Clip.antiAlias,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(const Color(0xFFF9FAFB)),
          horizontalMargin: 24,
          columnSpacing: 30,
          dataRowMinHeight: 72,
          dataRowMaxHeight: 72,
          columns: [
            DataColumn(
                label: Text(l10n.warehouseName.toUpperCase(),
                    style: _headerStyle)),
            DataColumn(
                label: Text(l10n.location.toUpperCase(), style: _headerStyle)),
            DataColumn(
                label:
                    Text(l10n.description.toUpperCase(), style: _headerStyle)),
            DataColumn(
                label: Text(l10n.actions.toUpperCase(), style: _headerStyle)),
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
                      child: const Icon(Icons.inventory_2_outlined,
                          size: 20, color: Colors.blueGrey),
                    ),
                    const SizedBox(width: 16),
                    Text(wh.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                  ],
                )),
                DataCell(
                  InkWell(
                    onTap: () => _openMap(wh.location, l10n),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 16, color: Colors.redAccent),
                        const SizedBox(width: 4),
                        Text(wh.location,
                            style: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline)),
                      ],
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 300,
                    child: Text(
                      wh.description.isNotEmpty
                          ? wh.description
                          : l10n.noDescription,
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
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.redAccent),
                      onPressed: () => _confirmDelete(context, wh, l10n),
                    ),
                  ],
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  TextStyle get _headerStyle => TextStyle(
      color: Colors.grey.shade600,
      fontWeight: FontWeight.bold,
      fontSize: 12,
      letterSpacing: 0.5);

  // --- MOBILE LIST ---
  Widget _buildMobileList(
      BuildContext context, List<Warehouse> warehouses, AppLocalizations l10n) {
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
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.store, color: Colors.orange),
                ),
                title: Text(wh.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: InkWell(
                  onTap: () => _openMap(wh.location, l10n),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 14, color: Colors.redAccent),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(wh.location,
                              style: const TextStyle(
                                  color: Colors.blue, fontSize: 13),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                ),
                trailing: PopupMenuButton(
                  onSelected: (val) {
                    if (val == 'edit') _showEditDialog(context, wh, l10n);
                    if (val == 'delete') _confirmDelete(context, wh, l10n);
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text("Sửa")
                        ])),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text("Xóa")
                        ])),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- DIALOGS ---
  void _showEditDialog(
      BuildContext context, Warehouse? wh, AppLocalizations l10n) {
    final nameCtrl = TextEditingController(text: wh?.name ?? '');
    final locationCtrl = TextEditingController(text: wh?.location ?? '');
    final descCtrl = TextEditingController(text: wh?.description ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(wh == null ? l10n.addWarehouse : l10n.editWarehouse),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                  controller: nameCtrl,
                  decoration: _inputDeco(l10n.warehouseName),
                  validator: (v) => v!.isEmpty ? l10n.required : null),
              const SizedBox(height: 16),
              TextFormField(
                  controller: locationCtrl,
                  decoration:
                      _inputDeco(l10n.location, icon: Icons.location_on),
                  validator: (v) => v!.isEmpty ? l10n.required : null),
              const SizedBox(height: 16),
              TextFormField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: _inputDeco(l10n.description)),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final newWh = Warehouse(
                  id: wh?.id ?? 0,
                  name: nameCtrl.text,
                  location: locationCtrl.text,
                  description: descCtrl.text,
                );
                context
                    .read<WarehouseCubit>()
                    .saveWarehouse(warehouse: newWh, isEdit: wh != null);
                Navigator.pop(ctx);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      suffixIcon: icon != null ? Icon(icon) : null,
      border: const OutlineInputBorder(),
    );
  }

  Widget _buildStatBadge(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ])
      ]),
    );
  }

  void _confirmDelete(
      BuildContext context, Warehouse wh, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteWarehouse),
        content: Text(l10n.confirmDeleteWarehouse(wh.name)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              context.read<WarehouseCubit>().deleteWarehouse(wh.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Xóa"),
          ),
        ],
      ),
    );
  }
}
