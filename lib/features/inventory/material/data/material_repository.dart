import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import '../../../../core/network/api_client.dart';
import '../domain/material_model.dart';

class MaterialRepository {
  final Dio _dio = ApiClient().dio;

  // --- GET ALL ---
  Future<List<MaterialModel>> getMaterials() async {
    try {
      final response = await _dio.get('/api/v1/materials');
      if (response.data is List) {
        return (response.data as List).map((e) => MaterialModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to load materials: $e");
    }
  }

  // --- SEARCH ---
  Future<List<MaterialModel>> searchMaterials(String keyword) async {
    try {
      final response = await _dio.get(
        '/api/v1/materials', // Dùng chung endpoint GET nhưng thêm params
        queryParameters: {'keyword': keyword, 'skip': 0, 'limit': 100},
      );
      if (response.data is List) {
        return (response.data as List).map((e) => MaterialModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to search materials: $e");
    }
  }

  // --- CREATE ---
  Future<void> createMaterial(MaterialModel material) async {
    try {
      await _dio.post('/api/v1/materials', data: material.toJson());
    } on DioException catch (e) {
      debugPrint("❌ CREATE ERROR: ${e.response?.data}");
      throw Exception(e.response?.data['detail'] ?? e.message);
    } catch (e) {
      throw Exception("Failed to create material: $e");
    }
  }

  // --- UPDATE ---
  Future<void> updateMaterial(MaterialModel material) async {
    try {
      await _dio.put('/api/v1/materials/${material.id}', data: material.toJson());
    } on DioException catch (e) {
      debugPrint("❌ UPDATE ERROR: ${e.response?.data}");
      throw Exception(e.response?.data['detail'] ?? e.message);
    } catch (e) {
      throw Exception("Failed to update material: $e");
    }
  }

  // --- DELETE ---
  Future<void> deleteMaterial(int id) async {
    try {
      await _dio.delete('/api/v1/materials/$id');
    } on DioException catch (e) {
      debugPrint("❌ DELETE ERROR: ${e.response?.data}");
      throw Exception(e.response?.data['detail'] ?? e.message);
    } catch (e) {
      throw Exception("Failed to delete material: $e");
    }
  }
}