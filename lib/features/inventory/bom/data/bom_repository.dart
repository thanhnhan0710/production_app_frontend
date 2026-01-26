// features/inventory/bom/data/bom_repository.dart

import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../domain/bom_model.dart'; // Đảm bảo import đúng file model mới sửa

class BOMRepository {
  final Dio _dio = ApiClient().dio;
  final String _endpoint = '/api/v1/boms/';

  /// Lấy danh sách BOM (Hỗ trợ lọc theo Product Code hoặc Năm)
  /// Backend API: GET /api/v1/boms/?product_code=...&year=...&is_active=...
  Future<List<BOMHeader>> getBOMs({String? productCode, int? year}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      
      if (productCode != null && productCode.isNotEmpty) {
        queryParams['product_code'] = productCode;
      }
      
      if (year != null) {
        queryParams['year'] = year; // Backend nhận tham số 'year'
      }

      final response = await _dio.get(
        _endpoint,
        queryParameters: queryParams,
      );

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

  /// Hàm tìm kiếm thông minh từ Search Bar
  /// Logic: 
  /// - Nếu keyword là 4 chữ số (VD: 2026) -> Tìm theo Năm
  /// - Nếu keyword là chữ -> Tìm theo Product Code
  Future<List<BOMHeader>> searchBOMs(String keyword) async {
    try {
      final Map<String, dynamic> queryParams = {};
      
      if (keyword.isNotEmpty) {
        // Kiểm tra xem keyword có phải là năm không (4 chữ số)
        final int? parsedYear = int.tryParse(keyword);
        
        if (parsedYear != null && keyword.length == 4) {
          queryParams['year'] = parsedYear;
        } else {
          queryParams['product_code'] = keyword;
        }
      }

      final response = await _dio.get(
        _endpoint,
        queryParameters: queryParams,
      );

      if (response.data is List) {
        return (response.data as List)
            .map((e) => BOMHeader.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      // Xử lý lỗi (Có thể return list rỗng thay vì throw nếu muốn UI không crash)
      throw Exception("Error searching BOMs: $e");
    }
  }

  /// Get BOM Detail by ID
  Future<BOMHeader> getBOMById(int id) async {
    try {
      final response = await _dio.get('$_endpoint$id');
      return BOMHeader.fromJson(response.data);
    } catch (e) {
      throw Exception("Failed to load BOM detail: $e");
    }
  }

  /// Create BOM
  /// Model BOMHeader đã update toJson() chứa 'applicable_year' thay vì 'bom_code'
  Future<void> createBOM(BOMHeader bom) async {
    try {
      await _dio.post(_endpoint, data: bom.toJson());
    } catch (e) {
      // Xử lý lỗi cụ thể từ Backend (VD: Trùng năm)
      if (e is DioException && e.response?.statusCode == 400) {
        throw Exception(e.response?.data['detail'] ?? "Lỗi tạo BOM");
      }
      throw Exception("Failed to create BOM: $e");
    }
  }

  /// Update BOM
  Future<void> updateBOM(BOMHeader bom) async {
    try {
      await _dio.put('$_endpoint${bom.bomId}', data: bom.toJson());
    } catch (e) {
       if (e is DioException && e.response?.statusCode == 400) {
        throw Exception(e.response?.data['detail'] ?? "Lỗi cập nhật BOM");
      }
      throw Exception("Failed to update BOM: $e");
    }
  }

  /// Delete BOM
  Future<void> deleteBOM(int id) async {
    try {
      await _dio.delete('$_endpoint$id');
    } catch (e) {
      throw Exception("Failed to delete BOM: $e");
    }
  }
}