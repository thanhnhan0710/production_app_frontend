class Basket {
  final int id;
  final String code;
  final double tareWeight;
  final String supplier;
  final String status; // READY, IN_USE, HOLDING, DAMAGED
  final String note;

  Basket({
    required this.id,
    required this.code,
    required this.tareWeight,
    required this.supplier,
    required this.status,
    required this.note,
  });

  factory Basket.fromJson(Map<String, dynamic> json) {
    return Basket(
      id: json['basket_id'] ?? 0,
      code: json['basket_code'] ?? '',
      tareWeight: (json['tare_weight'] ?? 0).toDouble(),
      supplier: json['supplier'] ?? '',
      status: json['status'] ?? 'READY',
      note: json['note'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'basket_code': code,
      'tare_weight': tareWeight,
      'supplier': supplier,
      'status': status,
      'note': note,
    };
  }
}