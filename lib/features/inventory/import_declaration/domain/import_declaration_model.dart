import 'package:production_app_frontend/features/inventory/material/domain/material_model.dart';

// 1. Enum Loại hình nhập khẩu
enum ImportType {
  E31, // Sản xuất xuất khẩu
  E21, // Gia công
  A11, // Kinh doanh tiêu dùng
  A12, // Kinh doanh sản xuất
  G11  // Tạm nhập tái xuất
}

// Helper chuyển đổi Enum <-> String
ImportType parseImportType(String? value) {
  return ImportType.values.firstWhere(
    (e) => e.toString().split('.').last == value,
    orElse: () => ImportType.E31,
  );
}

// 2. Chi tiết hàng hóa trong tờ khai
class ImportDeclarationDetail {
  final int detailId;
  final int declarationId;
  final int materialId;
  final int? poDetailId; // Link tới dòng của PO (nếu có)
  final double quantity;
  final double unitPrice;
  final String? hsCodeActual; // HS Code thực tế

  // Nested Object (Để hiển thị tên vật tư)
  final MaterialModel? material;

  ImportDeclarationDetail({
    this.detailId = 0,
    required this.declarationId,
    required this.materialId,
    this.poDetailId,
    required this.quantity,
    required this.unitPrice,
    this.hsCodeActual,
    this.material,
  });

  // Tính thành tiền (Dùng cho UI)
  double get totalAmount => quantity * unitPrice;

  factory ImportDeclarationDetail.fromJson(Map<String, dynamic> json) {
    return ImportDeclarationDetail(
      detailId: json['detail_id'] ?? 0,
      declarationId: json['declaration_id'] ?? 0,
      materialId: json['material_id'] ?? 0,
      poDetailId: json['po_detail_id'],
      quantity: (json['quantity'] ?? 0).toDouble(),
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      hsCodeActual: json['hs_code_actual'],
      material: json['material'] != null ? MaterialModel.fromJson(json['material']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'detail_id': detailId,
      'declaration_id': declarationId,
      'material_id': materialId,
      'po_detail_id': poDetailId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'hs_code_actual': hsCodeActual,
    };
  }
}

// 3. Header Tờ khai
class ImportDeclaration {
  final int id;
  final String declarationNo;
  final DateTime declarationDate;
  final ImportType type;
  final String? billOfLading;
  final String? invoiceNo;
  final double totalTaxAmount;
  final String? note;
  
  // List chi tiết
  final List<ImportDeclarationDetail> details;

  ImportDeclaration({
    this.id = 0,
    required this.declarationNo,
    required this.declarationDate,
    this.type = ImportType.E31,
    this.billOfLading,
    this.invoiceNo,
    this.totalTaxAmount = 0.0,
    this.note,
    this.details = const [],
  });

  factory ImportDeclaration.fromJson(Map<String, dynamic> json) {
    return ImportDeclaration(
      id: json['id'] ?? 0,
      declarationNo: json['declaration_no'] ?? '',
      declarationDate: DateTime.tryParse(json['declaration_date'] ?? '') ?? DateTime.now(),
      type: parseImportType(json['type_of_import']),
      billOfLading: json['bill_of_lading'],
      invoiceNo: json['invoice_no'],
      totalTaxAmount: (json['total_tax_amount'] ?? 0.0).toDouble(),
      note: json['note'],
      details: (json['details'] as List<dynamic>?)
              ?.map((e) => ImportDeclarationDetail.fromJson(e))
              .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'declaration_no': declarationNo,
      'declaration_date': declarationDate.toIso8601String().split('T').first, // YYYY-MM-DD
      'type_of_import': type.name, // E31, A11...
      'bill_of_lading': billOfLading,
      'invoice_no': invoiceNo,
      'total_tax_amount': totalTaxAmount,
      'note': note,
      'details': details.map((e) => e.toJson()).toList(),
    };
  }
}