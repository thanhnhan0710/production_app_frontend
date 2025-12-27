import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/supplier_repository.dart';
import '../../domain/supplier_model.dart';

abstract class SupplierState {}

class SupplierInitial extends SupplierState {}

class SupplierLoading extends SupplierState {}

class SupplierLoaded extends SupplierState {
  final List<Supplier> suppliers;
  SupplierLoaded(this.suppliers);
}

class SupplierError extends SupplierState {
  final String message;
  SupplierError(this.message);
}

class SupplierCubit extends Cubit<SupplierState> {
  final SupplierRepository _repo;

  SupplierCubit(this._repo) : super(SupplierInitial());

  // Load danh sách (Mặc định)
  Future<void> loadSuppliers() async {
    emit(SupplierLoading());
    try {
      final list = await _repo.getSuppliers();
      emit(SupplierLoaded(list));
    } catch (e) {
      emit(SupplierError(e.toString()));
    }
  }

  // [FIX] Hàm tìm kiếm riêng biệt
  Future<void> searchSuppliers(String query) async {
    // Nếu ô tìm kiếm rỗng -> Load lại danh sách tất cả
    if (query.trim().isEmpty) {
      loadSuppliers();
      return;
    }

    emit(SupplierLoading());
    try {
      // Gọi hàm searchSuppliers của Repository (truyền keyword)
      final list = await _repo.searchSuppliers(query);
      emit(SupplierLoaded(list));
    } catch (e) {
      emit(SupplierError(e.toString()));
    }
  }

  Future<void> saveSupplier({required Supplier supplier, required bool isEdit}) async {
    try {
      if (isEdit) {
        await _repo.updateSupplier(supplier);
      } else {
        await _repo.createSupplier(supplier);
      }
      // Reload sau khi lưu thành công
      loadSuppliers(); 
    } catch (e) {
      emit(SupplierError(e.toString()));
    }
  }

  Future<void> deleteSupplier(int id) async {
    try {
      await _repo.deleteSupplier(id);
      // Reload sau khi xóa thành công
      loadSuppliers();
    } catch (e) {
      emit(SupplierError(e.toString()));
    }
  }
}