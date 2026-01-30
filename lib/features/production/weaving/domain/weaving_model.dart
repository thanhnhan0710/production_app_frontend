// [MỚI] Class đại diện cho 1 lô sợi trong phiếu dệt
class WeavingTicketYarn {
  final int id;
  final int ticketId;
  final int batchId;
  final String componentType;
  final double quantity; 
  final String? note;
  
  // [CẬP NHẬT] Các trường hiển thị lấy từ Nested Object
  final String? internalBatchCode;
  final String? supplierShortName;

  WeavingTicketYarn({
    this.id = 0,
    this.ticketId = 0,
    required this.batchId,
    required this.componentType,
    this.quantity = 0.0,
    this.note,
    this.internalBatchCode,
    this.supplierShortName,
  });

  factory WeavingTicketYarn.fromJson(Map<String, dynamic> json) {
    // Trích xuất thông tin từ nested object 'batch' và 'batch' -> 'supplier'
    String? iBatchCode;
    String? sShortName;

    if (json['batch'] != null) {
      iBatchCode = json['batch']['internal_batch_code'];
      if (json['batch']['supplier'] != null) {
        sShortName = json['batch']['supplier']['supplier_short_name'];
      }
    }

    return WeavingTicketYarn(
      id: json['id'] ?? 0,
      ticketId: json['ticket_id'] ?? 0,
      batchId: json['batch_id'] ?? 0,
      componentType: json['component_type'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      note: json['note'],
      
      // Gán giá trị đã trích xuất
      internalBatchCode: iBatchCode,
      supplierShortName: sShortName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != 0) 'id': id,
      'ticket_id': ticketId,
      'batch_id': batchId,
      'component_type': componentType,
      'quantity': quantity,
      'note': note,
    };
  }
}

class WeavingTicket {
  final int id;
  final String code;
  final int productId;
  final int standardId;
  final int machineId;
  final String machineLine;
  final String yarnLoadDate;
  
  final List<WeavingTicketYarn> yarns;

  final int? basketId;
  final String timeIn;
  final int? employeeInId;
  final String? timeOut;
  final int? employeeOutId;
  final double grossWeight;
  final double netWeight;
  final double lengthMeters;
  final int numberOfKnots;
  
  final String? basketCode;
  final double? tareWeight;

  WeavingTicket({
    required this.id,
    required this.code,
    required this.productId,
    required this.standardId,
    required this.machineId,
    required this.machineLine,
    required this.yarnLoadDate,
    this.yarns = const [], 
    this.basketId, 
    required this.timeIn,
    this.employeeInId,
    this.timeOut,
    this.employeeOutId,
    required this.grossWeight,
    required this.netWeight,
    required this.lengthMeters,
    required this.numberOfKnots,
    this.basketCode,
    this.tareWeight,
  });

  factory WeavingTicket.fromJson(Map<String, dynamic> json) {
    final basketObj = json['basket'];
    
    var yarnList = json['yarns'] as List? ?? [];
    List<WeavingTicketYarn> yarns = yarnList.map((i) => WeavingTicketYarn.fromJson(i)).toList();

    return WeavingTicket(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      productId: json['product_id'] ?? 0,
      standardId: json['standard_id'] ?? 0,
      machineId: json['machine_id'] ?? 0,
      machineLine: (json['machine_line'] ?? '').toString(),
      yarnLoadDate: json['yarn_load_date'] ?? '',
      yarns: yarns, 
      basketId: json['basket_id'], 
      timeIn: json['time_in'] ?? '',
      employeeInId: json['employee_in_id'],
      timeOut: json['time_out'],
      employeeOutId: json['employee_out_id'],
      grossWeight: (json['gross_weight'] ?? 0).toDouble(),
      netWeight: (json['net_weight'] ?? 0).toDouble(),
      lengthMeters: (json['length_meters'] ?? 0).toDouble(),
      numberOfKnots: json['number_of_knots'] ?? 0,
      basketCode: basketObj != null ? basketObj['basket_code'] : null,
      tareWeight: basketObj != null ? (basketObj['tare_weight'] ?? 0).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'product_id': productId,
      'standard_id': standardId,
      'machine_id': machineId,
      'machine_line': machineLine,
      'yarn_load_date': yarnLoadDate,
      'yarns': yarns.map((e) => e.toJson()).toList(),
      'basket_id': basketId,
      'time_in': timeIn,
      'employee_in_id': employeeInId,
      'time_out': timeOut,
      'employee_out_id': employeeOutId,
      'gross_weight': grossWeight,
      'net_weight': netWeight,
      'length_meters': lengthMeters,
      'number_of_knots': numberOfKnots,
    };
  }
  
  int get firstBatchId => yarns.isNotEmpty ? yarns.first.batchId : 0;
}

// Class WeavingInspection (Giữ nguyên không đổi)
class WeavingInspection {
  final int id;
  final int ticketId;
  final String stageName;
  final int employeeId;
  final int shiftId;
  final double widthMm;
  final double weftDensity;
  final double tensionDan;
  final double thicknessMm;
  final double weightGm;
  final double bowing;
  final String inspectionTime;
  final String? employeeName;
  final String? shiftName;

  WeavingInspection({
    required this.id,
    required this.ticketId,
    required this.stageName,
    required this.employeeId,
    required this.shiftId,
    required this.widthMm,
    required this.weftDensity,
    required this.tensionDan,
    required this.thicknessMm,
    required this.weightGm,
    required this.bowing,
    required this.inspectionTime,
    this.employeeName,
    this.shiftName,
  });

  factory WeavingInspection.fromJson(Map<String, dynamic> json) {
    return WeavingInspection(
      id: json['id'] ?? 0,
      ticketId: json['weaving_basket_ticket_id'] ?? 0, 
      stageName: json['stage_name'] ?? '',
      employeeId: json['employee_id'] ?? 0,
      shiftId: json['shift_id'] ?? 0,
      widthMm: (json['width_mm'] ?? 0).toDouble(),
      weftDensity: (json['weft_density'] ?? 0).toDouble(),
      tensionDan: (json['tension_dan'] ?? 0).toDouble(),
      thicknessMm: (json['thickness_mm'] ?? 0).toDouble(),
      weightGm: (json['weight_gm'] ?? 0).toDouble(),
      bowing: (json['bowing'] ?? 0).toDouble(),
      inspectionTime: json['inspection_time'] ?? '',
      employeeName: json['employee'] != null ? json['employee']['full_name'] : null,
      shiftName: json['shift'] != null ? json['shift']['shift_name'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'weaving_basket_ticket_id': ticketId,
      'stage_name': stageName,
      'employee_id': employeeId,
      'shift_id': shiftId,
      'width_mm': widthMm,
      'weft_density': weftDensity,
      'tension_dan': tensionDan,
      'thickness_mm': thicknessMm,
      'weight_gm': weightGm,
      'bowing': bowing,
      'inspection_time': inspectionTime,
    };
  }
}