import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:production_app_frontend/core/widgets/responsive_layout.dart';
import 'package:production_app_frontend/l10n/app_localizations.dart';

import '../../domain/weaving_model.dart';
import '../bloc/weaving_cubit.dart';

// Import các Cubit liên quan để lấy thông tin chi tiết
import 'package:production_app_frontend/features/inventory/product/presentation/bloc/product_cubit.dart';
import 'package:production_app_frontend/features/inventory/product/domain/product_model.dart';
import 'package:production_app_frontend/features/production/standard/presentation/bloc/standard_cubit.dart';
import 'package:production_app_frontend/features/production/standard/domain/standard_model.dart';
import 'package:production_app_frontend/features/inventory/yarn_lot/presentation/bloc/yarn_lot_cubit.dart';
import 'package:production_app_frontend/features/inventory/yarn_lot/domain/yarn_lot_model.dart';
import 'package:production_app_frontend/features/hr/employee/presentation/bloc/employee_cubit.dart';
import 'package:production_app_frontend/features/hr/employee/domain/employee_model.dart';
import 'package:production_app_frontend/features/hr/shift/presentation/bloc/shift_cubit.dart';
import 'package:production_app_frontend/features/hr/shift/domain/shift_model.dart';

class WeavingInspectionDialog extends StatefulWidget {
  final WeavingTicket ticket;
  final VoidCallback? onRelease;

  const WeavingInspectionDialog({super.key, required this.ticket, this.onRelease});

  @override
  State<WeavingInspectionDialog> createState() => _WeavingInspectionDialogState();
}

class _WeavingInspectionDialogState extends State<WeavingInspectionDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _widthCtrl = TextEditingController();
  final _densityCtrl = TextEditingController();
  final _tensionCtrl = TextEditingController();
  final _thickCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _bowingCtrl = TextEditingController();

  int? _selectedEmpId;
  int? _selectedShiftId;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Load data
    context.read<WeavingCubit>().selectTicket(widget.ticket);
    // Load các danh mục để hiển thị tên thay vì ID
    context.read<EmployeeCubit>().loadEmployees();
    context.read<ShiftCubit>().loadShifts();
    context.read<ProductCubit>().loadProducts();
    context.read<StandardCubit>().loadStandards();
    context.read<YarnLotCubit>().loadYarnLots();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Dialog(
      insetPadding: EdgeInsets.all(isDesktop ? 30 : 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      // ignore: sized_box_for_whitespace
      child: Container(
        width: isDesktop ? 1000 : width,
        height: isDesktop ? 800 : height * 0.95,
        child: Column(
          children: [
            // --- 1. HEADER ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.blue.shade900,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.fact_check, color: Colors.white),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Inspection: Ticket #${widget.ticket.code}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text("Machine ${widget.ticket.machineId} (Line ${widget.ticket.machineLine})", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (widget.onRelease != null)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.stop_circle_outlined, size: 18),
                          label: Text(l10n.releaseBasket),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent, 
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
                          ),
                          onPressed: widget.onRelease,
                        ),
                      const SizedBox(width: 16),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white)),
                    ],
                  ),
                ],
              ),
            ),

            // --- 2. TICKET FULL INFO (Thông tin chi tiết phiếu) ---
            Container(
              width: double.infinity,
              color: Colors.blue.shade50,
              padding: const EdgeInsets.all(16),
              child: _buildTicketFullInfo(),
            ),

            // --- 3. BODY (History & Form) ---
            Expanded(
              child: isDesktop 
                ? _buildDesktopBody(l10n) 
                : _buildMobileBody(l10n),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HIỂN THỊ THÔNG TIN CHI TIẾT PHIẾU ---
  Widget _buildTicketFullInfo() {
    final t = widget.ticket;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hàng 1: Thông tin sản phẩm, tiêu chuẩn, vật tư
        Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            _infoBadge(Icons.shopping_bag, "Product", _ProductInfo(id: t.productId)),
            _infoBadge(Icons.assignment, "Standard", _StandardInfo(id: t.standardId)),
            _infoBadge(Icons.line_style, "Yarn Lot", _YarnLotInfo(id: t.yarnLotId)),
            _infoBadge(Icons.shopping_basket, "Basket", Text(t.basketCode ?? "N/A")),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, color: Colors.white),
        const SizedBox(height: 12),
        // Hàng 2: Thời gian và nhân sự
        Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            _infoBadge(Icons.calendar_today, "Load Date", Text(t.yarnLoadDate)),
            _infoBadge(Icons.access_time, "Time In", Text(DateFormat('HH:mm dd/MM').format(DateTime.parse(t.timeIn)))),
            _infoBadge(Icons.person, "Emp In", _EmployeeInfo(id: t.employeeInId ?? 0)),
          ],
        )
      ],
    );
  }

  Widget _infoBadge(IconData icon, String label, Widget content) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: Colors.blue.shade800.withOpacity(0.7)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
            DefaultTextStyle(
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
              child: content,
            ),
          ],
        )
      ],
    );
  }

  // --- DESKTOP BODY ---
  Widget _buildDesktopBody(AppLocalizations l10n) {
    return Row(
      children: [
        // Left: History List
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _buildHistoryList(),
          ),
        ),
        const VerticalDivider(width: 1),
        // Right: Input Form
        Expanded(
          flex: 4,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(24),
            child: _buildInputForm(l10n),
          ),
        ),
      ],
    );
  }

  // --- MOBILE BODY ---
  Widget _buildMobileBody(AppLocalizations l10n) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.blue.shade900,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue.shade900,
            tabs: const [
              Tab(icon: Icon(Icons.history), text: "History"),
              Tab(icon: Icon(Icons.add_circle_outline), text: "New Check"),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              Padding(padding: const EdgeInsets.all(8), child: _buildHistoryList()),
              SingleChildScrollView(padding: const EdgeInsets.all(16), child: _buildInputForm(l10n)),
            ],
          ),
        ),
      ],
    );
  }

  // --- HISTORY LIST ---
  Widget _buildHistoryList() {
    return BlocBuilder<WeavingCubit, WeavingState>(
      builder: (context, state) {
        if (state is WeavingLoading) return const Center(child: CircularProgressIndicator());
        
        List<WeavingInspection> list = [];
        if (state is WeavingLoaded) {
           list = state.inspections;
        }

        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text("No inspections recorded yet", style: TextStyle(color: Colors.grey.shade500)),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Inspection History (${list.length})", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_,__) => const SizedBox(height: 12),
                itemBuilder: (ctx, index) {
                  final item = list[index];
                  return Card(
                    elevation: 0,
                    color: Colors.grey.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.blue.shade100,
                                    child: Text("${list.length - index}", style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(item.stageName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                ],
                              ),
                              Text(DateFormat('HH:mm dd/MM').format(DateTime.parse(item.inspectionTime)), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            ],
                          ),
                          const Divider(),
                          // Hiển thị thông số chi tiết
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              _specItem("W", "${item.widthMm}mm"),
                              _specItem("Dens", "${item.weftDensity}"),
                              _specItem("Tens", "${item.tensionDan}N"),
                              _specItem("Thick", "${item.thicknessMm}mm"),
                              _specItem("Weight", "${item.weightGm}g"),
                              _specItem("Bow", "${item.bowing}"),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  "${item.employeeName ?? 'ID:${item.employeeId}'} • ${item.shiftName ?? 'Shift:${item.shiftId}'}", 
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700)
                                )
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _specItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey.shade300)),
      child: Text("$label: $value", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  // --- WIDGET: INPUT FORM ---
  Widget _buildInputForm(AppLocalizations l10n) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           BlocBuilder<WeavingCubit, WeavingState>(
             builder: (context, state) {
               int nextCount = 1;
               if (state is WeavingLoaded) nextCount = state.inspections.length + 1;
               return Container(
                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                 decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                 child: Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     const Icon(Icons.add_circle, color: Colors.blue, size: 20),
                     const SizedBox(width: 8),
                     Text("New Inspection (Lần $nextCount)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                   ],
                 ),
               );
             }
           ),
           const SizedBox(height: 20),
           
           // Operator & Shift
           Row(
             children: [
               Expanded(
                 child: BlocBuilder<EmployeeCubit, EmployeeState>(
                   builder: (context, state) {
                     List<Employee> items = (state is EmployeeLoaded) ? state.employees : [];
                     return DropdownButtonFormField<int>(
                       value: _selectedEmpId,
                       decoration: _inputDeco("Inspector"),
                       isExpanded: true,
                       items: items.map((e) => DropdownMenuItem(value: e.id, child: Text(e.fullName, overflow: TextOverflow.ellipsis))).toList(),
                       onChanged: (v) => setState(() => _selectedEmpId = v),
                       validator: (v) => v == null ? "Req" : null,
                     );
                   }
                 ),
               ),
               const SizedBox(width: 12),
               Expanded(
                 child: BlocBuilder<ShiftCubit, ShiftState>(
                   builder: (context, state) {
                     List<Shift> items = (state is ShiftLoaded) ? state.shifts : [];
                     return DropdownButtonFormField<int>(
                       value: _selectedShiftId,
                       decoration: _inputDeco("Shift"),
                       isExpanded: true,
                       items: items.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                       onChanged: (v) => setState(() => _selectedShiftId = v),
                       validator: (v) => v == null ? "Req" : null,
                     );
                   }
                 ),
               ),
             ],
           ),
           const SizedBox(height: 16),

           const Text("Measurements", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
           const SizedBox(height: 8),
           
           Row(
             children: [
               Expanded(child: TextFormField(controller: _widthCtrl, decoration: _inputDeco("Width (mm)"), keyboardType: TextInputType.number)),
               const SizedBox(width: 12),
               Expanded(child: TextFormField(controller: _densityCtrl, decoration: _inputDeco("Density"), keyboardType: TextInputType.number)),
             ],
           ),
           const SizedBox(height: 12),
           Row(
             children: [
               Expanded(child: TextFormField(controller: _tensionCtrl, decoration: _inputDeco("Tension (daN)"), keyboardType: TextInputType.number)),
               const SizedBox(width: 12),
               Expanded(child: TextFormField(controller: _thickCtrl, decoration: _inputDeco("Thick (mm)"), keyboardType: TextInputType.number)),
             ],
           ),
           const SizedBox(height: 12),
           Row(
             children: [
               Expanded(child: TextFormField(controller: _weightCtrl, decoration: _inputDeco("Weight (gm)"), keyboardType: TextInputType.number)),
               const SizedBox(width: 12),
               Expanded(child: TextFormField(controller: _bowingCtrl, decoration: _inputDeco("Bowing"), keyboardType: TextInputType.number)),
             ],
           ),
           const SizedBox(height: 24),

           SizedBox(
             width: double.infinity,
             height: 48,
             child: ElevatedButton.icon(
               icon: const Icon(Icons.check_circle),
               label: const Text("SAVE RESULTS"),
               style: ElevatedButton.styleFrom(
                 backgroundColor: Colors.blue.shade800, 
                 foregroundColor: Colors.white,
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
               ),
               onPressed: _saveInspection,
             ),
           )
        ],
      ),
    );
  }

  void _saveInspection() {
    if (_formKey.currentState!.validate() && _selectedEmpId != null && _selectedShiftId != null) {
      final state = context.read<WeavingCubit>().state;
      int count = (state is WeavingLoaded) ? state.inspections.length : 0;
      String stageName = "Lần ${count + 1}";

      final newItem = WeavingInspection(
        id: 0,
        ticketId: widget.ticket.id,
        stageName: stageName,
        employeeId: _selectedEmpId!,
        shiftId: _selectedShiftId!,
        widthMm: double.tryParse(_widthCtrl.text) ?? 0,
        weftDensity: double.tryParse(_densityCtrl.text) ?? 0,
        tensionDan: double.tryParse(_tensionCtrl.text) ?? 0,
        thicknessMm: double.tryParse(_thickCtrl.text) ?? 0,
        weightGm: double.tryParse(_weightCtrl.text) ?? 0,
        bowing: double.tryParse(_bowingCtrl.text) ?? 0,
        inspectionTime: DateTime.now().toIso8601String(),
      );

      context.read<WeavingCubit>().saveInspection(newItem);
      
      _widthCtrl.clear(); _densityCtrl.clear(); 
      _tensionCtrl.clear(); _thickCtrl.clear();
      _weightCtrl.clear(); _bowingCtrl.clear();
      
      if (!ResponsiveLayout.isDesktop(context)) {
        _tabController.animateTo(0); 
      }
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saved successfully"), backgroundColor: Colors.green));
    }
  }

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: Colors.white,
    );
  }
}

// ==========================================
// CÁC WIDGET BADGE ĐỂ HIỂN THỊ TÊN TỪ ID
// ==========================================

class _ProductInfo extends StatelessWidget {
  final int id; const _ProductInfo({required this.id});
  @override Widget build(BuildContext context) {
    return BlocBuilder<ProductCubit, ProductState>(builder: (c, s) => Text(s is ProductLoaded ? (s.products.where((e)=>e.id==id).firstOrNull?.itemCode ?? "$id") : "$id"));
  }
}

class _StandardInfo extends StatelessWidget {
  final int id; const _StandardInfo({required this.id});
  @override Widget build(BuildContext context) => BlocBuilder<StandardCubit, StandardState>(
    builder: (c,s) {
       String text = "STD-$id";
       if (s is StandardLoaded) {
          final item = s.standards.where((e)=>e.id==id).firstOrNull;
          if(item!=null) text = "${item.widthMm}x${item.thicknessMm}";
       }
       return Text(text);
    }
  );
}

class _YarnLotInfo extends StatelessWidget {
  final int id; const _YarnLotInfo({required this.id});
  @override Widget build(BuildContext context) => BlocBuilder<YarnLotCubit, YarnLotState>(builder: (c,s)=>Text(s is YarnLotLoaded ? (s.yarnLots.where((e)=>e.id==id).firstOrNull?.lotCode ?? "$id") : "$id"));
}

class _EmployeeInfo extends StatelessWidget {
  final int id; const _EmployeeInfo({required this.id});
  @override Widget build(BuildContext context) => BlocBuilder<EmployeeCubit, EmployeeState>(builder: (c,s)=>Text(s is EmployeeLoaded ? (s.employees.where((e)=>e.id==id).firstOrNull?.fullName ?? "$id") : "$id"));
}