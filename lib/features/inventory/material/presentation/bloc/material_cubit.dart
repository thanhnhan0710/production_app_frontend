import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/material_repository.dart';
import '../../domain/material_model.dart';

// [FIX] Đổi tên MaterialState -> InventoryMaterialState để tránh trùng với Flutter
abstract class InventoryMaterialState {}

class InventoryMaterialInitial extends InventoryMaterialState {}

class InventoryMaterialLoading extends InventoryMaterialState {}

class InventoryMaterialLoaded extends InventoryMaterialState {
  final List<InventoryMaterial> materials;
  InventoryMaterialLoaded(this.materials);
}

class InventoryMaterialError extends InventoryMaterialState {
  final String message;
  InventoryMaterialError(this.message);
}

class MaterialCubit extends Cubit<InventoryMaterialState> {
  final MaterialRepository _repo;

  MaterialCubit(this._repo) : super(InventoryMaterialInitial());

  Future<void> loadMaterials() async {
    emit(InventoryMaterialLoading());
    try {
      final list = await _repo.getMaterials();
      emit(InventoryMaterialLoaded(list));
    } catch (e) {
      emit(InventoryMaterialError(e.toString()));
    }
  }

  Future<void> searchMaterials(String keyword) async {
    if (keyword.trim().isEmpty) {
      loadMaterials();
      return;
    }
    emit(InventoryMaterialLoading());
    try {
      final list = await _repo.searchMaterials(keyword);
      emit(InventoryMaterialLoaded(list));
    } catch (e) {
      emit(InventoryMaterialError(e.toString()));
    }
  }

  Future<void> saveMaterial({required InventoryMaterial item, required bool isEdit}) async {
    try {
      if (isEdit) {
        await _repo.updateMaterial(item);
      } else {
        await _repo.createMaterial(item);
      }
      loadMaterials();
    } catch (e) {
      emit(InventoryMaterialError("Failed to save data: $e"));
    }
  }

  Future<void> deleteMaterial(int id) async {
    try {
      await _repo.deleteMaterial(id);
      loadMaterials();
    } catch (e) {
      emit(InventoryMaterialError("Failed to delete data: $e"));
    }
  }
}