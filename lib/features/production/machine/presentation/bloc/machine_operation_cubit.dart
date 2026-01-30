import 'dart:io'; 
import 'package:file_picker/file_picker.dart'; 
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
  // Load danh sách máy cho Dropdown trong Material Export & Dashboard chính
  Future<void> loadMachines() async {
      await loadDashboard(); 
  }

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

  // --- [MỚI] CẬP NHẬT THÔNG TIN PHIẾU (GÁN RỔ & TIÊU CHUẨN) ---
  Future<void> updateTicketInfo({
    required int ticketId,
    required int basketId,
    required int standardId,
    required int employeeInId, // Người thực hiện gán (đứng máy)
  }) async {
    try {
      // 1. Lấy thông tin phiếu cũ
      final tickets = await _weavingRepo.getTickets();
      final oldTicket = tickets.firstWhere((t) => t.id == ticketId);

      // 2. Tạo object update (Chỉ update các trường còn thiếu)
      final updatedTicket = WeavingTicket(
        id: oldTicket.id,
        code: oldTicket.code,
        
        // Giữ nguyên thông tin cũ
        machineId: oldTicket.machineId,
        machineLine: oldTicket.machineLine,
        yarnLoadDate: oldTicket.yarnLoadDate,
        productId: oldTicket.productId,
        
        // [THAY ĐỔI] Giữ nguyên danh sách yarns cũ
        yarns: oldTicket.yarns,
        
        // --- THÔNG TIN MỚI ---
        basketId: basketId,
        standardId: standardId,
        employeeInId: employeeInId, 
        timeIn: DateTime.now().toIso8601String(), // Cập nhật thời gian vào rổ thực tế
        // --------------------

        timeOut: oldTicket.timeOut,
        employeeOutId: oldTicket.employeeOutId,
        grossWeight: oldTicket.grossWeight,
        netWeight: oldTicket.netWeight,
        lengthMeters: oldTicket.lengthMeters,
        numberOfKnots: oldTicket.numberOfKnots,
        basketCode: oldTicket.basketCode, // Backend sẽ tự update lại theo ID mới
      );

      // 3. Gọi API Update Ticket
      await _weavingRepo.updateTicket(updatedTicket);

      // 4. Cập nhật trạng thái Rổ -> IN_USE
      final basketList = await _basketRepo.getBaskets();
      final selectedBasket = basketList.firstWhere((b) => b.id == basketId);
      
      final updatedBasket = Basket(
        id: selectedBasket.id,
        code: selectedBasket.code,
        tareWeight: selectedBasket.tareWeight,
        status: "IN_USE",
        note: selectedBasket.note,
      );
      await _basketRepo.updateBasket(updatedBasket);

      // 5. Reload Dashboard để cập nhật UI (Chuyển từ vàng sang xanh)
      loadDashboard();
    } catch (e) {
      emit(MachineOpError("Lỗi gán rổ: $e"));
      loadDashboard(); // Reset state để tránh treo UI
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
        
        // [THAY ĐỔI] Giữ nguyên yarns
        yarns: ticket.yarns,
        
        basketId: ticket.basketId,
        timeIn: ticket.timeIn,
        employeeInId: ticket.employeeInId,
        
        timeOut: DateTime.now().toIso8601String(),
        employeeOutId: employeeOutId,
        
        grossWeight: grossWeight,
        lengthMeters: length,
        numberOfKnots: numberOfKnots,
        netWeight: 0, // Backend tự tính hoặc tính ở đây nếu cần (Gross - Tare)
      );

      await _weavingRepo.updateTicket(updatedTicket);

      // 2. Cập nhật Rổ -> READY (Giải phóng rổ)
      final basketList = await _basketRepo.getBaskets();
      // Tìm rổ hiện tại (có thể dùng getById nhưng dùng list có sẵn cho nhanh)
      final currentBasket = basketList.where((b) => b.id == ticket.basketId).firstOrNull;

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

  // --- GÁN RỔ THỦ CÔNG (Dự phòng, ít dùng nếu quy trình chuẩn từ Kho) ---
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

      // [THAY ĐỔI] Tạo mới với danh sách yarns chứa 1 batchId (tương thích ngược)
      final newTicket = WeavingTicket(
        id: 0,
        code: "TKT-${DateTime.now().millisecondsSinceEpoch}",
        productId: productId,
        standardId: standardId,
        machineId: machineId,
        machineLine: line,
        yarnLoadDate: todayDate,
        
        // Tạo list yarns với 1 phần tử
        yarns: [WeavingTicketYarn(batchId: batchId, componentType: "UNKNOWN")],
        
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

  // --- CẬP NHẬT TRẠNG THÁI MÁY (KÈM ẢNH) ---
  Future<void> updateMachineStatus({
    required int machineId,
    required String status,
    String? reason,
    XFile? imageFile, 
  }) async {
    try {
      String? uploadedUrl;

      // 1. Nếu có ảnh, xử lý upload
      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        final String fileName = imageFile.name; 

        final platformFile = PlatformFile(
          name: fileName,
          size: bytes.length,
          bytes: bytes, 
          path: imageFile.path,
        );

        uploadedUrl = await _machineRepo.uploadImageLog(platformFile);
      }

      // 2. Gọi API cập nhật trạng thái
      await _machineRepo.updateMachineStatus(
        machineId,
        status,
        reason: reason,
        imageUrl: uploadedUrl,
      );

      // 3. Optimistic UI update
      if (state is MachineOpLoaded) {
        final currentMachines = (state as MachineOpLoaded).machines;
        final index = currentMachines.indexWhere((m) => m.id == machineId);

        if (index != -1) {
          final updatedMachines = List<Machine>.from(currentMachines);
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
      
      // loadDashboard(); // Có thể uncomment nếu muốn sync chuẩn với server

    } catch (e) {
      emit(MachineOpError("Lỗi cập nhật trạng thái: $e"));
      loadDashboard();
    }
  }
}