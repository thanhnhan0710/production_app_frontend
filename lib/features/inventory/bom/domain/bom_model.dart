enum BOMComponentType {
  ground,
  grdMarker,
  edge,
  binder,
  stuffer,
  stufferMaker,
  lock,
  catchCord,
  filling,
  secondFilling;

  // Helper: Backend trả về "GROUND" -> Convert sang Enum
  static BOMComponentType fromString(String value) {
    // Chuyển về chữ hoa để so sánh cho chắc chắn
    switch (value.toUpperCase()) {
      case "GROUND": return BOMComponentType.ground;
      case "GRD. MARKER": return BOMComponentType.grdMarker;
      case "EDGE": return BOMComponentType.edge;
      case "BINDER": return BOMComponentType.binder;
      case "STUFFER": return BOMComponentType.stuffer;
      case "STUFFER MAKER": return BOMComponentType.stufferMaker;
      case "LOCK": return BOMComponentType.lock;
      case "CATCH CORD": return BOMComponentType.catchCord;
      case "FILLING": return BOMComponentType.filling;
      case "2ND FILLING": return BOMComponentType.secondFilling;
      default: return BOMComponentType.ground;
    }
  }

  // Helper: Gửi lên Backend -> Trả về "GROUND"
  String get value {
    switch (this) {
      case BOMComponentType.ground: return "GROUND";
      case BOMComponentType.grdMarker: return "GRD. MARKER";
      case BOMComponentType.edge: return "EDGE";
      case BOMComponentType.binder: return "BINDER";
      case BOMComponentType.stuffer: return "STUFFER";
      case BOMComponentType.stufferMaker: return "STUFFER MAKER";
      case BOMComponentType.lock: return "LOCK";
      case BOMComponentType.catchCord: return "CATCH CORD";
      case BOMComponentType.filling: return "FILLING";
      case BOMComponentType.secondFilling: return "2ND FILLING";
    }
  }
}

class BOMHeader {
  final int bomId;
  final int productId;
  
  // [THAY ĐỔI] Thay Code/Name bằng Year
  final int applicableYear; 
  
  // [THAY ĐỔI] Trường hiển thị từ Backend (computed_field: display_name)
  final String? displayName; 
  
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
    required this.applicableYear, // Bắt buộc
    this.displayName,
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
      
      // Map trường năm và tên hiển thị
      applicableYear: json['applicable_year'] ?? DateTime.now().year,
      displayName: json['display_name'], // Backend trả về ví dụ: "BOM Năm 2026"
      
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
      'applicable_year': applicableYear, // Gửi năm lên thay vì code
      'target_weight_gm': targetWeightGm,
      'total_scrap_rate': totalScrapRate,
      'total_shrinkage_rate': totalShrinkageRate,
      'width_behind_loom': widthBehindLoom,
      'picks': picks,
      'is_active': isActive,
      // Gửi kèm danh sách chi tiết khi tạo/sửa
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
  Map<String, dynamic> toJson() {
    return {
      'detail_id': detailId, 
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
      // Giữ nguyên các trường computed (Vì copyWith thường dùng để user sửa input)
      yarnDtex: yarnDtex,
      weightPerYarnGm: weightPerYarnGm,
      actualWeightCal: actualWeightCal,
      weightPercentage: weightPercentage,
      bomGm: bomGm,
      note: note ?? this.note,
    );
  }
}