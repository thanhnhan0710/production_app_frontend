class ProductUnit {
  final int id;
  final String name;
  final String note;

  ProductUnit({
    required this.id,
    required this.name,
    required this.note,
  });

  factory ProductUnit.fromJson(Map<String, dynamic> json) {
    return ProductUnit(
      id: json['unit_id'] ?? 0,
      name: json['unit_name'] ?? '',
      note: json['note'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unit_name': name,
      'note': note,
      // 'unit_id': id, // Thường không gửi ID khi tạo mới
    };
  }
}