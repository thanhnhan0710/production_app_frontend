import 'package:production_app_frontend/features/inventory/unit/domain/unit_model.dart';

class MaterialModel {
  final int id;
  final String materialCode;
  final String? materialName; // [BỔ SUNG]
  final String? materialType;
  final String? color;
  final int? dtex;
  final double minStockLevel;

  // ID dùng để gửi lên API khi Create/Update
  final int uomBaseId;
  final int uomProductionId;
  final double? kgPerBobbin;

  // Object dùng để hiển thị tên đơn vị (Nested object từ API)
  final ProductUnit? uomBase;
  final ProductUnit? uomProduction;

  MaterialModel({
    required this.id,
    required this.materialCode,
    this.materialName, // [BỔ SUNG]
    this.materialType,
    this.color,
    this.dtex,
    this.minStockLevel = 0.0,
    required this.uomBaseId,
    required this.uomProductionId,
    this.uomBase,
    this.uomProduction,
    this.kgPerBobbin,
  });

  MaterialModel copyWith({
    int? id,
    String? materialCode,
    String? materialName, // [BỔ SUNG]
    String? materialType,
    String? color,
    int? dtex,
    double? minStockLevel,
    int? uomBaseId,
    int? uomProductionId,
    double? kgPerBobbin,
    ProductUnit? uomBase,
    ProductUnit? uomProduction,
  }) {
    return MaterialModel(
      id: id ?? this.id,
      materialCode: materialCode ?? this.materialCode,
      materialName: materialName ?? this.materialName, // [BỔ SUNG]
      materialType: materialType ?? this.materialType,
      color: color ?? this.color,
      dtex: dtex ?? this.dtex,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      uomBaseId: uomBaseId ?? this.uomBaseId,
      uomProductionId: uomProductionId ?? this.uomProductionId,
      uomBase: uomBase ?? this.uomBase,
      uomProduction: uomProduction ?? this.uomProduction,
      kgPerBobbin: kgPerBobbin ?? this.kgPerBobbin,
    );
  }

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
        id: json['id'] ?? 0,
        materialCode: json['material_code'] ?? '',
        materialName: json['material_name'], // [BỔ SUNG]
        materialType: json['material_type'],
        color: json['color'],
        dtex: json['dtex'],
        minStockLevel: (json['min_stock_level'] ?? 0).toDouble(),

        // Lấy ID từ field gốc hoặc từ nested object nếu có
        uomBaseId: json['uom_base_id'] ?? (json['uom_base']?['unit_id'] ?? 0),
        uomProductionId: json['uom_production_id'] ??
            (json['uom_production']?['unit_id'] ?? 0),

        // Parse nested objects
        uomBase: json['uom_base'] != null
            ? ProductUnit.fromJson(json['uom_base'])
            : null,
        uomProduction: json['uom_production'] != null
            ? ProductUnit.fromJson(json['uom_production'])
            : null,
        kgPerBobbin: json['kg_per_bobbin']);
  }

  Map<String, dynamic> toJson() {
    return {
      'material_code': materialCode,
      'material_name': materialName, // [BỔ SUNG]
      'material_type': materialType,
      'color': color,
      'dtex': dtex,
      'min_stock_level': minStockLevel,
      'uom_base_id': uomBaseId,
      'uom_production_id': uomProductionId,
      'kg_per_bobbin': kgPerBobbin,
    };
  }
}
