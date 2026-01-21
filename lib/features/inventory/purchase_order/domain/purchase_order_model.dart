import 'package:production_app_frontend/features/inventory/supplier/domain/supplier_model.dart';
import 'package:production_app_frontend/features/inventory/material/domain/material_model.dart';
import 'package:production_app_frontend/features/inventory/unit/domain/unit_model.dart';

// 1. Enums
enum IncotermType { EXW, FOB, CIF, DDP, DAP }

enum POStatus { Draft, Sent, Confirmed, Partial, Completed, Cancelled }

// Helper để parse String sang Enum an toàn
T enumFromString<T>(Iterable<T> values, String value) {
  return values.firstWhere((type) => type.toString().split(".").last == value,
      orElse: () => values.first);
}

// 2. PO Detail (Chi tiết dòng hàng)
class PurchaseOrderDetail {
  final int detailId;
  final int poId;
  final int materialId;
  final double quantity;
  final double unitPrice;
  final int? uomId;
  final double lineTotal;
  final double receivedQuantity;

  // Nested Objects (Optional - để hiển thị tên)
  final MaterialModel? material;
  final ProductUnit? uom;

  PurchaseOrderDetail({
    this.detailId = 0,
    required this.poId,
    required this.materialId,
    required this.quantity,
    required this.unitPrice,
    this.uomId,
    this.lineTotal = 0.0,
    this.receivedQuantity = 0.0,
    this.material,
    this.uom,
  });

  factory PurchaseOrderDetail.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderDetail(
      detailId: json['detail_id'] ?? 0,
      poId: json['po_id'] ?? 0,
      materialId: json['material_id'] ?? 0,
      quantity: (json['quantity'] ?? 0).toDouble(),
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      uomId: json['uom_id'],
      lineTotal: (json['line_total'] ?? 0).toDouble(),
      receivedQuantity: (json['received_quantity'] ?? 0).toDouble(),
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
      'unit_price': unitPrice,
      'uom_id': uomId,
      // line_total và received_quantity thường do BE tính toán
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
      'status': status.name, // BE nhận string: "Draft", "Sent"...
      'note': note,
      'details': details.map((e) => e.toJson()).toList(),
    };
  }
  
  // Helper để hiển thị màu sắc trạng thái trên UI
  bool get isDraft => status == POStatus.Draft;
  bool get isCompleted => status == POStatus.Completed;
}