class Warehouse {
  final int id;
  final String name;
  final String location;
  final String description;

  Warehouse({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
  });

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    return Warehouse(
      // Mapping theo key từ backend trả về (thường là snake_case)
      id: json['warehouse_id'] ?? 0,
      name: json['warehouse_name'] ?? '',
      location: json['location'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'warehouse_id': id,
      'warehouse_name': name,
      'location': location,
      'description': description,
    };
  }

  // Helper để tạo copy mới khi cần sửa 1 vài field
  Warehouse copyWith({
    int? id,
    String? name,
    String? location,
    String? description,
  }) {
    return Warehouse(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      description: description ?? this.description,
    );
  }
}