class Machine {
  final int id;
  final String name;
  final int totalLines;
  final String purpose;
  final String status; // 'Running', 'Stopped', 'Maintenance'
  final int supplierId;

  Machine({
    required this.id,
    required this.name,
    required this.totalLines,
    required this.purpose,
    required this.status,
    required this.supplierId,
  });

  factory Machine.fromJson(Map<String, dynamic> json) {
    return Machine(
      id: json['machine_id'] ?? 0,
      name: json['machine_name'] ?? '',
      totalLines: json['total_lines'] ?? 0,
      purpose: json['purpose'] ?? '',
      status: json['status'] ?? 'Stopped',
      supplierId: json['supplier_id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'machine_name': name,
      'total_lines': totalLines,
      'purpose': purpose,
      'status': status,
      'supplier_id': supplierId,
    };
  }
}