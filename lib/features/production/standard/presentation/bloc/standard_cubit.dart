import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/standard_repository.dart';
import '../../domain/standard_model.dart';

// ==============================
// 1. ĐỊNH NGHĨA CÁC STATES
// ==============================
abstract class StandardState {}

class StandardInitial extends StandardState {}

class StandardLoading extends StandardState {}

class StandardLoaded extends StandardState {
  final List<Standard> standards;
  StandardLoaded(this.standards);
}

class StandardError extends StandardState {
  final String message;
  StandardError(this.message);
}

// [QUAN TRỌNG] Thêm 2 state này để hiển thị Dialog sau khi Import Excel
class StandardSuccessMsg extends StandardState {
  final String message;
  StandardSuccessMsg(this.message);
}

class StandardErrorMsg extends StandardState {
  final String message;
  StandardErrorMsg(this.message);
}

// ==============================
// 2. LOGIC CUBIT
// ==============================
class StandardCubit extends Cubit<StandardState> {
  final StandardRepository _repo;

  StandardCubit(this._repo) : super(StandardInitial());

  Future<void> loadStandards() async {
    emit(StandardLoading());
    try {
      final list = await _repo.getStandards();
      emit(StandardLoaded(list));
    } catch (e) {
      emit(StandardError(e.toString()));
    }
  }

  Future<void> searchStandards(String keyword) async {
    if (keyword.trim().isEmpty) {
      loadStandards();
      return;
    }
    emit(StandardLoading());
    try {
      final list = await _repo.searchStandards(keyword);
      emit(StandardLoaded(list));
    } catch (e) {
      emit(StandardError(e.toString()));
    }
  }

  Future<void> saveStandard(
      {required Standard standard, required bool isEdit}) async {
    try {
      if (isEdit) {
        await _repo.updateStandard(standard);
      } else {
        await _repo.createStandard(standard);
      }
      loadStandards();
    } catch (e) {
      emit(StandardError("Failed to save data: $e"));
    }
  }

  Future<void> deleteStandard(int id) async {
    try {
      await _repo.deleteStandard(id);
      loadStandards();
    } catch (e) {
      emit(StandardError("Failed to delete data: $e"));
    }
  }

  // --- HÀM IMPORT EXCEL ---
  Future<void> importExcel(PlatformFile file) async {
    emit(StandardLoading());
    try {
      final result = await _repo.importExcel(file);
      await loadStandards(); // Tải lại danh sách sau khi import

      final int successCount = result['success_count'] ?? 0;
      final List errors = result['errors'] ?? [];

      String msg = "Đã import thành công $successCount Standards.";

      if (errors.isNotEmpty) {
        msg += "\n\n⚠️ Bỏ qua các dòng lỗi sau:\n${errors.join('\n')}";
        emit(StandardErrorMsg(
            msg)); // Gọi class StandardErrorMsg đã định nghĩa ở trên
      } else {
        emit(StandardSuccessMsg(
            msg)); // Gọi class StandardSuccessMsg đã định nghĩa ở trên
      }
    } catch (e) {
      emit(StandardErrorMsg(e.toString().replaceAll("Exception: ", "")));
      loadStandards(); // Nếu lỗi thì load lại danh sách cũ để tránh bị kẹt màn hình loading
    }
  }
}
