import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/yarn_repository.dart';
import '../../domain/yarn_model.dart';

abstract class YarnState {}
class YarnInitial extends YarnState {}
class YarnLoading extends YarnState {}
class YarnLoaded extends YarnState {
  final List<Yarn> yarns;
  YarnLoaded(this.yarns);
}
class YarnError extends YarnState {
  final String message;
  YarnError(this.message);
}

class YarnCubit extends Cubit<YarnState> {
  final YarnRepository _repo;

  YarnCubit(this._repo) : super(YarnInitial());

  Future<void> loadYarns() async {
    emit(YarnLoading());
    try {
      final list = await _repo.getYarns();
      emit(YarnLoaded(list));
    } catch (e) {
      emit(YarnError(e.toString()));
    }
  }

  Future<void> searchYarns(String keyword) async {
    if (keyword.trim().isEmpty) {
      loadYarns();
      return;
    }
    emit(YarnLoading());
    try {
      final list = await _repo.searchYarns(keyword);
      emit(YarnLoaded(list));
    } catch (e) {
      emit(YarnError(e.toString()));
    }
  }

  Future<void> saveYarn({required Yarn yarn, required bool isEdit}) async {
    try {
      if (isEdit) {
        await _repo.updateYarn(yarn);
      } else {
        await _repo.createYarn(yarn);
      }
      loadYarns();
    } catch (e) {
      emit(YarnError("Failed to save data: $e"));
    }
  }

  Future<void> deleteYarn(int id) async {
    try {
      await _repo.deleteYarn(id);
      loadYarns();
    } catch (e) {
      emit(YarnError("Failed to delete data: $e"));
    }
  }
}