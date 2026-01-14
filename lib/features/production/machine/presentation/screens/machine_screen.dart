import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:production_app_frontend/l10n/app_localizations.dart';
import 'package:production_app_frontend/core/widgets/responsive_layout.dart';

import '../../domain/machine_model.dart';
import '../bloc/machine_cubit.dart';

// Import Supplier Feature
import 'package:production_app_frontend/features/inventory/supplier/domain/supplier_model.dart';
import 'package:production_app_frontend/features/inventory/supplier/presentation/bloc/supplier_cubit.dart';

class MachineScreen extends StatefulWidget {
  const MachineScreen({super.key});

  @override
  State<MachineScreen> createState() => _MachineScreenState();
}

class _MachineScreenState extends State<MachineScreen> {
  final _searchController = TextEditingController();
  final Color _primaryColor = const Color(0xFF003366);
  final Color _accentColor = const Color(0xFFC2185B);
  final Color _bgLight = const Color(0xFFF5F7FA);

  // Danh sách trạng thái
  final List<String> _statusOptions = ['Running', 'Stopped', 'Maintenance', 'Spinning'];

  // [MỚI] Danh sách gợi ý khu vực dùng cho Dropdown
  final List<String> _areaSuggestions = ['Khu A', 'Khu B', 'Khu C'];

  @override
  void initState() {
    super.initState();
    context.read<MachineCubit>().loadMachines();
    context.read<SupplierCubit>().loadSuppliers();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: _bgLight,
      body: BlocBuilder<MachineCubit, MachineState>(
        builder: (context, state) {
          int total = 0;
          if (state is MachineLoaded) total = state.machines.length;

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
                            color: Colors.pink.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.precision_manufacturing, color: Colors.pink.shade800, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.machineTitle, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                            const SizedBox(height: 2),
                            Text("Production > Equipment", style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                          ],
                        ),
                        const Spacer(),
                        if (isDesktop)
                          ElevatedButton.icon(
                            onPressed: () => _showEditDialog(context, null, l10n),
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(l10n.addMachine.toUpperCase()),
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
                           _buildStatBadge(Icons.grid_view, "Total Machines", "$total", Colors.blue),
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
                                hintText: l10n.searchMachine,
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.arrow_forward, color: Colors.blue),
                                  onPressed: () => context.read<MachineCubit>().searchMachines(_searchController.text),
                                ),
                              ),
                              onSubmitted: (value) => context.read<MachineCubit>().searchMachines(value),
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
                    if (state is MachineLoading) return Center(child: CircularProgressIndicator(color: _primaryColor));
                    if (state is MachineError) return Center(child: Text("Error: ${state.message}", style: const TextStyle(color: Colors.red)));
                    if (state is MachineLoaded) {
                      if (state.machines.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.precision_manufacturing_outlined, size: 60, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(l10n.noMachineFound, style: TextStyle(color: Colors.grey.shade500)),
                            ],
                          ),
                        );
                      }
                      return isDesktop
                          ? _buildDesktopTable(context, state.machines, l10n)
                          : _buildMobileList(context, state.machines, l10n);
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
  Widget _buildDesktopTable(BuildContext context, List<Machine> machines, AppLocalizations l10n) {
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
                      DataColumn(label: Text(l10n.machineName.toUpperCase(), style: _headerStyle)),
                      DataColumn(label: Text(l10n.area.toUpperCase(), style: _headerStyle)), 
                      DataColumn(label: Text(l10n.purpose.toUpperCase(), style: _headerStyle)),
                      DataColumn(label: Text(l10n.totalLines.toUpperCase(), style: _headerStyle)),
                      DataColumn(label: Text(l10n.status.toUpperCase(), style: _headerStyle)),
                      DataColumn(label: Text(l10n.actions.toUpperCase(), style: _headerStyle)),
                    ],
                    rows: machines.map((item) {
                      return DataRow(
                        cells: [
                          DataCell(Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                            child: Text(item.area ?? '-', style: TextStyle(color: Colors.blue.shade800, fontSize: 12, fontWeight: FontWeight.bold)),
                          )),
                          DataCell(Text(item.purpose, overflow: TextOverflow.ellipsis)),
                          DataCell(Text("${item.totalLines}", style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(_buildStatusBadge(item.status, l10n)),
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
  Widget _buildMobileList(BuildContext context, List<Machine> machines, AppLocalizations l10n) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: machines.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = machines[index];
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
              backgroundColor: Colors.pink.shade50,
              child: Icon(Icons.settings_input_component, color: Colors.pink.shade800, size: 20),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                if (item.area != null)
                   Text(item.area!, style: TextStyle(fontSize: 12, color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(item.purpose, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                _buildStatusBadge(item.status, l10n, isChip: true),
              ],
            ),
            trailing: PopupMenuButton(
              onSelected: (val) {
                if (val == 'edit') _showEditDialog(context, item, l10n);
                if (val == 'delete') _confirmDelete(context, item, l10n);
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit, size: 18), const SizedBox(width: 8), Text(l10n.editMachine)])),
                PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete, size: 18, color: Colors.red), const SizedBox(width: 8), Text(l10n.deleteMachine)])),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- [ĐÃ CHỈNH SỬA] DIALOG VỚI DROPDOWN KHU VỰC ---
  void _showEditDialog(BuildContext context, Machine? item, AppLocalizations l10n) {
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final purposeCtrl = TextEditingController(text: item?.purpose ?? '');
    final linesCtrl = TextEditingController(text: item?.totalLines.toString() ?? '0');
    
    // 1. Xử lý Status (Chuẩn hóa)
    String initialStatus = item?.status ?? 'Stopped';
    if (!_statusOptions.contains(initialStatus)) {
        if (initialStatus.toUpperCase() == 'RUNNING') {
          initialStatus = 'Running';
        // ignore: curly_braces_in_flow_control_structures
        } else if (initialStatus.toUpperCase() == 'STOPPED') initialStatus = 'Stopped';
        // ignore: curly_braces_in_flow_control_structures
        else if (initialStatus.toUpperCase() == 'MAINTENANCE') initialStatus = 'Maintenance';
        // ignore: curly_braces_in_flow_control_structures
        else if (initialStatus.toUpperCase() == 'SPINNING') initialStatus = 'Spinning';
        // ignore: curly_braces_in_flow_control_structures
        else initialStatus = 'Stopped'; 
    }
    String selectedStatus = initialStatus;

    // 2. Xử lý Area (Dropdown)
    String? selectedArea = item?.area;
    // Kiểm tra an toàn: Nếu area có trong DB nhưng không có trong danh sách cứng, 
    // ta reset về null để người dùng chọn lại (hoặc có thể thêm logic add tạm vào list)
    if (selectedArea != null && !_areaSuggestions.contains(selectedArea)) {
        selectedArea = null; 
    }
  
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        // [QUAN TRỌNG] Dùng StatefulBuilder để update state bên trong Dialog khi chọn Dropdown
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.all(24),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              title: Text(item == null ? l10n.addMachine : l10n.editMachine, style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
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
                              Expanded(child: TextFormField(controller: nameCtrl, decoration: _inputDeco(l10n.machineName), validator: (v) => v!.isEmpty ? "Required" : null)),
                              const SizedBox(width: 12),
                              
                              // [THAY ĐỔI] Dropdown cho Area
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: selectedArea,
                                  decoration: _inputDeco("Area (Khu vực)"),
                                  items: _areaSuggestions.map((area) => DropdownMenuItem(
                                    value: area,
                                    child: Text(area),
                                  )).toList(),
                                  onChanged: (val) {
                                    // Update state cục bộ của Dialog
                                    setStateDialog(() {
                                      selectedArea = val;
                                    });
                                  },
                                  validator: (v) => v == null ? "Required" : null, // Bắt buộc chọn
                                ),
                              ), 
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(controller: purposeCtrl, decoration: _inputDeco(l10n.purpose)),
                        const SizedBox(height: 16),
                        Row(children: [
                          Expanded(child: TextFormField(controller: linesCtrl, decoration: _inputDeco(l10n.totalLines), keyboardType: TextInputType.number)),
                          const SizedBox(width: 12),
                          Expanded(child: DropdownButtonFormField<String>(
                            value: selectedStatus,
                            decoration: _inputDeco(l10n.status),
                            items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (val) {
                                setStateDialog(() {
                                    selectedStatus = val!;
                                });
                            },
                          )),
                        ]),
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
                    if (formKey.currentState!.validate() ) {
                      final newItem = Machine(
                        id: item?.id ?? 0,
                        name: nameCtrl.text,
                        purpose: purposeCtrl.text,
                        totalLines: int.tryParse(linesCtrl.text) ?? 0,
                        status: selectedStatus,
                        area: selectedArea, // Lấy giá trị từ biến selectedArea
                      );
                      context.read<MachineCubit>().saveMachine(machine: newItem, isEdit: item != null);
                      Navigator.pop(ctx);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: Text(l10n.save),
                ),
              ],
            );
          }
        );
      },
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

  Widget _buildStatusBadge(String status, AppLocalizations l10n, {bool isChip = true}) {
    Color color;
    String label;

    final normalizedStatus = status.toUpperCase();

    if (normalizedStatus == 'RUNNING') {
        color = Colors.blue;
        label = l10n.running;
    } else if (normalizedStatus == 'STOPPED') {
        color = Colors.red;
        label = l10n.stopped;
    } else if (normalizedStatus == 'MAINTENANCE') {
        color = Colors.orange;
        label = l10n.maintenance;
    } else if (normalizedStatus == 'SPINNING') {
        color = Colors.green;
        label = "Spinning";
    } else {
        color = Colors.grey;
        label = status;
    }

    if (!isChip) {
      return Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  void _confirmDelete(BuildContext context, Machine item, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteMachine),
        content: Text(l10n.confirmDeleteMachine(item.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              context.read<MachineCubit>().deleteMachine(item.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(l10n.deleteMachine),
          ),
        ],
      ),
    );
  }
}