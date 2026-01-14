import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/weaving_production_model.dart';
import '../../data/weaving_production_repository.dart';

// --- STATES ---
abstract class WeavingProductionState {}

class WeavingProductionInitial extends WeavingProductionState {}

class WeavingProductionLoading extends WeavingProductionState {}

class WeavingProductionLoaded extends WeavingProductionState {
  final List<WeavingDailyProduction> productions;
  
  // Lưu lại các param filter để UI hiển thị lại
  final String? keyword;
  final DateTime? fromDate;
  final DateTime? toDate;

  WeavingProductionLoaded(
    this.productions, {
    this.keyword,
    this.fromDate,
    this.toDate,
  });
}

class WeavingProductionError extends WeavingProductionState {
  final String message;
  WeavingProductionError(this.message);
}

// --- CUBIT ---
class WeavingProductionCubit extends Cubit<WeavingProductionState> {
  final WeavingProductionRepository _repo;

  WeavingProductionCubit(this._repo) : super(WeavingProductionInitial());

  Future<void> loadData({String? keyword, DateTime? fromDate, DateTime? toDate}) async {
    emit(WeavingProductionLoading());
    try {
      final list = await _repo.searchProductions(
        keyword: keyword,
        fromDate: fromDate,
        toDate: toDate,
      );
      emit(WeavingProductionLoaded(
        list,
        keyword: keyword,
        fromDate: fromDate,
        toDate: toDate,
      ));
    } catch (e) {
      emit(WeavingProductionError(e.toString()));
    }
  }
  
  // Gọi tính toán lại cho ngày hôm nay (Ví dụ)
  Future<void> recalculateToday() async {
    try {
      await _repo.calculateDailyManual(DateTime.now());
      // Sau khi tính xong thì reload lại list
      if (state is WeavingProductionLoaded) {
        final curr = state as WeavingProductionLoaded;
        loadData(keyword: curr.keyword, fromDate: curr.fromDate, toDate: curr.toDate);
      } else {
        loadData();
      }
    } catch (e) {
      emit(WeavingProductionError("Không thể tính toán lại: $e"));
    }
  }
}