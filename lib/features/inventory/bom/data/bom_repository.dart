import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../domain/bom_model.dart';

class BOMRepository {
  final Dio _dio = ApiClient().dio;

  // ==========================================
  // BOM HEADER OPERATIONS
  // ==========================================

  /// Lấy danh sách BOM (Mặc định lấy tất cả hoặc phân trang)
  /// Tương tự getProducts()
  Future<List<BOMHeader>> getBOMHeaders() async {
    try {
      final response = await _dio.get('/api/v1/bom-headers/');
      if (response.data is List) {
        return (response.data as List).map((e) => BOMHeader.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to load BOMs: $e");
    }
  }

  /// Tìm kiếm và Lọc BOM Header
  /// Tương tự searchProducts(keyword) nhưng có thêm productId
  Future<List<BOMHeader>> searchBOMHeaders({String? keyword, int? productId}) async {
    try {
      // [FIX ERROR] Khai báo tường minh Map<String, dynamic>
      final Map<String, dynamic> query = {
        'skip': 0,
        'limit': 100,
      };

      if (keyword != null && keyword.isNotEmpty) {
        query['keyword'] = keyword;
      }
      if (productId != null) {
        query['product_id'] = productId;
      }

      final response = await _dio.get(
        '/api/v1/bom-headers/search',
        queryParameters: query,
      );

      if (response.data is List) {
        return (response.data as List).map((e) => BOMHeader.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to search BOMs: $e");
    }
  }

  /// Lấy chi tiết 1 BOM kèm danh sách nguyên liệu
  Future<BOMHeader> getBOMHeaderById(int id) async {
    try {
      final response = await _dio.get('/api/v1/bom-headers/$id');
      return BOMHeader.fromJson(response.data);
    } catch (e) {
      throw Exception("Failed to load BOM Detail: $e");
    }
  }

  Future<void> createBOMHeader(BOMHeader item) async {
    try {
      await _dio.post('/api/v1/bom-headers/', data: item.toJson());
    } catch (e) {
      throw Exception("Failed to create BOM: $e");
    }
  }

  Future<void> updateBOMHeader(BOMHeader item) async {
    try {
      await _dio.put('/api/v1/bom-headers/${item.bomId}', data: item.toJson());
    } catch (e) {
      throw Exception("Failed to update BOM: $e");
    }
  }

  Future<void> deleteBOMHeader(int id) async {
    try {
      await _dio.delete('/api/v1/bom-headers/$id');
    } catch (e) {
      throw Exception("Failed to delete BOM: $e");
    }
  }

  // ==========================================
  // BOM DETAIL OPERATIONS
  // ==========================================

  Future<void> createBOMDetail(BOMDetail item) async {
    try {
      await _dio.post('/api/v1/bom-details/', data: item.toJson());
    } catch (e) {
      throw Exception("Failed to add detail: $e");
    }
  }

  Future<void> updateBOMDetail(BOMDetail item) async {
    try {
      await _dio.put('/api/v1/bom-details/${item.detailId}', data: item.toJson());
    } catch (e) {
      throw Exception("Failed to update detail: $e");
    }
  }

  Future<void> deleteBOMDetail(int id) async {
    try {
      await _dio.delete('/api/v1/bom-details/$id');
    } catch (e) {
      throw Exception("Failed to delete detail: $e");
    }
  }
}