import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:production_app_frontend/core/constants/api_endpoints.dart';
import 'package:production_app_frontend/l10n/app_localizations.dart';

// Import Repository và Model
import '../../data/machine_repository.dart';
import '../../domain/machine_model.dart';
import '../../domain/machine_log_model.dart';

// [QUAN TRỌNG] Thay đổi đường dẫn này trỏ tới đúng file ApiEndpoints trong dự án của bạn
// Ví dụ: import 'package:production_app_frontend/core/configs/api_endpoints.dart';

class MachineHistoryDialog extends StatelessWidget {
  final Machine machine;
  final MachineRepository _repo = MachineRepository();

  MachineHistoryDialog({super.key, required this.machine});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.machineHistoryTitle(machine.name)),
      content: SizedBox(
        width: 500,
        height: 600,
        child: FutureBuilder<List<MachineLog>>(
          future: _repo.getMachineHistory(machine.id),
          builder: (context, snapshot) {
            // 1. Trạng thái đang tải
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // 2. Trạng thái lỗi
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  "${l10n.errorGeneric}: ${snapshot.error}",
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              );
            }

            // 3. Xử lý dữ liệu rỗng
            final logs = snapshot.data ?? [];
            if (logs.isEmpty) {
              return Center(child: Text(l10n.noHistoryData));
            }

            // 4. Hiển thị danh sách log
            return ListView.separated(
              itemCount: logs.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final log = logs[index];
                return _buildLogItem(context, log, l10n);
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        )
      ],
    );
  }

  Widget _buildLogItem(BuildContext context, MachineLog log, AppLocalizations l10n) {
    Color statusColor = Colors.grey;
    IconData icon = Icons.info;
    String statusText = log.status;

    // Xử lý màu sắc và icon dựa trên trạng thái
    switch (log.status.toUpperCase()) {
      case 'RUNNING':
        statusColor = Colors.blue;
        icon = Icons.play_arrow;
        statusText = l10n.statusRunning;
        break;
      case 'STOPPED':
        statusColor = Colors.red;
        icon = Icons.stop;
        statusText = l10n.statusStopped;
        break;
      case 'MAINTENANCE':
        statusColor = Colors.orange;
        icon = Icons.build;
        statusText = l10n.statusMaintenance;
        break;
      case 'SPINNING':
        statusColor = Colors.purple;
        icon = Icons.loop;
        statusText = l10n.statusSpinning;
        break;
    }

    final durationStr = _formatDuration(log.durationMinutes, l10n);
    final timeFormat = DateFormat("dd/MM HH:mm");

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- ICON TRẠNG THÁI ---
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 12),

          // --- NỘI DUNG CHI TIẾT ---
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Trạng thái & Thời gian chạy
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      statusText.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        durationStr,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Thời gian bắt đầu - kết thúc
                Text(
                  "${timeFormat.format(log.startTime)} - ${log.endTime != null ? timeFormat.format(log.endTime!) : l10n.timeCurrent}",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),

                // Lý do (nếu có)
                if (log.reason != null && log.reason!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.reasonLabel(log.reason!),
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],

                // --- HIỂN THỊ ẢNH LOG (SỬ DỤNG API ENDPOINTS) ---
                if (log.imageUrl != null && log.imageUrl!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Builder(builder: (context) {
                    // Lấy Full URL thông qua ApiEndpoints (giống logic Avatar)
                    final fullUrl = ApiEndpoints.getImageUrl(log.imageUrl!);
                    debugPrint("LOG: Đang tải ảnh từ URL: $fullUrl");

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        fullUrl,
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                        
                        // Xử lý khi ảnh lỗi (404, sai đường dẫn...)
                        errorBuilder: (ctx, err, stack) => Container(
                          height: 100,
                          width: 100,
                          color: Colors.grey.shade200,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, color: Colors.grey),
                              SizedBox(height: 4),
                              Text("Lỗi ảnh", style: TextStyle(fontSize: 10, color: Colors.grey))
                            ],
                          ),
                        ),

                        // Xử lý khi đang tải ảnh
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 100,
                            width: 100,
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Hàm format thời gian (phút -> giờ phút)
  String _formatDuration(double minutes, AppLocalizations l10n) {
    if (minutes < 60) {
      return l10n.durationFormatMin(minutes.toStringAsFixed(1));
    } else {
      final hours = (minutes / 60).floor();
      final mins = (minutes % 60).toInt();
      return l10n.durationFormatHour(hours, mins);
    }
  }
}