import 'dart:io'; // Để xử lý File ảnh từ UI
import 'package:file_picker/file_picker.dart'; // Để tạo PlatformFile cho Repository
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

// Import các Repository và Model
import 'package:production_app_frontend/features/inventory/basket/data/baket_repository.dart';
import 'package:production_app_frontend/features/inventory/basket/doamain/basket_model.dart';
import '../../domain/machine_model.dart';
import '../../data/machine_repository.dart';
import '../../../weaving/domain/weaving_model.dart';
import '../../../weaving/data/weaving_repository.dart';

// =======================
// STATE
// =======================
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

// =======================
// CUBIT
// =======================
class MachineOperationCubit extends Cubit<MachineOpState> {
  final MachineRepository _machineRepo;
  final WeavingRepository _weavingRepo;
  final BasketRepository _basketRepo;

  MachineOperationCubit(
      this._machineRepo, this._weavingRepo, this._basketRepo)
      : super(MachineOpInitial());

  // --- LOAD DASHBOARD ---
  Future<void> loadDashboard() async {
    emit(MachineOpLoading());
    try {
      final machines = await _machineRepo.getMachines();

      final allBaskets = await _basketRepo.getBaskets();
      // Chỉ lấy rổ đang trạng thái READY
      final readyBaskets =
          allBaskets.where((b) => b.status == 'READY').toList();

      final allTickets = await _weavingRepo.getTickets();
      // Lọc các ticket đang chạy (chưa có timeOut)
      final activeTicketsList =
          allTickets.where((t) => t.timeOut == null).toList();

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

  // --- GÁN RỔ CHO MÁY ---
  Future<void> assignBasketToMachine({
    required int machineId,
    required String line,
    required Basket basket,
    required int productId,
    required int standardId,
    required int batchId,
    required int employeeId,
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
        batchId: batchId,
        basketId: basket.id,
        timeIn: nowTime,
        grossWeight: 0,
        netWeight: 0,
        lengthMeters: 0,
        numberOfKnots: 0,
        employeeInId: employeeId,
        employeeOutId: null,
        timeOut: null,
      );

      await _weavingRepo.createTicket(newTicket);

      final updatedBasket = Basket(
        id: basket.id,
        code: basket.code,
        tareWeight: basket.tareWeight,
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

  // --- CẬP NHẬT THÔNG TIN PHIẾU ĐANG CHẠY ---
  Future<void> updateTicketInfo({
    required int ticketId,
    required int productId,
    required int standardId,
    required int batchId,
    required int basketId,
  }) async {
    try {
      // 1. Lấy thông tin phiếu cũ
      final tickets = await _weavingRepo.getTickets();
      final oldTicket = tickets.firstWhere((t) => t.id == ticketId);

      // 2. Tạo object mới
      final updatedTicket = WeavingTicket(
        id: oldTicket.id,
        code: oldTicket.code,
        machineId: oldTicket.machineId,
        machineLine: oldTicket.machineLine,
        timeIn: oldTicket.timeIn,
        employeeInId: oldTicket.employeeInId,
        yarnLoadDate: oldTicket.yarnLoadDate,

        // --- THÔNG TIN MỚI ---
        productId: productId,
        standardId: standardId,
        batchId: batchId,
        basketId: basketId,
        // --------------------

        timeOut: oldTicket.timeOut,
        employeeOutId: oldTicket.employeeOutId,
        grossWeight: oldTicket.grossWeight,
        netWeight: oldTicket.netWeight,
        lengthMeters: oldTicket.lengthMeters,
        numberOfKnots: oldTicket.numberOfKnots,
        basketCode: oldTicket.basketCode,
      );

      // 3. Gọi API Update
      await _weavingRepo.updateTicket(updatedTicket);

      // 4. Reload Dashboard
      loadDashboard();
    } catch (e) {
      emit(MachineOpError("Lỗi cập nhật phiếu: $e"));
      loadDashboard();
    }
  }

  // --- KẾT THÚC PHIẾU ---
  Future<void> finishTicket({
    required WeavingTicket ticket,
    required int employeeOutId,
    required double grossWeight,
    required double length,
    required int numberOfKnots,
  }) async {
    try {
      // 1. Cập nhật Ticket
      final updatedTicket = WeavingTicket(
        id: ticket.id,
        code: ticket.code,
        productId: ticket.productId,
        standardId: ticket.standardId,
        machineId: ticket.machineId,
        machineLine: ticket.machineLine,
        yarnLoadDate: ticket.yarnLoadDate,
        batchId: ticket.batchId,
        basketId: ticket.basketId,
        timeIn: ticket.timeIn,
        employeeInId: ticket.employeeInId,
        timeOut: DateTime.now().toIso8601String(),
        employeeOutId: employeeOutId,
        grossWeight: grossWeight,
        lengthMeters: length,
        numberOfKnots: numberOfKnots,
        netWeight: 0,
      );

      await _weavingRepo.updateTicket(updatedTicket);

      // 2. Cập nhật Rổ -> READY
      final basketList = await _basketRepo.getBaskets();
      final currentBasket =
          basketList.where((b) => b.id == ticket.basketId).firstOrNull;

      if (currentBasket != null) {
        final updatedBasket = Basket(
          id: currentBasket.id,
          code: currentBasket.code,
          tareWeight: currentBasket.tareWeight,
          status: "READY",
          note: currentBasket.note,
        );
        await _basketRepo.updateBasket(updatedBasket);
      }

      loadDashboard();
    } catch (e) {
      emit(MachineOpError("Lỗi kết thúc phiếu: $e"));
      loadDashboard();
    }
  }

  // --- CẬP NHẬT TRẠNG THÁI MÁY (KÈM ẢNH) ---
  Future<void> updateMachineStatus({
    required int machineId,
    required String status,
    String? reason,
    XFile? imageFile, // [ĐÃ SỬA] Dùng XFile để hỗ trợ cả Web và Mobile
  }) async {
    try {
      String? uploadedUrl;

      // 1. Nếu có ảnh, xử lý upload
      if (imageFile != null) {
        // XFile.readAsBytes() hoạt động tốt trên cả Web và Mobile
        final bytes = await imageFile.readAsBytes();
        
        // Lấy tên file (XFile có sẵn thuộc tính name)
        final String fileName = imageFile.name; 

        // Tạo PlatformFile (yêu cầu của Repository để upload)
        final platformFile = PlatformFile(
          name: fileName,
          size: bytes.length,
          bytes: bytes, // Quan trọng: Nạp bytes vào để Repository gửi đi
          path: imageFile.path,
        );

        // Gọi Repository upload và lấy URL trả về
        uploadedUrl = await _machineRepo.uploadImageLog(platformFile);
      }

      // 2. Gọi API cập nhật trạng thái kèm URL ảnh (nếu có)
      await _machineRepo.updateMachineStatus(
        machineId,
        status,
        reason: reason,
        imageUrl: uploadedUrl,
      );

      // 3. Cập nhật State cục bộ (Optimistic UI update) để App mượt hơn
      if (state is MachineOpLoaded) {
        final currentMachines = (state as MachineOpLoaded).machines;
        final index = currentMachines.indexWhere((m) => m.id == machineId);

        if (index != -1) {
          final updatedMachines = List<Machine>.from(currentMachines);
          
          // Cập nhật trạng thái mới cho máy đó trong list
          updatedMachines[index] = updatedMachines[index].copyWith(
            status: status,
          );

          emit(MachineOpLoaded(
            machines: updatedMachines,
            activeTickets: (state as MachineOpLoaded).activeTickets,
            readyBaskets: (state as MachineOpLoaded).readyBaskets,
          ));
        }
      }
      
      // (Tùy chọn) Reload lại dashboard để đảm bảo đồng bộ dữ liệu server
      // loadDashboard(); 

    } catch (e) {
      emit(MachineOpError("Lỗi cập nhật trạng thái: $e"));
      // Load lại dashboard để reset về trạng thái đúng nếu API bị lỗi
      loadDashboard();
    }
  }
}