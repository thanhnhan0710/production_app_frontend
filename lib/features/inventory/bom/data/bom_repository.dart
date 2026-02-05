import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../domain/bom_model.dart';

class BOMRepository {
  final Dio _dio = ApiClient().dio;
  final String _endpoint = '/api/v1/boms/';

  Future<List<BOMHeader>> getBOMs({String? productCode, int? year}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (productCode != null && productCode.isNotEmpty) queryParams['product_code'] = productCode;
      if (year != null) queryParams['year'] = year;

      final response = await _dio.get(_endpoint, queryParameters: queryParams);

      if (response.data is List) {
        return (response.data as List).map((e) => BOMHeader.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to load BOMs: $e");
    }
  }

  Future<List<BOMHeader>> searchBOMs(String keyword) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (keyword.isNotEmpty) {
        final int? parsedYear = int.tryParse(keyword);
        if (parsedYear != null && keyword.length == 4) {
          queryParams['year'] = parsedYear;
        } else {
          queryParams['product_code'] = keyword;
        }
      }
      final response = await _dio.get(_endpoint, queryParameters: queryParams);
      if (response.data is List) {
        return (response.data as List).map((e) => BOMHeader.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Error searching BOMs: $e");
    }
  }

  Future<BOMHeader> getBOMById(int id) async {
    try {
      final response = await _dio.get('$_endpoint$id');
      return BOMHeader.fromJson(response.data);
    } catch (e) {
      throw Exception("Failed to load BOM detail: $e");
    }
  }

  // [MỚI] Hàm lấy bảng tổng hợp số cuộn
  Future<List<BOMMaterialSummary>> getBOMSummary(int bomId) async {
    try {
      final response = await _dio.get('$_endpoint$bomId/summary');
      if (response.data is List) {
        return (response.data as List).map((e) => BOMMaterialSummary.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      // Return empty list instead of throwing to prevent UI crash
      print("Error loading summary: $e");
      return [];
    }
  }

  Future<void> createBOM(BOMHeader bom) async {
    try {
      await _dio.post(_endpoint, data: bom.toJson());
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 400) {
        throw Exception(e.response?.data['detail'] ?? "Lỗi tạo BOM");
      }
      throw Exception("Failed to create BOM: $e");
    }
  }

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

  Future<void> deleteBOM(int id) async {
    try {
      await _dio.delete('$_endpoint$id');
    } catch (e) {
      throw Exception("Failed to delete BOM: $e");
    }
  }
}