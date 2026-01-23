import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import '../../../../core/network/api_client.dart';
import '../domain/purchase_order_model.dart';

class PurchaseOrderRepository {
  final Dio _dio = ApiClient().dio;
  final String _endpoint = '/api/v1/purchase-orders';

  // --- GET LIST (FILTER) ---
  Future<List<PurchaseOrderHeader>> getPurchaseOrders({
    int skip = 0,
    int limit = 100,
    String? search,
    int? vendorId,
    POStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'skip': skip,
        'limit': limit,
      };

      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (vendorId != null) queryParams['vendor_id'] = vendorId;
      if (status != null) queryParams['status'] = status.name;
      if (fromDate != null) queryParams['from_date'] = fromDate.toIso8601String().split('T').first;
      if (toDate != null) queryParams['to_date'] = toDate.toIso8601String().split('T').first;

      final response = await _dio.get(_endpoint, queryParameters: queryParams);
      
      if (response.data is List) {
        return (response.data as List)
            .map((e) => PurchaseOrderHeader.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to load PO list: $e");
    }
  }

  // --- GET DETAIL ---
  Future<PurchaseOrderHeader> getPurchaseOrderById(int poId) async {
    try {
      final response = await _dio.get('$_endpoint/$poId');
      return PurchaseOrderHeader.fromJson(response.data);
    } catch (e) {
      throw Exception("Failed to load PO detail: $e");
    }
  }

  // --- GET BY NUMBER ---
  Future<PurchaseOrderHeader> getPurchaseOrderByNumber(String poNumber) async {
    try {
      final response = await _dio.get('$_endpoint/by-number/$poNumber');
      return PurchaseOrderHeader.fromJson(response.data);
    } catch (e) {
      throw Exception("Failed to find PO: $e");
    }
  }

  // [MỚI] Lấy số PO tự động từ Backend
  Future<String> getNextPONumber() async {
    try {
      final response = await _dio.get('$_endpoint/next-number');
      return response.data['po_number'] ?? '';
    } catch (e) {
      print("Error fetching next PO number: $e");
      // Fallback offline format
      return "PO-OFFLINE-${DateTime.now().millisecondsSinceEpoch % 100}"; 
    }
  }

  // --- CREATE ---
  Future<PurchaseOrderHeader> createPurchaseOrder(PurchaseOrderHeader po) async {
    try {
      final response = await _dio.post(_endpoint, data: po.toJson());
      return PurchaseOrderHeader.fromJson(response.data);
    } on DioException catch (e) {
       debugPrint("❌ CREATE PO ERROR: ${e.response?.data}");
       throw Exception(e.response?.data['detail'] ?? "Failed to create PO");
    } catch (e) {
      throw Exception("Error creating PO: $e");
    }
  }

  // --- UPDATE ---
  Future<PurchaseOrderHeader> updatePurchaseOrder(int poId, PurchaseOrderHeader po) async {
    try {
      // Chỉ gửi các trường header cần update, không gửi details ở đây nếu BE tách biệt
      final data = po.toJson();
      data.remove('details'); 

      final response = await _dio.put('$_endpoint/$poId', data: data);
      return PurchaseOrderHeader.fromJson(response.data);
    } catch (e) {
      throw Exception("Failed to update PO: $e");
    }
  }

  // --- ADD ITEM (DETAIL) ---
  Future<PurchaseOrderHeader> addDetailItem(int poId, PurchaseOrderDetail detail) async {
    try {
      final response = await _dio.post(
        '$_endpoint/$poId/items', 
        data: detail.toJson()
      );
      return PurchaseOrderHeader.fromJson(response.data);
    } catch (e) {
      throw Exception("Failed to add item: $e");
    }
  }

  Future<void> deletePurchaseOrder(int id) async {
    try {
      await _dio.delete('$_endpoint/$id');
    } on DioException catch (e) {
      // Xử lý lỗi từ Backend trả về (VD: Không phải Draft)
      throw Exception(e.response?.data['detail'] ?? "Failed to delete PO: $e");
    } catch (e) {
      throw Exception("Failed to delete PO: $e");
    }
  }
}