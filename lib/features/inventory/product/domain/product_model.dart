class Product {
  final int id;
  final String itemCode;
  final String note;
  final String imageUrl;

  Product({
    required this.id,
    required this.itemCode,
    required this.note,
    required this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['product_id'] ?? 0,
      itemCode: json['item_code'] ?? '',
      note: json['note'] ?? '',
      imageUrl: json['image_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_code': itemCode,
      'note': note,
      'image_url': imageUrl,
    };
  }
}