class ApiEndpoints {
  // Đường dẫn gốc (Thay bằng IP máy tính của bạn nếu chạy máy ảo: 10.0.2.2)
  static const String baseUrl = 'https://localhost:8000/v1';
  
  // Các đường dẫn con
  static const String authLogin = '$baseUrl/auth/login';
  static const String employees = '$baseUrl/employees';
  static const String departments = '$baseUrl/departments';
}