import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/bom_repository.dart';
import '../../domain/bom_model.dart';

// --- STATES ---
abstract class BOMState {}

class BOMInitial extends BOMState {}

class BOMLoading extends BOMState {}

// State cho màn hình danh sách (BOM Screen)
class BOMListLoaded extends BOMState {
  final List<BOMHeader> boms;
  BOMListLoaded(this.boms);
}

// State cho màn hình chi tiết (BOM Detail Screen)
class BOMDetailViewLoaded extends BOMState {
  final BOMHeader bom;
  BOMDetailViewLoaded(this.bom);
}

class BOMOperationSuccess extends BOMState {
  final String message;
  BOMOperationSuccess(this.message);
}

class BOMError extends BOMState {
  final String message;
  BOMError(this.message);
}

// --- CUBIT ---
class BOMCubit extends Cubit<BOMState> {
  final BOMRepository _repo;

  BOMCubit(this._repo) : super(BOMInitial());

  // 1. Load danh sách (Có hỗ trợ Filter Server-side)
  Future<void> loadBOMHeaders({String? productCode, int? year}) async {
    emit(BOMLoading());
    try {
      // Gọi Repo với tham số filter mới
      final list = await _repo.getBOMs(productCode: productCode, year: year);
      emit(BOMListLoaded(list));
    } catch (e) {
      emit(BOMError(e.toString()));
    }
  }

  // 1.1 Search (Hàm tìm kiếm từ Search Bar)
  Future<void> searchBOMs(String keyword) async {
    emit(BOMLoading());
    try {
      final list = await _repo.searchBOMs(keyword);
      emit(BOMListLoaded(list));
    } catch (e) {
      emit(BOMError(e.toString()));
    }
  }

  // 2. Load chi tiết 1 BOM
  Future<void> loadBOMDetailView(int id) async {
    emit(BOMLoading());
    try {
      final bom = await _repo.getBOMById(id);
      emit(BOMDetailViewLoaded(bom));
    } catch (e) {
      emit(BOMError(e.toString()));
    }
  }

  // 3. Save Header (Tạo mới hoặc Sửa thông tin chung)
  Future<void> saveBOMHeader({required BOMHeader bom, required bool isEdit}) async {
    emit(BOMLoading());
    try {
      if (isEdit) {
        await _repo.updateBOM(bom);
      } else {
        await _repo.createBOM(bom);
      }
      emit(BOMOperationSuccess(isEdit ? "Cập nhật thành công" : "Tạo BOM thành công"));
      
      // Reload lại danh sách sau khi lưu
      loadBOMHeaders(); 
    } catch (e) {
      // Nếu lỗi là String (do ta throw Exception("message") ở repo) thì hiển thị gọn
      final msg = e.toString().replaceAll("Exception: ", "");
      emit(BOMError(msg));
    }
  }

  // 4. Save Detail (Thêm/Sửa thành phần con)
  // Logic: Lấy BOM hiện tại -> Sửa list details -> Gọi Update BOM Header
  Future<void> saveBOMDetail(BOMDetail detail, bool isEdit) async {
    final currentState = state;
    if (currentState is BOMDetailViewLoaded) {
      final currentBOM = currentState.bom;
      emit(BOMLoading());

      try {
        // Tạo list mới từ list cũ để tránh tham chiếu
        List<BOMDetail> updatedDetails = List.from(currentBOM.bomDetails);

        if (isEdit) {
          // Tìm và thay thế
          final index = updatedDetails.indexWhere((d) => d.detailId == detail.detailId);
          if (index != -1) {
            updatedDetails[index] = detail;
          }
        } else {
          // Thêm mới
          updatedDetails.add(detail);
        }

        // [SỬA ĐỔI QUAN TRỌNG] Cập nhật constructor theo Model mới (bỏ bomCode/Name, thêm applicableYear)
        final newBOMHeader = BOMHeader(
          bomId: currentBOM.bomId,
          productId: currentBOM.productId,
          
          applicableYear: currentBOM.applicableYear, // <--- Field mới
          displayName: currentBOM.displayName,       // <--- Field mới (giữ nguyên để hiển thị nếu cần)
          
          targetWeightGm: currentBOM.targetWeightGm,
          totalScrapRate: currentBOM.totalScrapRate,
          totalShrinkageRate: currentBOM.totalShrinkageRate,
          widthBehindLoom: currentBOM.widthBehindLoom,
          picks: currentBOM.picks,
          version: currentBOM.version,
          isActive: currentBOM.isActive,
          bomDetails: updatedDetails, // <--- List chi tiết mới
        );

        // Gọi API Update (Backend sẽ tính toán lại)
        await _repo.updateBOM(newBOMHeader);
        
        // Reload lại chi tiết để lấy số liệu tính toán từ server
        await loadBOMDetailView(currentBOM.bomId);
        
      } catch (e) {
        final msg = e.toString().replaceAll("Exception: ", "");
        emit(BOMError("Lỗi lưu chi tiết: $msg"));
        // Re-emit state cũ nếu lỗi để UI không bị treo ở Loading
        emit(BOMDetailViewLoaded(currentBOM)); 
      }
    }
  }

  // 5. Delete Detail
  Future<void> deleteBOMDetail(int detailId, int bomId) async {
    final currentState = state;
    if (currentState is BOMDetailViewLoaded) {
      final currentBOM = currentState.bom;
      emit(BOMLoading());

      try {
        List<BOMDetail> updatedDetails = List.from(currentBOM.bomDetails);
        updatedDetails.removeWhere((d) => d.detailId == detailId);

        // [SỬA ĐỔI QUAN TRỌNG] Cập nhật constructor theo Model mới
        final newBOMHeader = BOMHeader(
          bomId: currentBOM.bomId,
          productId: currentBOM.productId,
          
          applicableYear: currentBOM.applicableYear, // <--- Field mới
          displayName: currentBOM.displayName,
          
          targetWeightGm: currentBOM.targetWeightGm,
          totalScrapRate: currentBOM.totalScrapRate,
          totalShrinkageRate: currentBOM.totalShrinkageRate,
          widthBehindLoom: currentBOM.widthBehindLoom,
          picks: currentBOM.picks,
          version: currentBOM.version,
          isActive: currentBOM.isActive,
          bomDetails: updatedDetails, // <--- List đã xóa item
        );

        await _repo.updateBOM(newBOMHeader);
        await loadBOMDetailView(bomId);

      } catch (e) {
        emit(BOMError("Lỗi xóa chi tiết: $e"));
        emit(BOMDetailViewLoaded(currentBOM));
      }
    }
  }
  
  // 6. Delete Header
  Future<void> deleteBOMHeader(int id) async {
     try {
       await _repo.deleteBOM(id);
       loadBOMHeaders(); // Back to list
     } catch (e) {
       emit(BOMError(e.toString()));
     }
  }
}