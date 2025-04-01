class Slot {
  final DateTime scheduleDate;
  final String? dayOfWeek;
  final int courtId;
  final String? courtName;
  final int timeSlotId;
  final Duration startTime;
  final Duration endTime;
  final int status;
  final int? holdId;
  final String? heldBy;
  final int? bookingId;
  final int? bookingDetailId;

  Slot({
    required this.scheduleDate,
    this.dayOfWeek,
    required this.courtId,
    this.courtName,
    required this.timeSlotId,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.holdId,
    this.heldBy,
    this.bookingId,
    this.bookingDetailId,
  });

  factory Slot.fromJson(Map<String, dynamic> json) {
    return Slot(
      scheduleDate:
          DateTime.parse(json['scheduleDate']), // Key viết thường trong JSON
      dayOfWeek: json['dayOfWeek'],
      courtId: json['courtId'],
      courtName: json['courtName'],
      timeSlotId: json['timeSlotId'],
      startTime: _parseTimeSpan(json['startTime']),
      endTime: _parseTimeSpan(json['endTime']),
      status: json['status'],
      holdId: json['holdId'],
      heldBy: json['heldBy'],
      bookingId: json['bookingId'],
      bookingDetailId: json['bookingDetailId'],
    );
  }

  static Duration _parseTimeSpan(String timeSpan) {
    final parts = timeSpan.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    final seconds = int.parse(parts[2]);
    return Duration(hours: hours, minutes: minutes, seconds: seconds);
  }

  String get startTimeString => _formatDuration(startTime);
  String get endTimeString => _formatDuration(endTime);

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    return "$hours:$minutes";
  }
}
