import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../core/network/websocket_service.dart'; // Import WebSocket

// Import Cubit & Model
import '../bloc/material_export_cubit.dart';
import '../../domain/material_export_model.dart';

// Import màn hình sửa
import 'material_export_screen.dart';

class MaterialExportDetailScreen extends StatefulWidget {
  final MaterialExport export;

  const MaterialExportDetailScreen({super.key, required this.export});

  @override
  State<MaterialExportDetailScreen> createState() =>
      _MaterialExportDetailScreenState();
}

class _MaterialExportDetailScreenState
    extends State<MaterialExportDetailScreen> {
  @override
  void initState() {
    super.initState();
    // [MỚI] Đăng ký lắng nghe WebSocket
    WebSocketService().connect();
    WebSocketService().addListener(_onWebSocketMessage);
  }

  @override
  void dispose() {
    // [MỚI] Hủy lắng nghe WebSocket khi đóng màn hình
    WebSocketService().removeListener(_onWebSocketMessage);
    super.dispose();
  }

  // [MỚI] Xử lý WebSocket
  void _onWebSocketMessage(String message) {
    if (message == "REFRESH_MATERIAL_EXPORTS") {
      // Khi có thay đổi phiếu xuất từ server (do người khác sửa/xóa),
      // đẩy người dùng quay lại danh sách để load data mới cho an toàn, tránh ghi đè dữ liệu sai.
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Dữ liệu phiếu xuất đã được thay đổi trên server. Vui lòng xem lại danh sách."),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gán biến local để dễ gọi thay vì dùng widget.export liên tục
    final export = widget.export;

    // Format tiền tệ/số lượng/ngày tháng
    final numberFormat = NumberFormat("#,##0.##");
    final dateFormat = DateFormat("dd/MM/yyyy");

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text("Chi tiết phiếu: ${export.exportCode}"),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
        actions: [
          // Nút Sửa
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: "Chỉnh sửa phiếu",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MaterialExportScreen(
                      existingExport: export), // Truyền object để sửa
                ),
              ).then((_) {
                // Khi quay lại từ trang sửa, pop về list và báo hiệu cần reload
                if (mounted) {
                  Navigator.pop(context, true);
                }
              });
            },
          ),
          // Nút Xóa
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: "Hủy phiếu",
            onPressed: () => _confirmDelete(context, export),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. HEADER INFO ---
            _buildInfoCard(
              title: "THÔNG TIN CHUNG",
              children: [
                _buildRowInfo("Mã phiếu", export.exportCode, isBold: true),
                _buildRowInfo(
                    "Ngày xuất", dateFormat.format(export.exportDate)),
                const Divider(),
                _buildRowInfo("Kho xuất", "ID: ${export.warehouseId}"),
                _buildRowInfo("Người nhận", "ID: ${export.receiverId}"),
                _buildRowInfo("Ca làm việc",
                    export.shiftId != null ? "Ca ${export.shiftId}" : "--"),
                const Divider(),
                _buildRowInfo("Người tạo", export.createdBy ?? "N/A"),
                _buildRowInfo("Ghi chú", export.note ?? "--", maxLines: 3),
              ],
            ),

            const SizedBox(height: 16),

            // --- 2. CHI TIẾT VẬT TƯ ---
            Text("DANH SÁCH VẬT TƯ (${export.details.length})",
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF003366))),
            const SizedBox(height: 8),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: export.details.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = export.details[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Batch: ${item.batchId}",
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        Text("${numberFormat.format(item.quantity)} kg",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 16)),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                              Icons.layers, "Vật tư ID", "${item.materialId}"),
                          const SizedBox(height: 4),
                          _buildDetailRow(
                              Icons.precision_manufacturing,
                              "Máy / Line",
                              "Máy ${item.machineId} (L${item.machineLine})"),
                          const SizedBox(height: 4),
                          _buildDetailRow(Icons.shopping_bag, "Sản phẩm",
                              "ID: ${item.productId}"),
                          if (item.componentType != null) ...[
                            const SizedBox(height: 4),
                            _buildDetailRow(Icons.category, "Loại sợi",
                                item.componentType!),
                          ]
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
      {required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                    fontSize: 13)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildRowInfo(String label, String value,
      {bool isBold = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 100,
              child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: Colors.black87,
                  fontSize: 15),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text("$label: ",
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, MaterialExport exportData) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text("Hủy phiếu xuất", style: TextStyle(color: Colors.red)),
          ],
        ),
        content: const Text("Bạn có chắc chắn muốn hủy phiếu này không?\n\n"
            "- Số lượng xuất sẽ được hoàn trả lại tồn kho.\n"
            "- Dữ liệu đã hủy sẽ không thể khôi phục."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Đóng", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx); // Đóng dialog
              if (exportData.id != null) {
                context
                    .read<MaterialExportCubit>()
                    .deleteExport(exportData.id!);
                Navigator.pop(
                    context, true); // Pop màn hình detail về list và reload
              }
            },
            child: const Text("Xác nhận Hủy"),
          )
        ],
      ),
    );
  }
}
