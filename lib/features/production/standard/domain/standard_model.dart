class Standard {
  final int id;
  // Bỏ field code gốc của Standard
  // final String code; 
  final int productId;
  final int dyeColorId;
  
  // Thông số kỹ thuật
  final String widthMm;
  final String thicknessMm;
  final String breakingStrength;
  final String elongation;
  final String colorFastnessDry;
  final String colorFastnessWet;
  final String deltaE;
  final String appearance;
  final String weftDensity;
  final String weightGm;
  final String note;
  
  // --- [QUAN TRỌNG] Các trường mở rộng (Nested Objects) ---
  final String? productName;
  final String? productItemCode; // Mã sản phẩm (Lấy từ bảng Product)
  final String? productImage;    // Ảnh sản phẩm (Lấy từ bảng Product)
  
  final String? colorName;
  final String? colorHex;

  Standard({
    required this.id,
    required this.productId,
    required this.dyeColorId,
    required this.widthMm,
    required this.thicknessMm,
    required this.breakingStrength,
    required this.elongation,
    required this.colorFastnessDry,
    required this.colorFastnessWet,
    required this.deltaE,
    required this.appearance,
    required this.weftDensity,
    required this.weightGm,
    required this.note,
    this.productName,
    this.productItemCode,
    this.productImage,
    this.colorName,
    this.colorHex,
  });

  factory Standard.fromJson(Map<String, dynamic> json) {
    // Helper để lấy thông tin từ nested object 'product'
    final productData = json['product'];
    final colorData = json['dye_color'];

    return Standard(
      id: json['standard_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      dyeColorId: json['dye_color_id'] ?? 0,
      widthMm: json['width_mm'] ?? '',
      thicknessMm: json['thickness_mm'] ?? '',
      breakingStrength: json['breaking_strength_dan'] ?? '',
      elongation: json['elongation_at_load_percent'] ?? '',
      colorFastnessDry: json['color_fastness_dry'] ?? '',
      colorFastnessWet: json['color_fastness_wet'] ?? '',
      deltaE: json['delta_e'] ?? '',
      appearance: json['appearance'] ?? '',
      weftDensity: json['weft_density'] ?? '',
      weightGm: json['weight_gm'] ?? '',
      note: json['note'] ?? '',
      
      // Map dữ liệu lồng nhau
      productName: productData != null ? (productData['name'] ?? '') : null,
      // Lấy item_code, dự phòng trường hợp backend trả về key là 'code'
      productItemCode: productData != null ? (productData['item_code'] ?? productData['code'] ?? 'N/A') : null,
      // Lấy ảnh sản phẩm
      productImage: productData != null ? productData['image_url'] : null,
      
      colorName: colorData != null ? colorData['color_name'] : null,
      colorHex: colorData != null ? colorData['hex_code'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'dye_color_id': dyeColorId,
      'width_mm': widthMm,
      'thickness_mm': thicknessMm,
      'breaking_strength_dan': breakingStrength,
      'elongation_at_load_percent': elongation,
      'color_fastness_dry': colorFastnessDry,
      'color_fastness_wet': colorFastnessWet,
      'delta_e': deltaE,
      'appearance': appearance,
      'weft_density': weftDensity,
      'weight_gm': weightGm,
      'note': note,
    };
  }
}