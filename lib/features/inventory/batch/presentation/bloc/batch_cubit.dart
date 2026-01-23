import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:production_app_frontend/features/inventory/batch/data/batch_repository.dart';
import 'package:production_app_frontend/features/inventory/batch/domain/batch_model.dart';


// States
abstract class BatchState {}
class BatchInitial extends BatchState {}
class BatchLoading extends BatchState {}
class BatchLoaded extends BatchState {
  final List<Batch> batches;
  BatchLoaded(this.batches);
}
class BatchError extends BatchState {
  final String message;
  BatchError(this.message);
}

// Cubit
class BatchCubit extends Cubit<BatchState> {
  final BatchRepository _repo;

  BatchCubit(this._repo) : super(BatchInitial());

  // Load danh sách (có hỗ trợ filter)
  Future<void> loadBatches({
    String? search,
    String? supplierBatch,
    int? materialId,
    String? qcStatus,
  }) async {
    emit(BatchLoading());
    try {
      final list = await _repo.getBatches(
        search: search,
        supplierBatch: supplierBatch,
        materialId: materialId,
        qcStatus: qcStatus,
      );
      emit(BatchLoaded(list));
    } catch (e) {
      emit(BatchError(e.toString()));
    }
  }

  // Tạo hoặc Cập nhật
  Future<void> saveBatch({required Batch batch, required bool isEdit}) async {
    // Lưu ý: Không emit Loading ở đây để tránh mất danh sách hiện tại trên UI,
    // hoặc có thể emit nếu muốn hiện spinner toàn màn hình.
    // Ở đây ta dùng cách gọi xong thì reload lại list.
    try {
      if (isEdit) {
        await _repo.updateBatch(batch);
      } else {
        await _repo.createBatch(batch);
      }
      // Load lại danh sách sau khi lưu thành công
      loadBatches();
    } catch (e) {
      emit(BatchError("Lỗi khi lưu lô hàng: $e"));
      // Sau khi báo lỗi, có thể cần load lại data cũ để UI không bị treo ở state Error
      // loadBatches(); 
    }
  }

  // Cập nhật trạng thái QC
  Future<void> updateQcStatus(int batchId, String status, String note) async {
    try {
      await _repo.updateQcStatus(batchId, status, note: note);
      loadBatches(); // Reload để thấy trạng thái mới
    } catch (e) {
      emit(BatchError(e.toString()));
    }
  }

  // Xóa lô hàng
  Future<void> deleteBatch(int id) async {
    try {
      await _repo.deleteBatch(id);
      loadBatches();
    } catch (e) {
      emit(BatchError(e.toString().replaceAll("Exception:", "").trim()));
    }
  }
}