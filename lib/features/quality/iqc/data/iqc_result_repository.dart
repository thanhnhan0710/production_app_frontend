import 'package:dio/dio.dart';
import '../../../../../core/network/api_client.dart';
import '../domain/iqc_result_model.dart';

class IQCResultRepository {
  final Dio _dio = ApiClient().dio;
  // Đường dẫn API (Cần đảm bảo Router Backend đã đăng ký prefix này)
  static const String _endpoint = '/api/v1/iqc-results';

  // 1. Lấy danh sách kết quả (Có thể lọc theo Batch ID)
  Future<List<IQCResult>> getIQCResults({int? batchId, int skip = 0, int limit = 100}) async {
    try {
      final queryParams = {
        'skip': skip,
        'limit': limit,
        if (batchId != null) 'batch_id': batchId,
      };

      final response = await _dio.get(_endpoint, queryParameters: queryParams);

      if (response.data is List) {
        return (response.data as List)
            .map((e) => IQCResult.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to load IQC results: $e");
    }
  }

  // 2. Lấy chi tiết 1 phiếu test
  Future<IQCResult> getIQCResultById(int testId) async {
    try {
      final response = await _dio.get('$_endpoint/$testId');
      return IQCResult.fromJson(response.data);
    } catch (e) {
      throw Exception("Failed to get IQC detail: $e");
    }
  }

  // 3. Tạo phiếu test mới
  Future<void> createIQCResult(IQCResult result) async {
    try {
      await _dio.post('$_endpoint/', data: result.toJson());
    } catch (e) {
      throw Exception("Failed to create IQC result: $e");
    }
  }

  // 4. Cập nhật phiếu test
  Future<void> updateIQCResult(IQCResult result) async {
    if (result.testId == null) return;
    try {
      await _dio.put('$_endpoint/${result.testId}', data: result.toJson());
    } catch (e) {
      throw Exception("Failed to update IQC result: $e");
    }
  }
}