class Machine {
  final int id;
  final String name;
  final int totalLines;
  final String purpose;
  final String status;
  final String? area;
  // [BỔ SUNG] 2 trường mới
  final String? serialNumber;
  final int? speed;

  Machine({
    required this.id,
    required this.name,
    required this.totalLines,
    required this.purpose,
    required this.status,
    this.area,
    this.serialNumber,
    this.speed,
  });

  Machine copyWith({
    int? id,
    String? name,
    int? totalLines,
    String? purpose,
    String? status,
    String? area,
    String? serialNumber,
    int? speed,
  }) {
    return Machine(
      id: id ?? this.id,
      name: name ?? this.name,
      totalLines: totalLines ?? this.totalLines,
      purpose: purpose ?? this.purpose,
      status: status ?? this.status,
      area: area ?? this.area,
      serialNumber: serialNumber ?? this.serialNumber,
      speed: speed ?? this.speed,
    );
  }

  factory Machine.fromJson(Map<String, dynamic> json) {
    return Machine(
      id: json['machine_id'] ?? 0,
      name: json['machine_name'] ?? '',
      totalLines: json['total_lines'] ?? 0,
      purpose: json['purpose'] ?? '',
      status: json['status'] ?? 'Stopped',
      area: json['area'],
      serialNumber: json['serial_number'],
      speed: json['speed'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'machine_name': name,
      'total_lines': totalLines,
      'purpose': purpose,
      'status': status.toUpperCase(),
      'area': (area == null || area!.trim().isEmpty) ? null : area,
      'serial_number': serialNumber,
      'speed': speed,
    };
  }
}
