import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../domain/department_model.dart';

class DepartmentRepository {
  final Dio _dio = ApiClient().dio;

  // Get all departments
  Future<List<Department>> getDepartments() async {
    try {
      final response = await _dio.get('/api/v1/departments');
      if (response.data is List) {
        return (response.data as List)
            .map((e) => Department.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to load departments: $e");
    }
  }

  // Search departments
  Future<List<Department>> searchDepartments(String keyword) async {
    try {
      final response = await _dio.get(
        '/api/v1/departments/search', // Endpoint theo yêu cầu
        queryParameters: {
          'keyword': keyword,
        },
      );
      
      if (response.data is List) {
        return (response.data as List).map((e) => Department.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to search departments: $e");
    }
  }

  Future<void> createDepartment(Department dept) async {
    try {
      await _dio.post('/api/v1/departments', data: dept.toJson());
    } catch (e) {
      throw Exception("Failed to create department: $e");
    }
  }

  Future<void> updateDepartment(Department dept) async {
    try {
      await _dio.put('/api/v1/departments/${dept.id}', data: dept.toJson());
    } catch (e) {
      throw Exception("Failed to update department: $e");
    }
  }

  Future<void> deleteDepartment(int id) async {
    try {
      await _dio.delete('/api/v1/departments/$id');
    } catch (e) {
      throw Exception("Failed to delete department: $e");
    }
  }
}