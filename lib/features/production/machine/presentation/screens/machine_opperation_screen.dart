import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:production_app_frontend/features/inventory/basket/doamain/baket_model.dart';
import 'package:production_app_frontend/features/production/machine/presentation/bloc/machine_operation_cubit.dart';
import 'package:production_app_frontend/l10n/app_localizations.dart';
import '../../../weaving/domain/weaving_model.dart';
import '../../domain/machine_model.dart';


class MachineOperationScreen extends StatefulWidget {
  const MachineOperationScreen({super.key});

  @override
  State<MachineOperationScreen> createState() => _MachineOperationScreenState();
}

class _MachineOperationScreenState extends State<MachineOperationScreen> {
  final Color _primaryColor = const Color(0xFF003366);

  @override
  void initState() {
    super.initState();
    context.read<MachineOperationCubit>().loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: const Color(0xFFE0E0E0), // Nền xám đậm hơn chút để nổi bật thẻ máy
      appBar: AppBar(
        title: Text(l10n.machineOperation, style: const TextStyle(color: Colors.white)),
        backgroundColor: _primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<MachineOperationCubit>().loadDashboard(),
          )
        ],
      ),
      body: BlocConsumer<MachineOperationCubit, MachineOpState>(
        listener: (context, state) {
          if (state is MachineOpError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        builder: (context, state) {
          if (state is MachineOpLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is MachineOpLoaded) {
            if (state.machines.isEmpty) {
              return const Center(child: Text("No machines configured"));
            }

            // Grid View các máy
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400, // Độ rộng tối đa của 1 thẻ máy
                childAspectRatio: 1.1, // Tỷ lệ khung hình thẻ
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: state.machines.length,
              itemBuilder: (context, index) {
                final machine = state.machines[index];
                return _buildMachineCard(context, machine, state, l10n);
              },
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  // --- THẺ MÁY (MACHINE CARD) ---
  Widget _buildMachineCard(BuildContext context, Machine machine, MachineOpLoaded state, AppLocalizations l10n) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Header Máy
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _primaryColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.precision_manufacturing, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      machine.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
                  child: Text(machine.status, style: const TextStyle(color: Colors.white, fontSize: 10)),
                )
              ],
            ),
          ),

          // Body: 2 Line
          Expanded(
            child: Row(
              children: [
                // LINE 1
                Expanded(
                  child: _buildLineSlot(context, machine, "1", state.activeTickets["${machine.id}_1"], state.readyBaskets, l10n),
                ),
                // Divider dọc
                Container(width: 1, color: Colors.grey.shade300),
                // LINE 2
                Expanded(
                  child: _buildLineSlot(context, machine, "2", state.activeTickets["${machine.id}_2"], state.readyBaskets, l10n),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- SLOT CỦA TỪNG LINE ---
  Widget _buildLineSlot(BuildContext context, Machine machine, String lineCode, WeavingTicket? ticket, List<Basket> readyBaskets, AppLocalizations l10n) {
    final bool isActive = ticket != null;

    return InkWell(
      onTap: () {
        if (!isActive) {
          // Nếu trống -> Mở dialog chọn rổ
          _showAssignDialog(context, machine, lineCode, readyBaskets, l10n);
        } else {
          // Nếu đang chạy -> Xem chi tiết / Thêm QC
          _showActionDialog(context, ticket, l10n);
        }
      },
      child: Container(
        color: isActive ? Colors.green.shade50 : Colors.transparent,
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("${l10n.line} $lineCode", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            if (isActive) ...[
              // Trạng thái: Đang chạy
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green, width: 2),
                  boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.2), blurRadius: 8)]
                ),
                child: const Icon(Icons.settings_backup_restore, color: Colors.green, size: 28), // Icon quay vòng
              ),
              const SizedBox(height: 12),
              Text(
                ticket.basketCode ?? "Unknown",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                "#${ticket.code}",
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ] else ...[
              // Trạng thái: Trống
              const Icon(Icons.add_circle_outline, color: Colors.grey, size: 40),
              const SizedBox(height: 8),
              Text(l10n.noActiveBasket, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ]
          ],
        ),
      ),
    );
  }

  // --- DIALOG GÁN RỔ (Assign) ---
  void _showAssignDialog(BuildContext context, Machine machine, String line, List<Basket> readyBaskets, AppLocalizations l10n) {
    Basket? selectedBasket;
    final codeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("${l10n.assignBasket} - ${machine.name} Line $line"),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mô phỏng ô quét mã vạch
              TextField(
                controller: codeCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.scanBarcode,
                  prefixIcon: const Icon(Icons.qr_code_scanner),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () {
                      // Logic giả lập: Tìm rổ theo mã nhập vào
                      final found = readyBaskets.where((b) => b.code == codeCtrl.text).firstOrNull;
                      if (found != null) {
                         Navigator.pop(ctx);
                         context.read<MachineOperationCubit>().assignBasketToMachine(machine.id, line, found);
                      } else {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Basket not found or not READY")));
                      }
                    },
                  ),
                ),
                onSubmitted: (val) {
                   // Xử lý khi quét xong (Enter)
                   final found = readyBaskets.where((b) => b.code == val).firstOrNull;
                   if (found != null) {
                      Navigator.pop(ctx);
                      context.read<MachineOperationCubit>().assignBasketToMachine(machine.id, line, found);
                   } else {
                      // Thông báo lỗi nhỏ
                   }
                },
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              Text(l10n.selectBasket, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              // Dropdown chọn nhanh
              DropdownButtonFormField<Basket>(
                decoration: const InputDecoration(border: OutlineInputBorder()),
                hint: const Text("Select from list..."),
                items: readyBaskets.map((b) => DropdownMenuItem(
                  value: b,
                  child: Text("${b.code} (${b.tareWeight}kg)"),
                )).toList(),
                onChanged: (val) {
                   if (val != null) {
                      Navigator.pop(ctx);
                      context.read<MachineOperationCubit>().assignBasketToMachine(machine.id, line, val);
                   }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
        ],
      ),
    );
  }

  // --- DIALOG HÀNH ĐỘNG (Khi máy đang chạy) ---
  void _showActionDialog(BuildContext context, WeavingTicket ticket, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.featured_play_list, color: Colors.blue),
                const SizedBox(width: 12),
                Text("Ticket #${ticket.code}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                  child: Text("IN PRODUCTION", style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 10)),
                )
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            
            // Các nút hành động
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.add_task, color: Colors.white)),
              title: Text(l10n.addInspection),
              subtitle: const Text("Record quality check results"),
              onTap: () {
                Navigator.pop(ctx);
                // Mở dialog thêm Inspection (như đã làm ở WeavingScreen)
              },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.visibility, color: Colors.white)),
              title: Text(l10n.viewTicket),
              subtitle: const Text("View full details"),
              onTap: () {
                Navigator.pop(ctx);
                // Điều hướng sang trang chi tiết ticket
                // context.push('/weaving/ticket/${ticket.id}');
              },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.red, child: Icon(Icons.stop_circle, color: Colors.white)),
              title: Text(l10n.releaseLine, style: const TextStyle(color: Colors.red)),
              subtitle: const Text("Finish production & remove basket"),
              onTap: () {
                Navigator.pop(ctx);
                // Gọi hàm kết thúc (chưa implement trong cubit nhưng placeholder ở đó)
                // context.read<MachineOperationCubit>().releaseBasket(ticket);
              },
            ),
          ],
        ),
      ),
    );
  }
}
