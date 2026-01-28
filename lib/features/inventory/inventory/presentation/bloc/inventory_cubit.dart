import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/inventory_repository.dart';
import '../../domain/inventory_model.dart';

// --- STATES ---
abstract class InventoryState {}
class InventoryInitial extends InventoryState {}
class InventoryLoading extends InventoryState {}

class InventoryListLoaded extends InventoryState {
  final List<InventoryStock> stocks;
  InventoryListLoaded(this.stocks);
}

class InventoryError extends InventoryState {
  final String message;
  InventoryError(this.message);
}

class InventoryAdjustmentSuccess extends InventoryState {
  final InventoryStock updatedStock;
  InventoryAdjustmentSuccess(this.updatedStock);
}

// --- CUBIT ---
class InventoryCubit extends Cubit<InventoryState> {
  final InventoryRepository _repo;

  InventoryCubit(this._repo) : super(InventoryInitial());

  // 1. Load List
  Future<void> loadInventories({String? search, int? warehouseId}) async {
    emit(InventoryLoading());
    try {
      final list = await _repo.getInventories(search: search, warehouseId: warehouseId);
      emit(InventoryListLoaded(list));
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  // 2. Adjust Stock
  Future<void> adjustStock(InventoryAdjustment adjustment) async {
    emit(InventoryLoading());
    try {
      final updated = await _repo.adjustStock(adjustment);
      emit(InventoryAdjustmentSuccess(updated));
      // Reload list sau khi điều chỉnh
      loadInventories(); 
    } catch (e) {
      emit(InventoryError(e.toString().replaceAll("Exception: ", "")));
    }
  }
}