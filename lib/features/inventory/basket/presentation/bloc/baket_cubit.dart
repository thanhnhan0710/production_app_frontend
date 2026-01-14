import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:production_app_frontend/features/inventory/basket/data/baket_repository.dart';
import 'package:production_app_frontend/features/inventory/basket/doamain/basket_model.dart';


abstract class BasketState {}
class BasketInitial extends BasketState {}
class BasketLoading extends BasketState {}
class BasketLoaded extends BasketState {
  final List<Basket> baskets;
  BasketLoaded(this.baskets);
}
class BasketError extends BasketState {
  final String message;
  BasketError(this.message);
}

class BasketCubit extends Cubit<BasketState> {
  final BasketRepository _repo;

  BasketCubit(this._repo) : super(BasketInitial());

  Future<void> loadBaskets() async {
    emit(BasketLoading());
    try {
      final list = await _repo.getBaskets();
      emit(BasketLoaded(list));
    } catch (e) {
      emit(BasketError(e.toString()));
    }
  }

  Future<void> searchBaskets(String keyword) async {
    if (keyword.trim().isEmpty) {
      loadBaskets();
      return;
    }
    emit(BasketLoading());
    try {
      final list = await _repo.searchBaskets(keyword);
      emit(BasketLoaded(list));
    } catch (e) {
      emit(BasketError(e.toString()));
    }
  }

  Future<void> saveBasket({required Basket basket, required bool isEdit}) async {
    try {
      if (isEdit) {
        await _repo.updateBasket(basket);
      } else {
        await _repo.createBasket(basket);
      }
      loadBaskets();
    } catch (e) {
      emit(BasketError("Failed to save data: $e"));
    }
  }

  Future<void> deleteBasket(int id) async {
    try {
      await _repo.deleteBasket(id);
      loadBaskets();
    } catch (e) {
      emit(BasketError("Failed to delete data: $e"));
    }
  }
}