import 'package:dio/dio.dart';
import 'package:production_app_frontend/features/inventory/stock_in/domain/material_receipt_model.dart';
import '../../../../../core/network/api_client.dart';


class MaterialReceiptRepository {
  final Dio _dio = ApiClient().dio;
  static const String _endpoint = '/api/v1/material-receipts';

  // Get All with Filters
  Future<List<MaterialReceipt>> getReceipts({
    int skip = 0,
    int limit = 100,
    String? search,
    int? poId,
    int? declarationId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final queryParams = {
        'skip': skip,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (poId != null) 'po_id': poId,
        if (declarationId != null) 'declaration_id': declarationId,
        if (fromDate != null) 'from_date': fromDate.toIso8601String().substring(0, 10),
        if (toDate != null) 'to_date': toDate.toIso8601String().substring(0, 10),
      };

      final response = await _dio.get(_endpoint, queryParameters: queryParams);

      if (response.data is List) {
        return (response.data as List)
            .map((e) => MaterialReceipt.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to load material receipts: $e");
    }
  }

  // Get Single by ID
  Future<MaterialReceipt> getReceiptById(int id) async {
    try {
      final response = await _dio.get('$_endpoint/$id');
      return MaterialReceipt.fromJson(response.data);
    } catch (e) {
      throw Exception("Failed to get receipt detail: $e");
    }
  }

  // [MỚI] Lấy số phiếu tiếp theo từ Backend
  Future<String> getNextReceiptNumber() async {
    try {
      final response = await _dio.get('$_endpoint/next-number');
      return response.data['receipt_number'] ?? '';
    } catch (e) {
      // Fallback nếu mất kết nối
      print("Error fetching next number: $e");
      return "PN-OFFLINE-${DateTime.now().millisecondsSinceEpoch % 1000}"; 
    }
  }

  Future<void> createReceipt(MaterialReceipt receipt) async {
    try {
      await _dio.post('$_endpoint/', data: receipt.toJson());
    } catch (e) {
      throw Exception("Failed to create receipt: $e");
    }
  }

  Future<void> updateReceipt(MaterialReceipt receipt) async {
    try {
      await _dio.put('$_endpoint/${receipt.id}', data: receipt.toJson());
    } catch (e) {
      throw Exception("Failed to update receipt: $e");
    }
  }

  // Delete Header
  Future<void> deleteReceipt(int id) async {
    try {
      await _dio.delete('$_endpoint/$id');
    } catch (e) {
      throw Exception("Failed to delete receipt: $e");
    }
  }

  // --- DETAIL OPERATIONS ---

  // Add Detail
  Future<void> addDetail(int receiptId, MaterialReceiptDetail detail) async {
    try {
      await _dio.post('$_endpoint/$receiptId/details', data: detail.toJson());
    } catch (e) {
      throw Exception("Failed to add detail: $e");
    }
  }

  // Update Detail
  Future<void> updateDetail(int detailId, MaterialReceiptDetail detail) async {
    try {
      await _dio.put('$_endpoint/details/$detailId', data: detail.toJson());
    } catch (e) {
      throw Exception("Failed to update detail: $e");
    }
  }

  // Delete Detail
  Future<void> deleteDetail(int detailId) async {
    try {
      await _dio.delete('$_endpoint/details/$detailId');
    } catch (e) {
      throw Exception("Failed to delete detail: $e");
    }
  }
}