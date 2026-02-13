import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/dye_color_repository.dart';
import '../../domain/dye_color_model.dart';

abstract class DyeColorState {}

class DyeColorInitial extends DyeColorState {}

class DyeColorLoading extends DyeColorState {}

class DyeColorLoaded extends DyeColorState {
  final List<DyeColor> colors;
  DyeColorLoaded(this.colors);
}

class DyeColorError extends DyeColorState {
  final String message;
  DyeColorError(this.message);
}

class DyeColorCubit extends Cubit<DyeColorState> {
  final DyeColorRepository _repo;

  DyeColorCubit(this._repo) : super(DyeColorInitial());

  Future<void> loadColors() async {
    emit(DyeColorLoading());
    try {
      final list = await _repo.getColors();
      emit(DyeColorLoaded(list));
    } catch (e) {
      emit(DyeColorError(e.toString()));
    }
  }

  Future<void> searchColors(String keyword) async {
    if (keyword.trim().isEmpty) {
      loadColors();
      return;
    }
    emit(DyeColorLoading());
    try {
      final list = await _repo.searchColors(keyword);
      emit(DyeColorLoaded(list));
    } catch (e) {
      emit(DyeColorError(e.toString()));
    }
  }

  // [SỬA ĐỔI] Trả về String? thay vì void để UI biết kết quả
  // null = Thành công
  // String = Nội dung lỗi
  Future<String?> saveColor(
      {required DyeColor color, required bool isEdit}) async {
    try {
      if (isEdit) {
        await _repo.updateColor(color);
      } else {
        await _repo.createColor(color);
      }
      // Reload lại danh sách sau khi thành công
      loadColors();
      return null; // Thành công
    } catch (e) {
      // [QUAN TRỌNG] Không emit(DyeColorError) ở đây để tránh làm mất danh sách UI
      // Chỉ trả về lỗi cho UI xử lý (hiện snackbar)
      return e.toString();
    }
  }

  Future<void> deleteColor(int id) async {
    try {
      await _repo.deleteColor(id);
      loadColors();
    } catch (e) {
      // Xóa thất bại thì có thể emit lỗi hoặc load lại
      loadColors();
    }
  }
}
