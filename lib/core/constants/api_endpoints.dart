class ApiEndpoints {
  // Với Web App chạy local, dùng localhost là đúng.
  // QUAN TRỌNG: Phải là http (không có s)
  static const String baseUrl = 'http://localhost:8000/api/v1'; 
  
  static const String authLogin = '$baseUrl/login/access-token';
  static const String usersMe = '$baseUrl/users/me'; // API lấy thông tin user
}