import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import '../../../../core/network/api_client.dart';
import '../domain/weaving_record_model.dart'; // Import Model mới

class WeavingRecordRepository {
  final Dio _dio = ApiClient().dio;
  // Giữ nguyên endpoint backend cũ, chỉ đổi tên class ở Flutter
  final String _endpoint = '/api/v1/weaving-productions'; 

  Future<List<WeavingRecord>> getRecords() async {
    try {
      final response = await _dio.get(_endpoint);
      if (response.data is List) {
        return (response.data as List)
            .map((e) => WeavingRecord.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to load records: $e");
    }
  }

  Future<List<WeavingRecord>> searchRecords(String keyword) async {
    try {
      final response = await _dio.get(
        '$_endpoint/search',
        queryParameters: {'keyword': keyword, 'skip': 0, 'limit': 100},
      );
      if (response.data is List) {
        return (response.data as List)
            .map((e) => WeavingRecord.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to search records: $e");
    }
  }

  Future<void> createRecord(WeavingRecord item) async {
    try {
      await _dio.post(_endpoint, data: item.toJson());
    } on DioException catch (e) {
      debugPrint("❌ CREATE ERROR: ${e.response?.data}");
      throw Exception(e.response?.data['detail'] ?? e.message);
    } catch (e) {
      throw Exception("Failed to create record: $e");
    }
  }

  Future<void> updateRecord(WeavingRecord item) async {
    try {
      await _dio.put('$_endpoint/${item.id}', data: item.toJson());
    } on DioException catch (e) {
      debugPrint("❌ UPDATE ERROR: ${e.response?.data}");
      throw Exception(e.response?.data['detail'] ?? e.message);
    } catch (e) {
      throw Exception("Failed to update record: $e");
    }
  }

  Future<void> deleteRecord(int id) async {
    try {
      await _dio.delete('$_endpoint/$id');
    } catch (e) {
      throw Exception("Failed to delete record: $e");
    }
  }
}