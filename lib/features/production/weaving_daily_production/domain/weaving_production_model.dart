// lib/features/production/weaving_daily_production/domain/weaving_production_model.dart

class ProductSimple {
  final int id;
  final String itemCode;
  final String? note;
  final String? imageUrl; // [MỚI] Thêm trường ảnh

  ProductSimple({
    required this.id, 
    required this.itemCode, 
    this.note, 
    this.imageUrl
  });

  factory ProductSimple.fromJson(Map<String, dynamic> json) {
    return ProductSimple(
      id: json['product_id'] ?? 0,
      itemCode: json['item_code'] ?? 'N/A',
      note: json['note'],
      // [MỚI] Map link ảnh (Lưu ý: Backend phải trả về field này trong ProductSimpleSchema)
      imageUrl: json['image_url'], 
    );
  }
}

// Class WeavingDailyProduction giữ nguyên
class WeavingDailyProduction {
  // ... (giữ nguyên code cũ)
  final int id;
  final DateTime date;
  final int productId;
  final double totalMeters;
  final double totalKg;
  final int activeMachineLines;
  final ProductSimple? product;

  WeavingDailyProduction({
    required this.id,
    required this.date,
    required this.productId,
    required this.totalMeters,
    required this.totalKg,
    required this.activeMachineLines,
    this.product,
  });

  factory WeavingDailyProduction.fromJson(Map<String, dynamic> json) {
    return WeavingDailyProduction(
      id: json['id'] ?? 0,
      date: DateTime.parse(json['date']),
      productId: json['product_id'] ?? 0,
      totalMeters: (json['total_meters'] ?? 0).toDouble(),
      totalKg: (json['total_kg'] ?? 0).toDouble(),
      activeMachineLines: json['active_machine_lines'] ?? 0,
      product: json['product'] != null ? ProductSimple.fromJson(json['product']) : null,
    );
  }
}