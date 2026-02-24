import 'dart:async';
import 'dart:io'
    as io; // [QUAN TRỌNG] Phải có 'as io' để không lỗi trên Web (Docker)
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

// --- IMPORTS PROJECT ---
import '../../../../../core/network/websocket_service.dart';
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

// =============================================================================
// 1. MÀN HÌNH CHÍNH
// =============================================================================
class MachineOperationScreen extends StatefulWidget {
  const MachineOperationScreen({super.key});

  @override
  State<MachineOperationScreen> createState() => _MachineOperationScreenState();
}

class _MachineOperationScreenState extends State<MachineOperationScreen>
    with TickerProviderStateMixin {
  final Color _primaryColor = const Color(0xFF003366);
  final TextEditingController _machineSearchCtrl = TextEditingController();
  String _searchKeyword = "";
  Timer? _debounce;

  TabController? _tabController;
  String? _selectedArea;
  List<String> _currentAreas = [];

  @override
  void initState() {
    super.initState();
    context.read<MachineOperationCubit>().loadDashboard();
    context.read<ProductCubit>().loadProducts();
    context.read<StandardCubit>().loadStandards();
    context.read<BatchCubit>().loadBatches();
    context.read<EmployeeCubit>().loadEmployees();
    context.read<ShiftCubit>().loadShifts();
    context.read<WorkScheduleCubit>().loadSchedules();
    context.read<BasketCubit>().loadBaskets();
    context.read<BOMCubit>().loadBOMHeaders();

    WebSocketService().connect();
    WebSocketService().addListener(_onWebSocketMessage);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _machineSearchCtrl.dispose();
    _tabController?.dispose();
    WebSocketService().removeListener(_onWebSocketMessage);
    super.dispose();
  }

  void _onWebSocketMessage(String message) {
    if (message == "REFRESH_MACHINES") {
      debugPrint("WebSocket: Cập nhật lại danh sách Máy Móc tự động.");
      context.read<MachineOperationCubit>().loadDashboard();
    }
  }

  String _calculateCurrentShiftName() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 14) {
      return "Ca A";
    } else if (hour >= 14 && hour < 22) {
      return "Ca B";
    } else {
      return "Ca C";
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        title: Text(l10n.machineOperation,
            style: const TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: _primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 22),
            tooltip: l10n.refreshData,
            onPressed: () =>
                context.read<MachineOperationCubit>().loadDashboard(),
          )
        ],
      ),
      body: Column(
        children: [
          // --- THANH TÌM KIẾM NHỎ ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: Colors.white,
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: _machineSearchCtrl,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: l10n.searchMachine,
                  prefixIcon: const Icon(Icons.search, size: 18),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6)),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                  isDense: true,
                ),
                onChanged: (val) {
                  if (_debounce?.isActive ?? false) _debounce!.cancel();
                  _debounce = Timer(const Duration(milliseconds: 300), () {
                    setState(() {
                      _searchKeyword = val.toLowerCase();
                    });
                  });
                },
              ),
            ),
          ),

          // --- DANH SÁCH MÁY (TABS + VERTICAL GRID) ---
          Expanded(
            child: BlocConsumer<MachineOperationCubit, MachineOpState>(
              listener: (context, state) {
                if (state is MachineOpError) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red));
                }
              },
              builder: (context, state) {
                if (state is MachineOpLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is MachineOpLoaded) {
                  final filteredMachines = state.machines
                      .where((m) =>
                          m.name.toLowerCase().contains(_searchKeyword) ||
                          m.status.toLowerCase().contains(_searchKeyword))
                      .toList();

                  if (filteredMachines.isEmpty) {
                    return Center(
                        child: Text(l10n.noMachineFound,
                            style: const TextStyle(fontSize: 14)));
                  }

                  final Map<String, List<Machine>> groupedMachines = {};
                  for (var machine in filteredMachines) {
                    final areaName =
                        (machine.area != null && machine.area!.isNotEmpty)
                            ? machine.area!
                            : l10n.unassignedArea;
                    if (!groupedMachines.containsKey(areaName)) {
                      groupedMachines[areaName] = [];
                    }
                    groupedMachines[areaName]!.add(machine);
                  }
                  final sortedAreas = groupedMachines.keys.toList()..sort();

                  // ==========================================
                  // [MỚI] LOGIC QUẢN LÝ TAB GIỮ NGUYÊN VỊ TRÍ
                  // ==========================================
                  bool areasChanged =
                      _currentAreas.join(',') != sortedAreas.join(',');

                  if (_tabController == null || areasChanged) {
                    int initIndex = 0;
                    if (_selectedArea != null &&
                        sortedAreas.contains(_selectedArea)) {
                      initIndex = sortedAreas.indexOf(_selectedArea!);
                    } else if (sortedAreas.isNotEmpty) {
                      _selectedArea = sortedAreas[0];
                    }

                    _tabController?.dispose();
                    _tabController = TabController(
                      length: sortedAreas.length,
                      vsync: this,
                      initialIndex: initIndex,
                    );
                    _currentAreas = sortedAreas;

                    _tabController!.addListener(() {
                      if (!_tabController!.indexIsChanging) {
                        _selectedArea = _currentAreas[_tabController!.index];
                      }
                    });
                  }
                  // ==========================================

                  return Column(
                    children: [
                      // --- COMPACT TAB BAR ---
                      Container(
                        color: Colors.white,
                        height: 36,
                        child: TabBar(
                          controller:
                              _tabController, // Gán controller tự quản lý
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          labelColor: _primaryColor,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: _primaryColor,
                          indicatorWeight: 2,
                          labelPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          labelStyle: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                          tabs: sortedAreas
                              .map((area) => Tab(text: area.toUpperCase()))
                              .toList(),
                        ),
                      ),

                      // --- CONTENT (VERTICAL GRID TỰ ĐỘNG CHIA CỘT) ---
                      Expanded(
                        child: TabBarView(
                          controller:
                              _tabController, // Gán controller tự quản lý
                          children: sortedAreas.map((area) {
                            final machinesInArea = groupedMachines[area]!;

                            return LayoutBuilder(
                                builder: (context, constraints) {
                              int crossAxisCount;

                              if (constraints.maxWidth < 600) {
                                crossAxisCount = 3;
                              } else {
                                crossAxisCount =
                                    (constraints.maxWidth / 140).floor();
                                if (crossAxisCount < 3) crossAxisCount = 3;
                              }

                              return SingleChildScrollView(
                                padding: const EdgeInsets.all(4),
                                child: StaggeredGrid.count(
                                  crossAxisCount: crossAxisCount,
                                  mainAxisSpacing: 4,
                                  crossAxisSpacing: 4,
                                  children: machinesInArea.map((machine) {
                                    int crossAxisCellCount = 1;
                                    int totalLines = 2;
                                    try {
                                      totalLines = machine.totalLines > 0
                                          ? machine.totalLines
                                          : 2;
                                    } catch (_) {}

                                    if (totalLines > 2 && crossAxisCount >= 2) {
                                      crossAxisCellCount = 2;
                                    }

                                    return StaggeredGridTile.fit(
                                      crossAxisCellCount: crossAxisCellCount,
                                      child: _MachineCard(
                                        machine: machine,
                                        state: state,
                                        l10n: l10n,
                                        onStatusChanged: (newStatus) =>
                                            _showStatusDialog(context, machine,
                                                newStatus, l10n),
                                        onHistory: () => showDialog(
                                            context: context,
                                            builder: (ctx) =>
                                                MachineHistoryDialog(
                                                    machine: machine)),
                                        onLineTap: (lineCode, ticket) {
                                          _handleLineTap(
                                              context,
                                              machine,
                                              lineCode,
                                              ticket,
                                              state.readyBaskets,
                                              l10n);
                                        },
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            });
                          }).toList(),
                        ),
                      ),
                    ],
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

  // =============================================================================
  // LOGIC NGHIỆP VỤ
  // =============================================================================

  void _handleLineTap(BuildContext context, Machine machine, String lineCode,
      WeavingTicket? ticket, List<Basket> readyBaskets, AppLocalizations l10n) {
    bool hasTicket = ticket != null;
    bool isPendingBasket =
        hasTicket && (ticket.basketId == null || ticket.basketId == 0);

    if (!hasTicket) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Vui lòng tạo phiếu xuất kho để khởi tạo lệnh chạy."),
        backgroundColor: Colors.orange,
      ));
    } else if (isPendingBasket) {
      _showAssignBasketDialog(context, ticket, l10n);
    } else {
      _showTicketActionMenu(context, machine, lineCode, ticket, l10n);
    }
  }

  // --- DIALOG GÁN RỔ ---
  void _showAssignBasketDialog(
      BuildContext context, WeavingTicket ticket, AppLocalizations l10n) async {
    final standardState = context.read<StandardCubit>().state;
    final basketState = context.read<BasketCubit>().state;
    final authState = context.read<AuthCubit>().state;
    final int currentEmployeeId =
        (authState is AuthAuthenticated) ? (authState.user.employeeId ?? 0) : 0;

    Standard? autoSelectedStandard;
    if (standardState is StandardLoaded && ticket.productId != 0) {
      autoSelectedStandard = standardState.standards
          .where((s) => s.productId == ticket.productId)
          .firstOrNull;
    }

    List<Basket> readyBaskets = [];
    if (basketState is BasketLoaded) {
      readyBaskets =
          basketState.baskets.where((b) => b.status == "READY").toList();
    }

    Basket? selectedBasket;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Gán Rổ & Xác nhận",
                style: TextStyle(color: Color(0xFF003366), fontSize: 16)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            content: Form(
              key: formKey,
              child: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  color: Colors.orange, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text("SP: ${ticket.productItemCode}",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.orange.shade800))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text("Lô sợi:",
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold)),
                          _TicketBatchList(yarns: ticket.yarns),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Tiêu chuẩn (Tự động):",
                              style: TextStyle(
                                  fontSize: 10, color: Colors.blue.shade800)),
                          const SizedBox(height: 2),
                          if (autoSelectedStandard != null)
                            Text(
                                "W:${autoSelectedStandard.widthMm} | T:${autoSelectedStandard.thicknessMm}",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900))
                          else
                            const Text("LỖI: Sản phẩm chưa có tiêu chuẩn!",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: DropdownSearch<Basket>(
                            items: (filter, props) => readyBaskets,
                            itemAsString: (b) =>
                                "${b.code} (${b.tareWeight}kg)",
                            compareFn: (i, s) => i.id == s.id,
                            selectedItem: selectedBasket,
                            onChanged: (val) =>
                                setStateDialog(() => selectedBasket = val),
                            validator: (v) =>
                                v == null ? "Vui lòng chọn rổ" : null,
                            decoratorProps: const DropDownDecoratorProps(
                                decoration: InputDecoration(
                                    labelText: "Rổ chứa *",
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 0),
                                    border: OutlineInputBorder())),
                            popupProps:
                                const PopupProps.menu(showSearchBox: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: IconButton.filled(
                            constraints: const BoxConstraints(
                                minHeight: 40, minWidth: 40),
                            style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFF003366)),
                            icon: const Icon(Icons.qr_code_scanner,
                                color: Colors.white, size: 20),
                            onPressed: () async {
                              final code = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const SimpleBarcodeScanner()));
                              if (code != null) {
                                final found = readyBaskets
                                    .where((b) => b.code == code)
                                    .firstOrNull;
                                if (found != null) {
                                  setStateDialog(() => selectedBasket = found);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              "Không tìm thấy rổ hoặc rổ đang bận")));
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
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.cancel)),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    if (autoSelectedStandard == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                "Không thể xác nhận vì thiếu tiêu chuẩn, vui lòng nhập tiêu chuẩn cho mã này ở QC/ Tiêu chuẩn!"),
                            backgroundColor: Colors.red),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    context.read<MachineOperationCubit>().updateTicketInfo(
                          ticketId: ticket.id,
                          basketId: selectedBasket!.id,
                          standardId: autoSelectedStandard.id,
                          employeeInId: currentEmployeeId,
                        );
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003366),
                    foregroundColor: Colors.white),
                child: const Text("XÁC NHẬN"),
              )
            ],
          );
        });
      },
    );
  }

  void _showTicketActionMenu(BuildContext context, Machine machine,
      String lineCode, WeavingTicket ticket, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.teal),
            title: Text(l10n.viewTicket),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WeavingTicketDetailScreen(ticket: ticket),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.fact_check, color: Colors.blue),
            title: const Text("Kiểm tra chất lượng"),
            onTap: () {
              Navigator.pop(ctx);
              final autoShift = _calculateCurrentShiftName();
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
            leading: const Icon(Icons.monitor_weight, color: Colors.indigo),
            title: const Text("Cân rổ cuối ca"),
            onTap: () {
              Navigator.pop(ctx);
              _handleWeighingCheck(context, machine, lineCode, ticket);
            },
          ),
          ListTile(
            leading: const Icon(Icons.stop_circle, color: Colors.red),
            title: const Text("Ra rổ"),
            onTap: () {
              Navigator.pop(ctx);
              _showReleaseDialog(context, ticket, l10n);
            },
          ),
        ],
      ),
    );
  }

  void _handleWeighingCheck(BuildContext context, Machine machine,
      String lineCode, WeavingTicket ticket) async {
    final shiftState = context.read<ShiftCubit>().state;
    if (shiftState is! ShiftLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Chưa tải được thông tin Ca làm việc!"),
          backgroundColor: Colors.orange));
      _showWeighingDialog(context, machine, lineCode, ticket);
      return;
    }

    final currentShiftName = _calculateCurrentShiftName();
    final currentShift = shiftState.shifts.firstWhere(
        (s) =>
            s.name.contains(currentShiftName) ||
            s.name.contains(currentShiftName.replaceAll("Ca ", "")),
        orElse: () => shiftState.shifts.first);

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()));

    try {
      final records = await context
          .read<WeavingRecordCubit>()
          .getRecordsByTicketId(ticket.id);

      if (context.mounted) Navigator.pop(context);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final hasWeighedToday = records.any((r) {
        if (r.shiftId != currentShift.id) return false;
        if (r.updatedAt == null) return false;
        final recordTime = r.updatedAt!.toLocal();
        final recordDate =
            DateTime(recordTime.year, recordTime.month, recordTime.day);
        return recordDate.isAtSameMomentAs(today);
      });

      if (hasWeighedToday) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                "CẢNH BÁO: Ca ${currentShift.name} hôm nay đã thực hiện cân rồi!"),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ));
        }
      } else {
        if (context.mounted) {
          _showWeighingDialog(context, machine, lineCode, ticket);
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        _showWeighingDialog(context, machine, lineCode, ticket);
      }
    }
  }

  void _showWeighingDialog(BuildContext context, Machine machine,
      String lineCode, WeavingTicket ticket) {
    final formKey = GlobalKey<FormState>();
    final grossWeightCtrl = TextEditingController();
    final runWasteCtrl = TextEditingController(text: "0");
    final setupWasteCtrl = TextEditingController(text: "0");

    double basketTare = 0.0;
    final basketState = context.read<BasketCubit>().state;
    if (basketState is BasketLoaded && ticket.basketId != null) {
      try {
        final foundBasket =
            basketState.baskets.firstWhere((b) => b.id == ticket.basketId);
        basketTare = foundBasket.tareWeight;
      } catch (_) {}
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (context, setStateDialog) {
        double gross = double.tryParse(grossWeightCtrl.text) ?? 0;
        double net = gross > basketTare ? gross - basketTare : 0;

        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.monitor_weight, color: Colors.indigo),
              SizedBox(width: 8),
              Text("Cân rổ cuối ca"),
            ],
          ),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("${machine.name} - Line $lineCode",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("Rổ: ${ticket.basketCode} (Bì: ${basketTare}kg)",
                      style: TextStyle(color: Colors.grey.shade700)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: grossWeightCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: "Tổng (Gross)",
                        suffixText: "kg",
                        border: OutlineInputBorder(),
                        helperText: "Bao gồm cả rổ"),
                    onChanged: (val) => setStateDialog(() {}),
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Bắt buộc nhập";
                      if (double.tryParse(v) == null) return "Sai định dạng";
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Net:",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("${net.toStringAsFixed(2)} kg",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 16)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: runWasteCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            labelText: "Phế Run",
                            suffixText: "kg",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: setupWasteCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            labelText: "Phế Setup",
                            suffixText: "kg",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text("Lưu"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  _saveWeighingData(
                      context,
                      machine.id,
                      int.parse(lineCode),
                      ticket,
                      net,
                      double.tryParse(runWasteCtrl.text) ?? 0,
                      double.tryParse(setupWasteCtrl.text) ?? 0);
                  Navigator.pop(ctx);
                }
              },
            ),
          ],
        );
      }),
    );
  }

  void _saveWeighingData(
      BuildContext context,
      int machineId,
      int line,
      WeavingTicket ticket,
      double netWeight,
      double runWaste,
      double setupWaste) {
    final authState = context.read<AuthCubit>().state;
    int? currentEmployeeId;
    if (authState is AuthAuthenticated) {
      currentEmployeeId = authState.user.employeeId;
    }

    final shiftState = context.read<ShiftCubit>().state;
    int? currentShiftId;
    if (shiftState is ShiftLoaded) {
      final currentShiftName = _calculateCurrentShiftName();
      try {
        final shift = shiftState.shifts.firstWhere(
          (s) =>
              s.name.contains(currentShiftName) ||
              s.name.contains(currentShiftName.substring(3)),
        );
        currentShiftId = shift.id;
      } catch (_) {
        if (shiftState.shifts.isNotEmpty) {
          currentShiftId = shiftState.shifts.first.id;
        }
      }
    }

    final recordData = WeavingRecord(
      id: 0,
      machineId: machineId,
      line: line,
      basketId: ticket.basketId ?? 0,
      shiftId: currentShiftId,
      updatedById: currentEmployeeId,
      totalWeight: netWeight,
      runWaste: runWaste,
      setupWaste: setupWaste,
      updatedAt: DateTime.now(),
    );

    context
        .read<WeavingRecordCubit>()
        .saveRecord(item: recordData, isEdit: false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("Đã lưu dữ liệu sản xuất thành công!"),
          backgroundColor: Colors.green),
    );
  }

  void _showStatusDialog(BuildContext context, Machine machine,
      String newStatus, AppLocalizations l10n) {
    final reasonCtrl = TextEditingController();
    bool isIssue = newStatus == 'STOPPED' || newStatus == 'MAINTENANCE';
    final formKey = GlobalKey<FormState>();
    final localizedNewStatus = _getLocalizedStatus(newStatus, l10n);
    XFile? capturedImage;
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (context, setStateDialog) {
        return AlertDialog(
          title: Text(l10n.changeStatusTitle(localizedNewStatus),
              style: TextStyle(
                  color: _getMachineStatusColor(newStatus), fontSize: 18)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.confirmStatusChangeMsg(
                      machine.name, localizedNewStatus)),
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
                              // [ĐÃ SỬA] Thay thế dart:io bằng thư viện io an toàn
                              child: kIsWeb
                                  ? Image.network(capturedImage!.path,
                                      fit: BoxFit.cover)
                                  : Image.file(io.File(capturedImage!.path),
                                      fit: BoxFit.cover),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                setStateDialog(() => capturedImage = null),
                            icon: const Icon(Icons.close, color: Colors.red),
                          ),
                        ],
                      ),
                    ],
                    ElevatedButton.icon(
                      onPressed: () async {
                        final XFile? photo = await picker.pickImage(
                            source: ImageSource.camera, imageQuality: 50);
                        if (photo != null) {
                          setStateDialog(() => capturedImage = photo);
                        }
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
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
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
              style: ElevatedButton.styleFrom(
                  backgroundColor: _getMachineStatusColor(newStatus),
                  foregroundColor: Colors.white),
              child: Text(l10n.confirm),
            ),
          ],
        );
      }),
    );
  }

  void _showReleaseDialog(
      BuildContext context, WeavingTicket ticket, AppLocalizations l10n) {
    final grossCtrl = TextEditingController();
    final lengthCtrl = TextEditingController();
    final knotCtrl = TextEditingController();
    int? employeeOutId;
    final formKey = GlobalKey<FormState>();

    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated && authState.user.employeeId != null) {
      employeeOutId = authState.user.employeeId;
    }

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

    double basketTare = 0.0;
    final basketState = context.read<BasketCubit>().state;
    if (basketState is BasketLoaded && ticket.basketId != 0) {
      try {
        final basket =
            basketState.baskets.firstWhere((b) => b.id == ticket.basketId);
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
                Text("${l10n.ticketCode}: ${ticket.code}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (targetWeightGm > 0)
                      Text("Định mức BOM: $targetWeightGm g/m",
                          style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 12,
                              fontStyle: FontStyle.italic)),
                    if (basketTare > 0)
                      Text("Trừ bì rổ: $basketTare kg",
                          style: const TextStyle(
                              color: Colors.brown,
                              fontSize: 12,
                              fontStyle: FontStyle.italic)),
                    if (targetWeightGm == 0)
                      const Text("Cảnh báo: Không có BOM để tính mét!",
                          style: TextStyle(color: Colors.red, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: grossCtrl,
                  decoration: InputDecoration(
                      labelText: "${l10n.grossWeight} (Kg)",
                      border: const OutlineInputBorder(),
                      helperText: "Nhập tổng trọng lượng cân được"),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
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
                  decoration: InputDecoration(
                      labelText: l10n.splice,
                      border: const OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) =>
                      v == null || v.isEmpty ? l10n.required : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: lengthCtrl,
                  decoration: InputDecoration(
                      labelText: "${l10n.length} (m)",
                      border: const OutlineInputBorder(),
                      fillColor: Colors.grey.shade200,
                      filled: true,
                      helperText: targetWeightGm > 0
                          ? "Tự động tính (Net / Định mức)"
                          : "Nhập tay (Không có BOM)"),
                  keyboardType: TextInputType.number,
                  readOnly: targetWeightGm > 0,
                  validator: (v) => v!.isEmpty ? l10n.required : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
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

  // --- Helper methods for Dialogs ---
  Color _getMachineStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'RUNNING':
        return Colors.blue;
      case 'MAINTENANCE':
        return Colors.orange;
      case 'STOPPED':
        return Colors.red;
      case 'SPINNING':
        return Colors.purple;
      case 'YARNOUT':
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }

  String _getLocalizedStatus(String status, AppLocalizations l10n) {
    switch (status.toUpperCase()) {
      case 'RUNNING':
        return l10n.statusRunning;
      case 'STOPPED':
        return l10n.statusStopped;
      case 'MAINTENANCE':
        return l10n.statusMaintenance;
      case 'SPINNING':
        return l10n.statusSpinning;
      case 'YARNOUT':
        return 'Hết sợi (Yarnout)';
      default:
        return status;
    }
  }
}

// =============================================================================
// 2. WIDGET: MACHINE CARD (DENSE VERTICAL CARD)
// =============================================================================
class _MachineCard extends StatelessWidget {
  final Machine machine;
  final MachineOpLoaded state;
  final AppLocalizations l10n;
  final Function(String) onStatusChanged;
  final VoidCallback onHistory;
  final Function(String, WeavingTicket?) onLineTap;

  const _MachineCard({
    required this.machine,
    required this.state,
    required this.l10n,
    required this.onStatusChanged,
    required this.onHistory,
    required this.onLineTap,
  });

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case "RUNNING":
        return Colors.blue;
      case "STOPPED":
        return Colors.red;
      case "SPINNING":
        return Colors.purple;
      case "YARNOUT":
        return Colors.green;
      case "MAINTENANCE":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color statusColor = _getStatusColor(machine.status);

    int totalLines = 2;
    try {
      totalLines = machine.totalLines;
    } catch (_) {
      totalLines = 2;
    }
    if (totalLines == 0) totalLines = 2;

    return Card(
      color: Colors.white,
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: statusColor, width: 2), // Viền màu đậm
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min, // Quan trọng để card co lại
        children: [
          // --- HEADER: TÊN MÁY ---
          Container(
            height: 24, // Header thấp
            padding: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    machine.name,
                    style: const TextStyle(
                      fontSize: 12, // Font nhỏ
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: Text(
                    machine.status,
                    style: const TextStyle(
                      fontSize: 10, // Font nhỏ
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Theme(
                  data: Theme.of(context).copyWith(
                    iconTheme: const IconThemeData(color: Colors.white),
                    cardColor: Colors.white,
                  ),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 16),
                      padding: EdgeInsets.zero,
                      onSelected: (value) {
                        if (value == 'HISTORY') {
                          onHistory();
                        } else {
                          onStatusChanged(value);
                        }
                      },
                      itemBuilder: (context) => [
                        _buildMenuItem('RUNNING', l10n.statusRunning,
                            Icons.play_arrow, Colors.blue),
                        _buildMenuItem('SPINNING', l10n.statusSpinning,
                            Icons.loop, Colors.purple),
                        _buildMenuItem('STOPPED', l10n.statusStopped,
                            Icons.stop, Colors.red),
                        _buildMenuItem('MAINTENANCE', l10n.statusMaintenance,
                            Icons.build, Colors.orange),
                        _buildMenuItem('YARNOUT', 'Hết sợi (Yarnout)',
                            Icons.timeline, Colors.green),
                        const PopupMenuDivider(),
                        _buildMenuItem('HISTORY', l10n.viewHistory,
                            Icons.history, Colors.black87),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- BODY: DANH SÁCH LINE (NẰM NGANG) ---
          Container(
            height: 70, // Cố định chiều cao phần body
            padding: const EdgeInsets.all(2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(totalLines, (index) {
                String lineCode = "${index + 1}";
                WeavingTicket? ticket =
                    state.activeTickets["${machine.id}_$lineCode"];

                return Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: index < totalLines - 1
                          ? Border(
                              right: BorderSide(color: Colors.grey.shade300))
                          : null,
                    ),
                    child: _LineItem(
                      lineIndex: index + 1,
                      ticket: ticket,
                      onTap: () => onLineTap(lineCode, ticket),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(
      String value, String label, IconData icon, Color color) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13))
      ]),
    );
  }
}

// =============================================================================
// 3. WIDGET: LINE ITEM (COMPACT, FULL TEXT)
// =============================================================================
class _LineItem extends StatelessWidget {
  final int lineIndex;
  final WeavingTicket? ticket;
  final VoidCallback onTap;

  const _LineItem({
    required this.lineIndex,
    required this.ticket,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    bool hasTicket = ticket != null;
    bool isPendingBasket =
        hasTicket && (ticket!.basketId == null || ticket!.basketId == 0);
    bool isFullyActive = hasTicket && !isPendingBasket;

    Color bgColor = Colors.transparent;

    if (isPendingBasket) {
      bgColor = const Color(0xFFFFF9C4); // Vàng nhạt
    } else if (isFullyActive) {
      bgColor = Colors.green.shade50; // Xanh nhạt
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        color: bgColor,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Text "Line 1" đầy đủ, rõ ràng
            Text(
              "Line $lineIndex",
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),

            // Icon hoặc Mã Rổ
            if (isFullyActive) ...[
              const Icon(Icons.check_circle, color: Colors.green, size: 18),
              const SizedBox(height: 2),
              Text(
                ticket!.basketCode ?? "",
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ] else if (isPendingBasket) ...[
              const Icon(Icons.warning, color: Colors.orange, size: 20),
              const Text(
                "Gán rổ",
                style: TextStyle(fontSize: 10, color: Colors.orange),
              ),
            ] else ...[
              const Icon(Icons.add, color: Colors.grey, size: 20),
              const Text(
                "Trống",
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

// --- SCANNER & TICKET LIST (Giữ nguyên) ---
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
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Không mở được Camera: $e")));
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

class _TicketBatchList extends StatelessWidget {
  final List<WeavingTicketYarn> yarns;
  const _TicketBatchList({required this.yarns});

  @override
  Widget build(BuildContext context) {
    if (yarns.isEmpty) {
      return const Text("-", style: TextStyle(color: Colors.grey));
    }

    return BlocBuilder<BatchCubit, BatchState>(
      builder: (context, state) {
        final List<Batch> allBatches =
            (state is BatchLoaded) ? state.batches : [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: yarns.map((yarnItem) {
            final batch = allBatches
                .where((b) => b.batchId == yarnItem.batchId)
                .firstOrNull;
            final internalCode =
                batch?.internalBatchCode ?? "ID:${yarnItem.batchId}";
            final supplierCode = batch?.supplierBatchNo ?? "";

            final displayCode = supplierCode.isNotEmpty
                ? "$internalCode (Sup:$supplierCode)"
                : internalCode;

            return Padding(
              padding: const EdgeInsets.only(bottom: 2.0),
              child: RichText(
                  text: TextSpan(
                      style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 12,
                          fontFamily: 'Roboto'),
                      children: [
                    TextSpan(
                        text: "${yarnItem.componentType}: ",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey)),
                    TextSpan(
                        text: displayCode,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ])),
            );
          }).toList(),
        );
      },
    );
  }
}
