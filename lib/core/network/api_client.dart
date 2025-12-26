import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  final Dio dio;

  ApiClient._internal() : dio = Dio() {
    // 1. Cấu hình cơ bản (Base URL)
    dio.options.baseUrl = 'http://localhost:8000'; // Đảm bảo URL này đúng
    dio.options.connectTimeout = const Duration(seconds: 15);
    dio.options.receiveTimeout = const Duration(seconds: 15);
    
    // 2. [QUAN TRỌNG]: Thêm Interceptor để tự động thêm Token
    // FIX: Thay QueuedInterceptor bằng InterceptorsWrapper để sử dụng named parameter onRequest/onResponse
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('access_token');
          
          // Chỉ thêm Authorization Header nếu Token tồn tại
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        // Có thể thêm onError, onResponse ở đây nếu cần
      ),
    );
  }

  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() => _instance;
}