import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:production_app_frontend/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:production_app_frontend/features/hr/work_schedule/presentation/bloc/work_schedule_cubit.dart';
import 'package:production_app_frontend/features/inventory/basket/doamain/baket_model.dart';
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
          // [YÊU CẦU 1] Thanh tìm kiếm máy
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _machineSearchCtrl,
              decoration: InputDecoration(
                hintText: l10n.searchMachine, // "Tìm tên máy..."
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: (val) {
                setState(() {
                  _searchKeyword = val.toLowerCase();
                });
              },
            ),
          ),

          // Grid Máy
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
                  // Lọc máy theo từ khóa
                  final filteredMachines = state.machines.where((m) => 
                    m.name.toLowerCase().contains(_searchKeyword) || 
                    m.status.toLowerCase().contains(_searchKeyword)
                  ).toList();

                  if (filteredMachines.isEmpty) {
                    return Center(child: Text(l10n.noMachineFound));
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 400,
                      mainAxisExtent: 300, // Tăng chiều cao thẻ một chút
                      childAspectRatio: 1.1,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: filteredMachines.length,
                    itemBuilder: (context, index) {
                      final machine = filteredMachines[index];
                      return _buildMachineCard(context, machine, state, l10n);
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
      elevation: 4,
      color: _getMachineBgColor(machine.status),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor, width: 1.5),
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.precision_manufacturing, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      machine.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    machine.status,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                )
              ],
            ),
          ),

          // Lines
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
          // Mở dialog kiểm tra/tháo rổ
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => WeavingInspectionDialog(
              ticket: ticket,
              // [YÊU CẦU 1 - Tháo rổ] Callback để mở dialog tháo rổ từ Inspection Dialog
              onRelease: () {
                Navigator.pop(ctx); // Đóng Inspection Dialog
                _showReleaseDialog(context, ticket, l10n); // Mở Release Dialog
              },
            ),
          );
        }
      },
      child: Container(
        color: isActive ? Colors.green.shade50 : Colors.transparent,
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("${l10n.line} $lineCode", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            if (isActive) ...[
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.green, width: 2),
                      boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.2), blurRadius: 8)]
                    ),
                    child: const Icon(Icons.settings_backup_restore, color: Colors.green, size: 28),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                ticket.basketCode ?? "Unknown",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text("#${ticket.code}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ] else ...[
              const Icon(Icons.add_circle_outline, color: Colors.grey, size: 40),
              const SizedBox(height: 8),
              Text(l10n.noActiveBasket, style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
      // Tự động gán ID nhân viên
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
                  numberOfKnots: int.parse(grossCtrl.text),
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
    final barcodeCtrl = TextEditingController(); // Controller cho ô quét mã

    final productState = context.read<ProductCubit>().state;
    final standardState = context.read<StandardCubit>().state;
    final yarnLotState = context.read<YarnLotCubit>().state;
    final employeeState = context.read<EmployeeCubit>().state;

    List<Product> products = (productState is ProductLoaded) ? productState.products : [];
    List<Standard> allStandards = (standardState is StandardLoaded) ? standardState.standards : [];
    List<YarnLot> yarnLots = (yarnLotState is YarnLotLoaded) ? yarnLotState.yarnLots : [];
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated && authState.user.employeeId != null) {
      // Tự động gán ID nhân viên
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
                barcodeCtrl.clear(); // Xóa ô quét để quét tiếp nếu cần
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
                        autofocus: true, // Tự động focus để quét ngay
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

                      // 1. CHỌN RỔ (Basket) - Sẽ tự điền nếu quét đúng
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
      default:
        return Colors.white;
    }
  }
}