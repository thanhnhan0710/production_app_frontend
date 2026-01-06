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

  Future<void> saveColor({required DyeColor color, required bool isEdit}) async {
    try {
      if (isEdit) {
        await _repo.updateColor(color);
      } else {
        await _repo.createColor(color);
      }
      loadColors();
    } catch (e) {
      emit(DyeColorError("Failed to save data: $e"));
    }
  }

  Future<void> deleteColor(int id) async {
    try {
      await _repo.deleteColor(id);
      loadColors();
    } catch (e) {
      emit(DyeColorError("Failed to delete data: $e"));
    }
  }
}