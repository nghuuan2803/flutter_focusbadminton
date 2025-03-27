class Voucher {
  int id;
  String name;
  String? description;
  String discountType;
  double value;
  double maximumValue;
  int? voucherTemplateId;
  String? accountId;
  DateTime? expiry;
  bool isUsed;
  String? code;

  Voucher({
    this.id = 0,
    required this.name,
    this.description,
    required this.discountType,
    this.value = 0.0,
    this.maximumValue = 0.0,
    this.voucherTemplateId,
    this.accountId,
    this.expiry,
    this.isUsed = false,
    this.code,
  });

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      id: json['id'] is int ? json['id'] : 0, // Đảm bảo id là int
      name: json['name']?.toString() ?? '', // Chuyển đổi và xử lý null
      description: json['description']?.toString(), // Nullable
      discountType:
          json['discountType']?.toString() ?? 'Percent', // Mặc định "Percent"
      value: (json['value'] is num
          ? json['value'].toDouble()
          : 0.0), // Đảm bảo double
      maximumValue:
          (json['maximumValue'] is num ? json['maximumValue'].toDouble() : 0.0),
      voucherTemplateId:
          json['voucherTemplateId'] is int ? json['voucherTemplateId'] : null,
      accountId: json['accountId']?.toString(),
      expiry: json['expiry'] != null
          ? DateTime.tryParse(json['expiry'])
          : null, // Xử lý nullable
      isUsed: json['isUsed'] is bool ? json['isUsed'] : false,
      code: json['code']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'discountType': discountType,
        'value': value,
        'maximumValue': maximumValue,
        'voucherTemplateId': voucherTemplateId,
        'accountId': accountId,
        'expiry': expiry?.toIso8601String(),
        'isUsed': isUsed,
        'code': code,
      };
}
