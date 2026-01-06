import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/standard_repository.dart';
import '../../domain/standard_model.dart';

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

  Future<void> saveStandard({required Standard standard, required bool isEdit}) async {
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
}