// Enum khớp với Backend
enum BOMComponentType {
  // ignore: constant_identifier_names
  Warp,   // Sợi dọc
  // ignore: constant_identifier_names
  Weft,   // Sợi ngang
  // ignore: constant_identifier_names
  Binder, // Sợi biên
  // ignore: constant_identifier_names
  Dye     // Thuốc nhuộm
}

class BOMHeader {
  final int bomId;
  final int productId;
  final String bomCode;
  final String bomName;
  final int version;
  final bool isActive;
  final double baseQuantity;
  final List<BOMDetail> bomDetails; // Nested list

  BOMHeader({
    required this.bomId,
    required this.productId,
    required this.bomCode,
    required this.bomName,
    required this.version,
    required this.isActive,
    required this.baseQuantity,
    this.bomDetails = const [],
  });

  factory BOMHeader.fromJson(Map<String, dynamic> json) {
    var detailsList = json['bom_details'] as List? ?? [];
    List<BOMDetail> details = detailsList.map((i) => BOMDetail.fromJson(i)).toList();

    return BOMHeader(
      bomId: json['bom_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      bomCode: json['bom_code'] ?? '',
      bomName: json['bom_name'] ?? '',
      version: json['version'] ?? 1,
      isActive: json['is_active'] ?? true,
      baseQuantity: (json['base_quantity'] ?? 1.0).toDouble(),
      bomDetails: details,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'bom_code': bomCode,
      'bom_name': bomName,
      'version': version,
      'is_active': isActive,
      'base_quantity': baseQuantity,
    };
  }
}

class BOMDetail {
  final int detailId;
  final int bomId;
  final int materialId;
  final BOMComponentType componentType;
  final int numberOfEnds;
  final double quantityStandard;
  final double wastageRate;
  final double quantityGross;
  final String note;

  BOMDetail({
    required this.detailId,
    required this.bomId,
    required this.materialId,
    required this.componentType,
    required this.numberOfEnds,
    required this.quantityStandard,
    required this.wastageRate,
    required this.quantityGross,
    required this.note,
  });

  factory BOMDetail.fromJson(Map<String, dynamic> json) {
    return BOMDetail(
      detailId: json['detail_id'] ?? 0,
      bomId: json['bom_id'] ?? 0,
      materialId: json['material_id'] ?? 0,
      componentType: BOMComponentType.values.firstWhere(
          (e) => e.name == json['component_type'],
          orElse: () => BOMComponentType.Warp),
      numberOfEnds: json['number_of_ends'] ?? 0,
      quantityStandard: (json['quantity_standard'] ?? 0.0).toDouble(),
      wastageRate: (json['wastage_rate'] ?? 0.0).toDouble(),
      quantityGross: (json['quantity_gross'] ?? 0.0).toDouble(),
      note: json['note'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bom_id': bomId,
      'material_id': materialId,
      'component_type': componentType.name, // Gửi string lên server
      'number_of_ends': numberOfEnds,
      'quantity_standard': quantityStandard,
      'wastage_rate': wastageRate,
      'quantity_gross': quantityGross,
      'note': note,
    };
  }
}