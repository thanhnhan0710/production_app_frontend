import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/material_export_repository.dart';
import '../../domain/material_export_model.dart';

abstract class MaterialExportState {}
class MaterialExportInitial extends MaterialExportState {}
class MaterialExportLoading extends MaterialExportState {}
class MaterialExportSuccess extends MaterialExportState {} // Dùng cho Create/Delete thành công
class MaterialExportListLoaded extends MaterialExportState {
  final List<MaterialExport> list;
  MaterialExportListLoaded(this.list);
}
class MaterialExportError extends MaterialExportState {
  final String message;
  MaterialExportError(this.message);
}

class MaterialExportCubit extends Cubit<MaterialExportState> {
  final MaterialExportRepository _repo;

  MaterialExportCubit(this._repo) : super(MaterialExportInitial());

  Future<void> loadExports({String? search, int? warehouseId}) async {
    emit(MaterialExportLoading());
    try {
      final list = await _repo.getExports(search: search, warehouseId: warehouseId);
      emit(MaterialExportListLoaded(list));
    } catch (e) {
      emit(MaterialExportError(e.toString()));
    }
  }

  Future<void> createExport(MaterialExport exportData) async {
    emit(MaterialExportLoading());
    try {
      await _repo.createExport(exportData);
      emit(MaterialExportSuccess());
      loadExports(); // Reload list
    } catch (e) {
      emit(MaterialExportError(e.toString().replaceAll("Exception: ", "")));
    }
  }

  Future<void> deleteExport(int id) async {
    emit(MaterialExportLoading());
    try {
      await _repo.deleteExport(id);
      emit(MaterialExportSuccess());
      loadExports();
    } catch (e) {
      emit(MaterialExportError(e.toString().replaceAll("Exception: ", "")));
    }
  }
  
  String getNewCode() => _repo.generateExportCode();
}