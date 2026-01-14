class Machine {
  final int id;
  final String name;
  final int totalLines;
  final String purpose;
  final String status; // 'Running', 'Stopped', 'Maintenance', 'Spinning'
  final String? area;  // [MỚI] Thêm trường khu vực (Nullable)

  Machine({
    required this.id,
    required this.name,
    required this.totalLines,
    required this.purpose,
    required this.status,
    this.area, // [MỚI]
  });

  factory Machine.fromJson(Map<String, dynamic> json) {
    return Machine(
      id: json['machine_id'] ?? 0,
      name: json['machine_name'] ?? '',
      totalLines: json['total_lines'] ?? 0,
      purpose: json['purpose'] ?? '',
      // [CHÚ Ý] Backend có thể trả về UPPERCASE, cần xử lý hiển thị bên UI
      status: json['status'] ?? 'Stopped', 
      area: json['area'], // [MỚI] Map từ JSON
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