import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/iqc_result_repository.dart';
import '../../domain/iqc_result_model.dart';

// --- STATES ---
abstract class IQCResultState {}

class IQCInitial extends IQCResultState {}

class IQCLoading extends IQCResultState {}

class IQCListLoaded extends IQCResultState {
  final List<IQCResult> results;
  IQCListLoaded(this.results);
}

class IQCOperationSuccess extends IQCResultState {
  final String message;
  IQCOperationSuccess(this.message);
}

class IQCError extends IQCResultState {
  final String message;
  IQCError(this.message);
}

// --- CUBIT ---
class IQCResultCubit extends Cubit<IQCResultState> {
  final IQCResultRepository _repo;

  IQCResultCubit(this._repo) : super(IQCInitial());

  // 1. Load danh sách (Thường dùng để xem lịch sử test của 1 Batch)
  Future<void> loadResultsByBatch(int batchId) async {
    emit(IQCLoading());
    try {
      final list = await _repo.getIQCResults(batchId: batchId);
      emit(IQCListLoaded(list));
    } catch (e) {
      emit(IQCError(e.toString()));
    }
  }

  // 2. Lưu kết quả (Tạo mới hoặc Cập nhật)
  Future<void> saveResult({required IQCResult result, required bool isEdit}) async {
    // emit(IQCLoading()); // Có thể bật loading nếu muốn khóa màn hình khi lưu
    try {
      if (isEdit && result.testId != null) {
        await _repo.updateIQCResult(result);
        emit(IQCOperationSuccess("Cập nhật kết quả kiểm tra thành công."));
      } else {
        await _repo.createIQCResult(result);
        emit(IQCOperationSuccess("Tạo phiếu kiểm tra thành công. Trạng thái lô hàng đã được cập nhật."));
      }
      
      // Sau khi lưu xong, reload lại danh sách của batch đó
      loadResultsByBatch(result.batchId);
    } catch (e) {
      emit(IQCError(e.toString().replaceAll("Exception:", "").trim()));
    }
  }
}