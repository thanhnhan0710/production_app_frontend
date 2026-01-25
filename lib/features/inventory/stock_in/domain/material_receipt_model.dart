// --- NESTED MODELS ---

class ReceiptWarehouse {
  final int id;
  final String name;
  final String location;

  ReceiptWarehouse({required this.id, required this.name, required this.location});

  factory ReceiptWarehouse.fromJson(Map<String, dynamic> json) {
    return ReceiptWarehouse(
      id: json['warehouse_id'] ?? 0,
      name: json['warehouse_name'] ?? '',
      location: json['location'] ?? '',
    );
  }
}

class ReceiptPO {
  final int id;
  final String poNumber;
  final String vendorName;

  ReceiptPO({required this.id, required this.poNumber, required this.vendorName});

  factory ReceiptPO.fromJson(Map<String, dynamic> json) {
    return ReceiptPO(
      id: json['po_id'] ?? 0,
      poNumber: json['po_number'] ?? '',
      // Check kỹ key vendor name từ backend trả về
      vendorName: json['vendor']?['supplier_name'] ?? json['vendor']?['name'] ?? '',
    );
  }
}

class ReceiptDeclaration {
  final int id;
  final String declarationNo;

  ReceiptDeclaration({required this.id, required this.declarationNo});

  factory ReceiptDeclaration.fromJson(Map<String, dynamic> json) {
    return ReceiptDeclaration(
      id: json['id'] ?? 0,
      declarationNo: json['declaration_no'] ?? '',
    );
  }
}

class ReceiptMaterial {
  final int id;
  final String code;
  final String unit;

  ReceiptMaterial({required this.id, required this.code, required this.unit});

  factory ReceiptMaterial.fromJson(Map<String, dynamic> json) {
    return ReceiptMaterial(
      id: json['id'] ?? 0,
      // [FIX] Ưu tiên lấy 'material_code'
      code: json['material_code'] ?? json['code'] ?? '',
      // [FIX] Đơn vị tính thường nằm trong object uom_base
      unit: json['uom_base']?['unit_name'] ?? json['unit'] ?? '',
    );
  }
}

// --- MAIN MODELS ---

class MaterialReceiptDetail {
  final int? detailId;
  final int materialId;
  
  final ReceiptMaterial? material;

  final double poQuantityKg;
  final int poQuantityCones;

  final double receivedQuantityKg;
  final int receivedQuantityCones;

  final int numberOfPallets;
  final String? supplierBatchNo;
  
  // [MỚI] Thêm trường Xuất xứ
  final String? originCountry;
  
  final String? note;

  MaterialReceiptDetail({
    this.detailId,
    required this.materialId,
    this.material,
    this.poQuantityKg = 0.0,
    this.poQuantityCones = 0,
    required this.receivedQuantityKg,
    this.receivedQuantityCones = 0,
    this.numberOfPallets = 0,
    this.supplierBatchNo,
    this.originCountry, // [MỚI]
    this.note,
  });

  factory MaterialReceiptDetail.fromJson(Map<String, dynamic> json) {
    return MaterialReceiptDetail(
      detailId: json['detail_id'],
      materialId: json['material_id'] ?? 0,
      // Mapping nested material object
      material: json['material'] != null ? ReceiptMaterial.fromJson(json['material']) : null,
      poQuantityKg: (json['po_quantity_kg'] ?? 0.0).toDouble(),
      poQuantityCones: json['po_quantity_cones'] ?? 0,
      receivedQuantityKg: (json['received_quantity_kg'] ?? 0.0).toDouble(),
      receivedQuantityCones: json['received_quantity_cones'] ?? 0,
      numberOfPallets: json['number_of_pallets'] ?? 0,
      supplierBatchNo: json['supplier_batch_no'],
      originCountry: json['origin_country'], // [MỚI]
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'material_id': materialId,
      'po_quantity_kg': poQuantityKg,
      'po_quantity_cones': poQuantityCones,
      'received_quantity_kg': receivedQuantityKg,
      'received_quantity_cones': receivedQuantityCones,
      'number_of_pallets': numberOfPallets,
      'supplier_batch_no': supplierBatchNo,
      'origin_country': originCountry, // [MỚI]
      'note': note,
    };
    return data;
  }
}

class MaterialReceipt {
  final int? id;
  final String receiptNumber;
  final DateTime receiptDate;
  
  final int? poHeaderId;
  final int? declarationId;
  final int warehouseId;

  final String? containerNo;
  final String? sealNo;
  final String? note;
  final String? createdBy;

  final ReceiptWarehouse? warehouse;
  final ReceiptPO? poHeader;
  final ReceiptDeclaration? declaration;
  
  final List<MaterialReceiptDetail> details;

  MaterialReceipt({
    this.id,
    required this.receiptNumber,
    required this.receiptDate,
    this.poHeaderId,
    this.declarationId,
    required this.warehouseId,
    this.containerNo,
    this.sealNo,
    this.note,
    this.createdBy,
    this.warehouse,
    this.poHeader,
    this.declaration,
    this.details = const [],
  });

  factory MaterialReceipt.fromJson(Map<String, dynamic> json) {
    return MaterialReceipt(
      id: json['receipt_id'],
      receiptNumber: json['receipt_number'] ?? '',
      receiptDate: json['receipt_date'] != null 
          ? DateTime.parse(json['receipt_date']) 
          : DateTime.now(),
      poHeaderId: json['po_header_id'],
      declarationId: json['declaration_id'],
      warehouseId: json['warehouse_id'] ?? 0,
      containerNo: json['container_no'],
      sealNo: json['seal_no'],
      note: json['note'],
      createdBy: json['created_by'],
      
      warehouse: json['warehouse'] != null ? ReceiptWarehouse.fromJson(json['warehouse']) : null,
      poHeader: json['po_header'] != null ? ReceiptPO.fromJson(json['po_header']) : null,
      declaration: json['declaration'] != null ? ReceiptDeclaration.fromJson(json['declaration']) : null,
      
      details: json['details'] != null
          ? (json['details'] as List).map((e) => MaterialReceiptDetail.fromJson(e)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'receipt_number': receiptNumber,
      'receipt_date': receiptDate.toIso8601String().substring(0, 10),
      'po_header_id': poHeaderId,
      'declaration_id': declarationId,
      'warehouse_id': warehouseId,
      'container_no': containerNo,
      'seal_no': sealNo,
      'note': note,
      'created_by': createdBy,
    };
    
    if (details.isNotEmpty && id == null) {
      data['details'] = details.map((e) => e.toJson()).toList();
    }
    
    return data;
  }
}