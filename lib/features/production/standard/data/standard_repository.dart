import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../domain/standard_model.dart';

class StandardRepository {
  final Dio _dio = ApiClient().dio;

  Future<List<Standard>> getStandards() async {
    try {
      final response = await _dio.get('/api/v1/standards');
      if (response.data is List) {
        return (response.data as List).map((e) => Standard.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to load standards: $e");
    }
  }

  Future<List<Standard>> searchStandards(String keyword) async {
    try {
      final response = await _dio.get(
        '/api/v1/standards/search',
        queryParameters: {'keyword': keyword, 'skip': 0, 'limit': 100},
      );
      if (response.data is List) {
        return (response.data as List).map((e) => Standard.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to search standards: $e");
    }
  }

  Future<void> createStandard(Standard item) async {
    try {
      await _dio.post('/api/v1/standards', data: item.toJson());
    } catch (e) {
      throw Exception("Failed to create standard: $e");
    }
  }

  Future<void> updateStandard(Standard item) async {
    try {
      await _dio.put('/api/v1/standards/${item.id}', data: item.toJson());
    } catch (e) {
      throw Exception("Failed to update standard: $e");
    }
  }

  Future<void> deleteStandard(int id) async {
    try {
      await _dio.delete('/api/v1/standards/$id');
    } catch (e) {
      throw Exception("Failed to delete standard: $e");
    }
  }
}