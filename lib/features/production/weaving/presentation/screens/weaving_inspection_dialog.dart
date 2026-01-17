import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:production_app_frontend/core/widgets/responsive_layout.dart';
import 'package:production_app_frontend/l10n/app_localizations.dart';

import '../../domain/weaving_model.dart';
import '../bloc/weaving_cubit.dart';

// Import Cubits & Models
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
// Import Auth để lấy user hiện tại
import 'package:production_app_frontend/features/auth/presentation/bloc/auth_cubit.dart';

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
                          Text("Inspection: Ticket: ${widget.ticket.code}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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

            // --- 2. TICKET FULL INFO (STANDARD DETAIL) ---
            Container(
              width: double.infinity,
              color: Colors.blue.shade50,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.assignment, size: 18, color: Colors.black54),
                      const SizedBox(width: 8),
                      const Text("Standard & Product Info", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                      const Spacer(),
                      // Hiển thị thêm thông tin lô sợi
                      _YarnLotInfo(id: widget.ticket.yarnLotId),
                    ],
                  ),
                  const Divider(),
                  // [QUAN TRỌNG] Widget hiển thị đầy đủ thông tin tiêu chuẩn + ảnh
                  _StandardFullDetails(standardId: widget.ticket.standardId),
                ],
              ),
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

  // --- DESKTOP BODY ---
  Widget _buildDesktopBody(AppLocalizations l10n) {
    return Row(
      children: [
        // Left: History
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _buildHistoryList(l10n),
          ),
        ),
        const VerticalDivider(width: 1),
        // Right: Input Form
        Expanded(
          flex: 4,
          child: Container(
            color: Colors.grey.shade50,
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
            tabs: [
              Tab(icon: const Icon(Icons.history), text: l10n.inspectionHistory),
              Tab(icon: const Icon(Icons.add_circle_outline), text: l10n.newInspection),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              Padding(padding: const EdgeInsets.all(8), child: _buildHistoryList(l10n)),
              SingleChildScrollView(padding: const EdgeInsets.all(16), child: _buildInputForm(l10n)),
            ],
          ),
        ),
      ],
    );
  }

  // --- HISTORY LIST ---
  Widget _buildHistoryList(AppLocalizations l10n) {
    return BlocBuilder<WeavingCubit, WeavingState>(
      builder: (context, state) {
        if (state is WeavingLoading) return const Center(child: CircularProgressIndicator());
        
        List<WeavingInspection> list = [];
        if (state is WeavingLoaded) list = state.inspections;

        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(l10n.noInspectionsRecorded, style: TextStyle(color: Colors.grey.shade500)),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_,__) => const SizedBox(height: 8),
          itemBuilder: (ctx, index) {
            final item = list[index];
            return Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  child: Text("${list.length - index}", style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold)),
                ),
                title: Text(item.stageName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Time: ${DateFormat('HH:mm dd/MM').format(DateTime.parse(item.inspectionTime))}"),
                    Text("Emp: ${item.employeeName ?? 'ID:${item.employeeId}'}"),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.grey),
                  onPressed: () {
                    showDialog(context: context, builder: (ctx) => AlertDialog(
                      title: Text(item.stageName),
                      content: Column(
                         mainAxisSize: MainAxisSize.min,
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                            Text("${l10n.width}: ${item.widthMm} mm"),
                            Text("${l10n.density}: ${item.weftDensity}"),
                            Text("${l10n.tension}: ${item.tensionDan} daN"),
                            Text("${l10n.thickness}: ${item.thicknessMm} mm"),
                            Text("${l10n.weight}: ${item.weightGm} g/m"),
                            Text("${l10n.bow}: ${item.bowing} %"),
                         ],
                      ),
                      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close"))],
                    ));
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- INPUT FORM (Tự động chọn người dùng) ---
  Widget _buildInputForm(AppLocalizations l10n) {
     
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated && authState.user.employeeId != null) {
        // Tự động gán ID nhân viên
        _selectedEmpId = authState.user.employeeId; 
    }
    
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           BlocBuilder<WeavingCubit, WeavingState>(
             builder: (context, state) {
               int nextCount = 1;
               if (state is WeavingLoaded) nextCount = state.inspections.length + 1;
               return Text("Check #$nextCount", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
             }
             
           ),
           const SizedBox(height: 20),
           
           Expanded(
                 child: BlocBuilder<ShiftCubit, ShiftState>(
                   builder: (context, state) {
                     List<Shift> items = (state is ShiftLoaded) ? state.shifts : [];
                     return DropdownButtonFormField<int>(
                       value: _selectedShiftId,
                       decoration: _inputDeco(l10n.shiftTitle),
                       isExpanded: true,
                       items: items.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                       onChanged: (v) => setState(() => _selectedShiftId = v),
                       validator: (v) => v == null ? l10n.required : null,
                     );
                   }
                 ),
            ),
           const SizedBox(height: 16),

           Text(l10n.measurements, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
           const SizedBox(height: 8),
           
           Row(children: [
             Expanded(child: TextFormField(controller: _widthCtrl, decoration: _inputDeco(l10n.width), keyboardType: TextInputType.number)),
             const SizedBox(width: 12),
             Expanded(child: TextFormField(controller: _densityCtrl, decoration: _inputDeco(l10n.density), keyboardType: TextInputType.number)),
           ]),
           const SizedBox(height: 12),
           Row(children: [
             Expanded(child: TextFormField(controller: _tensionCtrl, decoration: _inputDeco(l10n.tension), keyboardType: TextInputType.number)),
             const SizedBox(width: 12),
             Expanded(child: TextFormField(controller: _thickCtrl, decoration: _inputDeco(l10n.thickness), keyboardType: TextInputType.number)),
           ]),
           const SizedBox(height: 12),
           Row(children: [
             Expanded(child: TextFormField(controller: _weightCtrl, decoration: _inputDeco(l10n.weight), keyboardType: TextInputType.number)),
             const SizedBox(width: 12),
             Expanded(child: TextFormField(controller: _bowingCtrl, decoration: _inputDeco(l10n.bow), keyboardType: TextInputType.number)),
           ]),
           const SizedBox(height: 24),

           SizedBox(
             width: double.infinity,
             height: 48,
             child: ElevatedButton.icon(
               icon: const Icon(Icons.check_circle),
               label: Text(l10n.save),
               style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
               onPressed: () => _saveInspection(l10n),
             ),
           )
        ],
      ),
    );
  }

  void _saveInspection(AppLocalizations l10n) {
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
      
      _widthCtrl.clear(); _densityCtrl.clear(); _tensionCtrl.clear(); 
      _thickCtrl.clear(); _weightCtrl.clear(); _bowingCtrl.clear();
      
      if (!ResponsiveLayout.isDesktop(context)) _tabController.animateTo(0);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saveSuccess), backgroundColor: Colors.green));
    }
  }

  InputDecoration _inputDeco(String label) {
    return InputDecoration(labelText: label, isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), filled: true, fillColor: Colors.white);
  }
}

// --- WIDGET HIỂN THỊ FULL TIÊU CHUẨN (Copy từ WeavingScreen) ---
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
          final item = state.standards.where((s) => s.id == standardId).firstOrNull;
          if (item == null) return const Text("Standard info not loaded", style: TextStyle(color: Colors.grey));
          
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               // 1. Hình ảnh sản phẩm
               Container(
                 width: 80, height: 80,
                 margin: const EdgeInsets.only(right: 16),
                 decoration: BoxDecoration(
                   color: Colors.grey.shade100,
                   borderRadius: BorderRadius.circular(8),
                   border: Border.all(color: Colors.grey.shade300),
                 ),
                 child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: (item.productImage != null && item.productImage!.isNotEmpty)
                       ? Image.network(item.productImage!, fit: BoxFit.cover, errorBuilder: (_,__,___)=>const Icon(Icons.image_not_supported, color: Colors.grey))
                       : const Icon(Icons.image, color: Colors.grey),
                 ),
               ),

               // 2. Thông tin chi tiết
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      // Product Info
                      Text(item.productItemCode ?? "Unknown Code", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                      Text(item.productName ?? "Unknown Name", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      
                      // Specs Grid
                      Wrap(
                        spacing: 12, runSpacing: 6,
                        children: [
                           _specItem("W", "${item.widthMm}mm"),
                           _specItem("T", "${item.thicknessMm}mm"),
                           _specItem("G/m", "${item.weightGm}g/m"),
                           _specItem("Str", "${item.breakingStrength}daN", color: Colors.red.shade700),
                           _specItem("El", "${item.elongation}%", color: Colors.indigo),
                           _specItem("Den", item.weftDensity),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Color
                      Row(
                        children: [
                          Container(width: 12, height: 12, decoration: BoxDecoration(color: _hexToColor(item.colorHex), shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300))),
                          const SizedBox(width: 6),
                          Text(item.colorName ?? "-", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          if (item.deltaE.isNotEmpty) ...[
                             const SizedBox(width: 8),
                             Text("ΔE: ${item.deltaE}", style: const TextStyle(fontSize: 11, color: Colors.purple)),
                          ]
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

  Widget _specItem(String label, String value, {Color? color}) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
        Text("$label: ", style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color ?? Colors.black87)),
    ]);
  }
}

// Widget Badge nhỏ
class _YarnLotInfo extends StatelessWidget {
  final int id; const _YarnLotInfo({required this.id});
  @override Widget build(BuildContext context) => BlocBuilder<YarnLotCubit, YarnLotState>(builder: (c,s)=>Text(s is YarnLotLoaded ? (s.yarnLots.where((e)=>e.id==id).firstOrNull?.lotCode ?? "$id") : "$id", style: const TextStyle(fontWeight: FontWeight.bold)));
}