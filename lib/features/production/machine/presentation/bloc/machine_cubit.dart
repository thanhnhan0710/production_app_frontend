import 'package:flutter_bloc/flutter_bloc.dart';
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

  Future<void> saveMachine({required Machine machine, required bool isEdit}) async {
    try {
      if (isEdit) {
        await _repo.updateMachine(machine);
      } else {
        await _repo.createMachine(machine);
      }
      loadMachines();
    } catch (e) {
      emit(MachineError("Failed to save data: $e"));
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
}