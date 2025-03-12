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
    this.adminNote,
    this.status = 1,
    this.details,
  });

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
        'Status': status,
        'Details': details?.map((e) => e.toJson()).toList(),
      };
}

class BookingItem {
  int id;
  int courtId;
  String? courtName;
  int timeSlotId;
  DateTime? beginAt;
  DateTime? endAt;
  String? dayOfWeek;
  double price;
  double amount;

  BookingItem({
    this.id = 0,
    required this.courtId,
    this.courtName,
    required this.timeSlotId,
    this.beginAt,
    this.endAt,
    this.dayOfWeek,
    required this.price,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
        'Id': id,
        'CourtId': courtId,
        'CourtName': courtName,
        'TimeSlotId': timeSlotId,
        'BeginAt': beginAt?.toIso8601String(),
        'EndAt': endAt?.toIso8601String(),
        'DayOfWeek': dayOfWeek,
        'Price': price,
        'Amount': amount,
      };
}
