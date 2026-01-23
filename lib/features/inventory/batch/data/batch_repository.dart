import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../domain/batch_model.dart';

class BatchRepository {
  final Dio _dio = ApiClient().dio;

  // 1. Get all batches (có thể truyền params để lọc)
  Future<List<Batch>> getBatches({
    String? search,
    String? supplierBatch,
    int? materialId,
    String? qcStatus,
    int limit = 100,
    int skip = 0,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'limit': limit,
        'skip': skip,
      };

      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (supplierBatch != null && supplierBatch.isNotEmpty) queryParams['supplier_batch'] = supplierBatch;
      if (materialId != null) queryParams['material_id'] = materialId;
      if (qcStatus != null) queryParams['qc_status'] = qcStatus;

      final response = await _dio.get('/api/v1/batches/', queryParameters: queryParams);

      if (response.data is List) {
        return (response.data as List).map((e) => Batch.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to load batches: $e");
    }
  }

  // 2. Get Single Batch
  Future<Batch> getBatchById(int id) async {
    try {
      final response = await _dio.get('/api/v1/batches/$id');
      return Batch.fromJson(response.data);
    } catch (e) {
      throw Exception("Failed to load batch detail: $e");
    }
  }

  // 3. Create
  Future<void> createBatch(Batch batch) async {
    try {
      await _dio.post('/api/v1/batches/', data: batch.toJson());
    } catch (e) {
      throw Exception("Failed to create batch: $e");
    }
  }

  // 4. Update Info
  Future<void> updateBatch(Batch batch) async {
    try {
      await _dio.put('/api/v1/batches/${batch.batchId}', data: batch.toJson());
    } catch (e) {
      throw Exception("Failed to update batch: $e");
    }
  }

  // 5. Update QC Status (Hàm chuyên biệt)
  Future<void> updateQcStatus(int batchId, String status, {String? note}) async {
    try {
      final data = {'status': status}; // FastAPI query param or body logic
      // Lưu ý: Endpoint server khai báo: /qc-status?status=Pass&note=...
      // Hoặc nếu endpoint nhận query params:
      await _dio.put(
        '/api/v1/batches/$batchId/qc-status',
        queryParameters: {
          'status': status,
          if (note != null) 'note': note,
        },
      );
    } catch (e) {
      throw Exception("Failed to update QC status: $e");
    }
  }

  // 6. Delete
  Future<void> deleteBatch(int id) async {
    try {
      await _dio.delete('/api/v1/batches/$id');
    } catch (e) {
      // Backend sẽ trả về 400 nếu lô đã Pass QC -> Cần catch để hiện thông báo
      if (e is DioException && e.response?.statusCode == 400) {
        throw Exception(e.response?.data['detail'] ?? "Không thể xóa lô hàng này.");
      }
      throw Exception("Failed to delete batch: $e");
    }
  }
}