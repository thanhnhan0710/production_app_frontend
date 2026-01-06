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
    await _dio.post('/api/v1/weaving-basket-tickets', data: ticket.toJson());
  }
  
  Future<void> updateTicket(WeavingTicket ticket) async {
    await _dio.put('/api/v1/weaving-basket-tickets/${ticket.id}', data: ticket.toJson());
  }

  Future<void> deleteTicket(int id) async {
    await _dio.delete('/api/v1/weaving-basket-tickets/$id');
  }

  // --- INSPECTIONS ---
  Future<List<WeavingInspection>> getInspections(int ticketId) async {
    try {
      final response = await _dio.get('/api/v1/weaving/inspections/ticket/$ticketId');
      if (response.data is List) {
        return (response.data as List).map((e) => WeavingInspection.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to load inspections: $e");
    }
  }

  Future<void> createInspection(WeavingInspection inspection) async {
    await _dio.post('/api/v1/weaving-inspections', data: inspection.toJson());
  }

  Future<void> deleteInspection(int id) async {
    await _dio.delete('/api/v1/weaving-inspections/$id');
  }
}