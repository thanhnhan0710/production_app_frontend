import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
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
      final machines = await _machineRepo.getMachines();
      
      final allBaskets = await _basketRepo.getBaskets();
      final readyBaskets = allBaskets.where((b) => b.status == 'READY').toList();

      final allTickets = await _weavingRepo.getTickets();
      // Lọc các ticket chưa có timeOut (đang chạy)
      final activeTicketsList = allTickets.where((t) => t.timeOut == null).toList();

      final Map<String, WeavingTicket> activeMap = {};
      for (var t in activeTicketsList) {
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

  // [CẬP NHẬT QUAN TRỌNG] Thêm tham số employeeId vào hàm này
  Future<void> assignBasketToMachine({
    required int machineId,
    required String line,
    required Basket basket,
    required int productId,
    required int standardId,
    required int yarnLotId,
    required int employeeId, // <--- Tham số này phải có
  }) async {
    try {
      final String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final String nowTime = DateTime.now().toIso8601String();

      final newTicket = WeavingTicket(
        id: 0, 
        code: "TKT-${DateTime.now().millisecondsSinceEpoch}", 
        productId: productId,   
        standardId: standardId, 
        machineId: machineId,
        machineLine: line,
        yarnLoadDate: todayDate,
        yarnLotId: yarnLotId,   
        basketId: basket.id,
        timeIn: nowTime,
        grossWeight: 0,
        netWeight: 0,
        lengthMeters: 0,
        numberOfKnots: 0,
        
        // Sử dụng ID nhân viên được truyền vào
        employeeInId: employeeId, 
        
        employeeOutId: null,
        timeOut: null,
      );
      
      await _weavingRepo.createTicket(newTicket);

      final updatedBasket = Basket(
        id: basket.id,
        code: basket.code,
        tareWeight: basket.tareWeight,
        supplier: basket.supplier,
        status: "IN_USE",
        note: basket.note,
      );
      await _basketRepo.updateBasket(updatedBasket);

      loadDashboard();
    } catch (e) {
      emit(MachineOpError("Lỗi gán rổ: $e"));
      loadDashboard();
    }
  }

  // Hàm kết thúc phiếu (Tháo rổ) - Placeholder để sau này phát triển
  Future<void> releaseBasket(WeavingTicket ticket) async {
    try {
       // Logic tháo rổ sẽ code sau
       loadDashboard();
    } catch (e) {
      emit(MachineOpError("Lỗi tháo rổ: $e"));
    }
  }
}