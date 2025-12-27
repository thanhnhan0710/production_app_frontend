class Supplier {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String note;

  Supplier({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.note,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['supplier_id'] ?? 0,
      name: json['supplier_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      note: json['note'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'supplier_name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'note': note,
      // 'supplier_id': id, // Thường không gửi ID khi tạo mới
    };
  }
}