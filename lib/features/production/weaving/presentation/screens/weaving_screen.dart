import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:production_app_frontend/features/inventory/basket/doamain/baket_model.dart';
import 'package:production_app_frontend/features/inventory/basket/presentation/bloc/baket_cubit.dart';
import 'package:production_app_frontend/features/production/weaving/presentation/screens/weaving_inspection_dialog.dart';
import 'package:production_app_frontend/l10n/app_localizations.dart';
import 'package:production_app_frontend/core/widgets/responsive_layout.dart';

import '../../domain/weaving_model.dart';
import '../bloc/weaving_cubit.dart';

// Import các Feature liên quan (Model & Cubit)
import 'package:production_app_frontend/features/inventory/product/domain/product_model.dart';
import 'package:production_app_frontend/features/inventory/product/presentation/bloc/product_cubit.dart';
import 'package:production_app_frontend/features/production/machine/presentation/bloc/machine_cubit.dart';
import 'package:production_app_frontend/features/production/machine/domain/machine_model.dart';
import 'package:production_app_frontend/features/inventory/yarn_lot/presentation/bloc/yarn_lot_cubit.dart';
import 'package:production_app_frontend/features/inventory/yarn_lot/domain/yarn_lot_model.dart';
import 'package:production_app_frontend/features/production/standard/presentation/bloc/standard_cubit.dart';
import 'package:production_app_frontend/features/production/standard/domain/standard_model.dart';
import 'package:production_app_frontend/features/hr/employee/presentation/bloc/employee_cubit.dart';
import 'package:production_app_frontend/features/hr/employee/domain/employee_model.dart';

class WeavingScreen extends StatefulWidget {
  const WeavingScreen({super.key});

  @override
  State<WeavingScreen> createState() => _WeavingScreenState();
}

class _WeavingScreenState extends State<WeavingScreen> {
  final Color _primaryColor = const Color(0xFF003366);
  final Color _bgLight = const Color(0xFFF5F7FA);
  
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  void _loadAllData() {
    context.read<WeavingCubit>().loadTickets();
    context.read<ProductCubit>().loadProducts();
    context.read<MachineCubit>().loadMachines();
    context.read<BasketCubit>().loadBaskets();
    context.read<YarnLotCubit>().loadYarnLots();
    context.read<StandardCubit>().loadStandards();
    context.read<EmployeeCubit>().loadEmployees();
  }

  // Lọc phiếu theo ngày
  List<WeavingTicket> _filterTicketsByDate(List<WeavingTicket> tickets) {
    final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 0, 0, 0);
    final endOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);

    return tickets.where((t) {
      try {
        final timeIn = DateTime.parse(t.timeIn);
        final timeOut = t.timeOut != null ? DateTime.parse(t.timeOut!) : null;
        // Phiếu được coi là active trong ngày nếu nó bắt đầu trước khi ngày kết thúc 
        // và (chưa kết thúc HOẶC kết thúc sau khi ngày bắt đầu)
        bool startedBeforeEnd = timeIn.isBefore(endOfDay);
        bool notEndedOrEndedAfterStart = timeOut == null || timeOut.isAfter(startOfDay);
        return startedBeforeEnd && notEndedOrEndedAfterStart;
      } catch (e) {
        return false;
      }
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
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: _bgLight,
      body: BlocBuilder<WeavingCubit, WeavingState>(
        builder: (context, state) {
          if (state is WeavingLoading) return Center(child: CircularProgressIndicator(color: _primaryColor));
          if (state is WeavingError) {
             return Center(child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 Text("Error: ${state.message}", style: const TextStyle(color: Colors.red)),
                 TextButton(onPressed: _loadAllData, child: const Text("Retry"))
               ],
             ));
          }
          
          if (state is WeavingLoaded) {
            final filteredTickets = _filterTicketsByDate(state.tickets);

            if (!isDesktop) {
              // --- MOBILE VIEW ---
              return Column(
                children: [
                   _buildHeader(l10n, isDesktop),
                   Expanded(
                     child: filteredTickets.isEmpty
                      ? _buildEmptyState(l10n)
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: filteredTickets.length,
                          separatorBuilder: (_,__) => const SizedBox(height: 12),
                          itemBuilder: (context, index) => _buildTicketCardMobile(filteredTickets[index], l10n),
                        ),
                   ),
                ],
              );
            }

            // --- DESKTOP VIEW (SPLIT) ---
            return Row(
              children: [
                // LEFT PANEL: LIST TICKETS (40%)
                Expanded(
                  flex: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(right: BorderSide(color: Colors.grey.shade300))
                    ),
                    child: Column(
                      children: [
                        _buildHeader(l10n, isDesktop),
                        Expanded(
                          child: filteredTickets.isEmpty 
                            ? _buildEmptyState(l10n)
                            : ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: filteredTickets.length,
                            separatorBuilder: (_,__) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final ticket = filteredTickets[index];
                              final isSelected = state.selectedTicket?.id == ticket.id;
                              return _buildTicketCardDesktop(ticket, isSelected,l10n);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // RIGHT PANEL: DETAILS & INSPECTIONS (60%)
                Expanded(
                  flex: 6,
                  child: state.selectedTicket == null 
                    ? Center(child: Text(l10n.noTicketSelected, style: TextStyle(color: Colors.grey.shade500, fontSize: 16)))
                    : _buildDetailPanel(state.selectedTicket!, state.inspections, l10n),
                ),
              ],
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  // --- WIDGETS CHUNG ---

  Widget _buildHeader(AppLocalizations l10n, bool isDesktop) {
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
                  Icon(Icons.receipt_long, color: _primaryColor, size: 28),
                  const SizedBox(width: 8),
                  Text(l10n.weavingTicketTitle, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryColor)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, size: 32), 
                color: _primaryColor, 
                onPressed: () => _showAddEditDialog(context, null, l10n),
                tooltip: l10n.addTicket,
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8)
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: isDesktop ? MainAxisSize.min : MainAxisSize.max,
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text("${l10n.workDate}: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_list_off, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(l10n.noTicketsFoundForThisDate, style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  // --- CARD & COLORS ---

  // Tạo màu nền dựa trên ID máy để dễ phân biệt các máy khác nhau
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

  Widget _buildTicketCardDesktop(WeavingTicket ticket, bool isSelected, AppLocalizations l10n) {
    bool isRunning = ticket.timeOut == null;
    return Card(
      elevation: isSelected ? 4 : 0,
      // Dùng màu máy làm nền, nếu chọn thì đậm hơn hoặc có viền
      color: isSelected ? Colors.white : _getMachineColor(ticket.machineId),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected ? BorderSide(color: _primaryColor, width: 2) : BorderSide.none,
      ),
      child: ListTile(
        onTap: () => context.read<WeavingCubit>().selectTicket(ticket),
        leading: CircleAvatar(
          backgroundColor: isRunning ? Colors.green : Colors.grey,
          radius: 12,
          child: Icon(isRunning ? Icons.play_arrow : Icons.stop, size: 14, color: Colors.white),
        ),
        title: Text(ticket.code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Row(
          children: [
            _MachineInfo(id: ticket.machineId, line: ticket.machineLine),
            const SizedBox(width: 8),
            Text("• ${l10n.basketTitleVS2}: ${ticket.basketCode ?? '-'}", style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          ],
        ),
        trailing: isRunning 
          ? const Icon(Icons.keyboard_arrow_right, color: Colors.grey)
          : const Text("DONE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
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
                  Text(ticket.code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isRunning ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(4)
                    ),
                    child: Text(isRunning ? "RUNNING" : "FINISHED", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.precision_manufacturing, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  _MachineInfo(id: ticket.machineId, line: ticket.machineLine),
                  const SizedBox(width: 16),
                  const Icon(Icons.shopping_basket, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(ticket.basketCode ?? l10n.noBasket),
                ],
              ),
              const SizedBox(height: 8),
              _ProductInfo(id: ticket.productId),
            ],
          ),
        ),
      ),
    );
  }

  // --- DETAIL PANEL (DESKTOP) ---
  Widget _buildDetailPanel(WeavingTicket ticket, List<WeavingInspection> inspections, AppLocalizations l10n) {
    return Container(
      color: _bgLight,
      child: Column(
        children: [
          // Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${l10n.ticketCode} :${ticket.code}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _primaryColor)),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_task, size: 18),
                      label: Text(l10n.newInspection),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      onPressed: () {
                         showDialog(context: context, builder: (ctx) => WeavingInspectionDialog(ticket: ticket));
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => _showAddEditDialog(context, ticket, l10n)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(ticket, l10n)),
                  ],
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Cards
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildInfoCard(l10n.productionInfo, [
                        _rowInfo(l10n.basketTitleVS2, _ProductInfo(id: ticket.productId)),
                        _rowInfo(l10n.standardTitle, _StandardInfo(id: ticket.standardId)),
                        _rowInfo(l10n.machineTitle, _MachineInfo(id: ticket.machineId, line: ticket.machineLine)),
                      ]),
                      _buildInfoCard(l10n.materialTitle, [
                         _rowInfo(l10n.yarnLotTitle, _YarnLotInfo(id: ticket.yarnLotId)),
                         _rowInfo(l10n.loadDate, Text(ticket.yarnLoadDate)),
                         _rowInfo(l10n.basketTitleVS2, Text("${ticket.basketCode}")),
                         _rowInfo(l10n.tage, Text("${ticket.tareWeight ?? 0} kg")),
                      ]),
                      _buildInfoCard(l10n.timeAndPersonnel, [
                         _rowInfo(l10n.timeIn, Text(_formatTime(ticket.timeIn))),
                         _rowInfo(l10n.empIn, _EmployeeInfo(id: ticket.employeeInId ?? 0)),
                         _rowInfo(l10n.timeOut, Text(ticket.timeOut != null ? _formatTime(ticket.timeOut!) : "--:--")),
                         _rowInfo(l10n.empOut, ticket.employeeOutId != null ? _EmployeeInfo(id: ticket.employeeOutId!) : const Text("-")),
                      ]),
                      _buildInfoCard(l10n.output, [
                         _rowInfo(l10n.gross, Text("${ticket.grossWeight} kg")),
                         _rowInfo(l10n.netWeight, Text("${ticket.netWeight} kg", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                         _rowInfo(l10n.length, Text("${ticket.lengthMeters} m")),
                         _rowInfo(l10n.knots, Text("${ticket.numberOfKnots}")),
                      ]),
                    ],
                  ),

                  const SizedBox(height: 32),
                  Text(l10n.inspectionHistory, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                  const SizedBox(height: 12),
                  
                  // Inspection List
                  if (inspections.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      width: double.infinity,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                      child: Center(child: Text(l10n.noInspectionsRecorded, style: TextStyle(color: Colors.grey.shade400))),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: inspections.length,
                      itemBuilder: (context, index) => _buildInspectionItem(inspections[index], context,l10n),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      width: 300, // Fixed width for consistent grid
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900, fontSize: 13)),
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
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          content,
        ],
      ),
    );
  }

  Widget _buildInspectionItem(WeavingInspection item, BuildContext context,AppLocalizations l10n) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(backgroundColor: Colors.blue.shade50, radius: 12, child: Text("QC", style: TextStyle(fontSize: 10, color: Colors.blue.shade800))),
                    const SizedBox(width: 8),
                    Text(item.stageName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Text(_formatTime(item.inspectionTime), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
                Text("${item.employeeName ?? ''} (${item.shiftName ?? ''})", style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
              ],
            ),
            const Divider(),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                 _specBadge("${l10n.width}: ${item.widthMm} mm"),
                 _specBadge("${l10n.density}: ${item.weftDensity} pick/10cm"),
                 _specBadge("${l10n.tension}: ${item.tensionDan} daN"),
                 _specBadge("${l10n.thickness}: ${item.thicknessMm}"),
                 _specBadge("${l10n.weight}: ${item.weightGm} g/m"),
                 _specBadge("${l10n.bow}: ${item.bowing}"),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _specBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  // --- MOBILE SHEET ---
  void _showMobileDetailSheet(BuildContext context, WeavingTicket ticket, AppLocalizations l10n) {
    // Gọi API lấy inspections trước khi hiện
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
                // Wait for inspections
                List<WeavingInspection> inspections = [];
                if (state is WeavingLoaded && state.selectedTicket?.id == ticket.id) {
                   inspections = state.inspections;
                }

                return SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                       // Handle bar
                       Center(child: Container(margin: const EdgeInsets.only(top: 12, bottom: 8), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                       // Reuse _buildDetailPanel logic but adapted
                       Padding(
                         padding: const EdgeInsets.all(16),
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                              Text("${l10n.ticketCode}:${ticket.code}", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _primaryColor)),
                              const SizedBox(height: 16),
                              _buildInfoCard(l10n.productionInfo, [
                                _rowInfo(l10n.productTitle, _ProductInfo(id: ticket.productId)),
                               _rowInfo(l10n.machineTitle, _MachineInfo(id: ticket.machineId, line: ticket.machineLine)),
                              ]),
                              // ... Các thông tin khác tương tự
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add_task),
                                label: Text(l10n.newInspection),
                                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 45)),
                                onPressed: () {
                                   Navigator.pop(ctx);
                                   showDialog(context: context, builder: (_) => WeavingInspectionDialog(ticket: ticket));
                                },
                              ),
                              const SizedBox(height: 20),
                              Text(l10n.inspectionHistory, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              ...inspections.map((i) => _buildInspectionItem(i, context,l10n)),
                           ],
                         ),
                       )
                    ],
                  ),
                );
              }
            ),
          );
        },
      ),
    );
  }

  // --- CRUD DIALOG (THÊM / SỬA) ---
  void _showAddEditDialog(BuildContext context, WeavingTicket? ticket, AppLocalizations l10n) {
    // Controllers
    final codeCtrl = TextEditingController(text: ticket?.code ?? "TKT-${DateTime.now().millisecondsSinceEpoch}");
    final lineCtrl = TextEditingController(text: ticket?.machineLine ?? "1");
    final dateCtrl = TextEditingController(text: ticket?.yarnLoadDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now()));
    
    // Result Fields (Cho phép nhập nếu sửa)
    final grossCtrl = TextEditingController(text: ticket?.grossWeight.toString() ?? "0");
    final netCtrl = TextEditingController(text: ticket?.netWeight.toString() ?? "0");
    final lenCtrl = TextEditingController(text: ticket?.lengthMeters.toString() ?? "0");
    final knotCtrl = TextEditingController(text: ticket?.numberOfKnots.toString() ?? "0");

    // Dropdown Values
    int? selectedProductId = ticket?.productId;
    int? selectedStandardId = ticket?.standardId;
    int? selectedMachineId = ticket?.machineId;
    int? selectedBasketId = ticket?.basketId;
    int? selectedYarnLotId = ticket?.yarnLotId;
    int? selectedEmpInId = ticket?.employeeInId;

    // Auto select first options if new (Logic đơn giản)
    if (ticket == null) {
      final pState = context.read<ProductCubit>().state;
      if (pState is ProductLoaded && pState.products.isNotEmpty) selectedProductId = pState.products.first.id;
    }

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ticket == null ? l10n.addTicket : l10n.editTicket),
        content: SizedBox(
          width: 800,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group 1: General
                  Text(l10n.generalInfo, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: codeCtrl, decoration: _inputDeco("Code"))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: BlocBuilder<ProductCubit, ProductState>(
                          builder: (context, state) {
                             List<Product> items = (state is ProductLoaded) ? state.products : [];
                             return DropdownButtonFormField<int>(
                               value: selectedProductId,
                               decoration: _inputDeco(l10n.productTitle),
                               items: items.map((e) => DropdownMenuItem(value: e.id, child: Text(e.itemCode))).toList(),
                               onChanged: (v) => selectedProductId = v,
                             );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: BlocBuilder<StandardCubit, StandardState>(
                          builder: (context, state) {
                             List<Standard> items = (state is StandardLoaded) ? state.standards : [];
                             return DropdownButtonFormField<int>(
                               value: selectedStandardId,
                               decoration: _inputDeco(l10n.standardTitle),
                               items: items.map((e) => DropdownMenuItem(value: e.id, child: Text("STD-${e.id}"))).toList(),
                               onChanged: (v) => selectedStandardId = v,
                             );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Group 2: Machine & Yarn
                  Text(l10n.machineAndMaterial, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                         child: BlocBuilder<MachineCubit, MachineState>(
                          builder: (context, state) {
                             List<Machine> items = (state is MachineLoaded) ? state.machines : [];
                             return DropdownButtonFormField<int>(
                               value: selectedMachineId,
                               decoration: _inputDeco(l10n.machineTitle),
                               items: items.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))).toList(),
                               onChanged: (v) => selectedMachineId = v,
                             );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: TextFormField(controller: lineCtrl, decoration: _inputDeco("Line (1/2)"))),
                      const SizedBox(width: 12),
                      Expanded(
                         child: BlocBuilder<BasketCubit, BasketState>(
                          builder: (context, state) {
                             List<Basket> items = (state is BasketLoaded) ? state.baskets : [];
                             return DropdownButtonFormField<int>(
                               value: selectedBasketId,
                               decoration: _inputDeco(l10n.basketTitleVS2),
                               items: items.map((e) => DropdownMenuItem(value: e.id, child: Text(e.code))).toList(),
                               onChanged: (v) => selectedBasketId = v,
                             );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                       Expanded(
                         child: BlocBuilder<YarnLotCubit, YarnLotState>(
                          builder: (context, state) {
                             List<YarnLot> items = (state is YarnLotLoaded) ? state.yarnLots : [];
                             return DropdownButtonFormField<int>(
                               value: selectedYarnLotId,
                               decoration: _inputDeco(l10n.yarnLotTitle),
                               items: items.map((e) => DropdownMenuItem(value: e.id, child: Text(e.lotCode))).toList(),
                               onChanged: (v) => selectedYarnLotId = v,
                             );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: TextFormField(controller: dateCtrl, decoration: _inputDeco(l10n.loadDate))),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Group 3: Operator
                  Text(l10n.personnel, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  BlocBuilder<EmployeeCubit, EmployeeState>(
                    builder: (context, state) {
                       List<Employee> items = (state is EmployeeLoaded) ? state.employees : [];
                       return DropdownButtonFormField<int>(
                         value: selectedEmpInId,
                         decoration: _inputDeco(l10n.empIn),
                         items: items.map((e) => DropdownMenuItem(value: e.id, child: Text(e.fullName))).toList(),
                         onChanged: (v) => selectedEmpInId = v,
                       );
                    },
                  ),
                  
                  // Chỉ hiện các trường kết quả khi Edit
                  if (ticket != null) ...[
                    const SizedBox(height: 16),
                    Text(l10n.resultsUpdateOnly, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: TextFormField(controller: grossCtrl, decoration: _inputDeco("${l10n.grossWeight} Kg"))),
                        const SizedBox(width: 12),
                        Expanded(child: TextFormField(controller: netCtrl, decoration: _inputDeco("${l10n.netWeight} Kg"))),
                        const SizedBox(width: 12),
                        Expanded(child: TextFormField(controller: lenCtrl, decoration: _inputDeco("${l10n.length} (m)"))),
                      ],
                    )
                  ]
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
               // Validate & Save
               if (formKey.currentState!.validate()) {
                  // Giả sử các ID đều đã chọn (thực tế cần check null)
                  final newTicket = WeavingTicket(
                    id: ticket?.id ?? 0,
                    code: codeCtrl.text,
                    productId: selectedProductId ?? 0,
                    standardId: selectedStandardId ?? 0,
                    machineId: selectedMachineId ?? 0,
                    machineLine: lineCtrl.text,
                    yarnLoadDate: dateCtrl.text,
                    yarnLotId: selectedYarnLotId ?? 0,
                    basketId: selectedBasketId ?? 0,
                    timeIn: ticket?.timeIn ?? DateTime.now().toIso8601String(),
                    employeeInId: selectedEmpInId ?? 0,
                    
                    // Fields update
                    grossWeight: double.tryParse(grossCtrl.text) ?? 0,
                    netWeight: double.tryParse(netCtrl.text) ?? 0,
                    lengthMeters: double.tryParse(lenCtrl.text) ?? 0,
                    numberOfKnots: int.tryParse(knotCtrl.text) ?? 0,
                  );
                  
                  context.read<WeavingCubit>().saveTicket(ticket: newTicket, isEdit: ticket != null);
                  Navigator.pop(ctx);
               }
            },
            child: Text(l10n.save),
          )
        ],
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
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
  
  InputDecoration _inputDeco(String label) {
    return InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true);
  }

  String _formatTime(String iso) {
    try {
      return DateFormat('HH:mm').format(DateTime.parse(iso));
    } catch (e) { return iso; }
  }
}

// --- WIDGET BADGES (Tái sử dụng) ---
// (Copy nguyên phần Badge từ các câu trả lời trước, không thay đổi)
class _ProductInfo extends StatelessWidget {
  final int id; const _ProductInfo({required this.id});
  @override Widget build(BuildContext context) {
    return BlocBuilder<ProductCubit, ProductState>(builder: (c, s) => Text(s is ProductLoaded ? (s.products.where((e)=>e.id==id).firstOrNull?.itemCode ?? "$id") : "$id"));
  }
}
class _StandardInfo extends StatelessWidget {
  final int id; const _StandardInfo({required this.id});
  @override Widget build(BuildContext context) => BlocBuilder<StandardCubit, StandardState>(builder: (c,s)=>Text(s is StandardLoaded ? "STD-$id" : "$id"));
}
class _MachineInfo extends StatelessWidget {
  final int id; final String line; const _MachineInfo({required this.id, required this.line});
  @override Widget build(BuildContext context) => BlocBuilder<MachineCubit, MachineState>(builder: (c,s) {
    String t = "Mac-$id Line $line";
    if (s is MachineLoaded) { final m = s.machines.where((e)=>e.id==id).firstOrNull; if(m!=null) t = "${m.name} - Line $line"; }
    return Text(t);
  });
}
class _YarnLotInfo extends StatelessWidget {
  final int id; const _YarnLotInfo({required this.id});
  @override Widget build(BuildContext context) => BlocBuilder<YarnLotCubit, YarnLotState>(builder: (c,s)=>Text(s is YarnLotLoaded ? (s.yarnLots.where((e)=>e.id==id).firstOrNull?.lotCode ?? "$id") : "$id"));
}
class _EmployeeInfo extends StatelessWidget {
  final int id; const _EmployeeInfo({required this.id});
  @override Widget build(BuildContext context) => BlocBuilder<EmployeeCubit, EmployeeState>(builder: (c,s)=>Text(s is EmployeeLoaded ? (s.employees.where((e)=>e.id==id).firstOrNull?.fullName ?? "$id") : "$id"));
}