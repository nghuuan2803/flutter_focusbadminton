// File: ../models/voucher_template.dart
class VoucherTemplate {
  int id;
  String name;
  String? description;
  String discountType; // Ánh xạ từ DiscountType (0: Fixed, 1: Percent)
  double value;
  double maximumValue;
  int duration;

  VoucherTemplate({
    this.id = 0,
    required this.name,
    this.description,
    this.discountType = 'Percent', // Mặc định là Percent
    this.value = 0.0,
    this.maximumValue = 0.0,
    this.duration = 0,
  });

  factory VoucherTemplate.fromJson(Map<String, dynamic> json) {
    // Ánh xạ DiscountType từ int sang String
    final discountTypeValue =
        json['discountType'] is int ? json['discountType'] : 1;
    final discountTypeString = discountTypeValue == 0 ? 'Fixed' : 'Percent';

    return VoucherTemplate(
      id: json['id'] is int ? json['id'] : 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      discountType: discountTypeString,
      value: (json['value'] is num ? json['value'].toDouble() : 0.0),
      maximumValue:
          (json['maximumValue'] is num ? json['maximumValue'].toDouble() : 0.0),
      duration: json['duration'] is int ? json['duration'] : 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'discountType':
            discountType == 'Fixed' ? 0 : 1, // Chuyển ngược lại thành int
        'value': value,
        'maximumValue': maximumValue,
        'duration': duration,
      };
}
