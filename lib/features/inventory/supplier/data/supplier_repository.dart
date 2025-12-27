import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../domain/supplier_model.dart';

class SupplierRepository {
  final Dio _dio = ApiClient().dio;

  // Lấy danh sách tất cả (Mặc định)
  Future<List<Supplier>> getSuppliers() async {
    try {
      final response = await _dio.get('/api/v1/suppliers');
      if (response.data is List) {
        return (response.data as List).map((e) => Supplier.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to load suppliers");
    }
  }

  // [FIX] Tìm kiếm đúng endpoint FastAPI
  // Endpoint: /api/v1/suppliers/search?keyword=...
  Future<List<Supplier>> searchSuppliers(String keyword) async {
    try {
      final response = await _dio.get(
        '/api/v1/suppliers/search',
        queryParameters: {
          'keyword': keyword,
        },
      );
      
      if (response.data is List) {
        return (response.data as List).map((e) => Supplier.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Suppliers not found");
    }
  }

  Future<void> createSupplier(Supplier item) async {
    await _dio.post('/api/v1/suppliers', data: item.toJson());
  }

  Future<void> updateSupplier(Supplier item) async {
    await _dio.put('/api/v1/suppliers/${item.id}', data: item.toJson());
  }

  Future<void> deleteSupplier(int id) async {
    await _dio.delete('/api/v1/suppliers/$id');
  }
}