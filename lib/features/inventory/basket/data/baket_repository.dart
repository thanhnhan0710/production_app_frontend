import 'package:dio/dio.dart';
import 'package:production_app_frontend/features/inventory/basket/doamain/basket_model.dart';
import '../../../../core/network/api_client.dart';
class BasketRepository {
  final Dio _dio = ApiClient().dio;

  Future<List<Basket>> getBaskets() async {
    try {
      final response = await _dio.get('/api/v1/baskets');
      if (response.data is List) {
        return (response.data as List).map((e) => Basket.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to load baskets: $e");
    }
  }

  Future<List<Basket>> searchBaskets(String keyword) async {
    try {
      final response = await _dio.get(
        '/api/v1/baskets/search',
        queryParameters: {'keyword': keyword, 'skip': 0, 'limit': 100},
      );
      if (response.data is List) {
        return (response.data as List).map((e) => Basket.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to search baskets: $e");
    }
  }

  Future<void> createBasket(Basket item) async {
    try {
      await _dio.post('/api/v1/baskets', data: item.toJson());
    } catch (e) {
      throw Exception("Failed to create basket: $e");
    }
  }

  Future<void> updateBasket(Basket item) async {
    try {
      await _dio.put('/api/v1/baskets/${item.id}', data: item.toJson());
    } catch (e) {
      throw Exception("Failed to update basket: $e");
    }
  }

  Future<void> deleteBasket(int id) async {
    try {
      await _dio.delete('/api/v1/baskets/$id');
    } catch (e) {
      throw Exception("Failed to delete basket: $e");
    }
  }
}