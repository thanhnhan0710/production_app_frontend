class DyeColor {
  final int id;
  final String name;
  final String hexCode;
  final String note;

  DyeColor({
    required this.id,
    required this.name,
    required this.hexCode,
    required this.note,
  });

  factory DyeColor.fromJson(Map<String, dynamic> json) {
    return DyeColor(
      id: json['color_id'] ?? 0,
      name: json['color_name'] ?? '',
      hexCode: json['hex_code'] ?? '#000000',
      note: json['note'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'color_name': name,
      'hex_code': hexCode,
      'note': note,
      // 'color_id': id,
    };
  }
}