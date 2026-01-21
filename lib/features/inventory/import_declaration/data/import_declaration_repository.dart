import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../domain/import_declaration_model.dart';

class ImportDeclarationRepository {
  final Dio _dio = ApiClient().dio;
  final String _endpoint = '/api/v1/import-declarations';

  Future<List<ImportDeclaration>> getDeclarations({
    int skip = 0, int limit = 100, String? search,
    ImportType? type, DateTime? fromDate, DateTime? toDate,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {'skip': skip, 'limit': limit};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (type != null) queryParams['import_type'] = type.name;
      if (fromDate != null) queryParams['from_date'] = fromDate.toIso8601String().split('T').first;
      if (toDate != null) queryParams['to_date'] = toDate.toIso8601String().split('T').first;

      final response = await _dio.get(_endpoint, queryParameters: queryParams);
      if (response.data is List) {
        return (response.data as List).map((e) => ImportDeclaration.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to load declarations: $e");
    }
  }

  Future<ImportDeclaration> getDeclarationById(int id) async {
    try {
      final response = await _dio.get('$_endpoint/$id');
      return ImportDeclaration.fromJson(response.data);
    } catch (e) {
      throw Exception("Failed to load detail: $e");
    }
  }

  Future<ImportDeclaration> createDeclaration(ImportDeclaration decl) async {
    try {
      final response = await _dio.post(_endpoint, data: decl.toJson());
      return ImportDeclaration.fromJson(response.data);
    } on DioException catch (e) {
       throw Exception(e.response?.data['detail'] ?? "Failed to create declaration");
    } catch (e) {
      throw Exception("Error creating declaration: $e");
    }
  }

  Future<ImportDeclaration> updateDeclaration(int id, ImportDeclaration decl) async {
    try {
      final data = decl.toJson();
      data.remove('details');
      final response = await _dio.put('$_endpoint/$id', data: data);
      return ImportDeclaration.fromJson(response.data);
    } catch (e) {
      throw Exception("Failed to update declaration: $e");
    }
  }

  Future<void> deleteDeclaration(int id) async {
    try {
      await _dio.delete('$_endpoint/$id');
    } catch (e) {
      throw Exception("Failed to delete declaration: $e");
    }
  }

  // --- DETAILS ---
  Future<void> addDetail(int declarationId, ImportDeclarationDetail detail) async {
    try {
      await _dio.post('$_endpoint/$declarationId/details', data: detail.toJson());
    } catch (e) {
      throw Exception("Failed to add item: $e");
    }
  }

  Future<void> updateDetail(int detailId, ImportDeclarationDetail detail) async {
    try {
      await _dio.put('$_endpoint/details/$detailId', data: detail.toJson());
    } catch (e) {
      throw Exception("Failed to update item: $e");
    }
  }

  Future<void> deleteDetail(int detailId) async {
    try {
      await _dio.delete('$_endpoint/details/$detailId');
    } catch (e) {
      throw Exception("Failed to delete item: $e");
    }
  }
}