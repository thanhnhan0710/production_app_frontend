import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/product_repository.dart';
import 'package:file_saver/file_saver.dart';
import '../../domain/product_model.dart';

abstract class ProductState {}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductLoaded extends ProductState {
  final List<Product> products;
  ProductLoaded(this.products);
}

class ProductError extends ProductState {
  final String message;
  ProductError(this.message);
}

class ProductCubit extends Cubit<ProductState> {
  final ProductRepository _repo;

  ProductCubit(this._repo) : super(ProductInitial());

  Future<void> loadProducts() async {
    emit(ProductLoading());
    try {
      final list = await _repo.getProducts();
      emit(ProductLoaded(list));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> searchProducts(String keyword) async {
    if (keyword.trim().isEmpty) {
      loadProducts();
      return;
    }
    emit(ProductLoading());
    try {
      final list = await _repo.searchProducts(keyword);
      emit(ProductLoaded(list));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> saveProduct(
      {required Product product,
      PlatformFile? imageFile,
      required bool isEdit}) async {
    try {
      String finalImageUrl = product.imageUrl;

      // Upload ảnh nếu có chọn mới
      if (imageFile != null) {
        finalImageUrl = await _repo.uploadProductImage(imageFile);
      }

      final newProduct = Product(
        id: product.id,
        itemCode: product.itemCode,
        note: product.note,
        imageUrl: finalImageUrl,
      );

      if (isEdit) {
        await _repo.updateProduct(newProduct);
      } else {
        await _repo.createProduct(newProduct);
      }
      loadProducts();
    } catch (e) {
      emit(ProductError("Error saving product: $e"));
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      await _repo.deleteProduct(id);
      loadProducts();
    } catch (e) {
      emit(ProductError("Error deleting: $e"));
    }
  }

  Future<void> importExcel(PlatformFile file) async {
    emit(ProductLoading());
    try {
      final result = await _repo.importExcel(file);
      await loadProducts();

      // Nếu có lỗi (ví dụ trùng lặp), gom lại và hiện thông báo
      if (result['errors'] != null && (result['errors'] as List).isNotEmpty) {
        emit(ProductError(
            "Đã import ${result['success_count']} dòng. Các lỗi:\n${(result['errors'] as List).join('\n')}"));
      }
    } catch (e) {
      emit(ProductError(e.toString().replaceAll("Exception: ", "")));
    }
  }

  // --- [MỚI] EXPORT EXCEL ---
  Future<void> exportExcel() async {
    try {
      final bytes = await _repo.exportExcel();

      await FileSaver.instance.saveFile(
        name: 'Loom State${DateTime.now().millisecondsSinceEpoch}.xlsx',
        bytes: bytes,
        mimeType: MimeType.microsoftExcel,
      );
    } catch (e) {
      emit(ProductError(
          "Lỗi xuất file: ${e.toString().replaceAll("Exception: ", "")}"));
    }
  }
}
