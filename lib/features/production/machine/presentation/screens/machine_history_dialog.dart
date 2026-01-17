import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:production_app_frontend/l10n/app_localizations.dart'; // Import Localization
import '../../data/machine_repository.dart';
import '../../domain/machine_model.dart';
import '../../domain/machine_log_model.dart';

class MachineHistoryDialog extends StatelessWidget {
  final Machine machine;
  final MachineRepository _repo = MachineRepository(); 

  MachineHistoryDialog({super.key, required this.machine});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Lấy instance

    return AlertDialog(
      title: Text(l10n.machineHistoryTitle(machine.name)),
      content: SizedBox(
        width: 500,
        height: 600,
        child: FutureBuilder<List<MachineLog>>(
          future: _repo.getMachineHistory(machine.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("${l10n.errorGeneric}: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
            }
            
            final logs = snapshot.data ?? [];
            if (logs.isEmpty) {
              return Center(child: Text(l10n.noHistoryData));
            }

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
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 12),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      statusText.toUpperCase(),
                      style: TextStyle(fontWeight: FontWeight.bold, color: statusColor),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                      child: Text(durationStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                
                Text(
                  "${timeFormat.format(log.startTime)} - ${log.endTime != null ? timeFormat.format(log.endTime!) : l10n.timeCurrent}",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),

                if (log.reason != null && log.reason!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(l10n.reasonLabel(log.reason!), style: const TextStyle(fontStyle: FontStyle.italic)),
                ],

                if (log.imageUrl != null && log.imageUrl!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      log.imageUrl!,
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

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