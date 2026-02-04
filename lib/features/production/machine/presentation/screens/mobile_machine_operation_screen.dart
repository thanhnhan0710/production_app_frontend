import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:mobile_scanner/mobile_scanner.dart'; 
import 'package:intl/intl.dart';

// --- IMPORTS GIỮ NGUYÊN TỪ CODE CŨ CỦA BẠN ---
import 'package:production_app_frontend/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:production_app_frontend/features/hr/work_schedule/presentation/bloc/work_schedule_cubit.dart';
import 'package:production_app_frontend/features/inventory/basket/doamain/basket_model.dart';
import 'package:production_app_frontend/features/inventory/basket/presentation/bloc/baket_cubit.dart';
import 'package:production_app_frontend/features/inventory/bom/presentation/bloc/bom_cubit.dart';
import 'package:production_app_frontend/features/production/machine/presentation/screens/weaving_ticket_detail_screen.dart'; 

import 'package:production_app_frontend/features/production/weaving/presentation/bloc/weaving_cubit.dart';
import 'package:production_app_frontend/features/production/weaving/presentation/screens/weaving_inspection_dialog.dart';
import 'package:production_app_frontend/l10n/app_localizations.dart';
import '../../../weaving/domain/weaving_model.dart';
import '../../domain/machine_model.dart';
import '../bloc/machine_operation_cubit.dart';

import 'package:production_app_frontend/features/inventory/product/domain/product_model.dart';
import 'package:production_app_frontend/features/inventory/product/presentation/bloc/product_cubit.dart';
import 'package:production_app_frontend/features/production/standard/domain/standard_model.dart';
import 'package:production_app_frontend/features/production/standard/presentation/bloc/standard_cubit.dart';

import 'package:production_app_frontend/features/inventory/batch/presentation/bloc/batch_cubit.dart';
import 'package:production_app_frontend/features/inventory/batch/domain/batch_model.dart';

import 'package:production_app_frontend/features/hr/employee/domain/employee_model.dart';
import 'package:production_app_frontend/features/hr/employee/presentation/bloc/employee_cubit.dart';
import 'package:production_app_frontend/features/hr/shift/presentation/bloc/shift_cubit.dart';
import 'package:production_app_frontend/features/production/machine/presentation/screens/machine_history_dialog.dart';

import 'package:production_app_frontend/features/production/weaving_record/presentation/bloc/weaving_record_cubit.dart';
import 'package:production_app_frontend/features/production/weaving_record/domain/weaving_record_model.dart';

class MobileMachineOperationScreen extends StatefulWidget {
  const MobileMachineOperationScreen({super.key});

  @override
  State<MobileMachineOperationScreen> createState() => _MobileMachineOperationScreenState();
}

class _MobileMachineOperationScreenState extends State<MobileMachineOperationScreen> {
  // Logic giữ nguyên
  final TextEditingController _machineSearchCtrl = TextEditingController();
  String _searchKeyword = "";

  @override
  void initState() {
    super.initState();
    // Load data giữ nguyên
    context.read<MachineOperationCubit>().loadDashboard();
    context.read<ProductCubit>().loadProducts();
    context.read<StandardCubit>().loadStandards();
    context.read<BatchCubit>().loadBatches();
    context.read<EmployeeCubit>().loadEmployees();
    context.read<ShiftCubit>().loadShifts();
    context.read<WorkScheduleCubit>().loadSchedules();
    context.read<BasketCubit>().loadBaskets();
    context.read<BOMCubit>().loadBOMHeaders(); 
  }

  String _calculateCurrentShift() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 14) {
      return "Ca A";
    // ignore: curly_braces_in_flow_control_structures
    } else if (hour >= 14 && hour < 22) return "Ca B";
    // ignore: curly_braces_in_flow_control_structures
    else return "Ca C";
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade100, // Nền xám nhẹ dịu mắt
      appBar: AppBar(
        title: const Text("VẬN HÀNH MÁY", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.blueGrey.shade900,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 28),
            onPressed: () => context.read<MachineOperationCubit>().loadDashboard(),
          )
        ],
      ),
      body: Column(
        children: [
          // THANH TÌM KIẾM TO HƠN
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _machineSearchCtrl,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: "Nhập tên máy để tìm...",
                prefixIcon: const Icon(Icons.search, size: 28),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
              onChanged: (val) => setState(() => _searchKeyword = val.toLowerCase()),
            ),
          ),

          Expanded(
            child: BlocConsumer<MachineOperationCubit, MachineOpState>(
              listener: (context, state) {
                if (state is MachineOpError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message), backgroundColor: Colors.red)
                  );
                }
              },
              builder: (context, state) {
                if (state is MachineOpLoading) return const Center(child: CircularProgressIndicator());
                
                if (state is MachineOpLoaded) {
                  final filteredMachines = state.machines.where((m) => 
                    m.name.toLowerCase().contains(_searchKeyword) || 
                    m.status.toLowerCase().contains(_searchKeyword)
                  ).toList();

                  if (filteredMachines.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(l10n.noMachineFound, style: const TextStyle(fontSize: 18, color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  // UI MỚI: LIST VIEW THẺ LỚN
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                    itemCount: filteredMachines.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final machine = filteredMachines[index];
                      return _buildMobileMachineCard(context, machine, state, l10n);
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

  // --- WIDGET CARD MÁY (THIẾT KẾ CHO MOBILE/TABLET) ---
  Widget _buildMobileMachineCard(BuildContext context, Machine machine, MachineOpLoaded state, AppLocalizations l10n) {
    final statusColor = _getMachineStatusColor(machine.status);
    final isRunning = machine.status == 'RUNNING';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // 1. HEADER TRẠNG THÁI (MÀU THEO STATUS)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.precision_manufacturing, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      machine.name.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                // Nút đổi trạng thái nhanh
                ElevatedButton.icon(
                  onPressed: () => _showStatusDialog(context, machine, isRunning ? 'STOPPED' : 'RUNNING', l10n),
                  icon: Icon(isRunning ? Icons.stop : Icons.play_arrow, color: statusColor),
                  label: Text(isRunning ? "BÁO DỪNG" : "CHẠY MÁY", style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                )
              ],
            ),
          ),

          // 2. LINE INFO (TRỤC 1 & TRỤC 2)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildBigLineSlot(context, machine, "1", state.activeTickets["${machine.id}_1"], state.readyBaskets, l10n)),
                const SizedBox(width: 12), // Khoảng cách giữa 2 line
                Expanded(child: _buildBigLineSlot(context, machine, "2", state.activeTickets["${machine.id}_2"], state.readyBaskets, l10n)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- SLOT TRỤC (GIAO DIỆN LỚN) ---
  Widget _buildBigLineSlot(BuildContext context, Machine machine, String lineCode, WeavingTicket? ticket, List<Basket> readyBaskets, AppLocalizations l10n) {
    bool hasTicket = ticket != null;
    bool isPendingBasket = hasTicket && (ticket.basketId == null || ticket.basketId == 0);
    
    return InkWell(
      onTap: () {
        if (!hasTicket) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chưa có lệnh sản xuất!"), backgroundColor: Colors.orange));
        } else if (isPendingBasket) {
          _showAssignBasketDialog(context, ticket, l10n);
        } else {
          // [QUAN TRỌNG] Mở menu hành động lớn
          _showOperatorActionSheet(context, machine, lineCode, ticket, l10n);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hasTicket ? (isPendingBasket ? Colors.orange.shade50 : Colors.blue.shade50) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasTicket ? (isPendingBasket ? Colors.orange : Colors.blue.shade200) : Colors.grey.shade300, 
            width: 1.5
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Line Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("LINE $lineCode", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                if (hasTicket) 
                  const Icon(Icons.touch_app, size: 16, color: Colors.blue)
              ],
            ),
            const Divider(),
            
            if (hasTicket) ...[
              Text(
                ticket.productItemCode??"---", 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (isPendingBasket)
                const Text("CHƯA CÓ RỔ", style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold))
              else 
                Row(
                  children: [
                    const Icon(Icons.shopping_basket, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(ticket.basketCode ?? "", style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                
              const SizedBox(height: 4),
              // Hiển thị Lô sợi tóm tắt
              _TicketBatchList(yarns: ticket.yarns), 
            ] else ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text("TRỐNG", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  // --- MENU HÀNH ĐỘNG CHO CÔNG NHÂN (BOTTOM SHEET) ---
  void _showOperatorActionSheet(BuildContext context, Machine machine, String lineCode, WeavingTicket ticket, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Thao tác: ${machine.name} - Line $lineCode", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(ticket.productItemCode??"---", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: _buildBigActionButton(
                    icon: Icons.monitor_weight,
                    label: "CÂN RỔ\nCUỐI CA",
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.pop(ctx);
                      _showWeighingDialog(context, machine, lineCode, ticket);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildBigActionButton(
                    icon: Icons.fact_check,
                    label: "KIỂM TRA\nCHẤT LƯỢNG",
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(ctx);
                      final autoShift = _calculateCurrentShift();
                      context.read<WeavingCubit>().loadInspections(ticket.id);
                      showDialog(
                        context: context,
                        builder: (_) => WeavingInspectionDialog(
                          ticket: ticket,
                          shiftName: autoShift,
                          onRelease: () {
                            Navigator.pop(context); // Close inspect
                            _showReleaseDialog(context, ticket, l10n);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildBigActionButton(
                    icon: Icons.stop_circle,
                    label: "RA RỔ\n(KẾT THÚC)",
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(ctx);
                      _showReleaseDialog(context, ticket, l10n);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildBigActionButton(
                    icon: Icons.info,
                    label: "XEM\nCHI TIẾT",
                    color: Colors.grey,
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => WeavingTicketDetailScreen(ticket: ticket)));
                    },
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBigActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // --- LOGIC GIỮ NGUYÊN (COPY TỪ FILE CŨ) ---
  // (Phần này chứa các hàm logic dialog, save data... y hệt như bạn yêu cầu)

  void _showAssignBasketDialog(BuildContext context, WeavingTicket ticket, AppLocalizations l10n) async {
    // ... (Logic giống hệt file cũ)
    // Để tiết kiệm không gian hiển thị ở đây, bạn hãy copy nội dung hàm _showAssignBasketDialog từ file cũ vào đây
    // Chỉ thay đổi nhỏ về giao diện nếu cần
    final standardState = context.read<StandardCubit>().state;
    final basketState = context.read<BasketCubit>().state;
    final authState = context.read<AuthCubit>().state;
    final int currentEmployeeId = (authState is AuthAuthenticated) ? (authState.user.employeeId ?? 0) : 0;
    
    List<Standard> availableStandards = [];
    if (standardState is StandardLoaded && ticket.productId != 0) {
      availableStandards = standardState.standards.where((s) => s.productId == ticket.productId).toList();
    }

    List<Basket> readyBaskets = [];
    if (basketState is BasketLoaded) {
      readyBaskets = basketState.baskets.where((b) => b.status == "READY").toList();
    }

    Standard? selectedStandard;
    Basket? selectedBasket;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Gán Rổ & Tiêu chuẩn"),
              content: Form(
                key: formKey,
                child: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Text("Sản phẩm: ${ticket.productItemCode}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<Standard>(
                        decoration: const InputDecoration(labelText: "Tiêu chuẩn *", border: OutlineInputBorder()),
                        items: availableStandards.map((s) => DropdownMenuItem(value: s, child: Text("W:${s.widthMm} | T:${s.thicknessMm}"))).toList(),
                        onChanged: (val) => setStateDialog(() => selectedStandard = val),
                        validator: (v) => v == null ? "Vui lòng chọn tiêu chuẩn" : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownSearch<Basket>(
                              items: (filter, props) => readyBaskets,
                              itemAsString: (b) => "${b.code} (${b.tareWeight}kg)",
                              compareFn: (i, s) => i.id == s.id,
                              selectedItem: selectedBasket,
                              onChanged: (val) => setStateDialog(() => selectedBasket = val),
                              validator: (v) => v == null ? "Vui lòng chọn rổ" : null,
                              decoratorProps: const DropDownDecoratorProps(decoration: InputDecoration(labelText: "Rổ chứa *", border: OutlineInputBorder())),
                              popupProps: const PopupProps.menu(showSearchBox: true),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.qr_code_scanner),
                            onPressed: () async {
                              final code = await Navigator.push(context, MaterialPageRoute(builder: (_) => const SimpleBarcodeScanner()));
                              if (code != null) {
                                final found = readyBaskets.where((b) => b.code == code).firstOrNull;
                                if (found != null) setStateDialog(() => selectedBasket = found);
                              }
                            },
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(ctx);
                      context.read<MachineOperationCubit>().updateTicketInfo(
                        ticketId: ticket.id,
                        basketId: selectedBasket!.id,
                        standardId: selectedStandard!.id,
                        employeeInId: currentEmployeeId,
                      );
                    }
                  },
                  child: const Text("XÁC NHẬN"),
                )
              ],
            );
          }
        );
      },
    );
  }

  void _showWeighingDialog(BuildContext context, Machine machine, String lineCode, WeavingTicket ticket) {
    // Copy nguyên hàm _showWeighingDialog từ file cũ
    final formKey = GlobalKey<FormState>();
    final grossWeightCtrl = TextEditingController();
    final runWasteCtrl = TextEditingController(text: "0");
    final setupWasteCtrl = TextEditingController(text: "0");

    double basketTare = 0.0;
    final basketState = context.read<BasketCubit>().state;
    if (basketState is BasketLoaded && ticket.basketId != null) {
       try {
         final foundBasket = basketState.baskets.firstWhere((b) => b.id == ticket.basketId);
         basketTare = foundBasket.tareWeight;
       } catch (_) {}
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          double gross = double.tryParse(grossWeightCtrl.text) ?? 0;
          double net = gross > basketTare ? gross - basketTare : 0;

          return AlertDialog(
            title: const Text("Cân rổ cuối ca"),
            content: Form(
              key: formKey,
              child: SizedBox(
                width: 350,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("${machine.name} - Line $lineCode", style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text("Rổ: ${ticket.basketCode} (Bì: ${basketTare}kg)"),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: grossWeightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: "Gross (kg)", border: OutlineInputBorder()),
                      onChanged: (val) => setStateDialog((){}), 
                      validator: (v) => (v == null || v.isEmpty) ? "Nhập số" : null,
                    ),
                    const SizedBox(height: 8),
                    Text("Net: ${net.toStringAsFixed(2)} kg", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: TextFormField(controller: runWasteCtrl, decoration: const InputDecoration(labelText: "Phế Run", border: OutlineInputBorder()))),
                        const SizedBox(width: 8),
                        Expanded(child: TextFormField(controller: setupWasteCtrl, decoration: const InputDecoration(labelText: "Phế Setup", border: OutlineInputBorder()))),
                      ],
                    )
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    _saveWeighingData(context, machine.id, int.parse(lineCode), ticket, net, double.parse(runWasteCtrl.text), double.parse(setupWasteCtrl.text));
                    Navigator.pop(ctx);
                  }
                },
                child: const Text("Lưu"),
              ),
            ],
          );
        }
      ),
    );
  }

  void _saveWeighingData(BuildContext context, int machineId, int line, WeavingTicket ticket, double netWeight, double runWaste, double setupWaste) {
    // Copy logic lưu record từ file cũ
    final authState = context.read<AuthCubit>().state;
    int? currentEmployeeId = (authState is AuthAuthenticated) ? authState.user.employeeId : null;

    final shiftState = context.read<ShiftCubit>().state;
    int? currentShiftId;
    if (shiftState is ShiftLoaded) {
      final currentShiftName = _calculateCurrentShift(); 
      try {
        currentShiftId = shiftState.shifts.firstWhere((s) => s.name.contains(currentShiftName)).id;
      } catch (_) {
        if (shiftState.shifts.isNotEmpty) currentShiftId = shiftState.shifts.first.id;
      }
    }

    final recordData = WeavingRecord(
      id: 0, machineId: machineId, line: line, basketId: ticket.basketId ?? 0,
      shiftId: currentShiftId, updatedById: currentEmployeeId,
      totalWeight: netWeight, runWaste: runWaste, setupWaste: setupWaste, updatedAt: DateTime.now(),
    );

    context.read<WeavingRecordCubit>().saveRecord(item: recordData, isEdit: false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã lưu!"), backgroundColor: Colors.green));
  }

  void _showReleaseDialog(BuildContext context, WeavingTicket ticket, AppLocalizations l10n) {
    // Copy hàm _showReleaseDialog từ file cũ
    // ... (Logic y hệt)
    final grossCtrl = TextEditingController();
    final lengthCtrl = TextEditingController();
    final knotCtrl = TextEditingController();
    int? employeeOutId;
    final formKey = GlobalKey<FormState>();

    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) employeeOutId = authState.user.employeeId; 

    double targetWeightGm = 0.0;
    final bomState = context.read<BOMCubit>().state;
    if (bomState is BOMListLoaded) {
       try {
         targetWeightGm = bomState.boms.firstWhere((b) => b.productId == ticket.productId && b.isActive).targetWeightGm;
       } catch (_) {}
    }

    double basketTare = 0.0;
    final basketState = context.read<BasketCubit>().state;
    if (basketState is BasketLoaded && ticket.basketId != 0) {
       try {
         basketTare = basketState.baskets.firstWhere((b) => b.id == ticket.basketId).tareWeight;
       } catch (_) {}
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.finishTicket),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: grossCtrl,
                  decoration: const InputDecoration(labelText: "Gross (Kg)", border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? "Nhập số" : null,
                  onChanged: (val) {
                      if (targetWeightGm > 0 && val.isNotEmpty) {
                          double? gross = double.tryParse(val);
                          if (gross != null) {
                              double net = gross - basketTare;
                              if (net > 0) lengthCtrl.text = ((net * 1000) / targetWeightGm).toStringAsFixed(2);
                          }
                      }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: knotCtrl,
                  decoration: InputDecoration(labelText: l10n.splice, border: const OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? "Nhập số" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: lengthCtrl,
                  decoration: InputDecoration(labelText: "${l10n.length} (m)", border: const OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? "Nhập số" : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate() && employeeOutId != null) {
                Navigator.pop(ctx);
                context.read<MachineOperationCubit>().finishTicket(
                  ticket: ticket, employeeOutId: employeeOutId,
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

  void _showStatusDialog(BuildContext context, Machine machine, String newStatus, AppLocalizations l10n) {
    // Copy hàm _showStatusDialog từ file cũ
    final reasonCtrl = TextEditingController();
    bool isIssue = newStatus == 'STOPPED' || newStatus == 'MAINTENANCE';
    final formKey = GlobalKey<FormState>();
    XFile? capturedImage;
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text("Đổi trạng thái: $newStatus"),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isIssue) ...[
                    TextFormField(
                      controller: reasonCtrl,
                      decoration: InputDecoration(labelText: l10n.reasonIssue, border: const OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? "Nhập lý do" : null,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final XFile? photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
                        if (photo != null) setStateDialog(() => capturedImage = photo);
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("Chụp ảnh"),
                    )
                  ] else 
                    const Text("Xác nhận đổi trạng thái máy?")
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
              ElevatedButton(
                onPressed: () {
                  if (isIssue && !formKey.currentState!.validate()) return;
                  context.read<MachineOperationCubit>().updateMachineStatus(
                    machineId: machine.id, status: newStatus, reason: reasonCtrl.text, imageFile: capturedImage,
                  );
                  Navigator.pop(ctx);
                },
                child: Text(l10n.confirm),
              )
            ],
          );
        }
      )
    );
  }

  // --- HELPERS MÀU SẮC ---
  Color _getMachineStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'RUNNING': return Colors.green.shade700; // Xanh đậm hơn cho dễ nhìn
      case 'MAINTENANCE': return Colors.orange;
      case 'STOPPED': return Colors.red;
      case 'SPINNING': return Colors.purple;
      default: return Colors.blueGrey;
    }
  }
}

// Widget Batch List nhỏ
class _TicketBatchList extends StatelessWidget {
  final List<WeavingTicketYarn> yarns;
  const _TicketBatchList({required this.yarns});

  @override
  Widget build(BuildContext context) {
    if (yarns.isEmpty) return const SizedBox.shrink();
    return BlocBuilder<BatchCubit, BatchState>(
      builder: (context, state) {
        final List<Batch> allBatches = (state is BatchLoaded) ? state.batches : [];
        return Wrap(
          spacing: 4,
          children: yarns.map((yarnItem) {
            final batch = allBatches.where((b) => b.batchId == yarnItem.batchId).firstOrNull;
            final code = batch?.internalBatchCode ?? "${yarnItem.batchId}";
            return Chip(
              label: Text("${yarnItem.componentType}: $code", style: const TextStyle(fontSize: 10)),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              backgroundColor: Colors.grey.shade100,
            );
          }).toList(),
        );
      },
    );
  }
}

// Widget Scanner
class SimpleBarcodeScanner extends StatefulWidget {
  const SimpleBarcodeScanner({super.key});
  @override
  State<SimpleBarcodeScanner> createState() => _SimpleBarcodeScannerState();
}
class _SimpleBarcodeScannerState extends State<SimpleBarcodeScanner> {
  final MobileScannerController controller = MobileScannerController(detectionSpeed: DetectionSpeed.normal);
  bool _isScanned = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quét mã")),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          if (_isScanned) return;
          if (capture.barcodes.isNotEmpty && capture.barcodes.first.rawValue != null) {
            setState(() => _isScanned = true);
            Navigator.pop(context, capture.barcodes.first.rawValue);
          }
        },
      ),
    );
  }
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}