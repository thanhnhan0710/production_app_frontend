import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';
import '../../../../core/network/api_client.dart';
import '../domain/employee_model.dart';

class EmployeeRepository {
  final Dio _dio = ApiClient().dio;

  // Get all employees
  Future<List<Employee>> getEmployees() async {
    try {
      final response = await _dio.get('/api/v1/employees');
      if (response.data is List) {
        return (response.data as List)
            .map((e) => Employee.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to load employees: $e");
    }
  }

  // Search employees
  Future<List<Employee>> searchEmployees(String keyword) async {
    try {
      final response = await _dio.get(
        '/api/v1/employees/search',
        queryParameters: {
          'keyword': keyword,
          'skip': 0,
          'limit': 100,
        },
      );
      if (response.data is List) {
        return (response.data as List)
            .map((e) => Employee.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception("Employees not found: $e");
    }
  }

  // [UPDATED] Lấy nhân viên theo ID phòng ban
  // Endpoint: /api/v1/employees/department/{id}
  Future<List<Employee>> getEmployeesByDepartmentId(int departmentId) async {
    try {
      final response = await _dio.get('/api/v1/employees/department/$departmentId');
      if (response.data is List) {
        return (response.data as List)
            .map((e) => Employee.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to load employees for department $departmentId: $e");
    }
  }

  Future<void> createEmployee(Employee emp) async {
    try {
      await _dio.post('/api/v1/employees', data: emp.toJson());
    } catch (e) {
      throw Exception("Failed to create employee: $e");
    }
  }

  Future<void> updateEmployee(Employee emp) async {
    try {
      await _dio.put('/api/v1/employees/${emp.id}', data: emp.toJson());
    } catch (e) {
      throw Exception("Failed to update employee: $e");
    }
  }

  Future<void> deleteEmployee(int id) async {
    try {
      await _dio.delete('/api/v1/employees/$id');
    } catch (e) {
      throw Exception("Failed to delete employee: $e");
    }
  }

  Future<String> uploadAvatar(PlatformFile file) async {
    try {
      if (file.bytes == null) {
        throw Exception("File data is empty.");
      }

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          file.bytes!,
          filename: file.name,
          contentType: MediaType('image', 'jpeg'), 
        ),
      });

      final response = await _dio.post('/api/v1/upload/avatar', data: formData);
      return response.data['url'] ?? '';
    } catch (e) {
      throw Exception("Failed to upload avatar: $e");
    }
  }
}

