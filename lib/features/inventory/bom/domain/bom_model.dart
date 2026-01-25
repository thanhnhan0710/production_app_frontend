
enum BOMComponentType {
  ground,
  grdMarker,
  edge,
  binder,
  stuffer,
  catchCord,
  filling,
  secondFilling;

  // Helper để map từ String (Backend) sang Enum (Frontend)
  static BOMComponentType fromString(String value) {
    switch (value) {
      case "Ground": return BOMComponentType.ground;
      case "Grd. Marker": return BOMComponentType.grdMarker;
      case "Edge": return BOMComponentType.edge;
      case "Binder": return BOMComponentType.binder;
      case "Stuffer": return BOMComponentType.stuffer;
      case "Catch cord": return BOMComponentType.catchCord;
      case "Filling": return BOMComponentType.filling;
      case "2nd Filling": return BOMComponentType.secondFilling;
      default: return BOMComponentType.ground; // Fallback
    }
  }

  // Helper để map từ Enum (Frontend) sang String (Backend) để gửi đi
  String get value {
    switch (this) {
      case BOMComponentType.ground: return "Ground";
      case BOMComponentType.grdMarker: return "Grd. Marker";
      case BOMComponentType.edge: return "Edge";
      case BOMComponentType.binder: return "Binder";
      case BOMComponentType.stuffer: return "Stuffer";
      case BOMComponentType.catchCord: return "Catch cord";
      case BOMComponentType.filling: return "Filling";
      case BOMComponentType.secondFilling: return "2nd Filling";
    }
  }
}

class BOMHeader {
  final int bomId;
  final int productId;
  final String bomCode;
  final String bomName;
  
  // --- Thông số kỹ thuật chung ---
  final double targetWeightGm;      // target_weight_gm
  final double totalScrapRate;      // total_scrap_rate
  final double totalShrinkageRate;  // total_shrinkage_rate
  final double? widthBehindLoom;    // width_behind_loom
  final int? picks;                 // picks

  final int version;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  final List<BOMDetail> bomDetails;

  BOMHeader({
    required this.bomId,
    required this.productId,
    required this.bomCode,
    required this.bomName,
    required this.targetWeightGm,
    required this.totalScrapRate,
    required this.totalShrinkageRate,
    this.widthBehindLoom,
    this.picks,
    required this.version,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.bomDetails = const [],
  });

  /// Map từ JSON (Backend trả về) -> Object Dart
  factory BOMHeader.fromJson(Map<String, dynamic> json) {
    var detailsList = json['bom_details'] as List? ?? [];
    List<BOMDetail> details = detailsList.map((i) => BOMDetail.fromJson(i)).toList();

    return BOMHeader(
      bomId: json['bom_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      bomCode: json['bom_code'] ?? '',
      bomName: json['bom_name'] ?? '',
      
      targetWeightGm: (json['target_weight_gm'] ?? 0.0).toDouble(),
      totalScrapRate: (json['total_scrap_rate'] ?? 0.0).toDouble(),
      totalShrinkageRate: (json['total_shrinkage_rate'] ?? 0.0).toDouble(),
      widthBehindLoom: json['width_behind_loom'] != null ? (json['width_behind_loom']).toDouble() : null,
      picks: json['picks'],

      version: json['version'] ?? 1,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      
      bomDetails: details,
    );
  }

  /// Map từ Object Dart -> JSON (Để gửi lên Backend tạo/sửa)
  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'bom_code': bomCode,
      'bom_name': bomName,
      'target_weight_gm': targetWeightGm,
      'total_scrap_rate': totalScrapRate,
      'total_shrinkage_rate': totalShrinkageRate,
      'width_behind_loom': widthBehindLoom,
      'picks': picks,
      'is_active': isActive,
      // Gửi kèm danh sách chi tiết khi tạo/sửa (khớp với BOMHeaderCreate/Update)
      'details': bomDetails.map((e) => e.toJson()).toList(),
    };
  }
}

class BOMDetail {
  final int detailId;
  final int bomId;
  final int materialId;
  final BOMComponentType componentType; // Enum

  // --- Input Fields (Người dùng nhập) ---
  final int threads;                // threads (Số đầu sợi)
  final String yarnTypeName;        // yarn_type_name (Mã sợi/Màu)
  final double twisted;             // twisted
  final double crossweaveRate;      // crossweave_rate
  final double actualLengthCm;      // actual_length_cm

  // --- Computed Fields (Backend tính toán trả về - ReadOnly ở FE) ---
  final double yarnDtex;            // yarn_dtex (Tự tách từ yarnTypeName)
  final double weightPerYarnGm;     // weight_per_yarn_gm
  final double actualWeightCal;     // actual_weight_cal
  final double weightPercentage;    // weight_percentage
  final double bomGm;               // bom_gm (Định mức chốt)

  final String note;

  BOMDetail({
    required this.detailId,
    required this.bomId,
    this.materialId = 1, // Default theo Backend Schema
    required this.componentType,
    
    required this.threads,
    required this.yarnTypeName,
    required this.twisted,
    required this.crossweaveRate,
    required this.actualLengthCm,
    
    this.yarnDtex = 0.0,
    this.weightPerYarnGm = 0.0,
    this.actualWeightCal = 0.0,
    this.weightPercentage = 0.0,
    this.bomGm = 0.0,
    
    required this.note,
  });

  /// Map từ JSON (Backend trả về) -> Object Dart
  factory BOMDetail.fromJson(Map<String, dynamic> json) {
    return BOMDetail(
      detailId: json['detail_id'] ?? 0,
      bomId: json['bom_id'] ?? 0,
      materialId: json['material_id'] ?? 1,
      componentType: BOMComponentType.fromString(json['component_type'] ?? "Ground"),
      
      threads: json['threads'] ?? 0,
      yarnTypeName: json['yarn_type_name'] ?? '',
      twisted: (json['twisted'] ?? 1.0).toDouble(),
      crossweaveRate: (json['crossweave_rate'] ?? 0.0).toDouble(),
      actualLengthCm: (json['actual_length_cm'] ?? 0.0).toDouble(),
      
      // Các trường tính toán
      yarnDtex: (json['yarn_dtex'] ?? 0.0).toDouble(),
      weightPerYarnGm: (json['weight_per_yarn_gm'] ?? 0.0).toDouble(),
      actualWeightCal: (json['actual_weight_cal'] ?? 0.0).toDouble(),
      weightPercentage: (json['weight_percentage'] ?? 0.0).toDouble(),
      bomGm: (json['bom_gm'] ?? 0.0).toDouble(),
      
      note: json['note'] ?? '',
    );
  }

  /// Map từ Object Dart -> JSON (Để gửi lên Backend)
  /// Chỉ cần gửi các trường Input, Backend sẽ tự tính toán lại các trường Computed
  Map<String, dynamic> toJson() {
    return {
      'detail_id': detailId, // Có thể cần khi update, nhưng create thì bỏ qua
      'material_id': materialId,
      'component_type': componentType.value, // Gửi string đúng định dạng
      'threads': threads,
      'yarn_type_name': yarnTypeName,
      'twisted': twisted,
      'crossweave_rate': crossweaveRate,
      'actual_length_cm': actualLengthCm,
      'note': note,
    };
  }
  
  // Helper để tạo một bản sao (clone) khi chỉnh sửa trên UI
  BOMDetail copyWith({
    int? detailId,
    int? bomId,
    int? materialId,
    BOMComponentType? componentType,
    int? threads,
    String? yarnTypeName,
    double? twisted,
    double? crossweaveRate,
    double? actualLengthCm,
    String? note,
  }) {
    return BOMDetail(
      detailId: detailId ?? this.detailId,
      bomId: bomId ?? this.bomId,
      materialId: materialId ?? this.materialId,
      componentType: componentType ?? this.componentType,
      threads: threads ?? this.threads,
      yarnTypeName: yarnTypeName ?? this.yarnTypeName,
      twisted: twisted ?? this.twisted,
      crossweaveRate: crossweaveRate ?? this.crossweaveRate,
      actualLengthCm: actualLengthCm ?? this.actualLengthCm,
      // Giữ nguyên các trường computed
      yarnDtex: yarnDtex,
      weightPerYarnGm: weightPerYarnGm,
      actualWeightCal: actualWeightCal,
      weightPercentage: weightPercentage,
      bomGm: bomGm,
      note: note ?? this.note,
    );
  }
}