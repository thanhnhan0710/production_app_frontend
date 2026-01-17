import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/material_repository.dart';
import '../../domain/material_model.dart';

abstract class MaterialState {}
class MaterialInitial extends MaterialState {}
class MaterialLoading extends MaterialState {}
class MaterialLoaded extends MaterialState {
  final List<MaterialModel> materials;
  MaterialLoaded(this.materials);
}
class MaterialError extends MaterialState {
  final String message;
  MaterialError(this.message);
}

class MaterialCubit extends Cubit<MaterialState> {
  final MaterialRepository _repo;

  MaterialCubit(this._repo) : super(MaterialInitial());

  Future<void> loadMaterials() async {
    emit(MaterialLoading());
    try {
      final list = await _repo.getMaterials();
      emit(MaterialLoaded(list));
    } catch (e) {
      emit(MaterialError(e.toString()));
    }
  }

  Future<void> searchMaterials(String keyword) async {
    if (keyword.trim().isEmpty) {
      loadMaterials();
      return;
    }
    emit(MaterialLoading());
    try {
      final list = await _repo.searchMaterials(keyword);
      emit(MaterialLoaded(list));
    } catch (e) {
      emit(MaterialError(e.toString()));
    }
  }

  Future<void> saveMaterial({required MaterialModel material, required bool isEdit}) async {
    try {
      print("📤 Sending Material Data: ${material.toJson()}");
      if (isEdit) {
        await _repo.updateMaterial(material);
      } else {
        await _repo.createMaterial(material);
      }
      loadMaterials();
    } catch (e) {
      print("❌ Save Failed: $e");
      emit(MaterialError(e.toString().replaceAll("Exception: ", "")));
    }
  }

  Future<void> deleteMaterial(int id) async {
    try {
      await _repo.deleteMaterial(id);
      loadMaterials();
    } catch (e) {
      emit(MaterialError("Failed to delete data: $e"));
    }
  }
}