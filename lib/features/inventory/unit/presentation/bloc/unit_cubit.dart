import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/unit_repository.dart';
import '../../domain/unit_model.dart';

abstract class UnitState {}
class UnitInitial extends UnitState {}
class UnitLoading extends UnitState {}
class UnitLoaded extends UnitState {
  final List<ProductUnit> units;
  UnitLoaded(this.units);
}
class UnitError extends UnitState {
  final String message;
  UnitError(this.message);
}

class UnitCubit extends Cubit<UnitState> {
  final UnitRepository _repo;

  UnitCubit(this._repo) : super(UnitInitial());

  Future<void> loadUnits() async {
    emit(UnitLoading());
    try {
      final list = await _repo.getUnits();
      emit(UnitLoaded(list));
    } catch (e) {
      emit(UnitError(e.toString()));
    }
  }

  Future<void> searchUnits(String keyword) async {
    if (keyword.trim().isEmpty) {
      loadUnits();
      return;
    }
    emit(UnitLoading());
    try {
      final list = await _repo.searchUnits(keyword);
      emit(UnitLoaded(list));
    } catch (e) {
      emit(UnitError(e.toString()));
    }
  }

  Future<void> saveUnit({required ProductUnit unit, required bool isEdit}) async {
    try {
      if (isEdit) {
        await _repo.updateUnit(unit);
      } else {
        await _repo.createUnit(unit);
      }
      loadUnits();
    } catch (e) {
      emit(UnitError("Failed to save data: $e"));
    }
  }

  Future<void> deleteUnit(int id) async {
    try {
      await _repo.deleteUnit(id);
      loadUnits();
    } catch (e) {
      emit(UnitError("Failed to delete data: $e"));
    }
  }
}