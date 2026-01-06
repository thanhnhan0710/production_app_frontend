import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';
import '../../../../core/network/api_client.dart';
import '../domain/product_model.dart';

class ProductRepository {
  final Dio _dio = ApiClient().dio;

  Future<List<Product>> getProducts() async {
    try {
      final response = await _dio.get('/api/v1/products');
      if (response.data is List) {
        return (response.data as List).map((e) => Product.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to load products: $e");
    }
  }

  Future<List<Product>> searchProducts(String keyword) async {
    try {
      final response = await _dio.get(
        '/api/v1/products/search',
        queryParameters: {'keyword': keyword, 'skip': 0, 'limit': 100},
      );
      if (response.data is List) {
        return (response.data as List).map((e) => Product.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to search products: $e");
    }
  }

  Future<void> createProduct(Product item) async {
    try {
      await _dio.post('/api/v1/products', data: item.toJson());
    } catch (e) {
      throw Exception("Failed to create product: $e");
    }
  }

  Future<void> updateProduct(Product item) async {
    try {
      await _dio.put('/api/v1/products/${item.id}', data: item.toJson());
    } catch (e) {
      throw Exception("Failed to update product: $e");
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      await _dio.delete('/api/v1/products/$id');
    } catch (e) {
      throw Exception("Failed to delete product: $e");
    }
  }

  // Upload ảnh sản phẩm
  Future<String> uploadProductImage(PlatformFile file) async {
    try {
      if (file.bytes == null) throw Exception("File empty");

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          file.bytes!,
          filename: file.name,
          contentType: MediaType('image', 'jpeg'),
        ),
      });

      // Gọi endpoint dành riêng cho Product mà chúng ta đã tạo ở Backend
      final response = await _dio.post('/api/v1/upload/product', data: formData);
      return response.data['url'] ?? '';
    } catch (e) {
      throw Exception("Failed to upload image: $e");
    }
  }
}