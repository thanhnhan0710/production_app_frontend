class Machine {
  final int id;
  final String name;
  final int totalLines;
  final String purpose;
  final String status; // 'Running', 'Stopped', 'Maintenance', 'Spinning'
  final String? area;  

  Machine({
    required this.id,
    required this.name,
    required this.totalLines,
    required this.purpose,
    required this.status,
    this.area,
  });

  // [BỔ SUNG QUAN TRỌNG] Hàm copyWith để cập nhật trạng thái
  Machine copyWith({
    int? id,
    String? name,
    int? totalLines,
    String? purpose,
    String? status,
    String? area,
  }) {
    return Machine(
      id: id ?? this.id,
      name: name ?? this.name,
      totalLines: totalLines ?? this.totalLines,
      purpose: purpose ?? this.purpose,
      status: status ?? this.status,
      area: area ?? this.area,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'machine_name': name,
      'total_lines': totalLines,
      'purpose': purpose,
      'status': status.toUpperCase(),
      'area': (area == null || area!.trim().isEmpty) ? null : area,
    };
  }
}