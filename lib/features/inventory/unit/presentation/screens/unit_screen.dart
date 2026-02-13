import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:production_app_frontend/l10n/app_localizations.dart';

// --- IMPORTS ---
import '../../../../../core/network/websocket_service.dart';
import '../../../../../core/widgets/responsive_layout.dart';
import '../../domain/unit_model.dart';
import '../bloc/unit_cubit.dart';

class UnitScreen extends StatefulWidget {
  const UnitScreen({super.key});

  @override
  State<UnitScreen> createState() => _UnitScreenState();
}

class _UnitScreenState extends State<UnitScreen> {
  final _searchController = TextEditingController();

  // Timer để debounce
  Timer? _debounce;

  final Color _primaryColor = const Color(0xFF003366);
  final Color _accentColor = const Color(0xFF43A047);
  final Color _bgLight = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    // 1. Load dữ liệu ban đầu
    context.read<UnitCubit>().loadUnits();

    // 2. Kết nối WebSocket và đăng ký lắng nghe
    WebSocketService().connect();
    WebSocketService().addListener(_onWebSocketMessage);
  }

  @override
  void dispose() {
    // Hủy timer và controller
    _debounce?.cancel();
    _searchController.dispose();

    // Hủy lắng nghe WebSocket khi thoát
    WebSocketService().removeListener(_onWebSocketMessage);
    super.dispose();
  }

  // Hàm xử lý tín hiệu WebSocket
  void _onWebSocketMessage(String message) {
    if (message == "REFRESH_UNITS") {
      debugPrint("✅ [WebSocket] Nhận tín hiệu cập nhật danh sách đơn vị tính.");
      if (mounted) {
        context.read<UnitCubit>().loadUnits();
      }
    }
  }

  // Hàm xử lý tìm kiếm khi gõ phím
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Đợi 500ms sau khi ngừng gõ mới gọi API
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isEmpty) {
        context.read<UnitCubit>().loadUnits();
      } else {
        context.read<UnitCubit>().searchUnits(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: _bgLight,
      body: BlocBuilder<UnitCubit, UnitState>(
        builder: (context, state) {
          // Khai báo biến danh sách hiển thị
          List<ProductUnit> displayList = [];
          int total = 0;

          if (state is UnitLoaded) {
            // [LOGIC SẮP XẾP] Tạo bản sao và xếp ID giảm dần (mới nhất lên đầu)
            displayList = List<ProductUnit>.from(state.units);
            displayList.sort((a, b) => b.id.compareTo(a.id));
            total = displayList.length;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- HEADER ---
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
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(10)),
                          child: Icon(Icons.straighten,
                              color: Colors.green.shade800, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.unitTitle,
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800)),
                            const SizedBox(height: 2),
                            Text("Inventory > Settings",
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey.shade500)),
                          ],
                        ),
                        const Spacer(),
                        if (isDesktop)
                          ElevatedButton.icon(
                            onPressed: () =>
                                _showEditDialog(context, null, l10n),
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(l10n.addUnit.toUpperCase()),
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
                    // Search Bar
                    Row(
                      children: [
                        if (isDesktop) ...[
                          _buildStatBadge(Icons.grid_view, "Total Units",
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
                                border:
                                    Border.all(color: Colors.grey.shade200)),
                            child: TextField(
                              controller: _searchController,
                              textInputAction: TextInputAction.search,
                              onChanged:
                                  _onSearchChanged, // [MỚI] Gắn sự kiện onChanged
                              decoration: InputDecoration(
                                hintText: l10n.searchUnit,
                                hintStyle: TextStyle(
                                    color: Colors.grey.shade400, fontSize: 14),
                                prefixIcon: Icon(Icons.search,
                                    color: Colors.grey.shade500, size: 20),
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                // [MỚI] Nút Clear
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear,
                                            color: Colors.grey, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          _onSearchChanged('');
                                          setState(() {});
                                        },
                                      )
                                    : null,
                              ),
                              onSubmitted: (value) {
                                if (value.isEmpty) {
                                  context.read<UnitCubit>().loadUnits();
                                } else {
                                  context.read<UnitCubit>().searchUnits(value);
                                }
                              },
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
                    if (state is UnitLoading) {
                      return Center(
                          child:
                              CircularProgressIndicator(color: _primaryColor));
                    }
                    if (state is UnitError) {
                      return Center(
                          child: Text("Error: ${state.message}",
                              style: const TextStyle(color: Colors.red)));
                    }
                    if (state is UnitLoaded) {
                      if (displayList.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_outlined,
                                  size: 60, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(l10n.noUnitFound,
                                  style:
                                      TextStyle(color: Colors.grey.shade500)),
                            ],
                          ),
                        );
                      }
                      return isDesktop
                          ? _buildDesktopTable(context, displayList, l10n)
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
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  // --- DESKTOP TABLE ---
  Widget _buildDesktopTable(
      BuildContext context, List<ProductUnit> units, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200)),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowColor:
                        MaterialStateProperty.all(const Color(0xFFF9FAFB)),
                    horizontalMargin: 24,
                    columnSpacing: 30,
                    dataRowMinHeight: 60,
                    dataRowMaxHeight: 60,
                    columns: [
                      DataColumn(
                          label: Text(l10n.unitName.toUpperCase(),
                              style: _headerStyle)),
                      DataColumn(
                          label: Text(l10n.note.toUpperCase(),
                              style: _headerStyle)),
                      DataColumn(
                          label: Text(l10n.actions.toUpperCase(),
                              style: _headerStyle)),
                    ],
                    rows: units.map((item) {
                      return DataRow(
                        cells: [
                          DataCell(Text(item.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold))),
                          DataCell(Text(item.note,
                              style: TextStyle(color: Colors.grey.shade600))),
                          DataCell(Row(
                            children: [
                              IconButton(
                                  icon: const Icon(Icons.edit_note,
                                      color: Colors.grey),
                                  onPressed: () =>
                                      _showEditDialog(context, item, l10n)),
                              IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.redAccent),
                                  onPressed: () =>
                                      _confirmDelete(context, item, l10n)),
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

  TextStyle get _headerStyle => TextStyle(
      color: Colors.grey.shade600,
      fontWeight: FontWeight.bold,
      fontSize: 12,
      letterSpacing: 0.5);

  // --- MOBILE LIST ---
  Widget _buildMobileList(
      BuildContext context, List<ProductUnit> units, AppLocalizations l10n) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: units.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = units[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade50,
              child: Text(item.name.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.bold)),
            ),
            title: Text(item.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: item.note.isNotEmpty
                ? Text(item.note,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600))
                : null,
            trailing: PopupMenuButton(
              onSelected: (val) {
                if (val == 'edit') _showEditDialog(context, item, l10n);
                if (val == 'delete') _confirmDelete(context, item, l10n);
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      const Icon(Icons.edit, size: 18),
                      const SizedBox(width: 8),
                      Text(l10n.editUnit)
                    ])),
                PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      const Icon(Icons.delete, size: 18, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(l10n.deleteUnit)
                    ])),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- DIALOG ---
  void _showEditDialog(
      BuildContext context, ProductUnit? item, AppLocalizations l10n) {
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final noteCtrl = TextEditingController(text: item?.note ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.all(24),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        title: Text(item == null ? l10n.addUnit : l10n.editUnit,
            style:
                TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                      controller: nameCtrl,
                      decoration: _inputDeco(l10n.unitName),
                      validator: (v) => v!.isEmpty ? "Required" : null),
                  const SizedBox(height: 16),
                  TextFormField(
                      controller: noteCtrl,
                      decoration: _inputDeco(l10n.note),
                      maxLines: 2),
                ],
              ),
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.all(24),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel,
                  style: const TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final newItem = ProductUnit(
                  id: item?.id ?? 0,
                  name: nameCtrl.text,
                  note: noteCtrl.text,
                );
                context
                    .read<UnitCubit>()
                    .saveUnit(unit: newItem, isEdit: item != null);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        item == null ? l10n.successAdded : l10n.successUpdated),
                    backgroundColor: Colors.green));
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      BuildContext context, ProductUnit item, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteUnit),
        content: Text(l10n.confirmDeleteUnit(item.name)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              context.read<UnitCubit>().deleteUnit(item.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(l10n.successDeleted),
                  backgroundColor: Colors.red));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(l10n.deleteUnit),
          ),
        ],
      ),
    );
  }
}
