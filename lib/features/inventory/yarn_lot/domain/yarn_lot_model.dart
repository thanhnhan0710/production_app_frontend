class YarnLot {
  final int id;
  final String lotCode;
  final int yarnId;
  final String importDate;
  final double totalKg;
  final int rollCount;
  final String warehouseLocation;
  final String containerCode;
  final int? driverId;   // Có thể null
  final int? receiverId; // Có thể null
  final String note;

  YarnLot({
    required this.id,
    required this.lotCode,
    required this.yarnId,
    required this.importDate,
    required this.totalKg,
    required this.rollCount,
    required this.warehouseLocation,
    required this.containerCode,
    this.driverId,
    this.receiverId,
    required this.note,
  });

  factory YarnLot.fromJson(Map<String, dynamic> json) {
    return YarnLot(
      id: json['id'] ?? 0,
      lotCode: json['lot_code'] ?? '',
      yarnId: json['yarn_id'] ?? 0,
      importDate: json['import_date'] ?? '',
      totalKg: (json['total_kg'] ?? 0).toDouble(),
      rollCount: json['roll_count'] ?? 0,
      warehouseLocation: json['warehouse_location'] ?? '',
      containerCode: json['container_code'] ?? '',
      driverId: json['driver_id'],
      receiverId: json['receiver_id'],
      note: json['note'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lot_code': lotCode,
      'yarn_id': yarnId,
      'import_date': importDate,
      'total_kg': totalKg,
      'roll_count': rollCount,
      'warehouse_location': warehouseLocation,
      'container_code': containerCode,
      'driver_id': driverId,
      'receiver_id': receiverId,
      'note': note,
    };
  }
}