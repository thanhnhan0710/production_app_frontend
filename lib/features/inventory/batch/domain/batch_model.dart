class Batch {
  final int batchId;
  final String internalBatchCode;
  final String supplierBatchNo;
  final int materialId;
  final String? manufactureDate;
  final String? expiryDate;
  final String? originCountry;
  
  // [MỚI] Vị trí kho
  final String? location;

  final String qcStatus;
  final String? qcNote;
  final String? note;
  final bool isActive;
  final int? receiptDetailId;
  final String? createdAt;
  
  // Số phiếu nhập
  final String? receiptNumber;

  Batch({
    this.batchId = 0,
    this.internalBatchCode = '',
    required this.supplierBatchNo,
    required this.materialId,
    this.manufactureDate,
    this.expiryDate,
    this.originCountry,
    this.location, // [MỚI]
    this.qcStatus = 'Pending',
    this.qcNote,
    this.note,
    this.isActive = true,
    this.receiptDetailId,
    this.createdAt,
    this.receiptNumber,
  });

  factory Batch.fromJson(Map<String, dynamic> json) {
    return Batch(
      batchId: json['batch_id'] ?? 0,
      internalBatchCode: json['internal_batch_code'] ?? '',
      supplierBatchNo: json['supplier_batch_no'] ?? '',
      materialId: json['material_id'] ?? 0,
      manufactureDate: json['manufacture_date'],
      expiryDate: json['expiry_date'],
      originCountry: json['origin_country'],
      // [MỚI] Map location từ JSON
      location: json['location'],
      qcStatus: json['qc_status'] ?? 'Pending',
      qcNote: json['qc_note'],
      note: json['note'],
      isActive: json['is_active'] ?? true,
      receiptDetailId: json['receipt_detail_id'],
      createdAt: json['created_at'],
      receiptNumber: json['receipt_number'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'supplier_batch_no': supplierBatchNo,
      'material_id': materialId,
      'qc_status': qcStatus,
      'is_active': isActive,
    };

    if (batchId != 0) data['batch_id'] = batchId;
    if (internalBatchCode.isNotEmpty) data['internal_batch_code'] = internalBatchCode;
    if (manufactureDate != null) data['manufacture_date'] = manufactureDate;
    if (expiryDate != null) data['expiry_date'] = expiryDate;
    if (originCountry != null) data['origin_country'] = originCountry;
    
    // [MỚI] Thêm location vào JSON gửi đi
    if (location != null) data['location'] = location;
    
    if (qcNote != null) data['qc_note'] = qcNote;
    if (note != null) data['note'] = note;
    if (receiptDetailId != null) data['receipt_detail_id'] = receiptDetailId;

    return data;
  }
  
  // Helper để copy object khi cần update 1 vài trường (Optional, nhưng rất hữu ích trong Flutter Bloc)
  Batch copyWith({
    int? batchId,
    String? internalBatchCode,
    String? supplierBatchNo,
    int? materialId,
    String? manufactureDate,
    String? expiryDate,
    String? originCountry,
    String? location,
    String? qcStatus,
    String? qcNote,
    String? note,
    bool? isActive,
    int? receiptDetailId,
    String? createdAt,
    String? receiptNumber,
  }) {
    return Batch(
      batchId: batchId ?? this.batchId,
      internalBatchCode: internalBatchCode ?? this.internalBatchCode,
      supplierBatchNo: supplierBatchNo ?? this.supplierBatchNo,
      materialId: materialId ?? this.materialId,
      manufactureDate: manufactureDate ?? this.manufactureDate,
      expiryDate: expiryDate ?? this.expiryDate,
      originCountry: originCountry ?? this.originCountry,
      location: location ?? this.location,
      qcStatus: qcStatus ?? this.qcStatus,
      qcNote: qcNote ?? this.qcNote,
      note: note ?? this.note,
      isActive: isActive ?? this.isActive,
      receiptDetailId: receiptDetailId ?? this.receiptDetailId,
      createdAt: createdAt ?? this.createdAt,
      receiptNumber: receiptNumber ?? this.receiptNumber,
    );
  }
}