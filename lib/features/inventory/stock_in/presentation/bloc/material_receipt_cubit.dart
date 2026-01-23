import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/material_receipt_repository.dart';
import '../../domain/material_receipt_model.dart';

// States
abstract class MaterialReceiptState {}

class MaterialReceiptInitial extends MaterialReceiptState {}

class MaterialReceiptLoading extends MaterialReceiptState {}

// State cho màn hình danh sách
class MaterialReceiptListLoaded extends MaterialReceiptState {
  final List<MaterialReceipt> receipts;
  MaterialReceiptListLoaded(this.receipts);
}

// State cho màn hình chi tiết/edit
class MaterialReceiptDetailLoaded extends MaterialReceiptState {
  final MaterialReceipt receipt;
  MaterialReceiptDetailLoaded(this.receipt);
}

class MaterialReceiptOperationSuccess extends MaterialReceiptState {
  final String message;
  MaterialReceiptOperationSuccess(this.message);
}

class MaterialReceiptError extends MaterialReceiptState {
  final String message;
  MaterialReceiptError(this.message);
}

// Cubit
class MaterialReceiptCubit extends Cubit<MaterialReceiptState> {
  final MaterialReceiptRepository _repo;

  MaterialReceiptCubit(this._repo) : super(MaterialReceiptInitial());

  // --- LIST ACTIONS ---

  Future<void> loadReceipts({
    String? search,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    emit(MaterialReceiptLoading());
    try {
      final list = await _repo.getReceipts(
        search: search,
        fromDate: fromDate,
        toDate: toDate,
      );
      emit(MaterialReceiptListLoaded(list));
    } catch (e) {
      emit(MaterialReceiptError(e.toString()));
    }
  }

  // --- DETAIL / CRUD ACTIONS ---

  Future<void> getReceiptDetail(int id) async {
    emit(MaterialReceiptLoading());
    try {
      final receipt = await _repo.getReceiptById(id);
      emit(MaterialReceiptDetailLoaded(receipt));
    } catch (e) {
      emit(MaterialReceiptError(e.toString()));
    }
  }

  // [MỚI] Hàm hỗ trợ lấy số phiếu tiếp theo cho form tạo mới
  Future<String> fetchNextReceiptNumber() async {
    try {
      return await _repo.getNextReceiptNumber();
    } catch (e) {
      return "";
    }
  }

  Future<void> createReceipt(MaterialReceipt receipt) async {
    emit(MaterialReceiptLoading());
    try {
      await _repo.createReceipt(receipt);
      emit(MaterialReceiptOperationSuccess("Tạo phiếu nhập thành công"));
      loadReceipts(); // Reload list
    } catch (e) {
      emit(MaterialReceiptError(e.toString()));
    }
  }

  Future<void> updateReceipt(MaterialReceipt receipt) async {
    if (receipt.id == null) return;
    try {
      await _repo.updateReceipt(receipt);
      // Sau khi update header, reload lại detail để UI cập nhật
      getReceiptDetail(receipt.id!);
      // Hoặc emit success nếu muốn thoát màn hình
      // emit(MaterialReceiptOperationSuccess("Cập nhật thành công"));
    } catch (e) {
      emit(MaterialReceiptError(e.toString()));
    }
  }

  Future<void> deleteReceipt(int id) async {
    try {
      await _repo.deleteReceipt(id);
      loadReceipts(); // Reload list sau khi xóa
    } catch (e) {
      emit(MaterialReceiptError(e.toString()));
    }
  }

  // --- DETAIL ITEM ACTIONS ---

  Future<void> addDetailItem(int receiptId, MaterialReceiptDetail detail) async {
    try {
      await _repo.addDetail(receiptId, detail);
      // Reload lại toàn bộ phiếu để thấy dòng mới
      getReceiptDetail(receiptId);
    } catch (e) {
      emit(MaterialReceiptError("Lỗi thêm chi tiết: $e"));
      // Re-emit state cũ để UI không bị treo loading
      getReceiptDetail(receiptId); 
    }
  }

  Future<void> updateDetailItem(int receiptId, MaterialReceiptDetail detail) async {
    if (detail.detailId == null) return;
    try {
      await _repo.updateDetail(detail.detailId!, detail);
      getReceiptDetail(receiptId);
    } catch (e) {
      emit(MaterialReceiptError("Lỗi cập nhật chi tiết: $e"));
      getReceiptDetail(receiptId);
    }
  }

  Future<void> deleteDetailItem(int receiptId, int detailId) async {
    try {
      await _repo.deleteDetail(detailId);
      getReceiptDetail(receiptId);
    } catch (e) {
      emit(MaterialReceiptError("Lỗi xóa chi tiết: $e"));
      getReceiptDetail(receiptId);
    }
  }
}