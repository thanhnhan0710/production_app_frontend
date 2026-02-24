import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/purchase_order_repository.dart';
import '../../domain/purchase_order_model.dart';

// --- STATES ---
abstract class PurchaseOrderState {}

class POInitial extends PurchaseOrderState {}

class POLoading extends PurchaseOrderState {}

// State cho danh sách
class POListLoaded extends PurchaseOrderState {
  final List<PurchaseOrderHeader> list;
  POListLoaded(this.list);
}

// State cho chi tiết 1 PO
class PODetailLoaded extends PurchaseOrderState {
  final PurchaseOrderHeader po;
  PODetailLoaded(this.po);
}

class POSuccess extends PurchaseOrderState {
  final String message;
  POSuccess(this.message);
}

class POError extends PurchaseOrderState {
  final String message;
  POError(this.message);
}

// --- CUBIT ---
class PurchaseOrderCubit extends Cubit<PurchaseOrderState> {
  final PurchaseOrderRepository _repo;

  PurchaseOrderCubit(this._repo) : super(POInitial());

  // 1. Load Danh sách (Có Filter)
  Future<void> loadPurchaseOrders({
    String? search,
    int? vendorId,
    POStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    emit(POLoading());
    try {
      final list = await _repo.getPurchaseOrders(
        search: search,
        vendorId: vendorId,
        status: status,
        fromDate: fromDate,
        toDate: toDate,
      );
      emit(POListLoaded(list));
    } catch (e) {
      emit(POError(e.toString()));
    }
  }

  // 2. Load Chi tiết
  Future<void> loadPurchaseOrderDetail(int poId) async {
    emit(POLoading());
    try {
      final po = await _repo.getPurchaseOrderById(poId);
      emit(PODetailLoaded(po));
    } catch (e) {
      emit(POError(e.toString()));
    }
  }

  // [MỚI] Hàm lấy số PO tiếp theo
  Future<String> fetchNextPONumber() async {
    try {
      return await _repo.getNextPONumber();
    } catch (e) {
      return "";
    }
  }

  // 3. Save (Create or Update)
  Future<void> savePurchaseOrder({
    required PurchaseOrderHeader po,
    required bool isEdit,
  }) async {
    try {
      if (isEdit) {
        await _repo.updatePurchaseOrder(po.poId, po);
      } else {
        await _repo.createPurchaseOrder(po);
      }

      loadPurchaseOrders();
    } catch (e) {
      print("❌ Save PO Failed: $e");
      emit(POError(e.toString().replaceAll("Exception: ", "")));
    }
  }

  // 4. Thêm vật tư vào PO (Add Item)
  Future<void> addDetailItem(int poId, PurchaseOrderDetail detail) async {
    try {
      await _repo.addDetailItem(poId, detail);
      loadPurchaseOrderDetail(poId);
    } catch (e) {
      emit(POError(e.toString()));
    }
  }

  // [UPDATED] Hàm xóa PO hoàn chỉnh
  Future<void> deletePurchaseOrder(int poId) async {
    try {
      await _repo.deletePurchaseOrder(poId);
      // Xóa thành công thì load lại danh sách
      loadPurchaseOrders();
    } catch (e) {
      // Emit lỗi để UI hiển thị SnackBar
      emit(POError(e.toString().replaceAll("Exception: ", "")));
      // Load lại danh sách để khôi phục trạng thái UI (tránh bị treo ở màn hình lỗi)
      loadPurchaseOrders();
    }
  }

  // --- [MỚI] HÀM IMPORT EXCEL ---
  Future<void> importExcel(PlatformFile file) async {
    emit(POLoading());
    try {
      final result = await _repo.importExcel(file);

      // Load lại danh sách PO ngay sau khi import
      await loadPurchaseOrders();

      // Phân tích kết quả trả về từ Backend
      final int successPO = result['success_po'] ?? 0;
      final int successDecl = result['success_decl'] ?? 0;
      final List errors = result['errors'] ?? [];

      String msg =
          "Đã import thành công:\n- $successPO Đơn hàng (PO)\n- $successDecl Tờ khai hải quan.";

      if (errors.isNotEmpty) {
        msg += "\n\n⚠️ Bỏ qua các dòng lỗi sau:\n${errors.join('\n')}";
        // Bắn ra POError để UI hiển thị dialog/snackbar màu đỏ hoặc cam chú ý
        emit(POError(msg));
      } else {
        // Hoàn hảo 100%
        emit(POSuccess(msg));
      }
    } catch (e) {
      emit(POError(e.toString().replaceAll("Exception: ", "")));
      loadPurchaseOrders(); // Phục hồi lại list
    }
  }
}
