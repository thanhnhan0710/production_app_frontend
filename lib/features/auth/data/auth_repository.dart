import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../domain/user_model.dart';

class AuthRepository {
  final Dio _dio = ApiClient().dio;

  Future<User> login(String username, String password) async {
    try {
      // 1. Gọi endpoint login (OAuth2PasswordRequestForm thường gửi form-data)
      final response = await _dio.post(
        '/api/v1/login/access-token', // Endpoint FastAPI mặc định
        data: FormData.fromMap({
          'username': username,
          'password': password,
        }),
      );

      // 2. Lưu token
      final token = response.data['access_token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);

      // 3. Gọi endpoint lấy thông tin user (me)
      final userResponse = await _dio.get('/api/v1/users/me'); // Endpoint FastAPI
      return User.fromJson(userResponse.data);

    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Login failed');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }
}