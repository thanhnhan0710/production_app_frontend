import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/bom_repository.dart';
import '../../domain/bom_model.dart';

abstract class BOMState {}
class BOMInitial extends BOMState {}
class BOMLoading extends BOMState {}
class BOMListLoaded extends BOMState {
  final List<BOMHeader> boms;
  BOMListLoaded(this.boms);
}
// State đặc biệt khi xem chi tiết 1 BOM để edit nguyên liệu
class BOMDetailViewLoaded extends BOMState {
  final BOMHeader bom;
  BOMDetailViewLoaded(this.bom);
}
class BOMError extends BOMState {
  final String message;
  BOMError(this.message);
}

class BOMCubit extends Cubit<BOMState> {
  final BOMRepository _repo;

  // Giữ lại productId hiện tại để reload list đúng ngữ cảnh sau khi Add/Delete
  int? _currentProductId;

  BOMCubit(this._repo) : super(BOMInitial());

  // ==========================================
  // HEADER ACTIONS
  // ==========================================

  // Load danh sách Header
  Future<void> loadBOMHeaders({int? productId}) async {
    _currentProductId = productId; // Lưu lại state filter
    emit(BOMLoading());
    try {
      List<BOMHeader> list;
      
      if (productId != null) {
        // [FIX ERROR] Nếu có productId, dùng hàm search để lọc
        list = await _repo.searchBOMHeaders(productId: productId);
      } else {
        // Nếu không, dùng hàm get all
        list = await _repo.getBOMHeaders();
      }
      
      emit(BOMListLoaded(list));
    } catch (e) {
      emit(BOMError(e.toString()));
    }
  }

  // Tìm kiếm theo từ khóa (Có thể kèm productId nếu đang đứng ở màn chi tiết SP)
  Future<void> searchBOMHeaders(String keyword) async {
    if (keyword.trim().isEmpty) {
      loadBOMHeaders(productId: _currentProductId);
      return;
    }
    emit(BOMLoading());
    try {
      final list = await _repo.searchBOMHeaders(
        keyword: keyword, 
        productId: _currentProductId
      );
      emit(BOMListLoaded(list));
    } catch (e) {
      emit(BOMError(e.toString()));
    }
  }

  // Load chi tiết 1 BOM để xem list nguyên liệu
  Future<void> loadBOMDetailView(int bomId) async {
    emit(BOMLoading());
    try {
      final bom = await _repo.getBOMHeaderById(bomId);
      emit(BOMDetailViewLoaded(bom));
    } catch (e) {
      emit(BOMError(e.toString()));
    }
  }

  // Save Header (Create / Update)
  Future<void> saveBOMHeader({required BOMHeader bom, required bool isEdit}) async {
    try {
      if (isEdit) {
        await _repo.updateBOMHeader(bom);
      } else {
        await _repo.createBOMHeader(bom);
      }
      // Reload lại list sau khi save, giữ nguyên filter productId nếu có
      loadBOMHeaders(productId: _currentProductId);
    } catch (e) {
      emit(BOMError("Error saving BOM: $e"));
    }
  }

  Future<void> deleteBOMHeader(int id) async {
    try {
      await _repo.deleteBOMHeader(id);
      loadBOMHeaders(productId: _currentProductId);
    } catch (e) {
      emit(BOMError("Error deleting: $e"));
    }
  }

  // ==========================================
  // DETAIL ACTIONS (Thêm/Sửa/Xóa nguyên liệu)
  // ==========================================
  
  Future<void> saveBOMDetail(BOMDetail detail, bool isEdit) async {
    try {
      if (isEdit) {
        await _repo.updateBOMDetail(detail);
      } else {
        await _repo.createBOMDetail(detail);
      }
      // Reload lại view chi tiết để cập nhật list nguyên liệu
      loadBOMDetailView(detail.bomId);
    } catch (e) {
      emit(BOMError("Error saving detail: $e"));
    }
  }

  Future<void> deleteBOMDetail(int detailId, int bomId) async {
    try {
      await _repo.deleteBOMDetail(detailId);
      loadBOMDetailView(bomId);
    } catch (e) {
      emit(BOMError("Error deleting detail: $e"));
    }
  }
}