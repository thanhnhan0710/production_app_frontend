import 'package:file_saver/file_saver.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/machine_repository.dart';
import '../../domain/machine_model.dart';

abstract class MachineState {}

class MachineInitial extends MachineState {}

class MachineLoading extends MachineState {}

class MachineLoaded extends MachineState {
  final List<Machine> machines;
  MachineLoaded(this.machines);
}

class MachineError extends MachineState {
  final String message;
  MachineError(this.message);
}

class MachineCubit extends Cubit<MachineState> {
  final MachineRepository _repo;

  MachineCubit(this._repo) : super(MachineInitial());

  Future<void> loadMachines() async {
    emit(MachineLoading());
    try {
      final list = await _repo.getMachines();
      emit(MachineLoaded(list));
    } catch (e) {
      emit(MachineError(e.toString()));
    }
  }

  Future<void> searchMachines(String keyword) async {
    if (keyword.trim().isEmpty) {
      loadMachines();
      return;
    }
    emit(MachineLoading());
    try {
      final list = await _repo.searchMachines(keyword);
      emit(MachineLoaded(list));
    } catch (e) {
      emit(MachineError(e.toString()));
    }
  }

  Future<void> saveMachine(
      {required Machine machine, required bool isEdit}) async {
    try {
      // [DEBUG] In dữ liệu gửi đi để kiểm tra xem Status/Area có đúng định dạng không
      print("📤 Sending Data: ${machine.toJson()}");

      if (isEdit) {
        await _repo.updateMachine(machine);
      } else {
        await _repo.createMachine(machine);
      }
      loadMachines();
    } catch (e) {
      // Log lỗi ra console
      print("❌ Save Failed: $e");

      // Emit lỗi để hiện lên SnackBar (bỏ chữ "Exception:" cho đẹp)
      emit(MachineError(e.toString().replaceAll("Exception: ", "")));
    }
  }

  Future<void> deleteMachine(int id) async {
    try {
      await _repo.deleteMachine(id);
      loadMachines();
    } catch (e) {
      emit(MachineError("Failed to delete data: $e"));
    }
  }

  // --- [MỚI] IMPORT EXCEL ---
  Future<void> importExcel(PlatformFile file) async {
    emit(MachineLoading());
    try {
      final result = await _repo.importExcel(file);
      await loadMachines();

      if (result['errors'] != null && (result['errors'] as List).isNotEmpty) {
        emit(MachineError(
            "Đã import ${result['success_count']} dòng. Các lỗi:\n${(result['errors'] as List).join('\n')}"));
      }
    } catch (e) {
      emit(MachineError(e.toString().replaceAll("Exception: ", "")));
    }
  }

  Future<void> exportExcel() async {
    try {
      final bytes = await _repo.exportExcel();

      await FileSaver.instance.saveFile(
        name: 'WEAVING MACHINE${DateTime.now().millisecondsSinceEpoch}.xlsx',
        bytes: bytes,
        mimeType: MimeType.microsoftExcel,
      );
    } catch (e) {
      emit(MachineError(
          "Lỗi xuất file: ${e.toString().replaceAll("Exception: ", "")}"));
    }
  }
}
