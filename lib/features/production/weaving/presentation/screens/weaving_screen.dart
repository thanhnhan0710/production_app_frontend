import 'dart:async'; // [MỚI]
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:production_app_frontend/core/widgets/responsive_layout.dart';
import 'package:production_app_frontend/core/network/websocket_service.dart'; // [MỚI] Import WebSocket

import 'package:production_app_frontend/features/hr/work_schedule/presentation/bloc/work_schedule_cubit.dart';
import 'package:production_app_frontend/features/inventory/basket/doamain/basket_model.dart';
import 'package:production_app_frontend/features/inventory/basket/presentation/bloc/baket_cubit.dart';
import 'package:production_app_frontend/features/inventory/bom/presentation/bloc/bom_cubit.dart';
import 'package:production_app_frontend/l10n/app_localizations.dart';

import '../../domain/weaving_model.dart';
import '../bloc/weaving_cubit.dart';

// Import Feature khác
import 'package:production_app_frontend/features/inventory/product/domain/product_model.dart';
import 'package:production_app_frontend/features/inventory/product/presentation/bloc/product_cubit.dart';
import 'package:production_app_frontend/features/production/machine/presentation/bloc/machine_cubit.dart';
import 'package:production_app_frontend/features/production/machine/domain/machine_model.dart';

// Import Batch
import 'package:production_app_frontend/features/inventory/batch/presentation/bloc/batch_cubit.dart';
import 'package:production_app_frontend/features/inventory/batch/domain/batch_model.dart';

import 'package:production_app_frontend/features/production/standard/presentation/bloc/standard_cubit.dart';
import 'package:production_app_frontend/features/production/standard/domain/standard_model.dart';
import 'package:production_app_frontend/features/hr/employee/presentation/bloc/employee_cubit.dart';
import 'package:production_app_frontend/features/hr/employee/domain/employee_model.dart';
import 'package:production_app_frontend/features/inventory/dye_color/presentation/bloc/dye_color_cubit.dart';

// Import thư viện in ấn
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class WeavingScreen extends StatefulWidget {
  final bool isEmbedded;
  const WeavingScreen({super.key, this.isEmbedded = false});

  @override
  State<WeavingScreen> createState() => _WeavingScreenState();
}

class _WeavingScreenState extends State<WeavingScreen> {
  final Color _primaryColor = const Color(0xFF003366);
  final Color _bgLight = const Color(0xFFF5F7FA);

  final TextEditingController _searchController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _searchKeyword = "";

  Timer? _debounce; // [MỚI] Timer cho debounce tìm kiếm

  @override
  void initState() {
    super.initState();
    _loadAllData();

    // [MỚI] Lắng nghe WebSocket
    WebSocketService().connect();
    WebSocketService().addListener(_onWebSocketMessage);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();

    // [MỚI] Hủy lắng nghe WebSocket
    WebSocketService().removeListener(_onWebSocketMessage);
    super.dispose();
  }

  // [MỚI] Xử lý sự kiện WebSocket
  void _onWebSocketMessage(String message) {
    if (message == "REFRESH_WEAVING_TICKETS") {
      debugPrint(
          "WebSocket: Cập nhật lại danh sách Phiếu Dệt (Weaving Tickets).");
      if (mounted) context.read<WeavingCubit>().loadTickets();
    }
  }

  void _loadAllData() {
    context.read<WeavingCubit>().loadTickets();
    context.read<ProductCubit>().loadProducts();
    context.read<MachineCubit>().loadMachines();
    context.read<BasketCubit>().loadBaskets();
    context.read<BatchCubit>().loadBatches();
    context.read<StandardCubit>().loadStandards();
    context.read<EmployeeCubit>().loadEmployees();
    context.read<DyeColorCubit>().loadColors();
    context.read<BOMCubit>().loadBOMHeaders();
  }

  // [MỚI] Hàm xử lý tìm kiếm với Debounce
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchKeyword = query;
      });
    });
  }

  // Lọc phiếu
  List<WeavingTicket> _filterTickets(List<WeavingTicket> tickets) {
    final startOfDay = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day, 0, 0, 0);
    final endOfDay = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);

    return tickets.where((t) {
      bool dateMatch = false;
      try {
        final timeIn = DateTime.parse(t.timeIn);
        final timeOut = t.timeOut != null ? DateTime.parse(t.timeOut!) : null;
        bool startedBeforeEnd = timeIn.isBefore(endOfDay);
        bool notEndedOrEndedAfterStart =
            timeOut == null || timeOut.isAfter(startOfDay);
        dateMatch = startedBeforeEnd && notEndedOrEndedAfterStart;
      } catch (e) {
        dateMatch = false;
      }

      bool searchMatch = true;
      if (_searchKeyword.isNotEmpty) {
        final keyword = _searchKeyword.toLowerCase();
        final codeMatch = t.code.toLowerCase().contains(keyword);
        final machineMatch = t.machineLine.toString().contains(keyword);
        searchMatch = codeMatch || machineMatch;
      }

      return dateMatch && searchMatch;
    }).toList();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  // Hàm tính ca làm việc từ thời gian
  String _getShiftFromTime(String? timeIso) {
    if (timeIso == null || timeIso.isEmpty) return "-";
    try {
      final dt = DateTime.parse(timeIso);
      final h = dt.hour;
      // Logic chia ca (Ví dụ: Ca A: 6h-14h, Ca B: 14h-22h, Ca C: 22h-6h)
      if (h >= 6 && h < 14) return "Ca A";
      if (h >= 14 && h < 22) return "Ca B";
      return "Ca C";
    } catch (e) {
      return "-";
    }
  }

  // Hàm xử lý in ấn (được dùng chung cho cả Mobile và Desktop)
  Future<void> _handlePrint(
      WeavingTicket ticket, List<WeavingInspection> inspections) async {
    // 1. Lấy Tên Sản phẩm & Máy
    final pState = context.read<ProductCubit>().state;
    String pName = "${ticket.productId}";
    if (pState is ProductLoaded) {
      final p =
          pState.products.where((e) => e.id == ticket.productId).firstOrNull;
      if (p != null) pName = p.itemCode;
    }

    final mState = context.read<MachineCubit>().state;
    String mName = "Mac-${ticket.machineId}";
    if (mState is MachineLoaded) {
      final m =
          mState.machines.where((e) => e.id == ticket.machineId).firstOrNull;
      if (m != null) mName = m.name;
    }

    // 2. Lấy Object Standard đầy đủ
    Standard? fullStandard;
    final stdState = context.read<StandardCubit>().state;
    if (stdState is StandardLoaded) {
      fullStandard = stdState.standards
          .where((s) => s.id == ticket.standardId)
          .firstOrNull;
    }

    // 3. Tính toán ca làm việc
    String sIn = _getShiftFromTime(ticket.timeIn);
    String sOut = _getShiftFromTime(ticket.timeOut);

    // 4. Gọi hàm in Service
    await WeavingPrintService.printFullTicket(
      ticket: ticket,
      productName: pName,
      machineName: mName,
      standard: fullStandard,
      inspections: inspections,
      shiftIn: sIn,
      shiftOut: sOut,
    );
  }

  Widget _buildGroundYarnInfo(WeavingTicket ticket) {
    // Tìm sợi có componentType là GROUND
    final groundYarn = ticket.yarns
        .where((y) => y.componentType.toUpperCase() == 'GROUND')
        .firstOrNull;

    if (groundYarn == null) {
      return Row(
        children: [
          Icon(Icons.layers_clear, size: 14, color: Colors.orange.shade400),
          const SizedBox(width: 4),
          Text("Chưa gắn sợi nền",
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.orange.shade700,
                  fontStyle: FontStyle.italic)),
        ],
      );
    }

    final internalCode =
        groundYarn.internalBatchCode ?? "ID:${groundYarn.batchId}";
    final supplierName = groundYarn.supplierShortName;
    final displayCode = (supplierName != null && supplierName.isNotEmpty)
        ? "$internalCode ($supplierName)"
        : internalCode;

    return Row(
      children: [
        Icon(Icons.layers, size: 14, color: Colors.brown.shade600),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            "Nền: $displayCode",
            style: TextStyle(
                fontSize: 12,
                color: Colors.brown.shade800,
                fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: _bgLight,
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: const Text("Quản lý Phiếu Dệt",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              backgroundColor: _primaryColor,
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [
                IconButton(
                    icon: const Icon(Icons.refresh), onPressed: _loadAllData)
              ],
            ),
      body: BlocBuilder<WeavingCubit, WeavingState>(
        builder: (context, state) {
          if (state is WeavingLoading) {
            return Center(
                child: CircularProgressIndicator(color: _primaryColor));
          }

          if (state is WeavingError) {
            return Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Error: ${state.message}",
                    style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                TextButton(onPressed: _loadAllData, child: const Text("Retry"))
              ],
            ));
          }

          if (state is WeavingLoaded) {
            final filteredTickets = _filterTickets(state.tickets);
            int total = filteredTickets.length;

            if (!isDesktop) {
              // --- MOBILE VIEW ---
              return Column(
                children: [
                  _buildHeader(l10n),
                  Expanded(
                    child: filteredTickets.isEmpty
                        ? _buildEmptyState(l10n)
                        : ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: filteredTickets.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final ticket = filteredTickets[index];
                              return _buildTicketCardMobile(ticket, l10n);
                            },
                          ),
                  ),
                ],
              );
            }

            // --- DESKTOP VIEW ---
            return Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Container(
                    decoration: BoxDecoration(
                        border: Border(
                            right: BorderSide(color: Colors.grey.shade300))),
                    child: Column(
                      children: [
                        _buildHeader(l10n),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          color: Colors.blue.shade50,
                          child: Text("Total: $total tickets",
                              style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          child: filteredTickets.isEmpty
                              ? _buildEmptyState(l10n)
                              : ListView.separated(
                                  padding: const EdgeInsets.all(12),
                                  itemCount: filteredTickets.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final ticket = filteredTickets[index];
                                    final isSelected =
                                        state.selectedTicket?.id == ticket.id;
                                    return _buildTicketCardDesktop(
                                        ticket, isSelected);
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: state.selectedTicket == null
                      ? Center(
                          child: Text(l10n.noTicketSelected,
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 16)))
                      : _buildDetailPanel(
                          state.selectedTicket!, state.inspections, l10n),
                ),
              ],
            );
          }
          return const SizedBox();
        },
      ),
      floatingActionButton: null,
    );
  }

  // --- HEADER & SEARCH ---
  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.receipt_long, color: _primaryColor, size: 24),
                  const SizedBox(width: 8),
                  Text(l10n.weavingTicketTitle,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              InkWell(
                onTap: _pickDate,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(DateFormat('dd/MM').format(_selectedDate),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8)),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged, // [CẬP NHẬT] Đã gắn debounce
                    decoration: InputDecoration(
                        hintText: "Search Code / Line...",
                        hintStyle: TextStyle(
                            fontSize: 13, color: Colors.grey.shade500),
                        prefixIcon: const Icon(Icons.search,
                            size: 18, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10)),
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
        child: Text("No tickets found",
            style: TextStyle(color: Colors.grey.shade500)));
  }

  Color _getMachineColor(int machineId) {
    final colors = [
      Colors.blue.shade50,
      Colors.green.shade50,
      Colors.orange.shade50,
      Colors.purple.shade50,
      Colors.teal.shade50,
      Colors.pink.shade50,
    ];
    return colors[machineId % colors.length];
  }

  Widget _buildTicketCardDesktop(WeavingTicket ticket, bool isSelected) {
    bool isRunning = ticket.timeOut == null;
    return Card(
      elevation: isSelected ? 4 : 0,
      color: isSelected ? Colors.white : _getMachineColor(ticket.machineId),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? BorderSide(color: _primaryColor, width: 2)
              : BorderSide.none),
      child: ListTile(
        onTap: () => context.read<WeavingCubit>().selectTicket(ticket),
        leading: CircleAvatar(
          backgroundColor: isRunning ? Colors.green : Colors.grey,
          radius: 12,
          child: Icon(isRunning ? Icons.play_arrow : Icons.stop,
              size: 14, color: Colors.white),
        ),
        title: Text(ticket.code,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                _MachineInfo(id: ticket.machineId, line: ticket.machineLine),
                const SizedBox(width: 8),
                Text("• ${ticket.basketCode ?? '-'}",
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade700)),
              ],
            ),
            const SizedBox(height: 6),
            _buildGroundYarnInfo(ticket),
          ],
        ),
        trailing: isRunning
            ? const Icon(Icons.keyboard_arrow_right, color: Colors.grey)
            : const Text("DONE",
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
      ),
    );
  }

  Widget _buildTicketCardMobile(WeavingTicket ticket, AppLocalizations l10n) {
    bool isRunning = ticket.timeOut == null;
    return Card(
      elevation: 2,
      color: _getMachineColor(ticket.machineId),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showMobileDetailSheet(context, ticket, l10n),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(ticket.code,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: isRunning ? Colors.green : Colors.grey,
                        borderRadius: BorderRadius.circular(4)),
                    child: Text(isRunning ? "RUNNING" : "FINISHED",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.precision_manufacturing,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  _MachineInfo(id: ticket.machineId, line: ticket.machineLine),
                  const SizedBox(width: 16),
                  const Icon(Icons.shopping_basket,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(ticket.basketCode ?? "No Basket"),
                ],
              ),
              const SizedBox(height: 8),
              _ProductInfo(id: ticket.productId),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6.0),
                child: Divider(height: 1, thickness: 0.5),
              ),
              _buildGroundYarnInfo(ticket),
            ],
          ),
        ),
      ),
    );
  }

  // --- CHI TIẾT PHIẾU (DESKTOP) ---
  Widget _buildDetailPanel(WeavingTicket ticket,
      List<WeavingInspection> inspections, AppLocalizations l10n) {
    return Container(
      color: _bgLight,
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header & Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text("Phiếu: ${ticket.code}",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor)),
                ),
                Expanded(
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.print, color: Colors.blue),
                        tooltip: "In phiếu chi tiết",
                        onPressed: () => _handlePrint(ticket, inspections),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(ticket, l10n)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 2. Production Info Grid
            _buildInfoSection("Production Info", [
              _infoRow("", _ProductFullDetails(id: ticket.productId)),
              _infoRow("Machine",
                  _MachineInfo(id: ticket.machineId, line: ticket.machineLine)),
            ]),

            // 3. Standard
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.assignment,
                            size: 18, color: Colors.blue.shade800),
                        const SizedBox(width: 8),
                        Text("Product & Standard Specifications",
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800)),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    _StandardFullDetails(standardId: ticket.standardId),
                  ],
                ),
              ),
            ),

            // 4. Materials
            _buildInfoSection("Materials", [
              _infoRow("Yarn Batches", _TicketBatchList(yarns: ticket.yarns)),
              _infoRow("Load Date", Text(ticket.yarnLoadDate)),
              _infoRow(
                  "Basket",
                  Text(
                      "${ticket.basketCode ?? 'N/A'} (ID: ${ticket.basketId ?? '-'})")),
              _infoRow("Tare Weight", Text("${ticket.tareWeight ?? 0} kg")),
            ]),

            // 5. Time & Personnel
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Time & Personnel",
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800)),
                    const Divider(),
                    const SizedBox(height: 8),

                    // START (IN)
                    Row(
                      children: [
                        const Icon(Icons.login, size: 18, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _infoRow("Start Time",
                                Text(_formatDateTimeFull(ticket.timeIn)))),
                        Expanded(
                            child: _infoRow(
                                "Operator In",
                                Text(ticket.employeeInName ?? "---",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500)))),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // END (OUT)
                    Row(
                      children: [
                        const Icon(Icons.logout, size: 18, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _infoRow(
                                "End Time",
                                Text(ticket.timeOut != null
                                    ? _formatDateTimeFull(ticket.timeOut!)
                                    : "-"))),
                        Expanded(
                            child: _infoRow(
                                "Operator Out",
                                Text(ticket.employeeOutName ?? "---",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500)))),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 6. Results
            _buildInfoSection("Results", [
              _infoRow("Gross Weight", Text("${ticket.grossWeight} kg")),
              _infoRow(
                  "Net Weight",
                  Text("${ticket.netWeight} kg",
                      style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold))),
              _infoRow("Length", Text("${ticket.lengthMeters} m")),
              _infoRow("Splice", Text("${ticket.numberOfKnots}")),
            ]),

            const SizedBox(height: 24),

            // 7. Inspection History
            Text(l10n.inspectionHistory,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800)),
            const SizedBox(height: 12),

            if (inspections.isEmpty)
              Container(
                height: 100,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8)),
                child: Center(
                    child: Text("No inspections recorded",
                        style: TextStyle(color: Colors.grey.shade400))),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: inspections.length,
                itemBuilder: (context, index) {
                  final item = inspections[index];
                  return _buildInspectionItem(item, context);
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatDateTimeFull(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (e) {
      return isoString;
    }
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity, // Mobile fill width
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                  fontSize: 13)),
          const Divider(height: 20),
          ...children
        ],
      ),
    );
  }

  Widget _rowInfo(String label, Widget content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          Expanded(
              child: Align(alignment: Alignment.centerRight, child: content)),
        ],
      ),
    );
  }

  Widget _buildInspectionItem(WeavingInspection item, BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      radius: 14,
                      child: Text("QC",
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Text(item.stageName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(width: 8),
                    Text(_formatDateTimeFull(item.inspectionTime),
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
                Text("${item.employeeName ?? ''} (${item.shiftName ?? ''})",
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade700)),
              ],
            ),
            const Divider(),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _specBadge("W: ${item.widthMm}mm"),
                _specBadge("Dens: ${item.weftDensity}"),
                _specBadge("Tens: ${item.tensionDan}N"),
                _specBadge("Thick: ${item.thicknessMm}mm"),
                _specBadge("Weight: ${item.weightGm}g"),
                _specBadge("Bow: ${item.bowing}%"),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _specBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
      child: Text(text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _infoRow(String label, Widget valueWidget) {
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          DefaultTextStyle(
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87),
            child: valueWidget,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800)),
            const Divider(),
            const SizedBox(height: 8),
            Wrap(spacing: 24, runSpacing: 12, children: children)
          ],
        ),
      ),
    );
  }

  // --- MOBILE SHEET (FULL INFO) ---
  void _showMobileDetailSheet(
      BuildContext context, WeavingTicket ticket, AppLocalizations l10n) {
    context.read<WeavingCubit>().selectTicket(ticket);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF5F7FA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: BlocBuilder<WeavingCubit, WeavingState>(
              builder: (context, state) {
                List<WeavingInspection> inspections = [];
                if (state is WeavingLoaded &&
                    state.selectedTicket?.id == ticket.id) {
                  inspections = state.inspections;
                }

                return SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                      // Thanh kéo (Handle)
                      Center(
                          child: Container(
                              margin: const EdgeInsets.only(top: 12, bottom: 8),
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(2)))),

                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Header with Actions
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    "Phiếu:${ticket.code}",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: _primaryColor),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                        icon: const Icon(Icons.print,
                                            color: Colors.blue),
                                        onPressed: () =>
                                            _handlePrint(ticket, inspections)),
                                    IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          _confirmDelete(ticket, l10n);
                                        }),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // 2. Production Info (Full)
                            _buildInfoCard(l10n.productionInfo, [
                              _rowInfo(l10n.productTitle,
                                  _ProductFullDetails(id: ticket.productId)),
                              const SizedBox(height: 8),
                              _rowInfo(
                                  l10n.machineTitle,
                                  _MachineInfo(
                                      id: ticket.machineId,
                                      line: ticket.machineLine)),
                            ]),

                            // 3. Standard Info (Full)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Standard",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade900)),
                                    const SizedBox(height: 8),
                                    _StandardFullDetails(
                                        standardId: ticket.standardId)
                                  ]),
                            ),
                            const SizedBox(height: 12),

                            // 4. Materials Info (Full)
                            _buildInfoCard("Materials", [
                              _rowInfo("Yarn Batches",
                                  _TicketBatchList(yarns: ticket.yarns)),
                              _rowInfo("Load Date", Text(ticket.yarnLoadDate)),
                              _rowInfo(
                                  "Basket",
                                  Text(
                                      "${ticket.basketCode ?? 'N/A'} (ID: ${ticket.basketId ?? '-'})")),
                            ]),

                            // 5. Time & Personnel (Full)
                            _buildInfoCard("Time & Personnel", [
                              _rowInfo("Start",
                                  Text(_formatDateTimeFull(ticket.timeIn))),
                              _rowInfo(
                                  "Op In", Text(ticket.employeeInName ?? "-")),
                              _rowInfo(
                                  "End",
                                  Text(ticket.timeOut != null
                                      ? _formatDateTimeFull(ticket.timeOut!)
                                      : "-")),
                              _rowInfo("Op Out",
                                  Text(ticket.employeeOutName ?? "-")),
                            ]),

                            // 6. Results (Output)
                            _buildInfoCard(l10n.output, [
                              _rowInfo(
                                  "Gross", Text("${ticket.grossWeight} kg")),
                              _rowInfo("Net", Text("${ticket.netWeight} kg")),
                              _rowInfo(
                                  "Length", Text("${ticket.lengthMeters} m")),
                              _rowInfo(
                                  "Splice", Text("${ticket.numberOfKnots}")),
                            ]),

                            const SizedBox(height: 20),

                            // 7. History
                            Text(l10n.inspectionHistory,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            if (inspections.isEmpty)
                              const Text("No inspections",
                                  style: TextStyle(color: Colors.grey))
                            else
                              ...inspections
                                  .map((i) => _buildInspectionItem(i, context)),

                            const SizedBox(height: 40), // Bottom padding
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(WeavingTicket ticket, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteTicket),
        content: Text(l10n.confirmDeleteTicket(ticket.code)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              context.read<WeavingCubit>().deleteTicket(ticket.id);
              Navigator.pop(ctx);
            },
            child: Text(l10n.deleteTicket),
          )
        ],
      ),
    );
  }
}

// ==========================================
// CÁC WIDGET BADGE & HELPER BÊN DƯỚI GIỮ NGUYÊN
// ==========================================

class _ProductInfo extends StatelessWidget {
  final int id;
  const _ProductInfo({required this.id});
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductCubit, ProductState>(
        builder: (c, s) => Text(
            s is ProductLoaded
                ? (s.products.where((e) => e.id == id).firstOrNull?.itemCode ??
                    "$id")
                : "$id",
            style: const TextStyle(fontWeight: FontWeight.bold)));
  }
}

class _ProductFullDetails extends StatelessWidget {
  final int id;
  const _ProductFullDetails({required this.id});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, state) {
        if (state is ProductLoaded) {
          final product = state.products.where((e) => e.id == id).firstOrNull;
          if (product == null) return Text("Product ID: $id (Not found)");

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: product.imageUrl.isNotEmpty
                      ? Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey),
                        )
                      : const Icon(Icons.image, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Product Code",
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                    Text(product.itemCode,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text(product.note,
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ],
          );
        }
        return const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2));
      },
    );
  }
}

class _StandardFullDetails extends StatelessWidget {
  final int standardId;
  const _StandardFullDetails({required this.standardId});

  Color _hexToColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return Colors.grey;
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StandardCubit, StandardState>(
      builder: (context, state) {
        if (state is StandardLoaded) {
          final item =
              state.standards.where((s) => s.id == standardId).firstOrNull;
          if (item == null) {
            return const Text("Standard info not loaded",
                style: TextStyle(color: Colors.grey));
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _specItem(Icons.straighten, "W", "${item.widthMm} mm"),
                        _specItem(
                            Icons.line_weight, "T", "${item.thicknessMm} mm"),
                        _specItem(Icons.scale, "G/m", "${item.weightGm} g/m"),
                        _specItem(
                            Icons.bolt, "Str", "${item.breakingStrength} daN",
                            color: Colors.red.shade700),
                        _specItem(Icons.expand, "El", "${item.elongation} %",
                            color: Colors.indigo),
                        _specItem(Icons.grid_on, "Den",
                            "${item.weftDensity} pick/10cm"),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                  color: _hexToColor(item.colorHex),
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.grey.shade300)),
                            ),
                            const SizedBox(width: 6),
                            Text(item.colorName ?? "N/A",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                            if (item.deltaE.isNotEmpty) ...[
                              const SizedBox(width: 12),
                              Text("ΔE: ${item.deltaE}",
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.purple,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (item.appearance.isNotEmpty)
                          Text("Appr: ${item.appearance}",
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                      ],
                    )
                  ],
                ),
              ),
            ],
          );
        }
        return const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2));
      },
    );
  }

  Widget _specItem(IconData icon, String label, String value, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade400),
        const SizedBox(width: 4),
        Text("$label: ",
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        Text(value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color ?? Colors.black87)),
      ],
    );
  }
}

class _MachineInfo extends StatelessWidget {
  final int id;
  final String line;
  const _MachineInfo({required this.id, required this.line});
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<MachineCubit, MachineState>(builder: (c, s) {
        String t = "Mac-$id Line $line";
        if (s is MachineLoaded) {
          final m = s.machines.where((e) => e.id == id).firstOrNull;
          if (m != null) t = "${m.name} - Line $line";
        }
        return Text(t, style: const TextStyle(fontWeight: FontWeight.bold));
      });
}

class _TicketBatchList extends StatelessWidget {
  final List<WeavingTicketYarn> yarns;
  const _TicketBatchList({required this.yarns});

  @override
  Widget build(BuildContext context) {
    if (yarns.isEmpty) {
      return const Text("-", style: TextStyle(color: Colors.grey));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: yarns.map((yarnItem) {
        final internalCode =
            yarnItem.internalBatchCode ?? "ID:${yarnItem.batchId}";
        final supplierName = yarnItem.supplierShortName;
        final displayCode = (supplierName != null && supplierName.isNotEmpty)
            ? "$internalCode ($supplierName)"
            : internalCode;
        final quantity = yarnItem.quantity;

        return Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                  color: Colors.black87, fontSize: 13, fontFamily: 'Roboto'),
              children: [
                TextSpan(
                  text: "${yarnItem.componentType}: ",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                      fontSize: 11),
                ),
                TextSpan(
                  text: displayCode,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const TextSpan(text: "  "),
                TextSpan(
                  text: "($quantity kg)",
                  style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class WeavingPrintService {
  static Future<void> printFullTicket({
    required WeavingTicket ticket,
    required String productName,
    required String machineName,
    required Standard? standard,
    required List<WeavingInspection> inspections,
    required String shiftIn,
    required String shiftOut,
  }) async {
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final doc = pw.Document();

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final nowStr = dateFormat.format(DateTime.now());

    const double fontSizeTitle = 14;
    const double fontSizeHeader = 9;
    const double fontSizeText = 8;
    const double fontSizeSmall = 7;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin:
            const pw.EdgeInsets.only(left: 40, top: 20, right: 20, bottom: 20),
        build: (pw.Context context) {
          return [
            // --- 1. HEADER (Thu gọn) ---
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("OPPERMANN VIETNAM",
                        style: pw.TextStyle(font: fontBold, fontSize: 16)),
                    pw.Text("Weaving Production Department",
                        style: pw.TextStyle(font: font, fontSize: 8)),
                  ],
                ),
                pw.BarcodeWidget(
                  data: ticket.code,
                  barcode: pw.Barcode.qrCode(),
                  width: 40,
                  height: 40,
                ),
              ],
            ),
            pw.Divider(thickness: 0.5),
            pw.Center(
              child: pw.Text("PHIẾU THÔNG TIN RỔ DỆT (WEAVING TICKET)",
                  style: pw.TextStyle(font: fontBold, fontSize: fontSizeTitle)),
            ),
            pw.SizedBox(height: 2),
            pw.Center(
                child: pw.Text(ticket.code,
                    style: pw.TextStyle(font: fontBold, fontSize: 10))),
            pw.SizedBox(height: 8),

            // --- 2. THÔNG TIN CHUNG ---
            _buildSectionTitle("1. THÔNG TIN SẢN XUẤT (PRODUCTION INFO)",
                fontBold, fontSizeHeader),
            pw.Table(
                border:
                    pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                children: [
                  _buildRowPair(
                      "Máy / Machine",
                      "$machineName (Line ${ticket.machineLine})",
                      "Sản phẩm / Product",
                      productName,
                      font,
                      fontBold,
                      fontSizeText,
                      fontSizeSmall),
                  _buildRowPair(
                      "Rổ / Basket",
                      "${ticket.basketCode} (Tare: ${ticket.tareWeight}kg)",
                      "Ngày lên sợi",
                      ticket.yarnLoadDate,
                      font,
                      fontBold,
                      fontSizeText,
                      fontSizeSmall),
                ]),
            pw.SizedBox(height: 8),

            // --- 3. TIÊU CHUẨN KỸ THUẬT ---
            _buildSectionTitle("2. TIÊU CHUẨN KỸ THUẬT (STANDARD SPECS)",
                fontBold, fontSizeHeader),
            if (standard != null)
              pw.Container(
                  decoration: pw.BoxDecoration(
                      border:
                          pw.Border.all(color: PdfColors.grey400, width: 0.5)),
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Column(children: [
                    pw.Row(children: [
                      pw.Expanded(
                          child: _buildSpecItem(
                              "Mã chuẩn",
                              "STD-${standard.id}",
                              font,
                              fontBold,
                              fontSizeText,
                              fontSizeSmall)),
                      pw.Expanded(
                          child: _buildSpecItem(
                              "Màu (Color)",
                              standard.colorName ?? "-",
                              font,
                              fontBold,
                              fontSizeText,
                              fontSizeSmall)),
                      pw.Expanded(
                          child: _buildSpecItem("Delta E", standard.deltaE,
                              font, fontBold, fontSizeText, fontSizeSmall)),
                    ]),
                    pw.SizedBox(height: 4),
                    pw.Divider(color: PdfColors.grey300, thickness: 0.5),
                    pw.SizedBox(height: 4),
                    pw.Row(children: [
                      pw.Expanded(
                          child: _buildSpecItem(
                              "Khổ (Width)",
                              "${standard.widthMm} mm",
                              font,
                              fontBold,
                              fontSizeText,
                              fontSizeSmall)),
                      pw.Expanded(
                          child: _buildSpecItem(
                              "Dày (Thick)",
                              "${standard.thicknessMm} mm",
                              font,
                              fontBold,
                              fontSizeText,
                              fontSizeSmall)),
                      pw.Expanded(
                          child: _buildSpecItem(
                              "Trọng lượng",
                              "${standard.weightGm} g/m",
                              font,
                              fontBold,
                              fontSizeText,
                              fontSizeSmall)),
                      pw.Expanded(
                          child: _buildSpecItem(
                              "Mật độ (Den)",
                              standard.weftDensity,
                              font,
                              fontBold,
                              fontSizeText,
                              fontSizeSmall)),
                    ]),
                    pw.SizedBox(height: 4),
                    pw.Row(children: [
                      pw.Expanded(
                          child: _buildSpecItem(
                              "Lực kéo (Str)",
                              "${standard.breakingStrength} daN",
                              font,
                              fontBold,
                              fontSizeText,
                              fontSizeSmall)),
                      pw.Expanded(
                          child: _buildSpecItem(
                              "Độ giãn (El)",
                              "${standard.elongation} %",
                              font,
                              fontBold,
                              fontSizeText,
                              fontSizeSmall)),
                      pw.Expanded(flex: 2, child: pw.Container()),
                    ]),
                  ]))
            else
              pw.Text("Không có dữ liệu tiêu chuẩn",
                  style: pw.TextStyle(
                      font: font,
                      fontSize: fontSizeText,
                      fontStyle: pw.FontStyle.italic)),

            pw.SizedBox(height: 8),

            // --- 4. NHÂN SỰ & THỜI GIAN ---
            _buildSectionTitle("3. NHÂN SỰ & THỜI GIAN (PERSONNEL & TIME)",
                fontBold, fontSizeHeader),
            pw.Table(
                border:
                    pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                children: [
                  pw.TableRow(
                      decoration:
                          const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        _buildCell("Hạng mục", fontBold, fontSizeText,
                            align: pw.TextAlign.center),
                        _buildCell("BẮT ĐẦU (START)", fontBold, fontSizeText,
                            align: pw.TextAlign.center),
                        _buildCell("KẾT THÚC (FINISH)", fontBold, fontSizeText,
                            align: pw.TextAlign.center),
                      ]),
                  pw.TableRow(children: [
                    _buildCell("Thời gian", font, fontSizeText),
                    _buildCell(
                        ticket.timeIn.replaceAll('T', ' ').substring(0, 16),
                        font,
                        fontSizeText,
                        align: pw.TextAlign.center),
                    _buildCell(
                        ticket.timeOut != null
                            ? ticket.timeOut!
                                .replaceAll('T', ' ')
                                .substring(0, 16)
                            : "-",
                        font,
                        fontSizeText,
                        align: pw.TextAlign.center),
                  ]),
                  pw.TableRow(children: [
                    _buildCell("Ca làm việc", font, fontSizeText),
                    _buildCell(shiftIn, fontBold, fontSizeText,
                        align: pw.TextAlign.center),
                    _buildCell(shiftOut, fontBold, fontSizeText,
                        align: pw.TextAlign.center),
                  ]),
                  pw.TableRow(children: [
                    _buildCell("Nhân viên", font, fontSizeText),
                    _buildCell(ticket.employeeInName ?? "-", font, fontSizeText,
                        align: pw.TextAlign.center),
                    _buildCell(
                        ticket.employeeOutName ?? "-", font, fontSizeText,
                        align: pw.TextAlign.center),
                  ]),
                ]),
            pw.SizedBox(height: 8),

            // --- 5. NGUYÊN LIỆU ---
            _buildSectionTitle(
                "4. NGUYÊN LIỆU SỬ DỤNG (MATERIALS)", fontBold, fontSizeHeader),
            pw.Table(
                border:
                    pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(1)
                },
                children: [
                  pw.TableRow(
                      decoration:
                          const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        _buildCell("Loại sợi", fontBold, fontSizeText),
                        _buildCell("Mã Lô (Batch No)", fontBold, fontSizeText),
                        _buildCell("SL (Kg)", fontBold, fontSizeText,
                            align: pw.TextAlign.right),
                      ]),
                  ...ticket.yarns.map((y) {
                    final batchInfo = y.internalBatchCode ?? "ID:${y.batchId}";
                    final supInfo = y.supplierShortName != null
                        ? " (${y.supplierShortName})"
                        : "";
                    return pw.TableRow(children: [
                      _buildCell(y.componentType, font, fontSizeText),
                      _buildCell("$batchInfo$supInfo", font, fontSizeText),
                      _buildCell("${y.quantity}", font, fontSizeText,
                          align: pw.TextAlign.right),
                    ]);
                  })
                ]),
            pw.SizedBox(height: 8),

            // --- 6. KẾT QUẢ ---
            _buildSectionTitle(
                "5. KẾT QUẢ (RESULTS)", fontBold, fontSizeHeader),
            pw.Container(
                padding: const pw.EdgeInsets.all(5),
                decoration: pw.BoxDecoration(
                    border:
                        pw.Border.all(color: PdfColors.grey400, width: 0.5)),
                child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      _buildResultItem(
                          "Gross Weight",
                          "${ticket.grossWeight} kg",
                          font,
                          fontBold,
                          fontSizeText,
                          fontSizeSmall),
                      _buildResultItem("Net Weight", "${ticket.netWeight} kg",
                          font, fontBold, fontSizeText, fontSizeSmall),
                      _buildResultItem("Length", "${ticket.lengthMeters} m",
                          font, fontBold, fontSizeText, fontSizeSmall),
                      _buildResultItem("Splice", "${ticket.numberOfKnots}",
                          font, fontBold, fontSizeText, fontSizeSmall),
                    ])),
            pw.SizedBox(height: 8),

            // --- 7. LỊCH SỬ QC ---
            if (inspections.isNotEmpty) ...[
              _buildSectionTitle("6. LỊCH SỬ KIỂM TRA (INSPECTION HISTORY)",
                  fontBold, fontSizeHeader),
              pw.Table(
                  border:
                      pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1.5),
                    1: const pw.FlexColumnWidth(1.2),
                    2: const pw.FlexColumnWidth(5.3),
                  },
                  children: [
                    pw.TableRow(
                        decoration:
                            const pw.BoxDecoration(color: PdfColors.grey200),
                        children: [
                          _buildCell("Thời gian/QC", fontBold, fontSizeText),
                          _buildCell("Công đoạn", fontBold, fontSizeText),
                          _buildCell("Thông số chi tiết (Specifications)",
                              fontBold, fontSizeText),
                        ]),
                    ...inspections.map((i) {
                      final time = i.inspectionTime.length > 16
                          ? i.inspectionTime.substring(11, 16)
                          : i.inspectionTime;

                      final List<String> details = [];
                      if (i.widthMm > 0) details.add("Width: ${i.widthMm}mm");
                      if (i.thicknessMm > 0) {
                        details.add("Thickness: ${i.thicknessMm}mm");
                      }
                      if (i.weftDensity > 0) {
                        details.add("Density: ${i.weftDensity}(pick/10cm)");
                      }
                      if (i.tensionDan > 0) {
                        details.add("Tension: ${i.tensionDan}N");
                      }
                      if (i.weightGm > 0) details.add("Weight: ${i.weightGm}g");
                      if (i.bowing > 0) details.add("Bowing: ${i.bowing}%");

                      final specsString = details.join("  |  ");

                      return pw.TableRow(children: [
                        _buildCell("$time\n${i.employeeName ?? '-'}", font,
                            fontSizeText),
                        _buildCell(i.stageName, font, fontSizeText),
                        _buildCell(specsString, font, fontSizeText),
                      ]);
                    })
                  ])
            ],

            pw.SizedBox(height: 10),
            // --- FOOTER ---
            pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("In lúc: $nowStr",
                      style: pw.TextStyle(
                          font: font, fontSize: 7, color: PdfColors.grey)),
                  pw.Column(children: [
                    pw.Text("Xác nhận của Trưởng ca",
                        style: pw.TextStyle(
                            font: fontBold, fontSize: fontSizeText)),
                    pw.SizedBox(height: 25),
                    pw.Text("_______________________",
                        style:
                            pw.TextStyle(font: font, fontSize: fontSizeText)),
                  ])
                ])
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'FullTicket-${ticket.code}',
    );
  }

  static pw.Widget _buildSectionTitle(
      String title, pw.Font fontBold, double fontSize) {
    return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Text(title,
            style: pw.TextStyle(
                font: fontBold, fontSize: fontSize, color: PdfColors.blue900)));
  }

  static pw.TableRow _buildRowPair(
      String label1,
      String value1,
      String label2,
      String value2,
      pw.Font font,
      pw.Font fontBold,
      double fontSizeText,
      double fontSizeLabel) {
    return pw.TableRow(children: [
      _buildCell(label1, font, fontSizeLabel, color: PdfColors.grey100),
      _buildCell(value1, fontBold, fontSizeText),
      _buildCell(label2, font, fontSizeLabel, color: PdfColors.grey100),
      _buildCell(value2, fontBold, fontSizeText),
    ]);
  }

  static pw.Widget _buildCell(String text, pw.Font font, double fontSize,
      {pw.TextAlign align = pw.TextAlign.left, PdfColor? color}) {
    return pw.Container(
      color: color,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Text(text,
          style: pw.TextStyle(font: font, fontSize: fontSize),
          textAlign: align),
    );
  }

  static pw.Widget _buildSpecItem(String label, String value, pw.Font font,
      pw.Font fontBold, double fontSizeText, double fontSizeLabel) {
    return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  font: font,
                  fontSize: fontSizeLabel,
                  color: PdfColors.grey600)),
          pw.Text(value,
              style: pw.TextStyle(font: fontBold, fontSize: fontSizeText)),
        ]);
  }

  static pw.Widget _buildResultItem(String label, String value, pw.Font font,
      pw.Font fontBold, double fontSizeText, double fontSizeLabel) {
    return pw.Column(children: [
      pw.Text(label,
          style: pw.TextStyle(
              font: font, fontSize: fontSizeLabel, color: PdfColors.grey700)),
      pw.Text(value,
          style: pw.TextStyle(
              font: fontBold,
              fontSize: fontSizeText + 1,
              color: PdfColors.black)),
    ]);
  }
}
