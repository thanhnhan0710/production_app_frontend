import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart'; // Đảm bảo đường dẫn đúng
import '../domain/weaving_production_model.dart';

class WeavingProductionRepository {
  final Dio _dio = ApiClient().dio;

  Future<List<WeavingDailyProduction>> searchProductions({
    String? keyword,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'skip': 0,
        'limit': 100, // Tăng giới hạn nếu cần
      };

      if (keyword != null && keyword.isNotEmpty) {
        queryParams['keyword'] = keyword;
      }
      
      // Format DateTime thành chuỗi YYYY-MM-DD cho Backend
      if (fromDate != null) {
        queryParams['from_date'] = "${fromDate.year}-${fromDate.month.toString().padLeft(2, '0')}-${fromDate.day.toString().padLeft(2, '0')}";
      }
      if (toDate != null) {
        queryParams['to_date'] = "${toDate.year}-${toDate.month.toString().padLeft(2, '0')}-${toDate.day.toString().padLeft(2, '0')}";
      }

      // Gọi Endpoint
      final response = await _dio.get(
        '/api/v1/weaving-daily-productions/search', 
        queryParameters: queryParams
      );

      if (response.data is List) {
        return (response.data as List)
            .map((e) => WeavingDailyProduction.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception("Lỗi tải thống kê sản lượng: $e");
    }
  }
  
  Future<void> calculateDailyManual(DateTime date) async {
     try {
       final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
       
       // [CHECK LẠI] Đảm bảo đường dẫn này khớp với Backend
       // Nếu Backend là @router.post("/calculate-manual") thì sửa dòng dưới:
       await _dio.post(
           '/api/v1/weaving-daily-productions/calculate-manual', 
           queryParameters: {'target_date': dateStr}
       );
     } catch (e) {
       throw Exception("Lỗi tính toán lại: $e");
     }
  }
}