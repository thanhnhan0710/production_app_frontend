class Unit {
  final int id;
  final String name;

  Unit({required this.id, required this.name});

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['unit_id'] ?? 0,
      name: json['unit_name'] ?? '',
    );
  }
}

class MaterialModel {
  final int id;
  final String materialCode;
  final String materialName;
  final String? materialType;
  final String? specDenier;
  final int? specFilament;
  final String? hsCode;
  final double minStockLevel;
  
  // ID dùng để gửi lên API khi Create/Update
  final int uomBaseId;
  final int uomProductionId;

  // Object dùng để hiển thị tên đơn vị (Nested object từ API)
  final Unit? uomBase;
  final Unit? uomProduction;

  MaterialModel({
    required this.id,
    required this.materialCode,
    required this.materialName,
    this.materialType,
    this.specDenier,
    this.specFilament,
    this.hsCode,
    this.minStockLevel = 0.0,
    required this.uomBaseId,
    required this.uomProductionId,
    this.uomBase,
    this.uomProduction,
  });

  MaterialModel copyWith({
    int? id,
    String? materialCode,
    String? materialName,
    String? materialType,
    String? specDenier,
    int? specFilament,
    String? hsCode,
    double? minStockLevel,
    int? uomBaseId,
    int? uomProductionId,
    Unit? uomBase,
    Unit? uomProduction,
  }) {
    return MaterialModel(
      id: id ?? this.id,
      materialCode: materialCode ?? this.materialCode,
      materialName: materialName ?? this.materialName,
      materialType: materialType ?? this.materialType,
      specDenier: specDenier ?? this.specDenier,
      specFilament: specFilament ?? this.specFilament,
      hsCode: hsCode ?? this.hsCode,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      uomBaseId: uomBaseId ?? this.uomBaseId,
      uomProductionId: uomProductionId ?? this.uomProductionId,
      uomBase: uomBase ?? this.uomBase,
      uomProduction: uomProduction ?? this.uomProduction,
    );
  }

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      id: json['id'] ?? 0,
      materialCode: json['material_code'] ?? '',
      materialName: json['material_name'] ?? '',
      materialType: json['material_type'],
      specDenier: json['spec_denier'],
      specFilament: json['spec_filament'],
      hsCode: json['hs_code'],
      minStockLevel: (json['min_stock_level'] ?? 0).toDouble(),
      
      // Lấy ID từ field gốc hoặc từ nested object nếu có
      uomBaseId: json['uom_base_id'] ?? (json['uom_base']?['unit_id'] ?? 0),
      uomProductionId: json['uom_production_id'] ?? (json['uom_production']?['unit_id'] ?? 0),
      
      // Parse nested objects
      uomBase: json['uom_base'] != null ? Unit.fromJson(json['uom_base']) : null,
      uomProduction: json['uom_production'] != null ? Unit.fromJson(json['uom_production']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'material_code': materialCode,
      'material_name': materialName,
      'material_type': materialType,
      'spec_denier': specDenier,
      'spec_filament': specFilament,
      'hs_code': hsCode,
      'min_stock_level': minStockLevel,
      'uom_base_id': uomBaseId,
      'uom_production_id': uomProductionId,
    };
  }
}