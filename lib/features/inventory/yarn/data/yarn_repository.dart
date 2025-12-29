import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../domain/yarn_model.dart';

class YarnRepository {
  final Dio _dio = ApiClient().dio;

  Future<List<Yarn>> getYarns() async {
    try {
      final response = await _dio.get('/api/v1/yarns');
      if (response.data is List) {
        return (response.data as List).map((e) => Yarn.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to load yarns: $e");
    }
  }

  // Tìm kiếm theo tên hoặc mã
  Future<List<Yarn>> searchYarns(String keyword) async {
    try {
      final response = await _dio.get(
        '/api/v1/yarns/search',
        queryParameters: {'keyword': keyword, 'skip': 0, 'limit': 100},
      );
      if (response.data is List) {
        return (response.data as List).map((e) => Yarn.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to search yarns: $e");
    }
  }

  Future<void> createYarn(Yarn yarn) async {
    try {
      await _dio.post('/api/v1/yarns', data: yarn.toJson());
    } catch (e) {
      throw Exception("Failed to create yarn: $e");
    }
  }

  Future<void> updateYarn(Yarn yarn) async {
    try {
      await _dio.put('/api/v1/yarns/${yarn.id}', data: yarn.toJson());
    } catch (e) {
      throw Exception("Failed to update yarn: $e");
    }
  }

  Future<void> deleteYarn(int id) async {
    try {
      await _dio.delete('/api/v1/yarns/$id');
    } catch (e) {
      throw Exception("Failed to delete yarn: $e");
    }
  }
}