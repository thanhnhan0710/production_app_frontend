import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:production_app_frontend/features/inventory/basket/doamain/baket_model.dart';
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

class MachineOperationScreen extends StatefulWidget {
  const MachineOperationScreen({super.key});

  @override
  State<MachineOperationScreen> createState() => _MachineOperationScreenState();
}

class _MachineOperationScreenState extends State<MachineOperationScreen> {
  final Color _primaryColor = const Color(0xFF003366);

  @override
  void initState() {
    super.initState();
    context.read<MachineOperationCubit>().loadDashboard();
    context.read<ProductCubit>().loadProducts();
    context.read<StandardCubit>().loadStandards();
    context.read<YarnLotCubit>().loadYarnLots();
    context.read<EmployeeCubit>().loadEmployees();
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
      body: BlocConsumer<MachineOperationCubit, MachineOpState>(
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
            if (state.machines.isEmpty) {
              return const Center(child: Text("No machines configured"));
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400,
                childAspectRatio: 1.1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: state.machines.length,
              itemBuilder: (context, index) {
                final machine = state.machines[index];
                return _buildMachineCard(context, machine, state, l10n);
              },
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildMachineCard(BuildContext context, Machine machine, MachineOpLoaded state, AppLocalizations l10n) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _primaryColor,
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
                  child: Text(machine.status, style: const TextStyle(color: Colors.white, fontSize: 10)),
                )
              ],
            ),
          ),

          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildLineSlot(context, machine, "1", state.activeTickets["${machine.id}_1"], state.readyBaskets, l10n),
                ),
                Container(width: 1, color: Colors.grey.shade300),
                Expanded(
                  child: _buildLineSlot(context, machine, "2", state.activeTickets["${machine.id}_2"], state.readyBaskets, l10n),
                ),
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
              const SizedBox(height: 12),
              Text(
                ticket.basketCode ?? "Unknown",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                "#${ticket.code}",
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
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
    List<Employee> employees = (employeeState is EmployeeLoaded) ? employeeState.employees : [];

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
                          helperText: "Quét mã rổ tại đây để tự chọn",
                        ),
                        // Khi máy quét nhập xong và nhấn Enter
                        onFieldSubmitted: (value) => onScanBarcode(value),
                      ),
                      const Divider(height: 30),

                      // 1. CHỌN RỔ (Basket) - Sẽ tự điền nếu quét đúng
                      DropdownButtonFormField<Basket>(
                        value: selectedBasket,
                        decoration: const InputDecoration(labelText: "Basket (Rổ)", border: OutlineInputBorder()),
                        items: readyBaskets.map((b) => DropdownMenuItem(
                          value: b,
                          child: Text("${b.code} (${b.tareWeight}kg)"),
                        )).toList(),
                        onChanged: (val) => setStateDialog(() => selectedBasket = val),
                        validator: (v) => v == null ? "Required" : null,
                      ),
                      const SizedBox(height: 16),
                      
                      // 2. CHỌN NGƯỜI ĐỨNG MÁY
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(labelText: "Operator (Người đứng máy)", border: OutlineInputBorder()),
                        items: employees.map((e) => DropdownMenuItem(
                          value: e.id,
                          child: Text("${e.id} - ${e.fullName}"),
                        )).toList(),
                        onChanged: (val) => selectedEmployeeId = val,
                        validator: (v) => v == null ? "Required" : null,
                      ),
                      const SizedBox(height: 16),
                      
                      // 3. CHỌN SẢN PHẨM
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(labelText: "Product (Sản phẩm)", border: OutlineInputBorder()),
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
                          labelText: "Standard (Tiêu chuẩn)", 
                          border: const OutlineInputBorder(),
                          enabled: selectedProductId != null, 
                          helperText: selectedProductId == null ? "Chọn sản phẩm trước" : null
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
                        decoration: const InputDecoration(labelText: "Yarn Lot (Lô sợi)", border: OutlineInputBorder()),
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
}