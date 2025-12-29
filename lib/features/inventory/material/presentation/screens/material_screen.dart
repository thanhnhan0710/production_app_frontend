import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:production_app_frontend/l10n/app_localizations.dart';
import 'package:production_app_frontend/core/widgets/responsive_layout.dart';

// Import Feature Material
import '../../domain/material_model.dart';
import '../bloc/material_cubit.dart';

// Import Feature Employee (Để chọn người nhập)
import 'package:production_app_frontend/features/hr/employee/domain/employee_model.dart';
import 'package:production_app_frontend/features/hr/employee/presentation/bloc/employee_cubit.dart';

// [MỚI] Import Feature Unit (Để lấy đơn vị tính)
import 'package:production_app_frontend/features/inventory/unit/domain/unit_model.dart';
import 'package:production_app_frontend/features/inventory/unit/presentation/bloc/unit_cubit.dart';

class MaterialScreen extends StatefulWidget {
  const MaterialScreen({super.key});

  @override
  State<MaterialScreen> createState() => _MaterialScreenState();
}

class _MaterialScreenState extends State<MaterialScreen> {
  final _searchController = TextEditingController();
  final Color _primaryColor = const Color(0xFF003366);
  final Color _accentColor = const Color(0xFF00897B); // Màu xanh ngọc
  final Color _bgLight = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    // Load tất cả dữ liệu cần thiết
    context.read<MaterialCubit>().loadMaterials();
    context.read<EmployeeCubit>().loadEmployees();
    context.read<UnitCubit>().loadUnits(); // [MỚI] Load danh sách đơn vị
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: _bgLight,
      // Sử dụng InventoryMaterialState (đã đổi tên ở bước trước để tránh trùng)
      body: BlocBuilder<MaterialCubit, InventoryMaterialState>(
        builder: (context, state) {
          int total = 0;
          if (state is InventoryMaterialLoaded) total = state.materials.length;

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
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.category, color: Colors.teal.shade800, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.materialTitle, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                            const SizedBox(height: 2),
                            Text("Inventory > Raw Materials", style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                          ],
                        ),
                        const Spacer(),
                        if (isDesktop)
                          ElevatedButton.icon(
                            onPressed: () => _showEditDialog(context, null, l10n),
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(l10n.addMaterial.toUpperCase()),
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
                          _buildStatBadge(Icons.grid_view, "Total Materials", "$total", Colors.blue),
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
                                hintText: l10n.searchMaterial,
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.arrow_forward, color: Colors.blue),
                                  onPressed: () => context.read<MaterialCubit>().searchMaterials(_searchController.text),
                                ),
                              ),
                              onSubmitted: (value) => context.read<MaterialCubit>().searchMaterials(value),
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
                    if (state is InventoryMaterialLoading) return Center(child: CircularProgressIndicator(color: _primaryColor));
                    if (state is InventoryMaterialError) return Center(child: Text("Error: ${state.message}", style: const TextStyle(color: Colors.red)));
                    if (state is InventoryMaterialLoaded) {
                      if (state.materials.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_outlined, size: 60, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(l10n.noMaterialFound, style: TextStyle(color: Colors.grey.shade500)),
                            ],
                          ),
                        );
                      }
                      return isDesktop
                          ? _buildDesktopTable(context, state.materials, l10n)
                          : _buildMobileList(context, state.materials, l10n);
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
  Widget _buildDesktopTable(BuildContext context, List<InventoryMaterial> materials, AppLocalizations l10n) {
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
                    headingRowColor: MaterialStateProperty.all(const Color(0xFFF9FAFB)),
                    horizontalMargin: 24,
                    columnSpacing: 30,
                    dataRowMinHeight: 60,
                    dataRowMaxHeight: 60,
                    columns: [
                      DataColumn(label: Text(l10n.materialName.toUpperCase(), style: _headerStyle)),
                      DataColumn(label: Text(l10n.lotCode.toUpperCase(), style: _headerStyle)),
                      DataColumn(label: Text(l10n.importDate.toUpperCase(), style: _headerStyle)),
                      DataColumn(label: Text(l10n.quantity.toUpperCase(), style: _headerStyle)),
                      DataColumn(label: Text(l10n.unit.toUpperCase(), style: _headerStyle)),
                      DataColumn(label: Text(l10n.importedBy.toUpperCase(), style: _headerStyle)),
                      DataColumn(label: Text(l10n.actions.toUpperCase(), style: _headerStyle)),
                    ],
                    rows: materials.map((item) {
                      return DataRow(
                        cells: [
                          DataCell(Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                            child: Text(item.lotCode, style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontFamily: 'Monospace')),
                          )),
                          DataCell(Text(item.importDate)),
                          DataCell(Text("${item.quantity}", style: const TextStyle(fontWeight: FontWeight.bold))),
                          // [MỚI] Sử dụng Badge hiển thị tên Unit
                          DataCell(_UnitNameBadge(unitId: item.unitId)),
                          DataCell(_EmployeeNameBadge(employeeId: item.importedBy)),
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
  Widget _buildMobileList(BuildContext context, List<InventoryMaterial> materials, AppLocalizations l10n) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: materials.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = materials[index];
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
              backgroundColor: Colors.teal.shade50,
              child: Icon(Icons.layers, color: Colors.teal.shade800, size: 20),
            ),
            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text("${l10n.lotCode}: ${item.lotCode} • ${item.importDate}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // [MỚI] Hiển thị Badge Unit trong list mobile
                    Row(
                      children: [
                         Text("Qty: ${item.quantity} ", style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.w600)),
                         _UnitNameBadge(unitId: item.unitId),
                      ],
                    ),
                    _EmployeeNameBadge(employeeId: item.importedBy),
                  ],
                )
              ],
            ),
            trailing: PopupMenuButton(
              onSelected: (val) {
                if (val == 'edit') _showEditDialog(context, item, l10n);
                if (val == 'delete') _confirmDelete(context, item, l10n);
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit, size: 18), const SizedBox(width: 8), Text(l10n.editMaterial)])),
                PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete, size: 18, color: Colors.red), const SizedBox(width: 8), Text(l10n.deleteMaterial)])),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- DIALOG ---
  void _showEditDialog(BuildContext context, InventoryMaterial? item, AppLocalizations l10n) {
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final lotCtrl = TextEditingController(text: item?.lotCode ?? '');
    final dateCtrl = TextEditingController(text: item?.importDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final qtyCtrl = TextEditingController(text: item?.quantity.toString() ?? '0');
    
    int? selectedUnitId = item?.unitId;
    int? selectedImporterId = item?.importedBy;

    // Auto select first options if new
    final empState = context.read<EmployeeCubit>().state;
    if (item == null && empState is EmployeeLoaded && empState.employees.isNotEmpty) {
      selectedImporterId = empState.employees.first.id;
    }
    
    final unitState = context.read<UnitCubit>().state;
    if (item == null && unitState is UnitLoaded && unitState.units.isNotEmpty) {
      selectedUnitId = unitState.units.first.id;
    }

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.all(24),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        title: Text(item == null ? l10n.addMaterial : l10n.editMaterial, style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(controller: nameCtrl, decoration: _inputDeco(l10n.materialName), validator: (v) => v!.isEmpty ? "Required" : null),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: TextFormField(controller: lotCtrl, decoration: _inputDeco(l10n.lotCode), validator: (v) => v!.isEmpty ? "Required" : null)),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(
                      controller: dateCtrl, 
                      decoration: _inputDeco(l10n.importDate),
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                        if(pickedDate != null) dateCtrl.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                      },
                    )),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: TextFormField(controller: qtyCtrl, decoration: _inputDeco(l10n.quantity), keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    
                    // [MỚI] Dropdown chọn Đơn vị tính từ API
                    Expanded(child: BlocBuilder<UnitCubit, UnitState>(
                      builder: (context, state) {
                        List<ProductUnit> units = (state is UnitLoaded) ? state.units : [];
                        return DropdownButtonFormField<int>(
                          value: selectedUnitId,
                          decoration: _inputDeco(l10n.unit),
                          items: units.map((u) => DropdownMenuItem(value: u.id, child: Text(u.name))).toList(),
                          onChanged: (val) => selectedUnitId = val,
                          validator: (v) => v == null ? "Required" : null,
                        );
                      },
                    )),
                  ]),
                  const SizedBox(height: 16),
                  
                  // Dropdown Employee
                  BlocBuilder<EmployeeCubit, EmployeeState>(
                    builder: (context, state) {
                      List<Employee> emps = (state is EmployeeLoaded) ? state.employees : [];
                      return DropdownButtonFormField<int>(
                        value: selectedImporterId,
                        decoration: _inputDeco(l10n.importedBy),
                        items: emps.map((e) => DropdownMenuItem(value: e.id, child: Text(e.fullName))).toList(),
                        onChanged: (val) => selectedImporterId = val,
                        validator: (v) => v == null ? "Required" : null,
                      );
                    },
                  ),
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
              if (formKey.currentState!.validate() && selectedImporterId != null && selectedUnitId != null) {
                final newItem = InventoryMaterial(
                  id: item?.id ?? 0,
                  name: nameCtrl.text,
                  lotCode: lotCtrl.text,
                  importDate: dateCtrl.text,
                  quantity: double.tryParse(qtyCtrl.text) ?? 0,
                  unitId: selectedUnitId!,
                  importedBy: selectedImporterId!,
                );
                context.read<MaterialCubit>().saveMaterial(item: newItem, isEdit: item != null);
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

  void _confirmDelete(BuildContext context, InventoryMaterial item, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteMaterial),
        content: Text(l10n.confirmDeleteMaterial(item.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              context.read<MaterialCubit>().deleteMaterial(item.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(l10n.deleteMaterial),
          ),
        ],
      ),
    );
  }
}

// Widget Badge hiển thị tên Nhân viên
class _EmployeeNameBadge extends StatelessWidget {
  final int employeeId;
  const _EmployeeNameBadge({required this.employeeId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmployeeCubit, EmployeeState>(
      builder: (context, state) {
        String name = "---";
        if (state is EmployeeLoaded) {
          final e = state.employees.where((x) => x.id == employeeId).firstOrNull;
          if (e != null) name = e.fullName;
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(name, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
          ],
        );
      },
    );
  }
}

// [MỚI] Widget hiển thị tên Đơn vị từ ID
class _UnitNameBadge extends StatelessWidget {
  final int unitId;
  const _UnitNameBadge({required this.unitId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UnitCubit, UnitState>(
      builder: (context, state) {
        String unitName = "";
        if (state is UnitLoaded) {
          final u = state.units.where((x) => x.id == unitId).firstOrNull;
          if (u != null) unitName = u.name;
        }
        return Text(unitName, style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500));
      },
    );
  }
}