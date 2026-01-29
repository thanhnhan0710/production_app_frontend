import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:http_parser/http_parser.dart'; // Để dùng MediaType
import 'package:production_app_frontend/features/production/machine/domain/machine_log_model.dart';
import '../../../../core/network/api_client.dart';
import '../domain/machine_model.dart';

class MachineRepository {
  final Dio _dio = ApiClient().dio;

  // --- GET ALL MACHINES ---
  Future<List<Machine>> getMachines() async {
    try {
      final response = await _dio.get('/api/v1/machines');
      if (response.data is List) {
        return (response.data as List).map((e) => Machine.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to load machines: $e");
    }
  }

  // --- SEARCH MACHINES ---
  Future<List<Machine>> searchMachines(String keyword) async {
    try {
      final response = await _dio.get(
        '/api/v1/machines/search',
        queryParameters: {'keyword': keyword, 'skip': 0, 'limit': 100},
      );
      if (response.data is List) {
        return (response.data as List).map((e) => Machine.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to search machines: $e");
    }
  }

  // --- CREATE MACHINE ---
  Future<void> createMachine(Machine machine) async {
    try {
      await _dio.post('/api/v1/machines', data: machine.toJson());
    } on DioException catch (e) {
      debugPrint("❌ CREATE ERROR: ${e.response?.data}");
      throw Exception(e.response?.data['detail'] ?? e.message);
    } catch (e) {
      throw Exception("Failed to create machine: $e");
    }
  }

  // --- UPDATE MACHINE INFO ---
  Future<void> updateMachine(Machine machine) async {
    try {
      await _dio.put('/api/v1/machines/${machine.id}', data: machine.toJson());
    } on DioException catch (e) {
      debugPrint("❌ UPDATE ERROR: ${e.response?.data}");
      throw Exception(e.response?.data['detail'] ?? e.message); 
    } catch (e) {
      throw Exception("Failed to update machine: $e");
    }
  }

  // --- DELETE MACHINE ---
  Future<void> deleteMachine(int id) async {
    try {
      await _dio.delete('/api/v1/machines/$id');
    } on DioException catch (e) {
      debugPrint("❌ DELETE ERROR: ${e.response?.data}");
      throw Exception(e.response?.data['detail'] ?? e.message);
    } catch (e) {
      throw Exception("Failed to delete machine: $e");
    }
  }

  // --- GET MACHINE HISTORY ---
  Future<List<MachineLog>> getMachineHistory(int machineId) async {
    try {
      final response = await _dio.get('/api/v1/machines/$machineId/history');
      if (response.data is List) {
        return (response.data as List)
            .map((e) => MachineLog.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      // [Updated] English message
      throw Exception("Failed to load machine history: $e");
    }
  }

  // --- UPDATE STATUS & LOG (With Image URL) ---
 Future<void> updateMachineStatus(int id, String status, {String? reason, String? imageUrl}) async {
    try {
      // [SỬA LỖI 422]
      // Vì Backend dùng Form(...), ta bắt buộc phải gửi FormData 
      // thay vì JSON map thông thường.
      final formData = FormData.fromMap({
        'status': status,
        'reason': reason ?? '', // Gửi chuỗi rỗng nếu null để tránh lỗi backend
        if (imageUrl != null) 'image_url': imageUrl,
      });

      await _dio.put(
        '/api/v1/machines/$id/status', 
        data: formData, // Truyền FormData vào đây
      );
      
    } catch (e) {
      throw Exception("Failed to update machine status: $e");
    }
  }

  // --- UPLOAD IMAGE (Returns URL) ---
  Future<String> uploadImageLog(PlatformFile file) async {
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

      final response = await _dio.post('/api/v1/upload/machine-logs', data: formData);
      return response.data['url'] ?? '';
    } catch (e) {
      // [Updated] English message (Fixed 'avatar' typo)
      throw Exception("Failed to upload log image: $e");
    }
  }
}