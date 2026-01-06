import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../domain/dye_color_model.dart';

class DyeColorRepository {
  final Dio _dio = ApiClient().dio;

  Future<List<DyeColor>> getColors() async {
    try {
      final response = await _dio.get('/api/v1/dye-colors'); // Endpoint giả định
      if (response.data is List) {
        return (response.data as List).map((e) => DyeColor.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to load colors: $e");
    }
  }

  Future<List<DyeColor>> searchColors(String keyword) async {
    try {
      final response = await _dio.get(
        '/api/v1/dye-colors/search',
        queryParameters: {'keyword': keyword, 'skip': 0, 'limit': 100},
      );
      if (response.data is List) {
        return (response.data as List).map((e) => DyeColor.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to search colors: $e");
    }
  }

  Future<void> createColor(DyeColor color) async {
    try {
      await _dio.post('/api/v1/dye-colors', data: color.toJson());
    } catch (e) {
      throw Exception("Failed to create color: $e");
    }
  }

  Future<void> updateColor(DyeColor color) async {
    try {
      await _dio.put('/api/v1/dye-colors/${color.id}', data: color.toJson());
    } catch (e) {
      throw Exception("Failed to update color: $e");
    }
  }

  Future<void> deleteColor(int id) async {
    try {
      await _dio.delete('/api/v1/dye-colors/$id');
    } catch (e) {
      throw Exception("Failed to delete color: $e");
    }
  }
}