import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/auth_exception.dart';
import '../../data/auth_repository.dart';
import '../../domain/user_model.dart';

// --- STATES ---
abstract class AuthState {}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final User user;
  AuthAuthenticated(this.user);
}
class AuthError extends AuthState {
  // Thay đổi: Bây giờ chúng ta truyền mã lỗi, thay vì chỉ truyền message
  final AuthErrorCode code; 
  final String? detailMessage;

  AuthError(this.code, {this.detailMessage});
}

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repository;

  AuthCubit(this._repository) : super(AuthInitial());

  Future<void> login(String username, String password) async {
    emit(AuthLoading());
    try {
      final user = await _repository.login(username, password);
      emit(AuthAuthenticated(user));
    } on AuthException catch (e) {
      // Bắt AuthException và truyền mã lỗi xuống UI
      emit(AuthError(e.code, detailMessage: e.detail));
    } catch (e) {
      // Xử lý các lỗi khác không phải AuthException (Rất hiếm)
      emit(AuthError(AuthErrorCode.systemError, detailMessage: e.toString()));
    }
  }

  Future<void> checkAuthStatus() async {
    // Logic kiểm tra token
    // ...
    emit(AuthInitial());
  }

  Future<void> logout() async {
    await _repository.logout();
    emit(AuthInitial());
  }
}