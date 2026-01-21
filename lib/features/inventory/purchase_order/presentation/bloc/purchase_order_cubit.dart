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

  // 3. Save (Create or Update) - Tương tự EmployeeCubit
  Future<void> savePurchaseOrder({
    required PurchaseOrderHeader po,
    required bool isEdit,
  }) async {
    try {
      // print("📤 Saving PO: ${po.toJson()}"); // Debug log nếu cần

      if (isEdit) {
        await _repo.updatePurchaseOrder(po.poId, po);
      } else {
        await _repo.createPurchaseOrder(po);
      }
      
      // Sau khi lưu thành công, tải lại danh sách để cập nhật UI
      // Lưu ý: Nếu đang dùng bộ lọc, việc gọi hàm không tham số này sẽ reset về danh sách mặc định
      loadPurchaseOrders(); 
    } catch (e) {
      // In lỗi ra console để debug
      print("❌ Save PO Failed: $e");
      // Emit state lỗi để UI hiển thị Snackbar/Alert
      emit(POError(e.toString().replaceAll("Exception: ", "")));
    }
  }

  // 4. Thêm vật tư vào PO (Add Item)
  Future<void> addDetailItem(int poId, PurchaseOrderDetail detail) async {
    try {
      await _repo.addDetailItem(poId, detail);
      // Reload detail để cập nhật tổng tiền và danh sách item mới nhất
      loadPurchaseOrderDetail(poId);
    } catch (e) {
      emit(POError(e.toString()));
    }
  }
}