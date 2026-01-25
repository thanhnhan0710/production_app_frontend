// features/inventory/bom/data/bom_repository.dart

import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../domain/bom_model.dart';

class BOMRepository {
  final Dio _dio = ApiClient().dio;

  // Get all BOMs (có hỗ trợ filter nếu cần, ở đây viết hàm get all cơ bản)
  Future<List<BOMHeader>> getBOMs() async {
    try {
      final response = await _dio.get('/api/v1/boms/');
      if (response.data is List) {
        return (response.data as List)
            .map((e) => BOMHeader.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to load BOMs: $e");
    }
  }

  // Search BOMs (Tìm theo Product Code hoặc BOM Code)
  // Dựa vào Backend: GET /api/v1/boms/?product_code=...&bom_code=...
  Future<List<BOMHeader>> searchBOMs({String? keyword}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (keyword != null && keyword.isNotEmpty) {
        // Giả định search chung keyword cho cả bom_code và product_code
        // Hoặc bạn có thể tách ra tùy UI. Ở đây mình ưu tiên tìm theo bom_code
        queryParams['bom_code'] = keyword; 
      }

      final response = await _dio.get(
        '/api/v1/boms/',
        queryParameters: queryParams,
      );

      if (response.data is List) {
        return (response.data as List)
            .map((e) => BOMHeader.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception("BOMs not found: $e");
    }
  }

  // Get BOM Detail by ID
  Future<BOMHeader> getBOMById(int id) async {
    try {
      final response = await _dio.get('/api/v1/boms/$id');
      return BOMHeader.fromJson(response.data);
    } catch (e) {
      throw Exception("Failed to load BOM detail: $e");
    }
  }

  // Create BOM
  Future<void> createBOM(BOMHeader bom) async {
    try {
      // Backend mong đợi: product_id, bom_code, details, etc...
      await _dio.post('/api/v1/boms/', data: bom.toJson());
    } catch (e) {
      throw Exception("Failed to create BOM: $e");
    }
  }

  // Update BOM
  Future<void> updateBOM(BOMHeader bom) async {
    try {
      await _dio.put('/api/v1/boms/${bom.bomId}', data: bom.toJson());
    } catch (e) {
      throw Exception("Failed to update BOM: $e");
    }
  }

  // Delete BOM
  Future<void> deleteBOM(int id) async {
    try {
      await _dio.delete('/api/v1/boms/$id');
    } catch (e) {
      throw Exception("Failed to delete BOM: $e");
    }
  }
}