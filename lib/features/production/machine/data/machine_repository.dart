import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import '../../../../core/network/api_client.dart';
import '../domain/machine_model.dart';

class MachineRepository {
  final Dio _dio = ApiClient().dio;

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

  Future<void> createMachine(Machine machine) async {
    try {
      await _dio.post('/api/v1/machines', data: machine.toJson());
    } on DioException catch (e) {
      // [QUAN TRỌNG] In ra lỗi chi tiết từ Server
      debugPrint("❌ CREATE ERROR: ${e.response?.data}");
      throw Exception(e.response?.data['detail'] ?? e.message);
    } catch (e) {
      throw Exception("Failed to create machine: $e");
    }
  }

  Future<void> updateMachine(Machine machine) async {
    try {
      await _dio.put('/api/v1/machines/${machine.id}', data: machine.toJson());
    } on DioException catch (e) {
      // [QUAN TRỌNG] In ra lỗi chi tiết từ Server
      debugPrint("❌ UPDATE ERROR: ${e.response?.data}");
      // Ném lỗi chứa message từ server để UI hiển thị
      throw Exception(e.response?.data['detail'] ?? e.message); 
    } catch (e) {
      throw Exception("Failed to update machine: $e");
    }
  }

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
}