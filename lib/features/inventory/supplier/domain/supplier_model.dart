class Supplier {
  final int id;
  final String name;
  final String? shortName; // Tên viết tắt
  final String email;      // Bắt buộc, Unique
  
  final String? originType;   // 'Domestic' hoặc 'Import'
  final String? country;  // VN, KR, CN...
  final String currencyDefault; // 'VND' hoặc 'USD'
  
  final String? taxCode;      // Mã số thuế
  final String? contactPerson; // Người liên hệ
  final String? address;
  
  final int leadTimeDays;     // Thời gian giao hàng (mặc định 7)
  final bool isActive;        // Trạng thái hoạt động

  Supplier({
    required this.id,
    required this.name,
    required this.email,
    this.shortName,
    this.originType,
    this.country,
    this.currencyDefault = 'VND', // Mặc định phía Client
    this.taxCode,
    this.contactPerson,
    this.address,
    this.leadTimeDays = 7,
    this.isActive = true,
  });

  // Factory nhận dữ liệu từ API (JSON -> Object)
  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      // Lưu ý: Key phải khớp chính xác với field trong Pydantic Schema (snake_case)
      id: json['supplier_id'] ?? 0,
      name: json['supplier_name'] ?? '',
      email: json['email'] ?? '', // Đã sửa thành bắt buộc
      
      shortName: json['short_name'],
      originType: json['origin_type'],
      country: json['country'],
      
      // Xử lý giá trị mặc định nếu null
      currencyDefault: json['currency_default'] ?? 'VND',
      
      taxCode: json['tax_code'],
      contactPerson: json['contact_person'],
      address: json['address'],
      
      leadTimeDays: json['lead_time_days'] ?? 7,
      isActive: json['is_active'] ?? true,
    );
  }

  // Chuyển Object thành JSON để gửi lên API (Create/Update)
  Map<String, dynamic> toJson() {
    return {
      'supplier_name': name,
      'email': email,
      'short_name': shortName,
      'origin_type': originType,
      'country': country,
      'currency_default': currencyDefault,
      'tax_code': taxCode,
      'contact_person': contactPerson,
      'address': address,
      'lead_time_days': leadTimeDays,
      'is_active': isActive,
      // Không gửi 'supplier_id' khi Create, nhưng có thể cần khi Update
    };
  }
}