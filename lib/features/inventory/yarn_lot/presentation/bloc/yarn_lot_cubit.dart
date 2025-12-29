import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/yarn_lot_repository.dart';
import '../../domain/yarn_lot_model.dart';

abstract class YarnLotState {}
class YarnLotInitial extends YarnLotState {}
class YarnLotLoading extends YarnLotState {}
class YarnLotLoaded extends YarnLotState {
  final List<YarnLot> yarnLots;
  YarnLotLoaded(this.yarnLots);
}
class YarnLotError extends YarnLotState {
  final String message;
  YarnLotError(this.message);
}

class YarnLotCubit extends Cubit<YarnLotState> {
  final YarnLotRepository _repo;

  YarnLotCubit(this._repo) : super(YarnLotInitial());

  Future<void> loadYarnLots() async {
    emit(YarnLotLoading());
    try {
      final list = await _repo.getYarnLots();
      emit(YarnLotLoaded(list));
    } catch (e) {
      emit(YarnLotError(e.toString()));
    }
  }

  Future<void> searchYarnLots(String keyword) async {
    if (keyword.trim().isEmpty) {
      loadYarnLots();
      return;
    }
    emit(YarnLotLoading());
    try {
      final list = await _repo.searchYarnLots(keyword);
      emit(YarnLotLoaded(list));
    } catch (e) {
      emit(YarnLotError(e.toString()));
    }
  }

  Future<void> saveYarnLot({required YarnLot lot, required bool isEdit}) async {
    try {
      if (isEdit) {
        await _repo.updateYarnLot(lot);
      } else {
        await _repo.createYarnLot(lot);
      }
      loadYarnLots();
    } catch (e) {
      emit(YarnLotError("Failed to save data: $e"));
    }
  }

  Future<void> deleteYarnLot(int id) async {
    try {
      await _repo.deleteYarnLot(id);
      loadYarnLots();
    } catch (e) {
      emit(YarnLotError("Failed to delete data: $e"));
    }
  }
}