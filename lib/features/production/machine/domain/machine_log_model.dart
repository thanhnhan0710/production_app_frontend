class MachineLog {
  final int id;
  final int machineId;
  final String status;
  final DateTime startTime;
  final DateTime? endTime;
  final double durationMinutes; // Backend đã tính sẵn
  final String? reason;
  final String? imageUrl;

  MachineLog({
    required this.id,
    required this.machineId,
    required this.status,
    required this.startTime,
    this.endTime,
    this.durationMinutes = 0.0,
    this.reason,
    this.imageUrl,
  });

  factory MachineLog.fromJson(Map<String, dynamic> json) {
    return MachineLog(
      id: json['id'] ?? 0,
      machineId: json['machine_id'] ?? 0,
      status: json['status'] ?? 'UNKNOWN',
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      durationMinutes: (json['duration_minutes'] ?? 0.0).toDouble(),
      reason: json['reason'],
      imageUrl: json['image_url'],
    );
  }
}