import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:production_app_frontend/features/inventory/basket/data/baket_repository.dart';
import 'package:production_app_frontend/features/inventory/basket/doamain/baket_model.dart';
import '../../domain/machine_model.dart';
import '../../data/machine_repository.dart';
import '../../../weaving/domain/weaving_model.dart';
import '../../../weaving/data/weaving_repository.dart';

// State
abstract class MachineOpState {}
class MachineOpInitial extends MachineOpState {}
class MachineOpLoading extends MachineOpState {}
class MachineOpLoaded extends MachineOpState {
  final List<Machine> machines;
  // Map lưu trữ: Key là "machineId_lineIndex" (VD: "1_1", "1_2"), Value là Ticket đang chạy
  final Map<String, WeavingTicket> activeTickets; 
  final List<Basket> readyBaskets;

  MachineOpLoaded({
    required this.machines,
    required this.activeTickets,
    required this.readyBaskets,
  });
}
class MachineOpError extends MachineOpState {
  final String message;
  MachineOpError(this.message);
}

// Cubit
class MachineOperationCubit extends Cubit<MachineOpState> {
  final MachineRepository _machineRepo;
  final WeavingRepository _weavingRepo;
  final BasketRepository _basketRepo;

  MachineOperationCubit(this._machineRepo, this._weavingRepo, this._basketRepo) : super(MachineOpInitial());

  Future<void> loadDashboard() async {
    emit(MachineOpLoading());
    try {
      // 1. Load danh sách máy
      final machines = await _machineRepo.getMachines();
      
      // 2. Load danh sách rổ đang READY
      final allBaskets = await _basketRepo.getBaskets();
      final readyBaskets = allBaskets.where((b) => b.status == 'READY').toList();

      // 3. Load các Ticket đang active (Chưa có time_out)
      // Giả sử API getTickets trả về tất cả, ta lọc ở client (Thực tế nên có API filter status)
      final allTickets = await _weavingRepo.getTickets();
      final activeTicketsList = allTickets.where((t) => t.timeOut == null).toList();

      // Map ticket vào từng line máy
      final Map<String, WeavingTicket> activeMap = {};
      for (var t in activeTicketsList) {
        // machineLine lưu dạng "1" hoặc "2"
        final key = "${t.machineId}_${t.machineLine}"; 
        activeMap[key] = t;
      }

      emit(MachineOpLoaded(
        machines: machines,
        activeTickets: activeMap,
        readyBaskets: readyBaskets,
      ));
    } catch (e) {
      emit(MachineOpError(e.toString()));
    }
  }

  // Gán rổ vào máy -> Tạo Ticket mới -> Update Basket Status
  Future<void> assignBasketToMachine(int machineId, String line, Basket basket) async {
    try {
      // 1. Tạo Ticket mới
      final newTicket = WeavingTicket(
        id: 0, // Backend tự sinh
        code: "TKT-${DateTime.now().millisecondsSinceEpoch}", // Mã tạm hoặc backend sinh
        productId: 0, // Cần logic chọn SP, tạm thời để 0 hoặc lấy từ context
        standardId: 0,
        machineId: machineId,
        machineLine: line,
        yarnLoadDate: DateTime.now().toIso8601String(),
        yarnLotId: 0, // Cần logic chọn lô sợi
        basketId: basket.id,
        timeIn: DateTime.now().toIso8601String(),
        grossWeight: 0,
        netWeight: 0,
        lengthMeters: 0,
        numberOfKnots: 0,
      );
      
      await _weavingRepo.createTicket(newTicket);

      // 2. Cập nhật trạng thái rổ -> IN_USE
      final updatedBasket = Basket(
        id: basket.id,
        code: basket.code,
        tareWeight: basket.tareWeight,
        supplier: basket.supplier,
        status: "IN_USE", // [QUAN TRỌNG]
        note: basket.note,
      );
      await _basketRepo.updateBasket(updatedBasket);

      // 3. Reload lại màn hình
      loadDashboard();
    } catch (e) {
      emit(MachineOpError("Lỗi gán rổ: $e"));
      loadDashboard(); // Reload để quay lại trạng thái cũ
    }
  }

  // Kết thúc phiếu (Tháo rổ)
  Future<void> releaseBasket(WeavingTicket ticket) async {
    try {
      // 1. Cập nhật Ticket: thêm timeOut
      // Code xử lý update ticket ở đây...
      
      // 2. Cập nhật Basket -> READY (hoặc HOLDING tùy quy trình)
      // Cần lấy Basket theo ID trước (logic này nên ở Backend thì tốt hơn)
      
      loadDashboard();
    } catch (e) {
      emit(MachineOpError("Lỗi tháo rổ: $e"));
    }
  }
}