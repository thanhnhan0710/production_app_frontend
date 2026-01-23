// Enum trạng thái kết quả (Khớp với Backend)
enum IQCResultStatus {
  pass,
  fail,
  pending;

  String toJson() {
    switch (this) {
      case IQCResultStatus.pass: return "Pass";
      case IQCResultStatus.fail: return "Fail";
      default: return "Pending";
    }
  }

  static IQCResultStatus fromJson(String? value) {
    if (value == "Pass") return IQCResultStatus.pass;
    if (value == "Fail") return IQCResultStatus.fail;
    return IQCResultStatus.pending;
  }
}

class IQCResult {
  final int? testId;
  final int batchId;
  final String? testDate; // Dạng ISO String
  final String? testerName;
  
  // Các chỉ số kỹ thuật
  final double? tensileStrength;
  final double? elongation;
  final double? colorFastness;
  
  final IQCResultStatus finalResult;
  final String? note;

  IQCResult({
    this.testId,
    required this.batchId,
    this.testDate,
    this.testerName,
    this.tensileStrength,
    this.elongation,
    this.colorFastness,
    this.finalResult = IQCResultStatus.pending,
    this.note,
  });

  factory IQCResult.fromJson(Map<String, dynamic> json) {
    return IQCResult(
      testId: json['test_id'],
      batchId: json['batch_id'] ?? 0,
      testDate: json['test_date'],
      testerName: json['tester_name'],
      tensileStrength: (json['tensile_strength'] as num?)?.toDouble(),
      elongation: (json['elongation'] as num?)?.toDouble(),
      colorFastness: (json['color_fastness'] as num?)?.toDouble(),
      finalResult: IQCResultStatus.fromJson(json['final_result']),
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'batch_id': batchId,
      'tester_name': testerName,
      'tensile_strength': tensileStrength,
      'elongation': elongation,
      'color_fastness': colorFastness,
      'final_result': finalResult.toJson(),
      'note': note,
    };
    // test_id và test_date thường do Backend tự sinh, không gửi lên khi create
    return data;
  }
}