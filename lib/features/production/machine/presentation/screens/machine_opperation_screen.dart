import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dropdown_search/dropdown_search.dart'; 
// Thư viện quét mã
import 'package:mobile_scanner/mobile_scanner.dart'; 

import 'package:production_app_frontend/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:production_app_frontend/features/hr/work_schedule/presentation/bloc/work_schedule_cubit.dart';
import 'package:production_app_frontend/features/inventory/basket/doamain/basket_model.dart';
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
import 'package:production_app_frontend/features/inventory/yarn_lot/domain/yarn_lot_model.dart';
import 'package:production_app_frontend/features/inventory/yarn_lot/presentation/bloc/yarn_lot_cubit.dart';
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
    final bool isActive = ticket != null;

    return Container(
      color: isActive ? Colors.green.shade50 : Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: InkWell(
              onTap: () {
                if (!isActive) {
                  // [THAY ĐỔI] Không cho phép gán rổ thủ công nữa. 
                  // Phải xuất kho mới có phiếu.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Vui lòng tạo phiếu xuất kho để gán rổ vào máy."),
                      backgroundColor: Colors.orange,
                    )
                  );
                } else {
                  // Đang chạy -> Mở Inspection
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${l10n.line}$lineCode", 
                    style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 10)
                  ),
                  const SizedBox(height: 2),
                  
                  if (isActive) ...[
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
                  ] else ...[
                    // [THAY ĐỔI] Thay icon (+) bằng icon chờ, thể hiện đang chờ kho xuất hàng
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

          if (isActive)
            Positioned(
              right: -2,
              top: -2,
              child: Tooltip(
                message: l10n.viewTicket, // Đổi tooltip từ "Edit" thành "View"
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    // [THAY ĐỔI] Mở dialog chỉ xem (Read-only)
                    _showAssignOrEditDialog(context, machine, lineCode, readyBaskets, l10n, existingTicket: ticket);
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

  // --- DIALOG XEM THÔNG TIN PHIẾU (READ ONLY) ---
  void _showAssignOrEditDialog(
    BuildContext context, 
    Machine machine, 
    String line, 
    List<Basket> readyBaskets, 
    AppLocalizations l10n, 
    {WeavingTicket? existingTicket}
  ) {
    // Nếu không có phiếu (Logic cũ là tạo mới), ta return luôn vì giờ đã chặn ở _buildLineSlot
    if (existingTicket == null) return;

    final productState = context.read<ProductCubit>().state;
    final standardState = context.read<StandardCubit>().state;
    final yarnLotState = context.read<YarnLotCubit>().state;
    
    List<Product> products = (productState is ProductLoaded) ? productState.products : [];
    List<Standard> allStandards = (standardState is StandardLoaded) ? standardState.standards : [];
    List<YarnLot> yarnLots = (yarnLotState is YarnLotLoaded) ? yarnLotState.yarnLots : [];

    // Lấy giá trị hiện tại
    int? selectedProductId = existingTicket.productId;
    int? selectedStandardId = existingTicket.standardId;
    int? selectedYarnLotId = existingTicket.batchId;

    // Filter standards để hiển thị đúng text
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
                  // 1. Rổ (Read Only)
                  TextFormField(
                    initialValue: existingTicket.basketCode,
                    decoration: const InputDecoration(labelText: "Mã Rổ", border: OutlineInputBorder(), filled: true, fillColor: Colors.white70),
                    readOnly: true,
                    enabled: false,
                  ),
                  const SizedBox(height: 16),
                  
                  // 2. Sản phẩm (Disabled)
                  DropdownSearch<Product>(
                    items: (filter, loadProps) => products,
                    itemAsString: (Product p) => p.itemCode,
                    selectedItem: products.where((p) => p.id == selectedProductId).firstOrNull,
                    compareFn: (i, s) => i.id == s.id,
                    decoratorProps: DropDownDecoratorProps(
                      decoration: InputDecoration(labelText: l10n.productTitle, border: const OutlineInputBorder(), filled: true, fillColor: Colors.grey.shade200),
                    ),
                    enabled: false, // [QUAN TRỌNG] Không cho sửa
                  ),
                  const SizedBox(height: 16),

                  // 3. Tiêu chuẩn (Disabled)
                  DropdownSearch<Standard>(
                    items: (filter, loadProps) => filteredStandards,
                    itemAsString: (Standard s) => "W:${s.widthMm} | T:${s.thicknessMm} (${s.colorName ?? 'N/A'})",
                    selectedItem: filteredStandards.where((s) => s.id == selectedStandardId).firstOrNull,
                    compareFn: (i, s) => i.id == s.id,
                    decoratorProps: DropDownDecoratorProps(
                      decoration: InputDecoration(labelText: l10n.standardTitle, border: const OutlineInputBorder(), filled: true, fillColor: Colors.grey.shade200),
                    ),
                    enabled: false, // [QUAN TRỌNG] Không cho sửa
                  ),
                  const SizedBox(height: 16),

                  // 4. Lô sợi (Disabled - Hoặc cho phép sửa nếu cần, nhưng theo yêu cầu là KHÔNG)
                  DropdownSearch<YarnLot>(
                    items: (filter, loadProps) => yarnLots,
                    itemAsString: (YarnLot y) => "${y.lotCode} (${y.totalKg}kg)",
                    selectedItem: yarnLots.where((y) => y.id == selectedYarnLotId).firstOrNull,
                    compareFn: (i, s) => i.id == s.id,
                    decoratorProps: DropDownDecoratorProps(
                      decoration: InputDecoration(labelText: l10n.yarnLotTitle, border: const OutlineInputBorder(), filled: true, fillColor: Colors.grey.shade200),
                    ),
                    enabled: false, // [QUAN TRỌNG] Không cho sửa
                  ),
                  
                  const SizedBox(height: 16),
                  const Text(
                    "(*) Thông tin sản xuất được đồng bộ từ Phiếu xuất kho. Vui lòng liên hệ kho nếu có sai sót.",
                    style: TextStyle(color: Colors.red, fontSize: 12, fontStyle: FontStyle.italic),
                  )
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Đóng")),
          // Đã xóa nút Save vì chỉ xem
        ],
      ),
    );
  }

  // --- DIALOG ĐỔI TRẠNG THÁI MÁY (Giữ nguyên) ---
  void _showStatusDialog(BuildContext context, Machine machine, String newStatus, AppLocalizations l10n) {
    final reasonCtrl = TextEditingController();
    bool isIssue = newStatus == 'STOPPED' || newStatus == 'MAINTENANCE';
    final formKey = GlobalKey<FormState>();
    final localizedNewStatus = _getLocalizedStatus(newStatus, l10n);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.changeStatusTitle(localizedNewStatus), 
          style: TextStyle(color: _getMachineStatusColor(newStatus), fontSize: 18)
        ),
        content: Form(
          key: formKey,
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
                  validator: (v) => v!.isEmpty ? l10n.reasonRequired : null,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.cameraFeatureDev)));
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: Text(l10n.captureEvidence),
                )
              ]
            ],
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
                reason: reasonCtrl.text
              );
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _getMachineStatusColor(newStatus), foregroundColor: Colors.white),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  // --- DIALOG KẾT THÚC PHIẾU (Giữ nguyên logic nhập kết quả) ---
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
                        labelText: l10n.splice,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (v) => v == null || v.isEmpty ? l10n.required : null,
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

// Widget Scanner (Giữ nguyên)
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
      if (mounted) {
        setState(() {
          _isCameraStarted = true;
        });
      }
    } catch (e) {
      debugPrint("Lỗi khởi động: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Không mở được Camera: $e")),
        );
      }
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt, size: 80, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text(
                    "Trình duyệt yêu cầu bạn\ncấp quyền thủ công",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _startCamera,
                    icon: const Icon(Icons.power_settings_new),
                    label: const Text("Bấm để mở Camera"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                  ),
                ],
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
              errorBuilder: (context, error, child) {
                return Center(
                  child: Text(
                    "Lỗi: ${error.errorCode}",
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              },
            ),
          if (_isCameraStarted)
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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