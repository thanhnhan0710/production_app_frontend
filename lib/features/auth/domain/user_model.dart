class User {
  // Đổi tên biến id thành userId để phản ánh key từ Backend
  final int id; 
  final String email;
  final String fullName;
  final String phoneNumber;
  final bool isActive;
  final bool isSuperuser;
  final String role;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.isActive,
    required this.isSuperuser,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // ----------------------------------------------------------------------
    // [FIX 1]: SỬA TÊN KEY: Dùng 'user_id' thay vì 'id'
    // ----------------------------------------------------------------------
    final int? userId = json['user_id'] as int?;
    final String? userEmail = json['email'] as String?;

    if (userId == null || userEmail == null) {
      // Đổi lại thông báo lỗi cho chính xác hơn
      throw const FormatException("Lỗi: Server không trả về 'user_id' hoặc 'email' hợp lệ.");
    }

    return User(
      // Gán user_id (từ JSON) vào biến id (trong Dart Class)
      id: userId,
      email: userEmail,
      
      // Các trường còn lại không bị ảnh hưởng, nhưng thêm check String?
      fullName: (json['full_name'] as String?) ?? '', 
      phoneNumber: (json['phone_number'] as String?) ?? '',
      
      isActive: json['is_active'] as bool? ?? true, 
      isSuperuser: json['is_superuser'] as bool? ?? false,
      role: (json['role'] as String?) ?? 'staff',
    );
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, fullName: $fullName, role: $role)';
  }
}