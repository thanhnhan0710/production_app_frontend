class Yarn {
  final int id;
  final String name;
  final String itemCode;
  final String type;
  final String color;
  final String origin;
  final int supplierId;
  final String note;

  Yarn({
    required this.id,
    required this.name,
    required this.itemCode,
    required this.type,
    required this.color,
    required this.origin,
    required this.supplierId,
    required this.note,
  });

  factory Yarn.fromJson(Map<String, dynamic> json) {
    return Yarn(
      id: json['yarn_id'] ?? 0,
      name: json['yarn_name'] ?? '',
      itemCode: json['item_code'] ?? '',
      type: json['type'] ?? '',
      color: json['color'] ?? '',
      origin: json['origin'] ?? '',
      supplierId: json['supplier_id'] ?? 0,
      note: json['note'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'yarn_name': name,
      'item_code': itemCode,
      'type': type,
      'color': color,
      'origin': origin,
      'supplier_id': supplierId,
      'note': note,
    };
  }
}