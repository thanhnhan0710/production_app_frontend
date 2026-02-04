import 'package:production_app_frontend/features/inventory/supplier/domain/supplier_model.dart';
import 'package:production_app_frontend/features/inventory/material/domain/material_model.dart';
import 'package:production_app_frontend/features/inventory/unit/domain/unit_model.dart';

// 1. Enums
enum IncotermType { EXW, FOB, CIF, DDP, DAP }

enum POStatus { Draft, Sent, Confirmed, Partial, Completed, Cancelled }

// Helper để parse String sang Enum an toàn
T enumFromString<T>(Iterable<T> values, String value) {
  return values.firstWhere(
    (type) => type.toString().split(".").last.toUpperCase() == value.toUpperCase(),
    orElse: () => values.first
  );
}

// 2. PO Detail (Chi tiết dòng hàng)
class PurchaseOrderDetail {
  final int detailId;
  final int poId;
  final int materialId;
  
  // [CẬP NHẬT] Số lượng (Kg)
  final double quantity; 
  // [MỚI] Số lượng (Cuộn)
  final int quantityRolls;

  final double unitPrice;
  final int? uomId;
  final double lineTotal;
  final bool isPricingByRoll;
  
  // [CẬP NHẬT] Đã nhận (Kg)
  final double receivedQuantity;
  // [MỚI] Đã nhận (Cuộn)
  final int receivedRolls;

  // Nested Objects (Optional - để hiển thị tên)
  final MaterialModel? material;
  final ProductUnit? uom;

  PurchaseOrderDetail({
    this.detailId = 0,
    required this.poId,
    required this.materialId,
    required this.quantity,
    this.quantityRolls = 0, // Mặc định 0
    required this.unitPrice,
    this.uomId,
    this.lineTotal = 0.0,
    this.isPricingByRoll = false,
    this.receivedQuantity = 0.0,
    this.receivedRolls = 0, // Mặc định 0
    this.material,
    this.uom,
  });

  // Getter alias cho rõ nghĩa (Optional)
  double get quantityKg => quantity;
  double get receivedKg => receivedQuantity;
  
  // Getter tên vật tư tiện lợi
  String get materialName => material?.materialCode ?? 'Item #$materialId';
  String get unitName => uom?.name ?? 'Unit';
  double get openQuantity => (quantity - receivedQuantity) > 0 ? (quantity - receivedQuantity) : 0;

  factory PurchaseOrderDetail.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderDetail(
      detailId: json['detail_id'] ?? 0,
      poId: json['po_id'] ?? 0,
      materialId: json['material_id'] ?? 0,
      
      quantity: (json['quantity'] ?? 0).toDouble(),
      quantityRolls: json['quantity_rolls'] ?? 0, // [MỚI] Map từ backend
      
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      uomId: json['uom_id'],
      lineTotal: (json['line_total'] ?? 0).toDouble(),
      isPricingByRoll: json['is_pricing_by_roll'] ?? false,
      
      receivedQuantity: (json['received_quantity'] ?? 0).toDouble(),
      receivedRolls: json['received_rolls'] ?? 0, // [MỚI] Map từ backend
      
      material: json['material'] != null ? MaterialModel.fromJson(json['material']) : null,
      uom: json['uom'] != null ? ProductUnit.fromJson(json['uom']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'detail_id': detailId,
      'po_id': poId,
      'material_id': materialId,
      'quantity': quantity,
      'quantity_rolls': quantityRolls, // [MỚI] Gửi lên backend
      'unit_price': unitPrice,
      'uom_id': uomId,
      'is_pricing_by_roll': isPricingByRoll,
      // line_total và received_* thường do BE tính toán, không cần gửi lên khi tạo/sửa
    };
  }
}

// 3. PO Header (Thông tin chung)
class PurchaseOrderHeader {
  final int poId;
  final String poNumber;
  final int vendorId;
  final DateTime orderDate;
  final DateTime? expectedArrivalDate;
  final IncotermType incoterm;
  final String currency;
  final double exchangeRate;
  final POStatus status;
  final double totalAmount;
  final String? note;
  
  // Nested Objects
  final Supplier? vendor;
  final List<PurchaseOrderDetail> details;

  PurchaseOrderHeader({
    this.poId = 0,
    required this.poNumber,
    required this.vendorId,
    required this.orderDate,
    this.expectedArrivalDate,
    this.incoterm = IncotermType.EXW,
    this.currency = "VND",
    this.exchangeRate = 1.0,
    this.status = POStatus.Draft,
    this.totalAmount = 0.0,
    this.note,
    this.vendor,
    this.details = const [],
  });
  
  // Getter tên nhà cung cấp tiện lợi
  String get vendorName => vendor?.name ?? vendor?.shortName ?? 'Vendor #$vendorId';
  String get code => poNumber; // Alias ngắn gọn
  int get id => poId; // Alias ngắn gọn
  int get totalRolls => details.fold(0, (sum, item) => sum + item.quantityRolls);

  factory PurchaseOrderHeader.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderHeader(
      poId: json['po_id'] ?? 0,
      poNumber: json['po_number'] ?? '',
      vendorId: json['vendor_id'] ?? 0,
      orderDate: DateTime.tryParse(json['order_date'] ?? '') ?? DateTime.now(),
      expectedArrivalDate: json['expected_arrival_date'] != null 
          ? DateTime.tryParse(json['expected_arrival_date']) 
          : null,
      incoterm: enumFromString(IncotermType.values, json['incoterm'] ?? 'EXW'),
      currency: json['currency'] ?? 'VND',
      exchangeRate: (json['exchange_rate'] ?? 1.0).toDouble(),
      status: enumFromString(POStatus.values, json['status'] ?? 'Draft'),
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
      note: json['note'],
      vendor: json['vendor'] != null ? Supplier.fromJson(json['vendor']) : null,
      details: (json['details'] as List<dynamic>?)
              ?.map((e) => PurchaseOrderDetail.fromJson(e))
              .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'po_number': poNumber,
      'vendor_id': vendorId,
      'order_date': orderDate.toIso8601String().split('T').first,
      'expected_arrival_date': expectedArrivalDate?.toIso8601String().split('T').first,
      'incoterm': incoterm.name,
      'currency': currency,
      'exchange_rate': exchangeRate,
      'status': status.name, 
      'note': note,
      'details': details.map((e) => e.toJson()).toList(),
    };
  }
  
  // Helper để hiển thị màu sắc trạng thái trên UI
  bool get isDraft => status == POStatus.Draft;
  bool get isCompleted => status == POStatus.Completed;
}