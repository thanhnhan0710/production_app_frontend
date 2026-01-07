class WeavingTicket {
  final int id;
  final String code;
  final int productId;
  final int standardId;
  final int machineId;
  final String machineLine; // Backend trả int, Frontend dùng String
  final String yarnLoadDate;
  final int yarnLotId;
  final int basketId;
  final String timeIn;
  final int? employeeInId;
  final String? timeOut;
  final int? employeeOutId;
  final double grossWeight;
  final double netWeight;
  final double lengthMeters;
  final int numberOfKnots;
  
  // Nested Objects (Read-only từ Backend)
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
    required this.yarnLotId,
    required this.basketId,
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
    // Helper để lấy nested data an toàn
    final basketObj = json['basket'];
    
    return WeavingTicket(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      productId: json['product_id'] ?? 0,
      standardId: json['standard_id'] ?? 0,
      machineId: json['machine_id'] ?? 0,
      // Ép kiểu sang String để tránh lỗi TypeError
      machineLine: json['machine_line']?.toString() ?? '',
      yarnLoadDate: json['yarn_load_date'] ?? '',
      yarnLotId: json['yarn_lot_id'] ?? 0,
      basketId: json['basket_id'] ?? 0,
      timeIn: json['time_in'] ?? '',
      employeeInId: json['employee_in_id'],
      timeOut: json['time_out'],
      employeeOutId: json['employee_out_id'],
      grossWeight: (json['gross_weight'] ?? 0).toDouble(),
      netWeight: (json['net_weight'] ?? 0).toDouble(),
      lengthMeters: (json['length_meters'] ?? 0).toDouble(),
      numberOfKnots: json['number_of_knots'] ?? 0,
      
      // Nested
      basketCode: basketObj != null ? basketObj['basket_code'] : null,
      tareWeight: basketObj != null ? (basketObj['tare_weight'] ?? 0).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'product_id': productId,
      'standard_id': standardId,
      'machine_id': machineId,
      'machine_line': machineLine,
      'yarn_load_date': yarnLoadDate,
      'yarn_lot_id': yarnLotId,
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
}

// Giữ nguyên WeavingInspection nếu đã có
class WeavingInspection {
  // ... (Code cũ của bạn)
  // Nếu chưa có thì báo mình bổ sung
  final int id;
  // ... demo properties
  WeavingInspection({required this.id});
  factory WeavingInspection.fromJson(Map<String, dynamic> json) => WeavingInspection(id: json['id']??0);
   Map<String, dynamic> toJson() => {};
}