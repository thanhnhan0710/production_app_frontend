import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../domain/material_export_model.dart';

class MaterialExportRepository {
  final Dio _dio = ApiClient().dio;

  // Search / Get List
  Future<List<MaterialExport>> getExports({String? search, int? warehouseId}) async {
    try {
      final response = await _dio.get(
        '/api/v1/material-exports/',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (warehouseId != null) 'warehouse_id': warehouseId,
          'skip': 0, 'limit': 100
        }
      );
      if (response.data is List) {
        return (response.data as List).map((e) => MaterialExport.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Create
  Future<void> createExport(MaterialExport exportData) async {
    try {
      await _dio.post('/api/v1/material-exports/', data: exportData.toJson());
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? e.message);
    }
  }

  // Delete
  Future<void> deleteExport(int id) async {
    try {
      await _dio.delete('/api/v1/material-exports/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? e.message);
    }
  }

  // Gen Code
  String generateExportCode() {
    final now = DateTime.now();
    return "PX-${now.year}${now.month.toString().padLeft(2,'0')}-${now.millisecondsSinceEpoch % 10000}";
  }
}