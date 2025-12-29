class InventoryMaterial {
  final int id;
  final String name;
  final String lotCode;
  final String importDate;
  final double quantity;
  final int unitId;
  final int importedBy; // Employee ID

  InventoryMaterial({
    required this.id,
    required this.name,
    required this.lotCode,
    required this.importDate,
    required this.quantity,
    required this.unitId,
    required this.importedBy,
  });

  factory InventoryMaterial.fromJson(Map<String, dynamic> json) {
    return InventoryMaterial(
      id: json['material_id'] ?? 0,
      name: json['material_name'] ?? '',
      lotCode: json['lot_code'] ?? '',
      importDate: json['import_date'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      unitId: json['unit_id'] ?? 0,
      importedBy: json['imported_by'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'material_name': name,
      'lot_code': lotCode,
      'import_date': importDate,
      'quantity': quantity,
      'unit_id': unitId,
      'imported_by': importedBy,
    };
  }
}