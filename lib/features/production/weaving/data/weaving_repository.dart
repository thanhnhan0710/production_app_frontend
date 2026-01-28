import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../domain/weaving_model.dart';

class WeavingRepository {
  final Dio _dio = ApiClient().dio;

  // --- TICKETS ---
  Future<List<WeavingTicket>> getTickets() async {
    try {
      final response = await _dio.get('/api/v1/weaving-basket-tickets');
      if (response.data is List) {
        return (response.data as List).map((e) => WeavingTicket.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to load tickets: $e");
    }
  }

  Future<void> createTicket(WeavingTicket ticket) async {
    try {
      // Chuẩn hóa dữ liệu gửi đi
      final data = {
        'code': ticket.code,
        'product_id': ticket.productId,
        'standard_id': ticket.standardId,
        'machine_id': ticket.machineId,
        'machine_line': ticket.machineLine, 
        'yarn_load_date': ticket.yarnLoadDate, // YYYY-MM-DD
        'batch_id': ticket.batchId,
        'basket_id': ticket.basketId,
        'employee_in_id': ticket.employeeInId,
        'time_in': ticket.timeIn,
        'number_of_knots': ticket.numberOfKnots,
      };

      print("Payload Create Ticket: $data");

      await _dio.post('/api/v1/weaving-basket-tickets', data: data);
    } catch (e) {
      if (e is DioException) {
         print("API Error Details: ${e.response?.data}");
      }
      throw Exception("Failed to create ticket: $e");
    }
  }
  
  Future<void> updateTicket(WeavingTicket ticket) async {
    await _dio.put('/api/v1/weaving-basket-tickets/${ticket.id}', data: ticket.toJson());
  }

  Future<void> deleteTicket(int id) async {
    await _dio.delete('/api/v1/weaving-basket-tickets/$id');
  }

  // --- INSPECTIONS (ĐÃ SỬA LỖI) ---
  Future<List<WeavingInspection>> getInspections(int ticketId) async {
    try {
      // [FIX] Sử dụng queryParameters thay vì path param
      // Backend: GET /api/v1/weaving-inspections?ticket_id=...
      final response = await _dio.get(
        '/api/v1/weaving-inspections', 
        queryParameters: {'ticket_id': ticketId},
      );
      
      if (response.data is List) {
        return (response.data as List).map((e) => WeavingInspection.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to load inspections: $e");
    }
  }

  Future<void> createInspection(WeavingInspection inspection) async {
    try {
      await _dio.post('/api/v1/weaving-inspections', data: inspection.toJson());
    } catch (e) {
      throw Exception("Failed to create inspection: $e");
    }
  }

  Future<void> deleteInspection(int id) async {
    try {
      await _dio.delete('/api/v1/weaving-inspections/$id');
    } catch (e) {
      throw Exception("Failed to delete inspection: $e");
    }
  }
}