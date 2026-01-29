class MaterialExport {
  final int? id;
  final String exportCode;
  final DateTime exportDate;
  final int warehouseId;
  final int? exporterId; // [NEW] Người xuất kho
  final int receiverId; 
  final int? departmentId;
  final int? shiftId;
  final String? note;
  final String? createdBy;
  final List<MaterialExportDetail> details;

  MaterialExport({
    this.id,
    required this.exportCode,
    required this.exportDate,
    required this.warehouseId,
    this.exporterId, // [NEW]
    required this.receiverId,
    this.departmentId,
    this.shiftId,
    this.note,
    this.createdBy,
    required this.details,
  });

  factory MaterialExport.fromJson(Map<String, dynamic> json) {
    return MaterialExport(
      id: json['id'],
      exportCode: json['export_code'] ?? '',
      exportDate: json['export_date'] != null 
          ? DateTime.tryParse(json['export_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      warehouseId: json['warehouse_id'] ?? 0,
      exporterId: json['exporter_id'], // [NEW] Map từ API
      receiverId: json['receiver_id'] ?? 0,
      departmentId: json['department_id'],
      shiftId: json['shift_id'],
      note: json['note'],
      createdBy: json['created_by'],
      details: (json['details'] as List<dynamic>?)
              ?.map((e) => MaterialExportDetail.fromJson(e))
              .toList() ?? 
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'export_code': exportCode,
      'export_date': exportDate.toIso8601String().split('T')[0],
      'warehouse_id': warehouseId,
      'exporter_id': exporterId, // [NEW] Gửi lên API
      'receiver_id': receiverId,
      'department_id': departmentId,
      'shift_id': shiftId,
      'note': note,
      'created_by': createdBy,
      'details': details.map((e) => e.toJson()).toList(),
    };
  }
}

class MaterialExportDetail {
  final int? detailId;
  final int materialId;
  final int batchId;
  final double quantity; 
  
  // Thông tin sản xuất
  final int machineId;
  final int machineLine; 
  final int productId;
  
  // [FIX] Đổi thành int? để có thể gửi null
  final int? standardId;
  final int? basketId;
  
  final String? note;

  MaterialExportDetail({
    this.detailId,
    required this.materialId,
    required this.batchId,
    required this.quantity,
    required this.machineId,
    required this.machineLine,
    required this.productId,
    this.standardId, // Bỏ required
    this.basketId,   // Bỏ required
    this.note,
  });

  factory MaterialExportDetail.fromJson(Map<String, dynamic> json) {
    return MaterialExportDetail(
      detailId: json['detail_id'],
      materialId: json['material_id'] ?? 0,
      batchId: json['batch_id'] ?? 0,
      quantity: (json['quantity'] ?? 0).toDouble(),
      machineId: json['machine_id'] ?? 0,
      machineLine: json['machine_line'] ?? 0,
      productId: json['product_id'] ?? 0,
      standardId: json['standard_id'], // Không gán mặc định 0 nữa
      basketId: json['basket_id'],     // Không gán mặc định 0 nữa
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (detailId != null) 'detail_id': detailId,
      'material_id': materialId,
      'batch_id': batchId,
      'quantity': quantity,
      'machine_id': machineId,
      'machine_line': machineLine,
      'product_id': productId,
      'standard_id': standardId, // Nếu null sẽ gửi null, DB sẽ chấp nhận
      'basket_id': basketId,     // Nếu null sẽ gửi null, DB sẽ chấp nhận
      'note': note,
    };
  }
}