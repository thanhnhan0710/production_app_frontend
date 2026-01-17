import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:production_app_frontend/core/widgets/responsive_layout.dart';
import 'package:production_app_frontend/features/hr/work_schedule/presentation/bloc/work_schedule_cubit.dart';
import 'package:production_app_frontend/features/inventory/basket/doamain/basket_model.dart';
import 'package:production_app_frontend/features/inventory/basket/presentation/bloc/baket_cubit.dart';
import 'package:production_app_frontend/l10n/app_localizations.dart';

import '../../domain/weaving_model.dart';
import '../bloc/weaving_cubit.dart';
import 'weaving_inspection_dialog.dart';

// Import Feature khác
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
import 'package:production_app_frontend/features/inventory/dye_color/presentation/bloc/dye_color_cubit.dart';

class WeavingScreen extends StatefulWidget {
  const WeavingScreen({super.key});

  @override
  State<WeavingScreen> createState() => _WeavingScreenState();
}

class _WeavingScreenState extends State<WeavingScreen> {
  final Color _primaryColor = const Color(0xFF003366);
  final Color _bgLight = const Color(0xFFF5F7FA);
  
  final TextEditingController _searchController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _searchKeyword = "";

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
    context.read<DyeColorCubit>().loadColors();
  }

  // Lọc phiếu theo ngày VÀ từ khóa tìm kiếm
  List<WeavingTicket> _filterTickets(List<WeavingTicket> tickets) {
    final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 0, 0, 0);
    final endOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);

    return tickets.where((t) {
      // 1. Lọc theo ngày
      bool dateMatch = false;
      try {
        final timeIn = DateTime.parse(t.timeIn);
        final timeOut = t.timeOut != null ? DateTime.parse(t.timeOut!) : null;
        bool startedBeforeEnd = timeIn.isBefore(endOfDay);
        bool notEndedOrEndedAfterStart = timeOut == null || timeOut.isAfter(startOfDay);
        dateMatch = startedBeforeEnd && notEndedOrEndedAfterStart;
      } catch (e) {
        dateMatch = false;
      }

      // 2. Lọc theo từ khóa (Mã phiếu, Line máy)
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
          
          // Xử lý lỗi nhưng vẫn cho phép reload
          if (state is WeavingError) {
             return Center(child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 Text("Error: ${state.message}", style: const TextStyle(color: Colors.red)),
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
                          separatorBuilder: (_,__) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                             final ticket = filteredTickets[index];
                             // Mobile list items
                             return _buildTicketCardMobile(ticket, l10n);
                          },
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
                    decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.shade300))),
                    child: Column(
                      children: [
                        _buildHeader(l10n),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: Colors.blue.shade50,
                          child: Text("Total: $total tickets", style: TextStyle(color: Colors.blue.shade800, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
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
                              return _buildTicketCardDesktop(ticket, isSelected);
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
      floatingActionButton: !isDesktop
        ? FloatingActionButton(
            backgroundColor: const Color(0xFFE65100),
            onPressed: () => _showAddEditDialog(context, null, l10n),
            child: const Icon(Icons.add, color: Colors.white),
          )
        : null,
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
                  Icon(Icons.receipt_long, color: _primaryColor, size: 28),
                  const SizedBox(width: 8),
                  Text(l10n.weavingTicketTitle, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryColor)),
                ],
              ),
              if (ResponsiveLayout.isDesktop(context))
                IconButton(
                  icon: const Icon(Icons.add_circle, size: 32), 
                  color: _primaryColor, 
                  onPressed: () => _showAddEditDialog(context, null, l10n),
                  tooltip: l10n.addTicket,
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Row chứa Date Picker & Search
          Row(
            children: [
              InkWell(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: Colors.grey.shade50, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(DateFormat('dd/MM').format(_selectedDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchKeyword = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Search Code / Line...",
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10)
                    ),
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
    return Center(child: Text("No tickets found", style: TextStyle(color: Colors.grey.shade500)));
  }

  // --- CARD & COLORS ---
  Color _getMachineColor(int machineId) {
    final colors = [
      Colors.blue.shade50, Colors.green.shade50, Colors.orange.shade50,
      Colors.purple.shade50, Colors.teal.shade50, Colors.pink.shade50,
    ];
    return colors[machineId % colors.length];
  }

  Widget _buildTicketCardDesktop(WeavingTicket ticket, bool isSelected) {
    bool isRunning = ticket.timeOut == null;
    return Card(
      elevation: isSelected ? 4 : 0,
      color: isSelected ? Colors.white : _getMachineColor(ticket.machineId),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: isSelected ? BorderSide(color: _primaryColor, width: 2) : BorderSide.none),
      child: ListTile(
        onTap: () => context.read<WeavingCubit>().selectTicket(ticket),
        leading: CircleAvatar(
          backgroundColor: isRunning ? Colors.green : Colors.grey,
          radius: 12,
          child: Icon(isRunning ? Icons.play_arrow : Icons.stop, size: 14, color: Colors.white),
        ),
        title: Text(ticket.code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Row(
          children: [
            _MachineInfo(id: ticket.machineId, line: ticket.machineLine),
            const SizedBox(width: 8),
            Text("• ${ticket.basketCode ?? '-'}", style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
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
                  Text(ticket.basketCode ?? "No Basket"),
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
  // --- CHI TIẾT PHIẾU (HIỂN THỊ ĐẦY ĐỦ THÔNG TIN) ---
  Widget _buildDetailPanel(WeavingTicket ticket, List<WeavingInspection> inspections, AppLocalizations l10n) {
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
                Text("TICKET :${ticket.code}", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _primaryColor)),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_task, size: 16),
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
            const SizedBox(height: 24),
            
            // 2. Production Info Grid
            _buildInfoSection("Production Info", [
               _infoRow("", _ProductFullDetails(id: ticket.productId)),
               _infoRow("Machine", _MachineInfo(id: ticket.machineId, line: ticket.machineLine)),
            ]),
            
            // 3. Standard & Product Detail
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.assignment, size: 18, color: Colors.blue.shade800),
                        const SizedBox(width: 8),
                        Text("Product & Standard Specifications", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
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
              _infoRow("Yarn Lot", _YarnLotInfo(id: ticket.yarnLotId)),
              _infoRow("Load Date", Text(ticket.yarnLoadDate)),
              _infoRow("Basket", Text("${ticket.basketCode} (ID: ${ticket.basketId})")),
              _infoRow("Tare Weight", Text("${ticket.tareWeight ?? 0} kg")),
            ]),

            // [CẬP NHẬT] 5. Time & Personnel (Hiển thị chi tiết)
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Time & Personnel", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                    const Divider(),
                    const SizedBox(height: 8),
                    
                    // START (IN)
                   Row(
                      children: [
                        const Icon(Icons.login, size: 18, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(child: _infoRow("Start Time", Text(_formatDateTimeFull(ticket.timeIn)))),
                        
                        // [SỬA LỖI Ở ĐÂY]
                        // Dùng ticket.employeeInId và ticket.timeIn cho Operator In
                        Expanded(child: _infoRow("Operator In", 
                          ticket.employeeInId != null 
                            ? _EmployeeAndShiftInfo(
                                employeeId: ticket.employeeInId!, // Dùng employeeInId
                                dateTimeStr: ticket.timeIn        // Dùng timeIn (vì timeIn luôn có giá trị)
                              ) 
                            : const Text("-")
                        )),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        const Icon(Icons.logout, size: 18, color: Colors.red),
                        const SizedBox(width: 8),
                        
                        // Kiểm tra null an toàn cho timeOut
                        Expanded(child: _infoRow("Finish Time", Text(ticket.timeOut != null ? _formatDateTimeFull(ticket.timeOut!) : "---"))),
                        
                        // [SỬA LỖI Ở ĐÂY]
                        // Kiểm tra kỹ ticket.employeeOutId và ticket.timeOut trước khi dùng
                        Expanded(child: _infoRow("Operator Out", 
                          (ticket.employeeOutId != null && ticket.timeOut != null)
                            ? _EmployeeAndShiftInfo(
                                employeeId: ticket.employeeOutId!, 
                                dateTimeStr: ticket.timeOut!
                              ) 
                            : const Text("-") // Nếu chưa kết thúc thì hiện dấu gạch ngang
                        )),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 6. Results
            _buildInfoSection("Results", [
               _infoRow("Gross Weight", Text("${ticket.grossWeight} kg")),
               _infoRow("Net Weight", Text("${ticket.netWeight} kg", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
               _infoRow("Length", Text("${ticket.lengthMeters} m")),
               _infoRow("Splice", Text("${ticket.numberOfKnots}")),
            ]),

            const SizedBox(height: 24),
            
            // [CẬP NHẬT] 7. Inspection History (Hiển thị chi tiết từng lần)
            Text(l10n.inspectionHistory, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
            const SizedBox(height: 12),
            
            if (inspections.isEmpty)
              Container(
                height: 100,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text("No inspections recorded", style: TextStyle(color: Colors.grey.shade400))),
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
      width: 300, 
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
          Expanded(child: Align(alignment: Alignment.centerRight, child: content)),
        ],
      ),
    );
  }

   Widget _buildInspectionItem(WeavingInspection item, BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
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
                        backgroundColor: Colors.blue.shade50, radius: 14,
                        child: Text("QC", style: TextStyle(fontSize: 10, color: Colors.blue.shade900, fontWeight: FontWeight.bold)),
                     ),
                     const SizedBox(width: 8),
                     Text(item.stageName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                     const SizedBox(width: 8),
                     Text(_formatDateTimeFull(item.inspectionTime), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
                Text("${item.employeeName ?? ''} (${item.shiftName ?? ''})", style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
              ],
            ),
            const Divider(),
            // Hiển thị lưới thông số kiểm tra
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
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _infoRow(String label, Widget valueWidget) {
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          DefaultTextStyle(
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
            const Divider(),
            const SizedBox(height: 8),
            Wrap(spacing: 24, runSpacing: 12, children: children)
          ],
        ),
      ),
    );
  }


  // --- MOBILE SHEET (HIỂN THỊ CHI TIẾT TRÊN ĐIỆN THOẠI) ---
  void _showMobileDetailSheet(BuildContext context, WeavingTicket ticket, AppLocalizations l10n) {
    // Gọi API load inspection
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
                if (state is WeavingLoaded && state.selectedTicket?.id == ticket.id) {
                   inspections = state.inspections;
                }

                return SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                       Center(child: Container(margin: const EdgeInsets.only(top: 12, bottom: 8), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                       Padding(
                         padding: const EdgeInsets.all(16),
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Ticket #${ticket.code}", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _primaryColor)),
                                  IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () {
                                    Navigator.pop(ctx);
                                    _showAddEditDialog(context, ticket, l10n);
                                  }),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Mobile info cards
                              _buildInfoCard(l10n.productionInfo, [
                                _rowInfo(l10n.productTitle, _ProductInfo(id: ticket.productId)),
                                _rowInfo(l10n.machineTitle, _MachineInfo(id: ticket.machineId, line: ticket.machineLine)),
                              ]),
                              const SizedBox(height: 12),
                              // Standard
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                   Text("Standard", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                                   const SizedBox(height: 8),
                                   _StandardFullDetails(standardId: ticket.standardId)
                                ]),
                              ),
                              const SizedBox(height: 12),
                              _buildInfoCard(l10n.output, [
                                 _rowInfo("Gross", Text("${ticket.grossWeight} kg")),
                                 _rowInfo("Net", Text("${ticket.netWeight} kg")),
                              ]),
                              
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
                              ...inspections.map((i) => _buildInspectionItem(i, context)),
                              
                              const SizedBox(height: 20),
                              Center(child: TextButton.icon(onPressed: (){ 
                                Navigator.pop(ctx);
                                _confirmDelete(ticket, l10n);
                              }, icon: const Icon(Icons.delete, color: Colors.red), label: Text(l10n.deleteTicket, style: const TextStyle(color: Colors.red)))),
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
    final codeCtrl = TextEditingController(text: ticket?.code ?? "TKT-${DateTime.now().millisecondsSinceEpoch}");
    final lineCtrl = TextEditingController(text: ticket?.machineLine ?? "1");
    final dateCtrl = TextEditingController(text: ticket?.yarnLoadDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now()));
    
    final grossCtrl = TextEditingController(text: ticket?.grossWeight.toString() ?? "0");
    final netCtrl = TextEditingController(text: ticket?.netWeight.toString() ?? "0");
    final lenCtrl = TextEditingController(text: ticket?.lengthMeters.toString() ?? "0");
    final knotCtrl = TextEditingController(text: ticket?.numberOfKnots.toString() ?? "0");

    int? selectedProductId = ticket?.productId;
    int? selectedStandardId = ticket?.standardId;
    int? selectedMachineId = ticket?.machineId;
    int? selectedBasketId = ticket?.basketId;
    int? selectedYarnLotId = ticket?.yarnLotId;
    int? selectedEmpInId = ticket?.employeeInId;

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
                  const Text("General Info", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(children: [
                      Expanded(child: TextFormField(controller: codeCtrl, decoration: _inputDeco(l10n.ticketCode))),
                      const SizedBox(width: 12),
                      Expanded(child: BlocBuilder<ProductCubit, ProductState>(builder: (c, s) {
                        List<Product> items = (s is ProductLoaded) ? s.products : [];
                        return DropdownButtonFormField<int>(
                          value: selectedProductId, decoration: _inputDeco(l10n.productTitle),
                          items: items.map((e) => DropdownMenuItem(value: e.id, child: Text(e.itemCode))).toList(),
                          onChanged: (v) => selectedProductId = v,
                        );
                      })),
                      const SizedBox(width: 12),
                      Expanded(child: BlocBuilder<StandardCubit, StandardState>(builder: (c, s) {
                        List<Standard> items = (s is StandardLoaded) ? s.standards : [];
                        return DropdownButtonFormField<int>(
                          value: selectedStandardId, decoration: _inputDeco(l10n.standardTitle),
                          items: items.map((e) => DropdownMenuItem(value: e.id, child: Text("STD-${e.id}"))).toList(),
                          onChanged: (v) => selectedStandardId = v,
                        );
                      })),
                  ]),
                  const SizedBox(height: 16),
                  
                  Text(l10n.machineAndMaterial, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: BlocBuilder<MachineCubit, MachineState>(builder: (c, s) {
                        List<Machine> items = (s is MachineLoaded) ? s.machines : [];
                        return DropdownButtonFormField<int>(
                          value: selectedMachineId, decoration: _inputDeco(l10n.machineTitle),
                          items: items.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))).toList(),
                          onChanged: (v) => selectedMachineId = v,
                        );
                      })),
                      const SizedBox(width: 12),
                      Expanded(child: TextFormField(controller: lineCtrl, decoration: _inputDeco("Line"))),
                      const SizedBox(width: 12),
                      Expanded(child: BlocBuilder<BasketCubit, BasketState>(builder: (c, s) {
                        List<Basket> items = (s is BasketLoaded) ? s.baskets : [];
                        return DropdownButtonFormField<int>(
                          value: selectedBasketId, decoration: _inputDeco(l10n.basketTitleVS2),
                          items: items.map((e) => DropdownMenuItem(value: e.id, child: Text(e.code))).toList(),
                          onChanged: (v) => selectedBasketId = v,
                        );
                      })),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                       Expanded(child: BlocBuilder<YarnLotCubit, YarnLotState>(builder: (c, s) {
                        List<YarnLot> items = (s is YarnLotLoaded) ? s.yarnLots : [];
                        return DropdownButtonFormField<int>(
                          value: selectedYarnLotId, decoration: _inputDeco(l10n.yarnLotTitle),
                          items: items.map((e) => DropdownMenuItem(value: e.id, child: Text(e.lotCode))).toList(),
                          onChanged: (v) => selectedYarnLotId = v,
                        );
                      })),
                      const SizedBox(width: 12),
                      Expanded(child: TextFormField(controller: dateCtrl, decoration: _inputDeco(l10n.loadDate))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Text(l10n.timeAndPersonnel, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  BlocBuilder<EmployeeCubit, EmployeeState>(builder: (c, s) {
                     List<Employee> items = (s is EmployeeLoaded) ? s.employees : [];
                     return DropdownButtonFormField<int>(
                       value: selectedEmpInId, decoration: _inputDeco(l10n.empIn),
                       items: items.map((e) => DropdownMenuItem(value: e.id, child: Text(e.fullName))).toList(),
                       onChanged: (v) => selectedEmpInId = v,
                     );
                  }),
                  
                  if (ticket != null) ...[
                     const SizedBox(height: 16),
                     Text(l10n.output, style: const TextStyle(fontWeight: FontWeight.bold)),
                     const SizedBox(height: 8),
                     Row(children: [
                       Expanded(child: TextFormField(controller: grossCtrl, decoration: _inputDeco(l10n.gross))),
                       const SizedBox(width: 12),
                       Expanded(child: TextFormField(controller: netCtrl, decoration: _inputDeco(l10n.netWeight))),
                       const SizedBox(width: 12),
                       Expanded(child: TextFormField(controller: lenCtrl, decoration: _inputDeco(l10n.length))),
                       const SizedBox(width: 12),
                       Expanded(child: TextFormField(controller: knotCtrl, decoration: _inputDeco(l10n.splice))),
                     ]),
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
               if (formKey.currentState!.validate()) {
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
  
}

// ==========================================
// CÁC WIDGET BADGE
// ==========================================

class _ProductInfo extends StatelessWidget {
  final int id; const _ProductInfo({required this.id});
  @override Widget build(BuildContext context) {
    return BlocBuilder<ProductCubit, ProductState>(builder: (c, s) => Text(s is ProductLoaded ? (s.products.where((e)=>e.id==id).firstOrNull?.itemCode ?? "$id") : "$id", style: const TextStyle(fontWeight: FontWeight.bold)));
  }
}

// [MỚI] Widget hiển thị đầy đủ thông tin Sản phẩm (Ảnh + Mã + Tên)
// ignore: unused_element
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
              // Ảnh sản phẩm
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
                          errorBuilder: (ctx, err, stack) => const Icon(Icons.image_not_supported, color: Colors.grey),
                        )
                      : const Icon(Icons.image, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 12),
              // Thông tin text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Product Code", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    Text(product.itemCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text(product.note, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ],
          );
        }
        return const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2));
      },
    );
  }
}


// [CẬP NHẬT] Widget hiển thị đầy đủ thông số Standard + Hình ảnh Sản phẩm
class _StandardFullDetails extends StatelessWidget {
  final int standardId;
  const _StandardFullDetails({required this.standardId});

  // Helper chuyển Hex
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
          final item = state.standards.where((s) => s.id == standardId).firstOrNull;
          if (item == null) return const Text("Standard info not loaded", style: TextStyle(color: Colors.grey));
          
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               // [THÔNG TIN CHI TIẾT]
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      // Specs Grid
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                           _specItem(Icons.straighten, "W", "${item.widthMm} mm"),
                           _specItem(Icons.line_weight, "T", "${item.thicknessMm} mm"),
                           _specItem(Icons.scale, "G/m", "${item.weightGm} g/m"),
                           _specItem(Icons.bolt, "Str", "${item.breakingStrength} daN", color: Colors.red.shade700),
                           _specItem(Icons.expand, "El", "${item.elongation} %", color: Colors.indigo),
                           _specItem(Icons.grid_on, "Den", "${item.weftDensity} pick/10cm"),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Color
                      Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 14, height: 14,
                                decoration: BoxDecoration(color: _hexToColor(item.colorHex), shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300)),
                              ),
                              const SizedBox(width: 6),
                              Text(item.colorName ?? "N/A", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              if (item.deltaE.isNotEmpty) ...[
                                 const SizedBox(width: 12),
                                 Text("ΔE: ${item.deltaE}", style: const TextStyle(fontSize: 12, color: Colors.purple, fontWeight: FontWeight.bold)),
                              ],
                              
                            ],
                          ),
                          const SizedBox(height: 8),
                              if (item.appearance.isNotEmpty)
                                        Text("Appr: ${item.appearance}", style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      )
                   ],
                 ),
               ),
            ],
          );
        }
        return const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2));
      },
    );
  }

  Widget _specItem(IconData icon, String label, String value, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade400),
        const SizedBox(width: 4),
        Text("$label: ", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color ?? Colors.black87)),
      ],
    );
  }
}

// ignore: unused_element
class _StandardInfo extends StatelessWidget {
  final int id; const _StandardInfo({required this.id});
  @override Widget build(BuildContext context) => BlocBuilder<StandardCubit, StandardState>(builder: (c,s)=>Text(s is StandardLoaded ? "STD-$id" : "$id", style: const TextStyle(fontWeight: FontWeight.bold)));
}

class _MachineInfo extends StatelessWidget {
  final int id; final String line; const _MachineInfo({required this.id, required this.line});
  @override Widget build(BuildContext context) => BlocBuilder<MachineCubit, MachineState>(builder: (c,s) {
    String t = "Mac-$id Line $line";
    if (s is MachineLoaded) { final m = s.machines.where((e)=>e.id==id).firstOrNull; if(m!=null) t = "${m.name} - Line $line"; }
    return Text(t, style: const TextStyle(fontWeight: FontWeight.bold));
  });
}

class _YarnLotInfo extends StatelessWidget {
  final int id; const _YarnLotInfo({required this.id});
  @override Widget build(BuildContext context) => BlocBuilder<YarnLotCubit, YarnLotState>(builder: (c,s)=>Text(s is YarnLotLoaded ? (s.yarnLots.where((e)=>e.id==id).firstOrNull?.lotCode ?? "$id") : "$id", style: const TextStyle(fontWeight: FontWeight.bold)));
}

// ignore: unused_element
class _EmployeeInfo extends StatelessWidget {
  final int id; const _EmployeeInfo({required this.id});
  @override Widget build(BuildContext context) => BlocBuilder<EmployeeCubit, EmployeeState>(builder: (c,s)=>Text(s is EmployeeLoaded ? (s.employees.where((e)=>e.id==id).firstOrNull?.fullName ?? "$id") : "$id", style: const TextStyle(fontWeight: FontWeight.bold)));
}
class _EmployeeAndShiftInfo extends StatelessWidget {
  final int employeeId;
  final String dateTimeStr; // Thời điểm làm việc để tra cứu lịch

  const _EmployeeAndShiftInfo({required this.employeeId, required this.dateTimeStr});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmployeeCubit, EmployeeState>(
      builder: (context, empState) {
        String empName = "ID: $employeeId";
        if (empState is EmployeeLoaded) {
          final e = empState.employees.where((x) => x.id == employeeId).firstOrNull;
          if (e != null) empName = e.fullName;
        }

        // Sau khi có tên nhân viên, tìm Ca làm việc
        return BlocBuilder<WorkScheduleCubit, WorkScheduleState>(
          builder: (context, scheduleState) {
            String shiftInfo = "";
            if (scheduleState is WorkScheduleLoaded) {
              try {
                // Parse ngày làm việc từ chuỗi thời gian (chỉ lấy yyyy-MM-dd)
                final date = DateTime.parse(dateTimeStr);
                final dateKey = DateFormat('yyyy-MM-dd').format(date);

                // Tìm lịch làm việc khớp User + Ngày
                final schedule = scheduleState.schedules.where((s) => 
                  s.employeeId == employeeId && s.workDate == dateKey
                ).firstOrNull;

                if (schedule != null && schedule.shiftName != null) {
                  shiftInfo = " (${schedule.shiftName})";
                }
              } catch (e) {
                // Lỗi parse date hoặc không tìm thấy
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(empName, style: const TextStyle(fontWeight: FontWeight.bold)),
                if (shiftInfo.isNotEmpty)
                  Text(shiftInfo.trim(), style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontStyle: FontStyle.italic)),
              ],
            );
          },
        );
      },
    );
  }
}