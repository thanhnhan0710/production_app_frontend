import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../domain/unit_model.dart';

class UnitRepository {
  final Dio _dio = ApiClient().dio;

  // Lấy danh sách (Mặc định)
  Future<List<ProductUnit>> getUnits() async {
    try {
      final response = await _dio.get('/api/v1/units');
      if (response.data is List) {
        return (response.data as List).map((e) => ProductUnit.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to load units: $e");
    }
  }

  // Tìm kiếm
  Future<List<ProductUnit>> searchUnits(String keyword) async {
    try {
      final response = await _dio.get(
        '/api/v1/units/search',
        queryParameters: {'keyword': keyword, 'skip': 0, 'limit': 100},
      );
      if (response.data is List) {
        return (response.data as List).map((e) => ProductUnit.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to search units: $e");
    }
  }

  Future<void> createUnit(ProductUnit unit) async {
    try {
      await _dio.post('/api/v1/units', data: unit.toJson());
    } catch (e) {
      throw Exception("Failed to create unit: $e");
    }
  }

  Future<void> updateUnit(ProductUnit unit) async {
    try {
      await _dio.put('/api/v1/units/${unit.id}', data: unit.toJson());
    } catch (e) {
      throw Exception("Failed to update unit: $e");
    }
  }

  Future<void> deleteUnit(int id) async {
    try {
      await _dio.delete('/api/v1/units/$id');
    } catch (e) {
      throw Exception("Failed to delete unit: $e");
    }
  }
}