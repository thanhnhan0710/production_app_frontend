import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../domain/material_model.dart';

class MaterialRepository {
  final Dio _dio = ApiClient().dio;

  Future<List<InventoryMaterial>> getMaterials() async {
    try {
      final response = await _dio.get('/api/v1/materials');
      if (response.data is List) {
        return (response.data as List).map((e) => InventoryMaterial.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to load materials: $e");
    }
  }

  Future<List<InventoryMaterial>> searchMaterials(String keyword) async {
    try {
      final response = await _dio.get(
        '/api/v1/materials/search',
        queryParameters: {'keyword': keyword, 'skip': 0, 'limit': 100},
      );
      if (response.data is List) {
        return (response.data as List).map((e) => InventoryMaterial.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to search materials: $e");
    }
  }

  Future<void> createMaterial(InventoryMaterial item) async {
    try {
      await _dio.post('/api/v1/materials', data: item.toJson());
    } catch (e) {
      throw Exception("Failed to create material: $e");
    }
  }

  Future<void> updateMaterial(InventoryMaterial item) async {
    try {
      await _dio.put('/api/v1/materials/${item.id}', data: item.toJson());
    } catch (e) {
      throw Exception("Failed to update material: $e");
    }
  }

  Future<void> deleteMaterial(int id) async {
    try {
      await _dio.delete('/api/v1/materials/$id');
    } catch (e) {
      throw Exception("Failed to delete material: $e");
    }
  }
}