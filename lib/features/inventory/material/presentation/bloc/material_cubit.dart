import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/material_repository.dart';
import '../../domain/material_model.dart';
import 'package:file_saver/file_saver.dart';

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

  Future<void> saveMaterial(
      {required MaterialModel material, required bool isEdit}) async {
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

  Future<void> importExcel(PlatformFile file) async {
    emit(MaterialLoading());
    try {
      final result = await _repo.importExcel(file);
      // Kết quả trả về có errors và success_count.
      // Do backend đã bắn tín hiệu WebSocket, UI tự động load lại dữ liệu thông qua listener.
      // Ở đây ta chỉ lấy lại danh sách mới để đảm bảo.
      await loadMaterials();

      // Bạn có thể emit 1 state riêng biệt nếu muốn hiển thị thông báo lỗi chi tiết từng dòng,
      // hoặc đơn giản là throw exception để UI bắt.
      if ((result['errors'] as List).isNotEmpty) {
        emit(MaterialError(
            "Đã import ${result['success_count']} dòng. Các lỗi:\n${(result['errors'] as List).join('\n')}"));
      }
    } catch (e) {
      emit(MaterialError(e.toString().replaceAll("Exception: ", "")));
    }
  }

  // Thêm hàm này vào trong class MaterialCubit
  Future<void> exportExcel() async {
    try {
      final bytes = await _repo.exportExcel();

      // Đã sửa lỗi "undefined_named_parameter" tại đây:
      await FileSaver.instance.saveFile(
        name:
            'YARN${DateTime.now().millisecondsSinceEpoch}.xlsx', // Thêm .xlsx thẳng vào tên file
        bytes: bytes,
        mimeType: MimeType.microsoftExcel,
      );
    } catch (e) {
      emit(MaterialError(
          "Lỗi xuất file: ${e.toString().replaceAll("Exception: ", "")}"));
    }
  }
}
