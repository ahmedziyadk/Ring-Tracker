class SharedOrderDraft {
  final String customerName;
  final String phoneNumber;
  final String stoneType;
  final String makingType;
  final String ringSize;
  final String totalAmount;
  final String advanceAmount;
  final bool urgent;
  final String note;
  final List<String> imagePaths;
  final String rawText;

  const SharedOrderDraft({
    this.customerName = '',
    this.phoneNumber = '',
    this.stoneType = '',
    this.makingType = 'Ring',
    this.ringSize = '',
    this.totalAmount = '',
    this.advanceAmount = '',
    this.urgent = false,
    this.note = '',
    this.imagePaths = const [],
    this.rawText = '',
  });

  SharedOrderDraft copyWith({
    String? customerName,
    String? phoneNumber,
    String? stoneType,
    String? makingType,
    String? ringSize,
    String? totalAmount,
    String? advanceAmount,
    bool? urgent,
    String? note,
    List<String>? imagePaths,
    String? rawText,
  }) {
    return SharedOrderDraft(
      customerName: customerName ?? this.customerName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      stoneType: stoneType ?? this.stoneType,
      makingType: makingType ?? this.makingType,
      ringSize: ringSize ?? this.ringSize,
      totalAmount: totalAmount ?? this.totalAmount,
      advanceAmount: advanceAmount ?? this.advanceAmount,
      urgent: urgent ?? this.urgent,
      note: note ?? this.note,
      imagePaths: imagePaths ?? this.imagePaths,
      rawText: rawText ?? this.rawText,
    );
  }
}
