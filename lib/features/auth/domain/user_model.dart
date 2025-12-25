class User {
  final int id;
  final String email;
  final String fullName;
  final bool isActive;

  User({required this.id, required this.email, required this.fullName, required this.isActive});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'] ?? '',
      isActive: json['is_active'] ?? true,
    );
  }
}