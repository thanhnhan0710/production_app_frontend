import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:production_app_frontend/features/production/weaving/domain/weaving_model.dart';
import 'package:production_app_frontend/features/production/weaving/presentation/bloc/weaving_cubit.dart';
import 'package:production_app_frontend/l10n/app_localizations.dart';

// Import các model và bloc
import 'package:production_app_frontend/features/inventory/product/presentation/bloc/product_cubit.dart';
import 'package:production_app_frontend/features/production/machine/presentation/bloc/machine_cubit.dart';
import 'package:production_app_frontend/features/production/machine/presentation/screens/machine_history_dialog.dart'; 
import 'package:production_app_frontend/features/production/machine/domain/machine_model.dart'; 
import 'package:production_app_frontend/features/production/standard/presentation/bloc/standard_cubit.dart';
import 'package:production_app_frontend/features/inventory/batch/presentation/bloc/batch_cubit.dart';
import 'package:production_app_frontend/features/inventory/batch/domain/batch_model.dart';

// Import WeavingRecord
import 'package:production_app_frontend/features/production/weaving_record/presentation/bloc/weaving_record_cubit.dart';
import 'package:production_app_frontend/features/production/weaving_record/domain/weaving_record_model.dart';

class WeavingTicketDetailScreen extends StatefulWidget {
  final WeavingTicket ticket;

  const WeavingTicketDetailScreen({super.key, required this.ticket});

  @override
  State<WeavingTicketDetailScreen> createState() => _WeavingTicketDetailScreenState();
}

class _WeavingTicketDetailScreenState extends State<WeavingTicketDetailScreen> {
  List<WeavingRecord> _weighingRecords = [];
  bool _isLoadingRecords = true;

  @override
  void initState() {
    super.initState();
    // 1. Load lịch sử kiểm tra (QC)
    context.read<WeavingCubit>().loadInspections(widget.ticket.id);
    
    // 2. Load lịch sử cân rổ
    _loadWeighingHistory();
  }

  Future<void> _loadWeighingHistory() async {
    try {
      final records = await context.read<WeavingRecordCubit>().getRecordsByTicketId(widget.ticket.id);
      if (mounted) {
        setState(() {
          _weighingRecords = records;
          _isLoadingRecords = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingRecords = false);
    }
  }

  // Hàm xử lý in ấn
  Future<void> _handlePrint(List<WeavingInspection> inspections) async {
    // Logic in ấn
  }

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Chi tiết phiếu dệt", style: TextStyle(fontSize: 16)),
            Text(ticket.code, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
        actions: [
          BlocBuilder<WeavingCubit, WeavingState>(
            builder: (context, state) {
              return IconButton(
                icon: const Icon(Icons.print),
                tooltip: "In phiếu",
                onPressed: () {
                   final inspections = (state is WeavingLoaded && state.selectedTicket?.id == ticket.id) 
                      ? state.inspections 
                      : <WeavingInspection>[]; 
                   _handlePrint(inspections);
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<WeavingCubit, WeavingState>(
        builder: (context, state) {
          List<WeavingInspection> inspections = [];
          if (state is WeavingLoaded) {
             inspections = state.inspections;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Production Info
                _buildInfoCard("Thông tin sản xuất", [
                   _rowInfo("Sản phẩm", _ProductFullDetails(id: ticket.productId)),
                   const SizedBox(height: 8),
                   _rowInfo("Máy & Line", _MachineInfo(id: ticket.machineId, line: ticket.machineLine)),
                ]),

                // 2. Standard
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text("Tiêu chuẩn kỹ thuật", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900, fontSize: 13)),
                      const Divider(height: 20),
                      _StandardFullDetails(standardId: ticket.standardId)
                  ]),
                ),

                // 3. Materials
                _buildInfoCard("Nguyên liệu", [
                  _rowInfo("Lô sợi", _TicketBatchListSimple(yarns: ticket.yarns)),
                  _rowInfo("Ngày lên sợi", Text(ticket.yarnLoadDate)),
                  _rowInfo("Rổ chứa", Text("${ticket.basketCode ?? 'N/A'} (Tare: ${ticket.tareWeight}kg)")),
                ]),

                // 4. Time & Personnel
                _buildInfoCard("Thời gian & Nhân sự", [
                  _rowInfo("Bắt đầu", Text(_formatDateTimeFull(ticket.timeIn))),
                  _rowInfo("Người đứng máy", Text(ticket.employeeInName ?? "-")),
                  if (ticket.timeOut != null) ...[
                    const Divider(),
                    _rowInfo("Kết thúc", Text(_formatDateTimeFull(ticket.timeOut!))),
                    _rowInfo("Người kết thúc", Text(ticket.employeeOutName ?? "-")),
                  ]
                ]),

                // 5. Results
                _buildInfoCard("Kết quả sản xuất", [
                    _rowInfo("Tổng trọng lượng", Text("${ticket.grossWeight} kg")),
                    _rowInfo("Trọng lượng tịnh", Text("${ticket.netWeight} kg", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                    _rowInfo("Chiều dài", Text("${ticket.lengthMeters} m")),
                    _rowInfo("Số nối/lỗi", Text("${ticket.numberOfKnots}")),
                ]),

                // 6. Lịch sử cân rổ
                const SizedBox(height: 10),
                const Text("Lịch sử cân rổ (Weighing Logs)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildWeighingHistoryCard(),

                // 7. Lịch sử máy
                const SizedBox(height: 20),
                _buildMachineHistoryCard(),

                const SizedBox(height: 20),
                // 8. Inspection History
                const Text("Lịch sử kiểm tra (QC)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                
                if (inspections.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                    child: const Center(child: Text("Chưa có dữ liệu kiểm tra", style: TextStyle(color: Colors.grey))),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: inspections.length,
                    separatorBuilder: (_,__) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => _buildInspectionItem(inspections[index]),
                  ),
                
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- [CẬP NHẬT] WIDGET LỊCH SỬ CÂN RỔ ---
  Widget _buildWeighingHistoryCard() {
    if (_isLoadingRecords) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_weighingRecords.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
        child: const Text("Chưa có dữ liệu cân", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
      );
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.indigo.shade100)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _weighingRecords.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final record = _weighingRecords[index];
          return ListTile(
            dense: true,
            leading: const Icon(Icons.monitor_weight, color: Colors.indigo),
            // [THAY ĐỔI] Tách hiển thị Phế thành Run và Setup
            title: Row(
              children: [
                Text("Net: ${record.totalWeight}kg", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                const SizedBox(width: 8),
                // Run Waste Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(4)),
                  child: Text("Run: ${record.runWaste}Kg", style: TextStyle(fontSize: 11, color: Colors.orange.shade800, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 4),
                // Setup Waste Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                  child: Text("Setup: ${record.setupWaste}Kg", style: TextStyle(fontSize: 11, color: Colors.red.shade800, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            subtitle: Text(
              "Ca: ${record.shiftName} • ${record.updatedAt != null ? _formatDateTimeFull(record.updatedAt!.toIso8601String()) : '-'}",
              style: const TextStyle(fontSize: 11)
            ),
            trailing: const Icon(Icons.check_circle, color: Colors.green, size: 16),
          );
        },
      ),
    );
  }

  // --- WIDGET LỊCH SỬ MÁY ---
  Widget _buildMachineHistoryCard() {
    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.blue.shade200)),
      child: ListTile(
        leading: const Icon(Icons.history, color: Colors.blue),
        title: const Text("Lịch sử hoạt động của máy", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text("Xem trạng thái chạy/dừng của máy NF-${widget.ticket.machineId}"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () {
          final machineStub = Machine(
            id: widget.ticket.machineId, 
            name: "NF-${widget.ticket.machineId}", 
            totalLines: 2, 
            purpose: "Sản xuất", status: '',
          );
          
          showDialog(
            context: context,
            builder: (ctx) => MachineHistoryDialog(machine: machineStub),
          );
        },
      ),
    );
  }


  // --- UI HELPERS ---

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
          Expanded(child: Align(alignment: Alignment.centerRight, child: content)),
        ],
      ),
    );
  }

  Widget _buildInspectionItem(WeavingInspection item) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
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
                      CircleAvatar(backgroundColor: Colors.blue.shade50, radius: 12, child: Text("QC", style: TextStyle(fontSize: 9, color: Colors.blue.shade900, fontWeight: FontWeight.bold))),
                      const SizedBox(width: 8),
                      Text(item.stageName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                Text(_formatDateTimeFull(item.inspectionTime), style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
            const Divider(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                  _specBadge("W: ${item.widthMm}"),
                  _specBadge("D: ${item.weftDensity}"),
                  _specBadge("T: ${item.thicknessMm}"),
                  _specBadge("G: ${item.weightGm}"),
                  _specBadge("Bow: ${item.bowing}"),
              ],
            ),
             const SizedBox(height: 4),
            Align(alignment: Alignment.centerRight, child: Text("By: ${item.employeeName ?? '-'}", style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade700))),
          ],
        ),
      ),
    );
  }

  Widget _specBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  String _formatDateTimeFull(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('dd/MM HH:mm').format(dt);
    } catch (e) {
      return isoString;
    }
  }
}

// =========================================================================
// CÁC WIDGET CON
// =========================================================================

class _ProductFullDetails extends StatelessWidget {
  final int id;
  const _ProductFullDetails({required this.id});
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, state) {
        if (state is ProductLoaded) {
          final product = state.products.where((e) => e.id == id).firstOrNull;
          if (product == null) return Text("ID: $id");
          return Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(product.itemCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              if(product.note.isNotEmpty) Text(product.note, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          );
        }
        return const Text("...");
      },
    );
  }
}

class _MachineInfo extends StatelessWidget {
  final int id; final String line;
  const _MachineInfo({required this.id, required this.line});
  @override
  Widget build(BuildContext context) => BlocBuilder<MachineCubit, MachineState>(builder: (c,s) {
    String t = "Mac-$id Line $line";
    if (s is MachineLoaded) { final m = s.machines.where((e)=>e.id==id).firstOrNull; if(m!=null) t = "${m.name} - Line $line"; }
    return Text(t, style: const TextStyle(fontWeight: FontWeight.w500));
  });
}

class _TicketBatchListSimple extends StatelessWidget {
  final List<WeavingTicketYarn> yarns;
  const _TicketBatchListSimple({required this.yarns});
  @override
  Widget build(BuildContext context) {
    if (yarns.isEmpty) return const Text("-");
    return BlocBuilder<BatchCubit, BatchState>(
      builder: (context, state) {
        final allBatches = (state is BatchLoaded) ? state.batches : <Batch>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: yarns.map((y) {
            final b = allBatches.where((bat) => bat.batchId == y.batchId).firstOrNull;
            String code = b?.internalBatchCode ?? "ID:${y.batchId}";
            if (b?.supplierBatchNo != null && b!.supplierBatchNo.isNotEmpty) code += " (${b.supplierBatchNo})";
            return Text("${y.componentType}: $code", style: const TextStyle(fontSize: 12));
          }).toList(),
        );
      }
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
    } catch (e) { return Colors.grey; }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StandardCubit, StandardState>(
      builder: (context, state) {
        if (state is StandardLoaded) {
          final item = state.standards.where((s) => s.id == standardId).firstOrNull;
          if (item == null) return const Text("Chưa có thông tin tiêu chuẩn");
          
          return Column(
            children: [
               Row(
                 children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: _hexToColor(item.colorHex), shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300))),
                    const SizedBox(width: 6),
                    Text(item.colorName ?? "Màu?", style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    if(item.deltaE.isNotEmpty) Text("dE: ${item.deltaE}", style: const TextStyle(fontSize: 11, color: Colors.purple)),
                 ],
               ),
               const SizedBox(height: 8),
               Wrap(
                 spacing: 12, runSpacing: 6,
                 children: [
                   _sItem("Rộng", "${item.widthMm}mm"),
                   _sItem("Dày", "${item.thicknessMm}mm"),
                   _sItem("Mật độ", item.weftDensity),
                   _sItem("Trọng lượng", "${item.weightGm}g/m"),
                   _sItem("Lực kéo", "${item.breakingStrength}daN"),
                   _sItem("Độ giãn", "${item.elongation}%"),
                 ],
               )
            ],
          );
        }
        return const Text("Loading standard...");
      },
    );
  }
  Widget _sItem(String l, String v) => Container(
     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
     color: Colors.grey.shade100,
     child: Text("$l: $v", style: const TextStyle(fontSize: 11)),
  );
}