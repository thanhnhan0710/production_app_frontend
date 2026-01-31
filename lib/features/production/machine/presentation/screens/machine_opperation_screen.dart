import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:mobile_scanner/mobile_scanner.dart'; 

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

// [THAY ĐỔI] Import Batch thay vì YarnLot
import 'package:production_app_frontend/features/inventory/batch/presentation/bloc/batch_cubit.dart';
import 'package:production_app_frontend/features/inventory/batch/domain/batch_model.dart';

import 'package:production_app_frontend/features/hr/employee/domain/employee_model.dart';
import 'package:production_app_frontend/features/hr/employee/presentation/bloc/employee_cubit.dart';
import 'package:production_app_frontend/features/hr/shift/presentation/bloc/shift_cubit.dart';
import 'package:production_app_frontend/features/production/machine/presentation/screens/machine_history_dialog.dart';


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
    
    // [THAY ĐỔI] Load Batch
    context.read<BatchCubit>().loadBatches();
    
    context.read<EmployeeCubit>().loadEmployees();
    context.read<ShiftCubit>().loadShifts();
    context.read<WorkScheduleCubit>().loadSchedules();
    context.read<BasketCubit>().loadBaskets();
    context.read<BOMCubit>().loadBOMHeaders(); 
  }

  // Hàm tính toán Ca làm việc tự động theo giờ
  String _calculateCurrentShift() {
    final hour = DateTime.now().hour;
    // Ca A: 06:00 - 14:00 (tức < 14h)
    if (hour >= 6 && hour < 14) {
      return "Ca A";
    } 
    // Ca B: 14:00 - 22:00 (tức < 22h)
    else if (hour >= 14 && hour < 22) {
      return "Ca B";
    } 
    // Ca C: 22:00 - 06:00
    else {
      return "Ca C";
    }
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
            tooltip: l10n.refreshData,
            onPressed: () => context.read<MachineOperationCubit>().loadDashboard(),
          )
        ],
      ),
      body: Column(
        children: [
          // --- THANH TÌM KIẾM ---
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

          // --- DANH SÁCH MÁY ---
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
                if (state is MachineOpLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (state is MachineOpLoaded) {
                  final filteredMachines = state.machines.where((m) => 
                    m.name.toLowerCase().contains(_searchKeyword) || 
                    m.status.toLowerCase().contains(_searchKeyword)
                  ).toList();

                  if (filteredMachines.isEmpty) {
                    return Center(child: Text(l10n.noMachineFound));
                  }

                  final Map<String, List<Machine>> groupedMachines = {};
                  for (var machine in filteredMachines) {
                    final areaName = (machine.area != null && machine.area!.isNotEmpty) 
                        ? machine.area! 
                        : l10n.unassignedArea;
                    if (!groupedMachines.containsKey(areaName)) {
                      groupedMachines[areaName] = [];
                    }
                    groupedMachines[areaName]!.add(machine);
                  }
                  final sortedAreas = groupedMachines.keys.toList()..sort();

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: sortedAreas.length,
                    itemBuilder: (context, index) {
                      final area = sortedAreas[index];
                      final machinesInArea = groupedMachines[area]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              border: Border(bottom: BorderSide(color: Colors.grey.shade400)),
                            ),
                            child: Text(
                              area.toUpperCase(),
                              style: TextStyle(
                                color: _primaryColor, 
                                fontWeight: FontWeight.bold, 
                                fontSize: 13, 
                                letterSpacing: 1.0
                              ),
                            ),
                          ),
                          
                          // Grid Máy
                          GridView.builder(
                            padding: const EdgeInsets.all(8),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 150, 
                              mainAxisExtent: 150, 
                              childAspectRatio: 1.0,
                              crossAxisSpacing: 6,
                              mainAxisSpacing: 6,
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

  // --- WIDGET CARD MÁY ---
  Widget _buildMachineCard(BuildContext context, Machine machine, MachineOpLoaded state, AppLocalizations l10n) {
    final statusColor = _getMachineStatusColor(machine.status);
    final bgColor = _getMachineBgColor(machine.status);
    final displayStatus = _getLocalizedStatus(machine.status, l10n);

    return Card(
      elevation: 2,
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: statusColor, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Column(
          children: [
            // HEADER
            Container(
              height: 30,
              padding: const EdgeInsets.fromLTRB(6, 0, 0, 0),
              decoration: BoxDecoration(color: statusColor),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.precision_manufacturing, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            machine.name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // MENU 3 CHẤM
                  Theme(
                    data: Theme.of(context).copyWith(
                      cardColor: Colors.white, 
                      iconTheme: const IconThemeData(color: Colors.white)
                    ),
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 16),
                      padding: EdgeInsets.zero,
                      onSelected: (value) {
                        if (value == 'HISTORY') {
                           showDialog(
                             context: context,
                             builder: (ctx) => MachineHistoryDialog(machine: machine),
                           );
                        } else {
                           _showStatusDialog(context, machine, value, l10n);
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'RUNNING', 
                          child: Row(children: [const Icon(Icons.play_arrow, color: Colors.blue), const SizedBox(width: 8), Text(l10n.statusRunning)])
                        ),
                        PopupMenuItem<String>(
                          value: 'SPINNING', 
                          child: Row(children: [const Icon(Icons.loop, color: Colors.purple), const SizedBox(width: 8), Text(l10n.statusSpinning)])
                        ),
                        PopupMenuItem<String>(
                          value: 'STOPPED', 
                          child: Row(children: [const Icon(Icons.stop, color: Colors.red), const SizedBox(width: 8), Text(l10n.statusStopped)])
                        ),
                        PopupMenuItem<String>(
                          value: 'MAINTENANCE', 
                          child: Row(children: [const Icon(Icons.build, color: Colors.orange), const SizedBox(width: 8), Text(l10n.statusMaintenance)])
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem<String>(
                          value: 'HISTORY', 
                          child: Row(children: [const Icon(Icons.history, color: Colors.black87), const SizedBox(width: 8), Text(l10n.viewHistory)])
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // STATUS LABEL
            Container(
              height: 20,
              width: double.infinity,
              color: statusColor.withOpacity(0.15),
              alignment: Alignment.center,
              child: Text(
                displayStatus.toUpperCase(),
                style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),

            // LINES
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
      ),
    );
  }

  // --- WIDGET SLOT TRỤC ---
  Widget _buildLineSlot(BuildContext context, Machine machine, String lineCode, WeavingTicket? ticket, List<Basket> readyBaskets, AppLocalizations l10n) {
    bool hasTicket = ticket != null;
    
    // Check nếu rổ chưa được gán (null hoặc 0)
    bool isPendingBasket = hasTicket && (ticket.basketId == null || ticket.basketId == 0);
    bool isFullyActive = hasTicket && !isPendingBasket;

    Color slotColor = Colors.transparent;
    
    if (isPendingBasket) slotColor = const Color(0xFFFFF9C4); // Vàng nhạt
    if (isFullyActive) slotColor = Colors.green.shade50;

    return Container(
      color: slotColor,
      child: Stack(
        children: [
          Positioned.fill(
            child: InkWell(
              onTap: () {
                if (!hasTicket) {
                  // Chưa có phiếu -> Báo user
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Vui lòng tạo phiếu xuất kho để khởi tạo lệnh chạy."),
                      backgroundColor: Colors.orange,
                    )
                  );
                } else if (isPendingBasket) {
                  // Có phiếu nhưng chưa có rổ -> Mở dialog chọn rổ & tiêu chuẩn
                  _showAssignBasketDialog(context, ticket, l10n);
                } else {
                  // Đã có đủ -> Menu Inspect/Release
                  _showTicketActionMenu(context, ticket, l10n);
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${l10n.line}$lineCode", 
                    style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 10)
                  ),
                  const SizedBox(height: 2),
                  
                  if (isFullyActive) ...[
                    // Hiển thị Rổ như cũ
                    const Icon(Icons.settings_backup_restore, color: Colors.green, size: 16),
                    const SizedBox(height: 2),
                    Text(
                      ticket.basketCode ?? "",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "#${ticket.code.substring(ticket.code.length > 4 ? ticket.code.length - 4 : 0)}", 
                      style: const TextStyle(fontSize: 9, color: Colors.grey)
                    ),
                  ] else if (isPendingBasket) ...[
                    const Icon(Icons.warning_amber_rounded, color: Colors.deepOrange, size: 24),
                    const SizedBox(height: 2),
                    const Text(
                      "Chưa có rổ",
                      style: TextStyle(fontSize: 10, color: Colors.deepOrange, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ] else ...[
                    // Không có phiếu
                    Icon(Icons.hourglass_empty, color: Colors.grey.shade300, size: 24),
                    const Text(
                      "---",
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    )
                  ]
                ],
              ),
            ),
          ),

          if (hasTicket)
            Positioned(
              right: -2,
              top: -2,
              child: Tooltip(
                message: l10n.viewTicket,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    // [THAY ĐỔI Ở ĐÂY]
                    // Thay vì gọi dialog cũ, chuyển sang màn hình chi tiết mới
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WeavingTicketDetailScreen(ticket: ticket),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.visibility, size: 12, color: Colors.blue.shade700),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- DIALOG: GÁN RỔ & TIÊU CHUẨN ---
  void _showAssignBasketDialog(BuildContext context, WeavingTicket ticket, AppLocalizations l10n) async {
    // Load Data
    final standardState = context.read<StandardCubit>().state;
    final basketState = context.read<BasketCubit>().state;
    final authState = context.read<AuthCubit>().state;
    final int currentEmployeeId = (authState is AuthAuthenticated) 
        ? (authState.user.employeeId ?? 0) 
        : 0;
    
    // Lọc tiêu chuẩn theo ProductID của ticket
    List<Standard> availableStandards = [];
    if (standardState is StandardLoaded && ticket.productId != 0) {
      availableStandards = standardState.standards.where((s) => s.productId == ticket.productId).toList();
    }

    // Lọc rổ Ready
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
              title: const Text("Gán Rổ & Tiêu chuẩn", style: TextStyle(color: Color(0xFF003366))),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.info_outline, color: Colors.orange, size: 16),
                                const SizedBox(width: 8),
                                Expanded(child: Text("Đang chạy sản phẩm ID: ${ticket.productId}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade800))),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // [MỚI] Hiển thị danh sách lô sợi trong dialog gán rổ
                            const Text("Lô sợi sử dụng:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            _TicketBatchList(yarns: ticket.yarns),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 1. Chọn Tiêu chuẩn (Lọc theo Product)
                      DropdownButtonFormField<Standard>(
                        decoration: const InputDecoration(labelText: "Tiêu chuẩn *", border: OutlineInputBorder()),
                        items: availableStandards.map((s) => DropdownMenuItem(value: s, child: Text("W:${s.widthMm} | T:${s.thicknessMm}"))).toList(),
                        onChanged: (val) => setStateDialog(() => selectedStandard = val),
                        validator: (v) => v == null ? "Vui lòng chọn tiêu chuẩn" : null,
                      ),
                      const SizedBox(height: 16),

                      // 2. Chọn Rổ (Có nút Scan)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: IconButton.filled(
                              style: IconButton.styleFrom(backgroundColor: const Color(0xFF003366)),
                              icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                              onPressed: () async {
                                final code = await Navigator.push(context, MaterialPageRoute(builder: (_) => const SimpleBarcodeScanner()));
                                if (code != null) {
                                  final found = readyBaskets.where((b) => b.code == code).firstOrNull;
                                  if (found != null) {
                                    setStateDialog(() => selectedBasket = found);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Không tìm thấy rổ hoặc rổ đang bận")));
                                  }
                                }
                              },
                            ),
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
                      
                      // Gọi API Update Ticket trong Cubit
                      context.read<MachineOperationCubit>().updateTicketInfo(
                        ticketId: ticket.id,
                        basketId: selectedBasket!.id,
                        standardId: selectedStandard!.id,
                        // Lấy ID người đang đăng nhập
                        employeeInId: currentEmployeeId,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003366), foregroundColor: Colors.white),
                  child: const Text("XÁC NHẬN"),
                )
              ],
            );
          }
        );
      },
    );
  }

  // --- MENU CHỌN HÀNH ĐỘNG ---
  void _showTicketActionMenu(BuildContext context, WeavingTicket ticket, AppLocalizations l10n) {
      showModalBottomSheet(
        context: context,
        builder: (ctx) => Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.fact_check, color: Colors.blue),
              title: const Text("Kiểm tra chất lượng"), 
              onTap: () {
                Navigator.pop(ctx);
                final autoShift = _calculateCurrentShift();
                context.read<WeavingCubit>().loadInspections(ticket.id);
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (dlgCtx) => WeavingInspectionDialog(
                    ticket: ticket,
                    shiftName: autoShift, 
                    onRelease: () {
                      Navigator.pop(dlgCtx);
                      _showReleaseDialog(context, ticket, l10n);
                    },
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.stop_circle, color: Colors.red),
              title: Text(l10n.finishTicket),
              onTap: () {
                Navigator.pop(ctx);
                _showReleaseDialog(context, ticket, l10n);
              },
            ),
          ],
        ),
      );
  }

  // --- DIALOG XEM THÔNG TIN (READ ONLY) ---
  // ignore: unused_element
  void _showAssignOrEditDialog(
    BuildContext context, 
    Machine machine, 
    String line, 
    List<Basket> readyBaskets, 
    AppLocalizations l10n, 
    {WeavingTicket? existingTicket}
  ) {
    if (existingTicket == null) return;

    final productState = context.read<ProductCubit>().state;
    final standardState = context.read<StandardCubit>().state;
    // Bỏ YarnLotState, dùng BatchCubit đã load ở initState hoặc widget con tự xử lý
    
    List<Product> products = (productState is ProductLoaded) ? productState.products : [];
    List<Standard> allStandards = (standardState is StandardLoaded) ? standardState.standards : [];

    int? selectedProductId = existingTicket.productId;
    int? selectedStandardId = existingTicket.standardId;

    List<Standard> filteredStandards = [];
    filteredStandards = allStandards.where((s) => s.productId == selectedProductId).toList();
  
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.blue),
            const SizedBox(width: 8),
            Text("Thông tin phiếu: ${machine.name} - Line $line"),
          ],
        ),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Rổ
                  TextFormField(
                    initialValue: existingTicket.basketCode ?? "CHƯA GÁN",
                    decoration: const InputDecoration(labelText: "Mã Rổ", border: OutlineInputBorder(), filled: true, fillColor: Colors.white70),
                    readOnly: true,
                    enabled: false,
                  ),
                  const SizedBox(height: 16),
                  
                  // Sản phẩm
                  DropdownSearch<Product>(
                    items: (filter, loadProps) => products,
                    itemAsString: (Product p) => p.itemCode,
                    selectedItem: products.where((p) => p.id == selectedProductId).firstOrNull,
                    compareFn: (i, s) => i.id == s.id,
                    decoratorProps: DropDownDecoratorProps(
                      decoration: InputDecoration(labelText: l10n.productTitle, border: const OutlineInputBorder(), filled: true, fillColor: Colors.grey.shade200),
                    ),
                    enabled: false, 
                  ),
                  const SizedBox(height: 16),

                  // Tiêu chuẩn
                  DropdownSearch<Standard>(
                    items: (filter, loadProps) => filteredStandards,
                    itemAsString: (Standard s) => "W:${s.widthMm} | T:${s.thicknessMm}",
                    selectedItem: filteredStandards.where((s) => s.id == selectedStandardId).firstOrNull,
                    compareFn: (i, s) => i.id == s.id,
                    decoratorProps: DropDownDecoratorProps(
                      decoration: InputDecoration(labelText: l10n.standardTitle, border: const OutlineInputBorder(), filled: true, fillColor: Colors.grey.shade200),
                    ),
                    enabled: false, 
                  ),
                  const SizedBox(height: 16),

                  // [THAY ĐỔI] Lô sợi (Hiển thị list thay vì Dropdown đơn)
                  InputDecorator(
                    decoration: const InputDecoration(labelText: "Lô sợi", border: OutlineInputBorder(), filled: true, fillColor: Color(0xFFEEEEEE)),
                    child: _TicketBatchList(yarns: existingTicket.yarns),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Đóng")),
        ],
      ),
    );
  }

  // --- DIALOG STATUS & RELEASE (GIỮ NGUYÊN) ---
  void _showStatusDialog(BuildContext context, Machine machine, String newStatus, AppLocalizations l10n) {
    final reasonCtrl = TextEditingController();
    bool isIssue = newStatus == 'STOPPED' || newStatus == 'MAINTENANCE';
    final formKey = GlobalKey<FormState>();
    final localizedNewStatus = _getLocalizedStatus(newStatus, l10n);
    XFile? capturedImage;
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(
              l10n.changeStatusTitle(localizedNewStatus), 
              style: TextStyle(color: _getMachineStatusColor(newStatus), fontSize: 18)
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.confirmStatusChangeMsg(machine.name, localizedNewStatus)),
                    if (isIssue) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: reasonCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.reasonIssue,
                          hintText: l10n.enterReason,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) => v!.isEmpty ? l10n.required : null,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      if (capturedImage != null) ...[
                        Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Container(
                              height: 150,
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: kIsWeb
                                    ? Image.network(capturedImage!.path, fit: BoxFit.cover)
                                    : Image.file(File(capturedImage!.path), fit: BoxFit.cover),
                              ),
                            ),
                            IconButton(
                              onPressed: () => setStateDialog(() => capturedImage = null),
                              icon: const Icon(Icons.close, color: Colors.red),
                            ),
                          ],
                        ),
                      ],
                      ElevatedButton.icon(
                        onPressed: () async {
                          final XFile? photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
                          if (photo != null) setStateDialog(() => capturedImage = photo);
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: const Text("Chụp ảnh"),
                      )
                    ]
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
              ElevatedButton(
                onPressed: () {
                  if (isIssue && !formKey.currentState!.validate()) return;
                  context.read<MachineOperationCubit>().updateMachineStatus(
                    machineId: machine.id, 
                    status: newStatus,
                    reason: reasonCtrl.text,
                    imageFile: capturedImage,
                  );
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(backgroundColor: _getMachineStatusColor(newStatus), foregroundColor: Colors.white),
                child: Text(l10n.confirm),
              ),
            ],
          );
        }
      ),
    );
  }

  // --- DIALOG KẾT THÚC PHIẾU ---
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

    // 1. Tìm Target Weight từ BOM
    double targetWeightGm = 0.0;
    
    final bomState = context.read<BOMCubit>().state;
    if (bomState is BOMListLoaded) {
       try {
         final bom = bomState.boms.firstWhere(
           (b) => b.productId == ticket.productId && b.isActive,
         );
         targetWeightGm = bom.targetWeightGm;
       } catch (_) {}
    }

    // 2. Tìm Rổ để lấy Trọng lượng bì (Tare Weight)
    double basketTare = 0.0;
    final basketState = context.read<BasketCubit>().state;
    if (basketState is BasketLoaded && ticket.basketId != 0) {
       try {
         final basket = basketState.baskets.firstWhere((b) => b.id == ticket.basketId);
         basketTare = basket.tareWeight;
       } catch (_) {}
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
                
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (targetWeightGm > 0)
                      Text("Định mức BOM: $targetWeightGm g/m", style: TextStyle(color: Colors.blue.shade700, fontSize: 12, fontStyle: FontStyle.italic)),
                    if (basketTare > 0)
                      Text("Trừ bì rổ: $basketTare kg", style: const TextStyle(color: Colors.brown, fontSize: 12, fontStyle: FontStyle.italic)),
                    if (targetWeightGm == 0)
                      const Text("Cảnh báo: Không có BOM để tính mét!", style: TextStyle(color: Colors.red, fontSize: 12)),
                  ],
                ),

                const SizedBox(height: 16),
                
                TextFormField(
                  controller: grossCtrl, 
                  decoration: InputDecoration(
                      labelText: "${l10n.grossWeight} (Kg)", 
                      border: const OutlineInputBorder(),
                      helperText: "Nhập tổng trọng lượng cân được"
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => v!.isEmpty ? l10n.required : null,
                  onChanged: (val) {
                      if (targetWeightGm > 0 && val.isNotEmpty) {
                          double? grossKg = double.tryParse(val);
                          if (grossKg != null) {
                              double netKg = grossKg - basketTare;
                              if (netKg > 0) {
                                  double meters = (netKg * 1000) / targetWeightGm;
                                  lengthCtrl.text = meters.toStringAsFixed(2);
                              } else {
                                  lengthCtrl.text = "0"; 
                              }
                          } else {
                              lengthCtrl.text = "";
                          }
                      }
                  },
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: knotCtrl,
                  decoration: InputDecoration(labelText: l10n.splice, border: const OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => v == null || v.isEmpty ? l10n.required : null,
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: lengthCtrl, 
                  decoration: InputDecoration(
                      labelText: "${l10n.length} (m)", 
                      border: const OutlineInputBorder(),
                      fillColor: Colors.grey.shade200,
                      filled: true,
                      helperText: targetWeightGm > 0 ? "Tự động tính (Net / Định mức)" : "Nhập tay (Không có BOM)"
                  ),
                  keyboardType: TextInputType.number,
                  readOnly: targetWeightGm > 0, 
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

  Color _getMachineStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'RUNNING': return Colors.blue;
      case 'MAINTENANCE': return Colors.orange;
      case 'STOPPED': return Colors.red;
      case 'SPINNING': return Colors.purple;
      default: return Colors.blueGrey;
    }
  }

  Color _getMachineBgColor(String status) {
    switch (status.toUpperCase()) {
      case 'RUNNING': return Colors.green.shade50;
      case 'MAINTENANCE': return Colors.orange.shade50;
      case 'STOPPED': return Colors.red.shade50;
      case 'SPINNING': return Colors.purple.shade50;
      default: return Colors.white;
    }
  }

  String _getLocalizedStatus(String status, AppLocalizations l10n) {
    switch (status.toUpperCase()) {
      case 'RUNNING': return l10n.statusRunning;
      case 'STOPPED': return l10n.statusStopped;
      case 'MAINTENANCE': return l10n.statusMaintenance;
      case 'SPINNING': return l10n.statusSpinning;
      default: return status;
    }
  }
}

// Widget Scanner
class SimpleBarcodeScanner extends StatefulWidget {
  const SimpleBarcodeScanner({super.key});

  @override
  State<SimpleBarcodeScanner> createState() => _SimpleBarcodeScannerState();
}

class _SimpleBarcodeScannerState extends State<SimpleBarcodeScanner> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
    autoStart: false,
  );

  bool _isScanned = false;
  bool _isCameraStarted = false;

  Future<void> _startCamera() async {
    try {
      await controller.start();
      if (mounted) setState(() => _isCameraStarted = true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Không mở được Camera: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("Quét mã Barcode")),
      body: Stack(
        children: [
          if (!_isCameraStarted)
            Center(
              child: ElevatedButton.icon(
                onPressed: _startCamera,
                icon: const Icon(Icons.camera_alt),
                label: const Text("Bấm để mở Camera"),
              ),
            )
          else
            MobileScanner(
              controller: controller,
              onDetect: (capture) {
                if (_isScanned) return;
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    setState(() => _isScanned = true);
                    Navigator.pop(context, barcode.rawValue);
                    break;
                  }
                }
              },
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

// [MỚI] Widget hiển thị danh sách Batch chi tiết
class _TicketBatchList extends StatelessWidget {
  final List<WeavingTicketYarn> yarns;
  const _TicketBatchList({required this.yarns});

  @override
  Widget build(BuildContext context) {
    if (yarns.isEmpty) return const Text("-", style: TextStyle(color: Colors.grey));

    return BlocBuilder<BatchCubit, BatchState>(
      builder: (context, state) {
        final List<Batch> allBatches = (state is BatchLoaded) ? state.batches : [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: yarns.map((yarnItem) {
            // Tìm thông tin Batch trong Cubit
            final batch = allBatches.where((b) => b.batchId == yarnItem.batchId).firstOrNull;
            final internalCode = batch?.internalBatchCode ?? "ID:${yarnItem.batchId}";
            final supplierCode = batch?.supplierBatchNo ?? "";
            
            final displayCode = supplierCode.isNotEmpty 
                ? "$internalCode (Sup:$supplierCode)" 
                : internalCode;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 2.0),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black87, fontSize: 12, fontFamily: 'Roboto'),
                  children: [
                    TextSpan(text: "${yarnItem.componentType}: ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    TextSpan(text: displayCode, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ]
                )
              ),
            );
          }).toList(),
        );
      },
    );
  }
}