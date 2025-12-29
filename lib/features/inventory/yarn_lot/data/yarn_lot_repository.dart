import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../domain/yarn_lot_model.dart';

class YarnLotRepository {
  final Dio _dio = ApiClient().dio;

  Future<List<YarnLot>> getYarnLots() async {
    try {
      final response = await _dio.get('/api/v1/yarn-lots'); // Endpoint giả định
      if (response.data is List) {
        return (response.data as List).map((e) => YarnLot.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to load yarn lots: $e");
    }
  }

  Future<List<YarnLot>> searchYarnLots(String keyword) async {
    try {
      final response = await _dio.get(
        '/api/v1/yarn-lots/search',
        queryParameters: {'keyword': keyword, 'skip': 0, 'limit': 100},
      );
      if (response.data is List) {
        return (response.data as List).map((e) => YarnLot.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to search yarn lots: $e");
    }
  }

  Future<void> createYarnLot(YarnLot lot) async {
    try {
      await _dio.post('/api/v1/yarn-lots', data: lot.toJson());
    } catch (e) {
      throw Exception("Failed to create yarn lot: $e");
    }
  }

  Future<void> updateYarnLot(YarnLot lot) async {
    try {
      await _dio.put('/api/v1/yarn-lots/${lot.id}', data: lot.toJson());
    } catch (e) {
      throw Exception("Failed to update yarn lot: $e");
    }
  }

  Future<void> deleteYarnLot(int id) async {
    try {
      await _dio.delete('/api/v1/yarn-lots/$id');
    } catch (e) {
      throw Exception("Failed to delete yarn lot: $e");
    }
  }
}