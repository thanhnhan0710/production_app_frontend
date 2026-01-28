import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // Import để dùng debugPrint
import '../../../../core/network/api_client.dart';
import '../domain/inventory_model.dart';

class InventoryRepository {
  final Dio _dio = ApiClient().dio;

  // --- 1. GET ALL STOCKS (List) ---
  // [FIX] Sửa đường dẫn từ '/api/v1/inventory' thành '/api/v1/inventorys'
  Future<List<InventoryStock>> getInventories({String? search, int? warehouseId}) async {
    try {
      final response = await _dio.get(
        '/api/v1/inventorys', 
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (warehouseId != null) 'warehouse_id': warehouseId,
          'skip': 0,
          'limit': 100
        }
      );
      
      if (response.data is List) {
        return (response.data as List).map((e) => InventoryStock.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      // [FIX] In lỗi ra console để debug thay vì im lặng trả về rỗng
      debugPrint("❌ Get Inventories Error: $e");
      
      // Nếu muốn UI hiện lỗi, hãy throw exception. 
      // Nếu muốn UI hiện danh sách rỗng khi lỗi, giữ nguyên return [] nhưng phải chắc chắn URL đúng.
      throw Exception("Failed to load inventory: $e"); 
    }
  }

  // --- 2. GET STOCK BY BATCH ---
  // [FIX] Sửa đường dẫn thành '/api/v1/inventorys/...'
  Future<InventoryStock?> getStockByBatch(int warehouseId, int batchId) async {
    try {
      final response = await _dio.get('/api/v1/inventorys/stock/$warehouseId/$batchId');
      return response.data != null ? InventoryStock.fromJson(response.data) : null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw Exception(e.response?.data['detail'] ?? e.message);
    }
  }

  // --- 3. ADJUST STOCK ---
  // [FIX] Sửa đường dẫn thành '/api/v1/inventorys/...'
  Future<InventoryStock> adjustStock(InventoryAdjustment adjustment) async {
    try {
      final response = await _dio.post('/api/v1/inventorys/adjust', data: adjustment.toJson());
      return InventoryStock.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? e.message);
    }
  }
}