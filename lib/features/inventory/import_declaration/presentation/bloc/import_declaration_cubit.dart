import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/import_declaration_repository.dart';
import '../../domain/import_declaration_model.dart';

abstract class ImportDeclState {}
class ImportDeclInitial extends ImportDeclState {}
class ImportDeclLoading extends ImportDeclState {}
class ImportDeclListLoaded extends ImportDeclState {
  final List<ImportDeclaration> list;
  ImportDeclListLoaded(this.list);
}
class ImportDeclDetailLoaded extends ImportDeclState {
  final ImportDeclaration declaration;
  ImportDeclDetailLoaded(this.declaration);
}
class ImportDeclError extends ImportDeclState {
  final String message;
  ImportDeclError(this.message);
}

class ImportDeclarationCubit extends Cubit<ImportDeclState> {
  final ImportDeclarationRepository _repo;

  ImportDeclarationCubit(this._repo) : super(ImportDeclInitial());

  Future<void> loadDeclarations({String? search, ImportType? type, DateTime? fromDate, DateTime? toDate}) async {
    emit(ImportDeclLoading());
    try {
      final list = await _repo.getDeclarations(search: search, type: type, fromDate: fromDate, toDate: toDate);
      emit(ImportDeclListLoaded(list));
    } catch (e) {
      emit(ImportDeclError(e.toString()));
    }
  }

  Future<void> loadDetail(int id) async {
    emit(ImportDeclLoading());
    try {
      final item = await _repo.getDeclarationById(id);
      emit(ImportDeclDetailLoaded(item));
    } catch (e) {
      emit(ImportDeclError(e.toString()));
    }
  }

  Future<void> saveDeclaration({required ImportDeclaration declaration, required bool isEdit}) async {
    try {
      if (isEdit) {
        await _repo.updateDeclaration(declaration.id, declaration);
      } else {
        await _repo.createDeclaration(declaration);
      }
      loadDeclarations(); 
    } catch (e) {
      emit(ImportDeclError(e.toString().replaceAll("Exception: ", "")));
    }
  }

  Future<void> deleteDeclaration(int id) async {
    try {
      await _repo.deleteDeclaration(id);
      loadDeclarations();
    } catch (e) {
      emit(ImportDeclError(e.toString()));
    }
  }

  // --- DETAILS ---
  Future<void> addDetailItem(int declarationId, ImportDeclarationDetail detail) async {
    try {
      await _repo.addDetail(declarationId, detail);
      loadDetail(declarationId);
    } catch (e) {
      emit(ImportDeclError(e.toString()));
    }
  }

  Future<void> updateDetailItem(int declarationId, ImportDeclarationDetail detail) async {
    try {
      await _repo.updateDetail(detail.detailId, detail);
      loadDetail(declarationId);
    } catch (e) {
      emit(ImportDeclError(e.toString()));
    }
  }

  Future<void> deleteDetailItem(int declarationId, int detailId) async {
    try {
      await _repo.deleteDetail(detailId);
      loadDetail(declarationId);
    } catch (e) {
      emit(ImportDeclError(e.toString()));
    }
  }
}