import 'package:dio/dio.dart';
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
    } catch (e) {
      throw Exception("Failed to create machine: $e");
    }
  }

  Future<void> updateMachine(Machine machine) async {
    try {
      await _dio.put('/api/v1/machines/${machine.id}', data: machine.toJson());
    } catch (e) {
      throw Exception("Failed to update machine: $e");
    }
  }

  Future<void> deleteMachine(int id) async {
    try {
      await _dio.delete('/api/v1/machines/$id');
    } catch (e) {
      throw Exception("Failed to delete machine: $e");
    }
  }
}