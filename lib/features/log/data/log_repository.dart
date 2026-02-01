import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart'; // Đường dẫn tới file cấu hình Dio của bạn
import '../domain/log_model.dart';

class LogRepository {
  final Dio _dio = ApiClient().dio;

  // Lấy danh sách log có phân trang & lọc
  Future<List<LogModel>> getLogs({
    int skip = 0,
    int limit = 50,
    String? targetType,
    int? targetId,
    int? userId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/logs', // Endpoint backend bạn đã viết
        queryParameters: {
          'skip': skip,
          'limit': limit,
          if (targetType != null) 'target_type': targetType,
          if (targetId != null) 'target_id': targetId,
          if (userId != null) 'user_id': userId,
          if (fromDate != null) 'from_date': fromDate.toIso8601String(),
          if (toDate != null) 'to_date': toDate.toIso8601String(),
        },
      );

      if (response.data is List) {
        return (response.data as List).map((e) => LogModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Lỗi tải nhật ký: $e");
    }
  }
  
  Future<void> revertLog(int logId) async {
    try {
      await _dio.post('/api/v1/logs/$logId/revert');
    } catch (e) {
      // Xử lý lỗi đẹp hơn để hiển thị UI
      if (e is DioException) {
         throw Exception(e.response?.data['detail'] ?? "Lỗi kết nối");
      }
      throw Exception("Không thể hoàn tác: $e");
    }
  }
}