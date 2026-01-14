import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:production_app_frontend/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:production_app_frontend/features/hr/work_schedule/presentation/bloc/work_schedule_cubit.dart';
import 'package:production_app_frontend/features/inventory/basket/doamain/basket_model.dart';
import 'package:production_app_frontend/features/production/weaving/presentation/bloc/weaving_cubit.dart';
import 'package:production_app_frontend/features/production/weaving/presentation/screens/weaving_inspection_dialog.dart';
import 'package:production_app_frontend/l10n/app_localizations.dart';
import '../../../weaving/domain/weaving_model.dart';
import '../../domain/machine_model.dart';
import '../bloc/machine_operation_cubit.dart';

// Import các feature liên quan
import 'package:production_app_frontend/features/inventory/product/domain/product_model.dart';
import 'package:production_app_frontend/features/inventory/product/presentation/bloc/product_cubit.dart';
import 'package:production_app_frontend/features/production/standard/domain/standard_model.dart';
import 'package:production_app_frontend/features/production/standard/presentation/bloc/standard_cubit.dart';
import 'package:production_app_frontend/features/inventory/yarn_lot/domain/yarn_lot_model.dart';
import 'package:production_app_frontend/features/inventory/yarn_lot/presentation/bloc/yarn_lot_cubit.dart';
import 'package:production_app_frontend/features/hr/employee/domain/employee_model.dart';
import 'package:production_app_frontend/features/hr/employee/presentation/bloc/employee_cubit.dart';
import 'package:production_app_frontend/features/hr/shift/presentation/bloc/shift_cubit.dart';

class MachineOperationScreen extends StatefulWidget {
  const MachineOperationScreen({super.key});

  @override
  State<MachineOperationScreen> createState() => _MachineOperationScreenState();
}

class _MachineOperationScreenState extends State<MachineOperationScreen> {
  final Color _primaryColor = const Color(0xFF003366);
  final TextEditingController _machineSearchCtrl = TextEditingController();
  String _searchKeyword = "";

  @override
  void initState() {
    super.initState();
    context.read<MachineOperationCubit>().loadDashboard();
    context.read<ProductCubit>().loadProducts();
    context.read<StandardCubit>().loadStandards();
    context.read<YarnLotCubit>().loadYarnLots();
    context.read<EmployeeCubit>().loadEmployees();
    context.read<ShiftCubit>().loadShifts();
    context.read<WorkScheduleCubit>().loadSchedules();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: const Color(0xFFE0E0E0),
      appBar: AppBar(
        title: Text(l10n.machineOperation, style: const TextStyle(color: Colors.white)),
        backgroundColor: _primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<MachineOperationCubit>().loadDashboard(),
          )
        ],
      ),
      body: Column(
        children: [
          // [THANH TÌM KIẾM MÁY]
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: TextField(
              controller: _machineSearchCtrl,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: l10n.searchMachine,
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                isDense: true,
              ),
              onChanged: (val) {
                setState(() {
                  _searchKeyword = val.toLowerCase();
                });
              },
            ),
          ),

          // [DANH SÁCH MÁY THEO KHU VỰC]
          Expanded(
            child: BlocConsumer<MachineOperationCubit, MachineOpState>(
              listener: (context, state) {
                if (state is MachineOpError) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
                }
              },
              builder: (context, state) {
                if (state is MachineOpLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (state is MachineOpLoaded) {
                  // 1. Lọc máy theo từ khóa tìm kiếm
                  final filteredMachines = state.machines.where((m) => 
                    m.name.toLowerCase().contains(_searchKeyword) || 
                    m.status.toLowerCase().contains(_searchKeyword)
                  ).toList();

                  if (filteredMachines.isEmpty) {
                    return Center(child: Text(l10n.noMachineFound));
                  }

                  // 2. Nhóm máy theo Khu vực (Area)
                  final Map<String, List<Machine>> groupedMachines = {};
                  for (var machine in filteredMachines) {
                    // Nếu machine.area null thì gán là "Chưa phân khu" (hoặc lấy từ l10n)
                    final areaName = (machine.area != null && machine.area!.isNotEmpty) 
                        ? machine.area! 
                        : "Unassigned Area"; // Hoặc l10n.unassignedArea

                    if (!groupedMachines.containsKey(areaName)) {
                      groupedMachines[areaName] = [];
                    }
                    groupedMachines[areaName]!.add(machine);
                  }

                  // Sắp xếp tên khu vực (A -> Z)
                  final sortedAreas = groupedMachines.keys.toList()..sort();

                  // 3. Hiển thị List các Khu vực
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: sortedAreas.length,
                    itemBuilder: (context, index) {
                      final area = sortedAreas[index];
                      final machinesInArea = groupedMachines[area]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- HEADER KHU VỰC ---
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              border: Border(bottom: BorderSide(color: Colors.grey.shade400)),
                            ),
                            child: Text(
                              area.toUpperCase(), // VD: KHU A
                              style: TextStyle(
                                color: _primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 1.0
                              ),
                            ),
                          ),
                          
                          // --- GRID MÁY TRONG KHU VỰC ---
                          GridView.builder(
                            padding: const EdgeInsets.all(8),
                            shrinkWrap: true, // Quan trọng: để Grid nằm gọn trong List
                            physics: const NeverScrollableScrollPhysics(), // Vô hiệu hóa scroll riêng của Grid
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              // [KÍCH THƯỚC CARD NHỎ]
                              maxCrossAxisExtent: 160, 
                              mainAxisExtent: 125,     
                              childAspectRatio: 1.1,
                              crossAxisSpacing: 8,     
                              mainAxisSpacing: 8,
                            ),
                            itemCount: machinesInArea.length,
                            itemBuilder: (context, index) {
                              final machine = machinesInArea[index];
                              return _buildMachineCard(context, machine, state, l10n);
                            },
                          ),
                        ],
                      );
                    },
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMachineCard(BuildContext context, Machine machine, MachineOpLoaded state, AppLocalizations l10n) {
    final statusColor = _getMachineStatusColor(machine.status);
    return Card(
      elevation: 2,
      color: _getMachineBgColor(machine.status),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: statusColor, width: 1),
      ),
      child: Column(
        children: [
          // Header (Tên máy + Trạng thái)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.precision_manufacturing, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          machine.name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    machine.status.substring(0, machine.status.length > 3 ? 3 : machine.status.length).toUpperCase(),
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 9),
                  ),
                )
              ],
            ),
          ),

          // Lines (2 slot bên dưới)
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildLineSlot(context, machine, "1", state.activeTickets["${machine.id}_1"], state.readyBaskets, l10n)),
                Container(width: 1, color: Colors.grey.shade300),
                Expanded(child: _buildLineSlot(context, machine, "2", state.activeTickets["${machine.id}_2"], state.readyBaskets, l10n)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineSlot(BuildContext context, Machine machine, String lineCode, WeavingTicket? ticket, List<Basket> readyBaskets, AppLocalizations l10n) {
    final bool isActive = ticket != null;

    return InkWell(
      onTap: () {
        if (!isActive) {
          _showAssignDialog(context, machine, lineCode, readyBaskets, l10n);
        } else {
          context.read<WeavingCubit>().loadInspections(ticket.id);
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => WeavingInspectionDialog(
              ticket: ticket,
              onRelease: () {
                Navigator.pop(ctx);
                _showReleaseDialog(context, ticket, l10n);
              },
            ),
          );
        }
      },
      child: Container(
        color: isActive ? Colors.green.shade50 : Colors.transparent,
        padding: const EdgeInsets.all(2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Line$lineCode", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 10)),
            const SizedBox(height: 4),
            
            if (isActive) ...[
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green, width: 1.5),
                ),
                child: const Icon(Icons.settings_backup_restore, color: Colors.green, size: 16),
              ),
              const SizedBox(height: 2),
              Text(
                ticket.basketCode ?? "",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Text("#${ticket.code.substring(ticket.code.length > 4 ? ticket.code.length - 4 : 0)}", 
                style: const TextStyle(fontSize: 8, color: Colors.grey)
              ),
            ] else ...[
              const Icon(Icons.add_circle_outline, color: Colors.grey, size: 20),
              const SizedBox(height: 2),
            ]
          ],
        ),
      ),
    );
  }

   void _showReleaseDialog(BuildContext context, WeavingTicket ticket, AppLocalizations l10n) {
    final grossCtrl = TextEditingController();
    final lengthCtrl = TextEditingController();
    final knotCtrl = TextEditingController();
    int? employeeOutId;
    final formKey = GlobalKey<FormState>();

    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated && authState.user.employeeId != null) {
      employeeOutId = authState.user.employeeId; 
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.finishTicket),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("${l10n.ticketCode}: ${ticket.code}", style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: TextFormField(
                    controller: grossCtrl, 
                    decoration: InputDecoration(labelText: l10n.grossWeight, border: const OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? l10n.required : null,
                  )),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: knotCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.knots,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (v) =>
                          v == null || v.isEmpty ? l10n.required : null,
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                TextFormField(
                    controller: lengthCtrl, 
                    decoration: InputDecoration(labelText: l10n.length, border: const OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? l10n.required : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              if (formKey.currentState!.validate() && employeeOutId != null) {
                Navigator.pop(ctx);
                context.read<MachineOperationCubit>().finishTicket(
                  ticket: ticket,
                  employeeOutId: employeeOutId,
                  grossWeight: double.parse(grossCtrl.text),
                  length: double.parse(lengthCtrl.text),
                  numberOfKnots: int.parse(knotCtrl.text),
                );
              }
            },
            child: Text(l10n.releaseBasket),
          )
        ],
      ),
    );
  }

  // --- DIALOG GÁN RỔ (TÍCH HỢP QUÉT MÃ VẠCH) ---
  void _showAssignDialog(BuildContext context, Machine machine, String line, List<Basket> readyBaskets, AppLocalizations l10n) {
    Basket? selectedBasket;
    int? selectedProductId;
    int? selectedStandardId;
    int? selectedYarnLotId;
    int? selectedEmployeeId;
    
    final formKey = GlobalKey<FormState>();
    final barcodeCtrl = TextEditingController(); 

    final productState = context.read<ProductCubit>().state;
    final standardState = context.read<StandardCubit>().state;
    final yarnLotState = context.read<YarnLotCubit>().state;
    
    // ignore: unused_local_variable
    final employeeState = context.read<EmployeeCubit>().state;

    List<Product> products = (productState is ProductLoaded) ? productState.products : [];
    List<Standard> allStandards = (standardState is StandardLoaded) ? standardState.standards : [];
    List<YarnLot> yarnLots = (yarnLotState is YarnLotLoaded) ? yarnLotState.yarnLots : [];
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated && authState.user.employeeId != null) {
      selectedEmployeeId = authState.user.employeeId; 
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          
          List<Standard> filteredStandards = [];
          if (selectedProductId != null) {
            filteredStandards = allStandards.where((s) => s.productId == selectedProductId).toList();
          }

          // Hàm xử lý khi quét mã xong
          void onScanBarcode(String code) {
            if (code.isEmpty) return;
            // Tìm rổ có mã khớp trong danh sách READY
            final foundBasket = readyBaskets.where((b) => b.code.toLowerCase() == code.toLowerCase()).firstOrNull;
            
            if (foundBasket != null) {
              setStateDialog(() {
                selectedBasket = foundBasket; // Tự động chọn vào Dropdown
                barcodeCtrl.clear(); 
              });
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Basket Found: ${foundBasket.code}"), backgroundColor: Colors.green));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Basket not found or NOT READY"), backgroundColor: Colors.red));
            }
          }

          return AlertDialog(
            title: Text("${l10n.assignBasket} - ${machine.name} Line $line"),
            content: Form(
              key: formKey,
              child: SizedBox(
                width: 500, 
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- Ô QUÉT MÃ VẠCH ---
                      TextFormField(
                        controller: barcodeCtrl,
                        autofocus: true, 
                        decoration: InputDecoration(
                          labelText: l10n.scanBarcode,
                          prefixIcon: const Icon(Icons.qr_code_scanner, color: Colors.blue),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green),
                            onPressed: () => onScanBarcode(barcodeCtrl.text),
                          ),
                          helperText: l10n.scanBarcodeSubline
                        ),
                        // Khi máy quét nhập xong và nhấn Enter
                        onFieldSubmitted: (value) => onScanBarcode(value),
                      ),
                      const Divider(height: 30),

                      // 1. CHỌN RỔ (Basket)
                      DropdownButtonFormField<Basket>(
                        value: selectedBasket,
                        decoration: InputDecoration(labelText: l10n.basketTitleVS2, border: const OutlineInputBorder()),
                        items: readyBaskets.map((b) => DropdownMenuItem(
                          value: b,
                          child: Text("${b.code} (${b.tareWeight}kg)"),
                        )).toList(),
                        onChanged: (val) => setStateDialog(() => selectedBasket = val),
                        validator: (v) => v == null ? "Required" : null,
                      ),
                      const SizedBox(height: 16),
                      
                      // 3. CHỌN SẢN PHẨM
                      DropdownButtonFormField<int>(
                        decoration: InputDecoration(labelText: l10n.productTitle, border: const OutlineInputBorder()),
                        items: products.map((p) => DropdownMenuItem(
                          value: p.id, 
                          child: Text(p.itemCode)
                        )).toList(),
                        onChanged: (val) {
                          setStateDialog(() {
                            selectedProductId = val;
                            selectedStandardId = null;
                          });
                        },
                        validator: (v) => v == null ? "Required" : null,
                      ),
                      const SizedBox(height: 16),

                      // 4. CHỌN TIÊU CHUẨN
                      DropdownButtonFormField<int>(
                        value: selectedStandardId,
                        decoration: InputDecoration(
                          labelText: l10n.standardTitle, 
                          border: const OutlineInputBorder(),
                          enabled: selectedProductId != null, 
                          helperText: selectedProductId == null ? l10n.selectProductBefore: null
                        ),
                        items: filteredStandards.map((s) => DropdownMenuItem(
                          value: s.id, 
                          child: Text("W:${s.widthMm} x T:${s.thicknessMm} (${s.colorName ?? 'N/A'})")
                        )).toList(),
                        onChanged: (val) => selectedStandardId = val,
                        validator: (v) => v == null ? "Required" : null,
                      ),
                      const SizedBox(height: 16),

                      // 5. CHỌN LÔ SỢI
                      DropdownButtonFormField<int>(
                        decoration: InputDecoration(labelText: l10n.yarnLotTitle, border: const OutlineInputBorder()),
                        items: yarnLots.map((y) => DropdownMenuItem(
                          value: y.id, 
                          child: Text("${y.lotCode} (${y.totalKg}kg)")
                        )).toList(),
                        onChanged: (val) => selectedYarnLotId = val,
                        validator: (v) => v == null ? "Required" : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                      Navigator.pop(ctx);
                      context.read<MachineOperationCubit>().assignBasketToMachine(
                        machineId: machine.id, 
                        line: line, 
                        basket: selectedBasket!,
                        productId: selectedProductId!,
                        standardId: selectedStandardId!,
                        yarnLotId: selectedYarnLotId!,
                        employeeId: selectedEmployeeId!,
                      );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
                child: Text(l10n.save),
              ),
            ],
          );
        }
      ),
    );
  }

  Color _getMachineStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'RUNNING':
        return Colors.blue;
      case 'MAINTENANCE':
        return Colors.grey;
      case 'STOPPED':
        return Colors.red;
      case 'SPINNING':
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }
  Color _getMachineBgColor(String status) {
    switch (status.toUpperCase()) {
      case 'RUNNING':
        return Colors.green.shade50;
      case 'MAINTENANCE':
        return Colors.grey.shade200;
      case 'STOPPED':
        return Colors.red.shade100;
      case 'SPINNING':
        return Colors.green.shade50;
      default:
        return Colors.white;
    }
  }
}