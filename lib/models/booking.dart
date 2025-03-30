import 'package:focus_badminton/models/voucher.dart';

import '../api_services/payment_service.dart';

class BookingDTO {
  int id;
  int memberId;
  String? memberName;
  int? teamId;
  String? teamName;
  int type;
  DateTime? approvedAt;
  DateTime? completedAt;
  double amount;
  double deposit;
  int? voucherId;
  int? promotionId;
  double discount;
  DateTime? pausedDate;
  DateTime? resumeDate;
  String? note;
  String? adminNote;
  int status;
  PaymentMethod paymentMethod;
  String? paymentLink;
  List<BookingItem>? details;

  BookingDTO({
    this.id = 0,
    required this.memberId,
    this.memberName,
    this.teamId,
    this.teamName,
    this.type = 1,
    this.approvedAt,
    this.completedAt,
    this.amount = 0.0,
    this.deposit = 0.0,
    this.voucherId,
    this.promotionId,
    this.discount = 0.0,
    this.pausedDate,
    this.resumeDate,
    this.note,
    required this.paymentMethod,
    this.paymentLink,
    this.adminNote,
    this.status = 1,
    this.details,
  });

  void applyVoucher(Voucher? voucher) {
    if (voucher == null ||
        voucher.isUsed ||
        (voucher.expiry != null && voucher.expiry!.isBefore(DateTime.now()))) {
      discount = 0.0;
      voucherId = null;
      return;
    }

    voucherId = voucher.id;
    if (voucher.discountType == "Percent") {
      discount = amount * (voucher.value / 100);
      if (voucher.maximumValue > 0 && discount > voucher.maximumValue) {
        discount = voucher.maximumValue;
      }
    } else {
      discount = voucher.value; // Giả sử là giá trị cố định
      if (voucher.maximumValue > 0 && discount > voucher.maximumValue) {
        discount = voucher.maximumValue;
      }
    }
    // Đảm bảo discount không vượt quá amount
    if (discount > amount) discount = amount;
  }

  Map<String, dynamic> toJson() => {
        'Id': id,
        'MemberId': memberId,
        'MemberName': memberName,
        'TeamId': teamId,
        'TeamName': teamName,
        'Type': type,
        'ApprovedAt': approvedAt?.toIso8601String(),
        'CompletedAt': completedAt?.toIso8601String(),
        'Amount': amount,
        'Deposit': deposit,
        'VoucherId': voucherId,
        'PromotionId': promotionId,
        'Discount': discount,
        'PausedDate': pausedDate?.toIso8601String(),
        'ResumeDate': resumeDate?.toIso8601String(),
        'Note': note,
        'AdminNote': adminNote,
        'paymentLink': paymentLink,
        'Status': status,
        'Details': details?.map((e) => e.toJson()).toList(),
      };
}

class BookingItem {
  int id;
  int courtId;
  String? courtName;
  int timeSlotId;
  Duration? startTime;
  Duration? endTime;
  DateTime? beginAt;
  DateTime? endAt;
  String? dayOfWeek;
  double price;
  double amount;
  final int? holdId;

  BookingItem({
    this.id = 0,
    required this.courtId,
    this.courtName,
    required this.timeSlotId,
    this.startTime,
    this.endTime,
    this.beginAt,
    this.endAt,
    this.dayOfWeek,
    required this.price,
    required this.amount,
    this.holdId,
  });

  factory BookingItem.fromJson(Map<String, dynamic> json) {
    print('Parsing BookingItem: $json'); // Debug log
    return BookingItem(
      id: json['id'] ?? 0,
      courtId: json['courtId'] ?? 0,
      courtName: json['courtName'],
      timeSlotId: json['timeSlotId'] ?? 0,
      startTime:
          json['startTime'] != null ? _parseTimeSpan(json['startTime']) : null,
      endTime: json['endTime'] != null ? _parseTimeSpan(json['endTime']) : null,
      beginAt: json['beginAt'] != null
          ? DateTime.parse(json['beginAt']).toLocal()
          : null,
      endAt: json['endAt'] != null
          ? DateTime.parse(json['endAt']).toLocal()
          : null,
      dayOfWeek: json['dayOfWeek'],
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      holdId: json['holdId'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'courtId': courtId,
        'courtName': courtName,
        'timeSlotId': timeSlotId,
        'startTime': startTime != null
            ? '${startTime!.inHours.toString().padLeft(2, '0')}:${(startTime!.inMinutes % 60).toString().padLeft(2, '0')}'
            : null,
        'endTime': endTime != null
            ? '${endTime!.inHours.toString().padLeft(2, '0')}:${(endTime!.inMinutes % 60).toString().padLeft(2, '0')}'
            : null,
        'beginAt': beginAt?.toIso8601String(),
        'endAt': endAt?.toIso8601String(),
        'dayOfWeek': dayOfWeek,
        'price': price,
        'amount': amount,
        'holdId': holdId,
      };

  static Duration? _parseTimeSpan(String? timeSpan) {
    if (timeSpan == null) return null;
    print('Parsing TimeSpan: $timeSpan'); // Debug log
    final parts = timeSpan.split(':');
    if (parts.length >= 2) {
      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;
      final seconds = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;
      final duration =
          Duration(hours: hours, minutes: minutes, seconds: seconds);
      print('Parsed Duration: $duration'); // Debug log
      return duration;
    }
    return null;
  }
}
