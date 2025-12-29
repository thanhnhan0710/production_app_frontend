import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/employee_repository.dart';
import '../../domain/employee_model.dart';

// States
abstract class EmployeeState {}
class EmployeeInitial extends EmployeeState {}
class EmployeeLoading extends EmployeeState {}
class EmployeeLoaded extends EmployeeState {
  final List<Employee> employees;
  EmployeeLoaded(this.employees);
}
class EmployeeError extends EmployeeState {
  final String message;
  EmployeeError(this.message);
}

// Cubit
class EmployeeCubit extends Cubit<EmployeeState> {
  final EmployeeRepository _repo;

  EmployeeCubit(this._repo) : super(EmployeeInitial());

  // Load all
  Future<void> loadEmployees() async {
    emit(EmployeeLoading());
    try {
      final list = await _repo.getEmployees();
      emit(EmployeeLoaded(list));
    } catch (e) {
      emit(EmployeeError(e.toString()));
    }
  }

  // [NEW] Load by Department ID
  Future<void> loadEmployeesByDepartment(int departmentId) async {
    emit(EmployeeLoading());
    try {
      final list = await _repo.getEmployeesByDepartmentId(departmentId);
      emit(EmployeeLoaded(list));
    } catch (e) {
      emit(EmployeeError(e.toString()));
    }
  }

  // Search logic
  Future<void> searchEmployees(String keyword) async {
    if (keyword.trim().isEmpty) {
      loadEmployees();
      return;
    }
    emit(EmployeeLoading());
    try {
      final list = await _repo.searchEmployees(keyword);
      emit(EmployeeLoaded(list));
    } catch (e) {
      emit(EmployeeError(e.toString()));
    }
  }

  Future<void> saveEmployee({
    required Employee employee,
    PlatformFile? imageFile,
    required bool isEdit,
  }) async {
    try {
      String finalAvatarUrl = employee.avatarUrl;

      if (imageFile != null) {
        finalAvatarUrl = await _repo.uploadAvatar(imageFile);
      }

      final Employee finalEmployee = Employee(
        id: employee.id,
        fullName: employee.fullName,
        email: employee.email,
        phone: employee.phone,
        address: employee.address,
        position: employee.position,
        departmentId: employee.departmentId,
        note: employee.note,
        avatarUrl: finalAvatarUrl,
      );

      if (isEdit) {
        await _repo.updateEmployee(finalEmployee);
      } else {
        await _repo.createEmployee(finalEmployee);
      }
      
      // Sau khi lưu xong, ta reload lại danh sách. 
      // Lưu ý: Nếu đang ở màn hình chi tiết bộ phận, logic này sẽ load lại ALL employees.
      // Để hoàn hảo, ta nên check ngữ cảnh hoặc load lại đúng hàm cần thiết.
      // Ở đây tạm thời load all để đơn giản.
      loadEmployees(); 
    } catch (e) {
      emit(EmployeeError("Failed to save employee: $e"));
    }
  }

  Future<void> deleteEmployee(int id) async {
    try {
      await _repo.deleteEmployee(id);
      loadEmployees();
    } catch (e) {
      emit(EmployeeError(e.toString()));
    }
  }
}