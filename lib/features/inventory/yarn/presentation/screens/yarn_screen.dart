import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:production_app_frontend/l10n/app_localizations.dart';
import '../../../../../core/widgets/responsive_layout.dart';
import '../../../supplier/presentation/bloc/supplier_cubit.dart';
import '../../domain/yarn_model.dart';
import '../bloc/yarn_cubit.dart';

class YarnScreen extends StatefulWidget {
  const YarnScreen({super.key});

  @override
  State<YarnScreen> createState() => _YarnScreenState();
}

class _YarnScreenState extends State<YarnScreen> {
  final _searchController = TextEditingController();
  final Color _primaryColor = const Color(0xFF003366);
  final Color _accentColor = const Color(0xFF6A1B9A); // Màu Tím cho Sợi
  final Color _bgLight = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    context.read<YarnCubit>().loadYarns();
    context.read<SupplierCubit>().loadSuppliers();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: _bgLight,
      body: BlocBuilder<YarnCubit, YarnState>(
        builder: (context, state) {
          int total = 0;
          if (state is YarnLoaded) total = state.yarns.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- HEADER ---
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(10)),
                          child: Icon(Icons.line_style, color: Colors.purple.shade800, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.yarnTitle, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                            const SizedBox(height: 2),
                            Text("Inventory > Raw Materials", style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                          ],
                        ),
                        const Spacer(),
                        if (isDesktop)
                          ElevatedButton.icon(
                            onPressed: () => _showEditDialog(context, null, l10n),
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(l10n.addYarn.toUpperCase()),
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
                    
                    // Search Bar
                    Row(
                      children: [
                        if (isDesktop) ...[
                          _buildStatBadge(Icons.grid_view, "Total Items", "$total", Colors.blue),
                          const SizedBox(width: 16),
                          const Spacer(),
                        ],
                        Expanded(
                          flex: isDesktop ? 0 : 1,
                          child: Container(
                            width: isDesktop ? 350 : double.infinity,
                            decoration: BoxDecoration(color: _bgLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                            child: TextField(
                              controller: _searchController,
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                hintText: l10n.searchYarn,
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.arrow_forward, color: Colors.blue),
                                  onPressed: () => context.read<YarnCubit>().searchYarns(_searchController.text),
                                ),
                              ),
                              onSubmitted: (value) => context.read<YarnCubit>().searchYarns(value),
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
                    if (state is YarnLoading) return Center(child: CircularProgressIndicator(color: _primaryColor));
                    if (state is YarnError) return Center(child: Text("Error: ${state.message}", style: const TextStyle(color: Colors.red)));
                    if (state is YarnLoaded) {
                      if (state.yarns.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_outlined, size: 60, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              // [FIX] Dùng l10n
                              Text(l10n.noYarnFound, style: TextStyle(color: Colors.grey.shade500)),
                            ],
                          ),
                        );
                      }
                      return isDesktop
                          ? _buildDesktopTable(context, state.yarns, l10n)
                          : _buildMobileList(context, state.yarns, l10n);
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
  Widget _buildDesktopTable(BuildContext context, List<Yarn> yarns, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      // [FIX] Full Width
      // ignore: sized_box_for_whitespace
      child: Container(
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
                    headingRowColor: MaterialStateProperty.all(const Color(0xFFF9FAFB)),
                    horizontalMargin: 24,
                    columnSpacing: 30,
                    dataRowMinHeight: 60,
                    dataRowMaxHeight: 60,
                    columns: [
                      DataColumn(label: Text(l10n.itemCode.toUpperCase(), style: _headerStyle)),
                      DataColumn(label: Text(l10n.yarnName.toUpperCase(), style: _headerStyle)),
                      DataColumn(label: Text(l10n.yarnType.toUpperCase(), style: _headerStyle)),
                      DataColumn(label: Text("${l10n.color} / ${l10n.origin}".toUpperCase(), style: _headerStyle)),
                      DataColumn(label: Text(l10n.supplier.toUpperCase(), style: _headerStyle)),
                      // [FIX] Thêm cột Note
                      DataColumn(label: Text(l10n.note.toUpperCase(), style: _headerStyle)),
                      DataColumn(label: Text(l10n.actions.toUpperCase(), style: _headerStyle)),
                    ],
                    rows: yarns.map((item) {
                      return DataRow(
                        cells: [
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                            child: Text(item.itemCode, style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontFamily: 'Monospace')),
                          )),
                          DataCell(Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                          DataCell(_buildTag(item.type, Colors.purple)),
                          DataCell(Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(item.color, style: const TextStyle(fontSize: 13)),
                              Text(item.origin, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            ],
                          )),
                          DataCell(_SupplierNameBadge(supplierId: item.supplierId)),
                          // [FIX] Hiển thị Note
                          DataCell(Text(item.note, style: TextStyle(color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          DataCell(Row(
                            children: [
                              IconButton(icon: const Icon(Icons.edit_note, color: Colors.grey), onPressed: () => _showEditDialog(context, item, l10n)),
                              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _confirmDelete(context, item, l10n)),
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
  Widget _buildMobileList(BuildContext context, List<Yarn> yarns, AppLocalizations l10n) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: yarns.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = yarns[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Colors.purple.shade50,
              child: Text(item.itemCode.length > 2 ? item.itemCode.substring(0,2) : "Y", style: TextStyle(color: Colors.purple.shade800, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(children: [
                  _buildTag(item.type, Colors.grey),
                  const SizedBox(width: 8),
                  Text("${item.color} • ${item.origin}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ]),
                const SizedBox(height: 4),
                _SupplierNameBadge(supplierId: item.supplierId),
              ],
            ),
            trailing: PopupMenuButton(
              onSelected: (val) {
                if (val == 'edit') _showEditDialog(context, item, l10n);
                if (val == 'delete') _confirmDelete(context, item, l10n);
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit, size: 18), const SizedBox(width: 8), Text(l10n.editYarn)])),
                PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete, size: 18, color: Colors.red), const SizedBox(width: 8), Text(l10n.deleteYarn)])),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- DIALOG ---
  void _showEditDialog(BuildContext context, Yarn? item, AppLocalizations l10n) {
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final codeCtrl = TextEditingController(text: item?.itemCode ?? '');
    final typeCtrl = TextEditingController(text: item?.type ?? '');
    final colorCtrl = TextEditingController(text: item?.color ?? '');
    final originCtrl = TextEditingController(text: item?.origin ?? '');
    final noteCtrl = TextEditingController(text: item?.note ?? '');
    
    int? selectedSupplierId = item?.supplierId;
    
    // Auto select first supplier if creating new
    final supplierState = context.read<SupplierCubit>().state;
    if (item == null && supplierState is SupplierLoaded && supplierState.suppliers.isNotEmpty) {
      selectedSupplierId = supplierState.suppliers.first.id;
    }

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.all(24),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        title: Text(item == null ? l10n.addYarn : l10n.editYarn, style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: codeCtrl, decoration: _inputDeco(l10n.itemCode), validator: (v) => v!.isEmpty ? "Required" : null)),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: TextFormField(controller: nameCtrl, decoration: _inputDeco(l10n.yarnName), validator: (v) => v!.isEmpty ? "Required" : null)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: typeCtrl, decoration: _inputDeco(l10n.yarnType))),
                      const SizedBox(width: 12),
                      Expanded(child: TextFormField(controller: colorCtrl, decoration: _inputDeco(l10n.color))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(controller: originCtrl, decoration: _inputDeco(l10n.origin)),
                  const SizedBox(height: 16),
                  // Dropdown Supplier
                  DropdownButtonFormField<int>(
                    value: selectedSupplierId,
                    decoration: _inputDeco(l10n.supplier),
                    items: (supplierState is SupplierLoaded) 
                      ? supplierState.suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList() 
                      : [],
                    onChanged: (val) => selectedSupplierId = val,
                    validator: (v) => v == null ? "Required" : null,
                  ),
                  const SizedBox(height: 16),
                  // [FIX] Sử dụng l10n.note
                  TextFormField(controller: noteCtrl, decoration: _inputDeco(l10n.note), maxLines: 2),
                ],
              ),
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.all(24),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate() && selectedSupplierId != null) {
                final newItem = Yarn(
                  id: item?.id ?? 0,
                  name: nameCtrl.text,
                  itemCode: codeCtrl.text,
                  type: typeCtrl.text,
                  color: colorCtrl.text,
                  origin: originCtrl.text,
                  supplierId: selectedSupplierId!,
                  note: noteCtrl.text,
                );
                context.read<YarnCubit>().saveYarn(yarn: newItem, isEdit: item != null);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
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

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
    );
  }

  void _confirmDelete(BuildContext context, Yarn item, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteYarn),
        content: Text(l10n.confirmDeleteYarn(item.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              context.read<YarnCubit>().deleteYarn(item.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(l10n.deleteYarn),
          ),
        ],
      ),
    );
  }
}

class _SupplierNameBadge extends StatelessWidget {
  final int supplierId;
  const _SupplierNameBadge({required this.supplierId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SupplierCubit, SupplierState>(
      builder: (context, state) {
        String name = "Unknown";
        if (state is SupplierLoaded) {
          final s = state.suppliers.where((e) => e.id == supplierId).firstOrNull;
          if (s != null) name = s.name;
        }
        return Text(name, style: TextStyle(color: Colors.grey.shade700, fontSize: 13));
      },
    );
  }
}