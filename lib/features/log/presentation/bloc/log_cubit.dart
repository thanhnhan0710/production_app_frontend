import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:production_app_frontend/features/log/data/log_repository.dart';
import 'package:production_app_frontend/features/log/domain/log_model.dart';


abstract class LogState {}
class LogInitial extends LogState {}
class LogLoading extends LogState {}
class LogLoaded extends LogState {
  final List<LogModel> logs;
  LogLoaded(this.logs);
}
class LogError extends LogState {
  final String message;
  LogError(this.message);
}

class LogCubit extends Cubit<LogState> {
  final LogRepository _repo;

  LogCubit(this._repo) : super(LogInitial());

  Future<void> loadLogs({String? targetType, int? targetId, DateTime? fromDate,
    DateTime? toDate,}) async {
    emit(LogLoading());
    try {
      final logs = await _repo.getLogs(targetType: targetType, targetId: targetId, fromDate: fromDate, // Truyền xuống repo
        toDate: toDate,);
      emit(LogLoaded(logs));
    } catch (e) {
      emit(LogError(e.toString()));
    }
  }

  Future<void> revertLogItem(int logId) async {
    // Lưu lại state hiện tại để không bị mất list khi loading
    final currentState = state;
    if (currentState is LogLoaded) {
       // Có thể emit trạng thái loading riêng hoặc dùng Dialog loading ở UI
       // Ở đây ta gọi repo trực tiếp
       try {
         await _repo.revertLog(logId);
         // Sau khi revert thành công, load lại danh sách để thấy log mới
         loadLogs(); 
       } catch (e) {
         emit(LogError(e.toString()));
         // Emit lại list cũ sau khi báo lỗi (để UI không trắng trơn)
         emit(currentState);
       }
    }
  }
}