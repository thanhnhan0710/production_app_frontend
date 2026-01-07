import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:production_app_frontend/features/inventory/basket/presentation/bloc/baket_cubit.dart';
import 'package:production_app_frontend/l10n/app_localizations.dart';
import 'package:production_app_frontend/core/widgets/responsive_layout.dart';

import '../../domain/weaving_model.dart';
import '../bloc/weaving_cubit.dart';

// Import Feature khác để lấy dữ liệu chi tiết từ ID
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
    context.read<WeavingCubit>().loadTickets();
    // Load các danh mục để mapping ID -> Name
    context.read<ProductCubit>().loadProducts();
    context.read<MachineCubit>().loadMachines();
    context.read<BasketCubit>().loadBaskets();
    context.read<YarnLotCubit>().loadYarnLots();
    context.read<StandardCubit>().loadStandards();
    context.read<EmployeeCubit>().loadEmployees();
  }

  // ... (Giữ nguyên các hàm _filterTicketsByDate, _pickDate)
  List<WeavingTicket> _filterTicketsByDate(List<WeavingTicket> tickets) {
    final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 0, 0, 0);
    final endOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);

    return tickets.where((t) {
      try {
        final timeIn = DateTime.parse(t.timeIn);
        final timeOut = t.timeOut != null ? DateTime.parse(t.timeOut!) : null;
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
          if (state is WeavingError) return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
          
          if (state is WeavingLoaded) {
            if (!isDesktop) return const Center(child: Text("Mobile View Coming Soon"));

            final filteredTickets = _filterTicketsByDate(state.tickets);

            return Row(
              children: [
                // --- LEFT PANEL ---
                Expanded(
                  flex: 4,
                  child: Container(
                    decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.shade300))),
                    child: Column(
                      children: [
                        _buildHeader(l10n),
                        Expanded(
                          child: filteredTickets.isEmpty 
                            ? Center(child: Text("No active tickets on ${DateFormat('dd/MM/yyyy').format(_selectedDate)}", style: const TextStyle(color: Colors.grey)))
                            : ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: filteredTickets.length,
                            separatorBuilder: (_,__) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final ticket = filteredTickets[index];
                              final isSelected = state.selectedTicket?.id == ticket.id;
                              return _buildTicketCard(ticket, isSelected);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // --- RIGHT PANEL ---
                Expanded(
                  flex: 6,
                  child: state.selectedTicket == null 
                    ? Center(child: Text(l10n.noTicketSelected, style: TextStyle(color: Colors.grey.shade500)))
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

  // ... (Hàm _buildHeader, _buildTicketCard giữ nguyên)
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
                  Icon(Icons.receipt_long, color: _primaryColor),
                  const SizedBox(width: 8),
                  Text(l10n.weavingTicketTitle, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryColor)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, size: 28), 
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
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text("Date: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTicketCard(WeavingTicket ticket, bool isSelected) {
    bool isRunning = ticket.timeOut == null;
    return Card(
      elevation: isSelected ? 4 : 0,
      color: isSelected ? Colors.blue.shade50 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: isSelected ? BorderSide(color: _primaryColor, width: 1.5) : BorderSide.none),
      child: ListTile(
        onTap: () => context.read<WeavingCubit>().selectTicket(ticket),
        leading: CircleAvatar(
          backgroundColor: isRunning ? Colors.green.shade100 : Colors.grey.shade200,
          child: Icon(isRunning ? Icons.play_arrow : Icons.stop, color: isRunning ? Colors.green.shade800 : Colors.grey),
        ),
        title: Text(ticket.code, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Line: ${ticket.machineLine} • Basket: ${ticket.basketCode ?? '-'}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("${ticket.netWeight} kg", style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor)),
            Text("${ticket.lengthMeters} m", style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // --- DETAIL PANEL (ĐÃ CẬP NHẬT) ---
  Widget _buildDetailPanel(WeavingTicket ticket, List<WeavingInspection> inspections, AppLocalizations l10n) {
    return Container(
      color: _bgLight,
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("TICKET #${ticket.code}", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _primaryColor)),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.edit, size: 16),
                      label: Text(l10n.editSchedule),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                      onPressed: () => _showAddEditDialog(context, ticket, l10n),
                    ),
                    const SizedBox(width: 8),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(ticket, l10n)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // [CẬP NHẬT] Sử dụng các Widget Badge để hiển thị tên thay vì ID
            _buildInfoSection("Production Info", [
              _infoRow("Product", _ProductInfo(id: ticket.productId)),
              _infoRow("Standard", _StandardInfo(id: ticket.standardId)),
              _infoRow("Machine", _MachineInfo(id: ticket.machineId, line: ticket.machineLine)),
            ]),
            
            _buildInfoSection("Materials", [
              _infoRow("Yarn Lot", _YarnLotInfo(id: ticket.yarnLotId)),
              _infoRow("Load Date", Text(ticket.yarnLoadDate)),
              _infoRow("Basket", Text("${ticket.basketCode} (ID: ${ticket.basketId})")),
              _infoRow("Tare Weight", Text("${ticket.tareWeight ?? 0} kg")),
            ]),

            _buildInfoSection("Time & Personnel", [
               _infoRow("Time In", Text(_formatDateTime(ticket.timeIn))),
               _infoRow("Emp In", ticket.employeeInId != null ? _EmployeeInfo(id: ticket.employeeInId!) : const Text("-")),
               _infoRow("Time Out", Text(ticket.timeOut != null ? _formatDateTime(ticket.timeOut!) : "---")),
               _infoRow("Emp Out", ticket.employeeOutId != null ? _EmployeeInfo(id: ticket.employeeOutId!) : const Text("-")),
            ]),

            _buildInfoSection("Results", [
               _infoRow("Gross Weight", Text("${ticket.grossWeight} kg")),
               _infoRow("Net Weight", Text("${ticket.netWeight} kg", style: const TextStyle(color: Colors.green))),
               _infoRow("Length", Text("${ticket.lengthMeters} m")),
               _infoRow("Knots", Text("${ticket.numberOfKnots}")),
            ]),

            const SizedBox(height: 24),
            const Text("Quality Inspections", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              height: 150,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text("Inspection list here (${inspections.length} records)")),
            )
          ],
        ),
      ),
    );
  }

  // [CẬP NHẬT] _infoRow nhận Widget thay vì String
  Widget _infoRow(String label, Widget valueWidget) {
    return SizedBox(
      width: 200, // Tăng chiều rộng để hiển thị đủ thông tin
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
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: children,
            )
          ],
        ),
      ),
    );
  }

  String _formatDateTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('dd/MM HH:mm').format(dt);
    } catch (e) {
      return isoString;
    }
  }

  // --- DIALOG & CRUD (Giữ nguyên) ---
  void _showAddEditDialog(BuildContext context, WeavingTicket? ticket, AppLocalizations l10n) {
      // (Code dialog giữ nguyên như phiên bản trước)
      // Để ngắn gọn tôi không paste lại, bạn giữ nguyên phần này
  }

  void _confirmDelete(WeavingTicket ticket, AppLocalizations l10n) {
     // (Code delete giữ nguyên)
  }
}

// ==========================================
// CÁC WIDGET BADGE HIỂN THỊ TÊN TỪ ID
// ==========================================

class _ProductInfo extends StatelessWidget {
  final int id;
  const _ProductInfo({required this.id});
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, state) {
        String text = "ID: $id";
        if (state is ProductLoaded) {
          final item = state.products.where((e) => e.id == id).firstOrNull;
          if (item != null) text = item.itemCode; // Hiển thị Item Code
        }
        return Text(text);
      }
    );
  }
}

class _StandardInfo extends StatelessWidget {
  final int id;
  const _StandardInfo({required this.id});
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StandardCubit, StandardState>(
      builder: (context, state) {
        String text = "STD-$id";
        if (state is StandardLoaded) {
          final item = state.standards.where((e) => e.id == id).firstOrNull;
          if (item != null) {
            // Hiển thị chi tiết: Khổ x Dày (Màu)
            text = "${item.widthMm}x${item.thicknessMm} (${item.colorName ?? 'N/A'})";
          }
        }
        return Text(text, overflow: TextOverflow.ellipsis);
      }
    );
  }
}

class _MachineInfo extends StatelessWidget {
  final int id;
  final String line;
  const _MachineInfo({required this.id, required this.line});
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MachineCubit, MachineState>(
      builder: (context, state) {
        String text = "Mac-$id Line $line";
        if (state is MachineLoaded) {
          final item = state.machines.where((e) => e.id == id).firstOrNull;
          if (item != null) text = "${item.name} - Line $line";
        }
        return Text(text);
      }
    );
  }
}

class _YarnLotInfo extends StatelessWidget {
  final int id;
  const _YarnLotInfo({required this.id});
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<YarnLotCubit, YarnLotState>(
      builder: (context, state) {
        String text = "Lot-$id";
        if (state is YarnLotLoaded) {
          final item = state.yarnLots.where((e) => e.id == id).firstOrNull;
          if (item != null) text = item.lotCode;
        }
        return Text(text);
      }
    );
  }
}

class _EmployeeInfo extends StatelessWidget {
  final int id;
  const _EmployeeInfo({required this.id});
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmployeeCubit, EmployeeState>(
      builder: (context, state) {
        String text = "ID: $id";
        if (state is EmployeeLoaded) {
          final item = state.employees.where((e) => e.id == id).firstOrNull;
          if (item != null) text = item.fullName;
        }
        return Text(text);
      }
    );
  }
}