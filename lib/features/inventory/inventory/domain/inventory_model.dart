import 'package:production_app_frontend/features/inventory/material/domain/material_model.dart';
import 'package:production_app_frontend/features/inventory/warehouse/domain/warehouse_model.dart';
import 'package:production_app_frontend/features/inventory/batch/domain/batch_model.dart';

class InventoryStock {
  final int id;
  final int materialId;
  final int warehouseId;
  final int batchId;
  
  final double quantityOnHand;
  final double quantityReserved;
  final DateTime? lastUpdated;

  // --- Nested Objects ---
  final MaterialModel? material;
  final Warehouse? warehouse;
  final Batch? batch;

  // --- [MỚI] Các trường bổ sung cho hiển thị ---
  // (Giả định Backend trả về các trường này thông qua join query hoặc DTO)
  final String? supplierShortName;
  final int? receivedQuantityCones;
  final int? numberOfPallets;

  InventoryStock({
    required this.id,
    required this.materialId,
    required this.warehouseId,
    required this.batchId,
    this.quantityOnHand = 0.0,
    this.quantityReserved = 0.0,
    this.lastUpdated,
    this.material,
    this.warehouse,
    this.batch,
    this.supplierShortName,
    this.receivedQuantityCones,
    this.numberOfPallets,
  });

  double get availableQuantity => quantityOnHand - quantityReserved;

  InventoryStock copyWith({
    int? id,
    int? materialId,
    int? warehouseId,
    int? batchId,
    double? quantityOnHand,
    double? quantityReserved,
    DateTime? lastUpdated,
    MaterialModel? material,
    Warehouse? warehouse,
    Batch? batch,
    String? supplierShortName,
    int? receivedQuantityCones,
    int? numberOfPallets,
  }) {
    return InventoryStock(
      id: id ?? this.id,
      materialId: materialId ?? this.materialId,
      warehouseId: warehouseId ?? this.warehouseId,
      batchId: batchId ?? this.batchId,
      quantityOnHand: quantityOnHand ?? this.quantityOnHand,
      quantityReserved: quantityReserved ?? this.quantityReserved,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      material: material ?? this.material,
      warehouse: warehouse ?? this.warehouse,
      batch: batch ?? this.batch,
      supplierShortName: supplierShortName ?? this.supplierShortName,
      receivedQuantityCones: receivedQuantityCones ?? this.receivedQuantityCones,
      numberOfPallets: numberOfPallets ?? this.numberOfPallets,
    );
  }

  factory InventoryStock.fromJson(Map<String, dynamic> json) {
    return InventoryStock(
      id: json['id'] ?? 0,
      materialId: json['material_id'] ?? 0,
      warehouseId: json['warehouse_id'] ?? 0,
      batchId: json['batch_id'] ?? 0,
      quantityOnHand: (json['quantity_on_hand'] ?? 0).toDouble(),
      quantityReserved: (json['quantity_reserved'] ?? 0).toDouble(),
      lastUpdated: json['last_updated'] != null 
          ? DateTime.tryParse(json['last_updated']) 
          : null,
      
      material: json['material'] != null 
          ? MaterialModel.fromJson(json['material']) 
          : null,
      warehouse: json['warehouse'] != null 
          ? Warehouse.fromJson(json['warehouse']) 
          : null,
      batch: json['batch'] != null 
          ? Batch.fromJson(json['batch']) 
          : null,
      
      // [MỚI] Map các trường bổ sung (nếu backend chưa trả về thì sẽ là null)
      supplierShortName: json['supplier_short_name'],
      receivedQuantityCones: json['received_quantity_cones'], // Hoặc 'cones' tùy response backend
      numberOfPallets: json['number_of_pallets'], // Hoặc 'pallets' tùy response backend
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'material_id': materialId,
      'warehouse_id': warehouseId,
      'batch_id': batchId,
      'quantity_on_hand': quantityOnHand,
      'quantity_reserved': quantityReserved,
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }
}

class InventoryAdjustment {
  final int materialId;
  final int warehouseId;
  final int batchId;
  final double newQuantity;
  final String? reason;

  InventoryAdjustment({
    required this.materialId,
    required this.warehouseId,
    required this.batchId,
    required this.newQuantity,
    this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'material_id': materialId,
      'warehouse_id': warehouseId,
      'batch_id': batchId,
      'new_quantity': newQuantity,
      'reason': reason,
    };
  }
}