class TimeSlotDTO {
  final int id;
  final Duration startTime;
  final Duration endTime;
  final double price;
  final double duration;
  final bool isApplied;
  final bool isDeleted;

  TimeSlotDTO({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.price,
    required this.duration,
    required this.isApplied,
    required this.isDeleted,
  });

  factory TimeSlotDTO.fromJson(Map<String, dynamic> json) {
    print('Parsing TimeSlot: $json'); // Debug JSON từng slot
    return TimeSlotDTO(
      id: json['id'] ?? json['Id'] ?? 0, // Hỗ trợ cả "id" và "Id"
      startTime: _parseTimeSpan(json['startTime'] ?? json['StartTime']),
      endTime: _parseTimeSpan(json['endTime'] ?? json['EndTime']),
      price: (json['price'] ?? json['Price'] as num?)?.toDouble() ?? 50000,
      duration:
          (json['duration'] ?? json['Duration'] as num?)?.toDouble() ?? 1.0,
      isApplied: json['isApplied'] ?? json['IsApplied'] ?? true,
      isDeleted: json['isDeleted'] ?? json['IsDeleted'] ?? false,
    );
  }

  static Duration _parseTimeSpan(String? timeSpan) {
    if (timeSpan == null || timeSpan.isEmpty) {
      print('TimeSpan null or empty, defaulting to 00:00');
      return const Duration(hours: 0);
    }
    try {
      final parts = timeSpan.split(':');
      if (parts.length != 3) {
        print('Invalid TimeSpan format: $timeSpan');
        return const Duration(hours: 0);
      }
      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;
      final seconds = int.tryParse(parts[2]) ?? 0;
      print('Parsed TimeSpan $timeSpan -> $hours:$minutes:$seconds');
      return Duration(hours: hours, minutes: minutes, seconds: seconds);
    } catch (e) {
      print('Error parsing TimeSpan $timeSpan: $e');
      return const Duration(hours: 0);
    }
  }

  String get startTimeString => _formatDuration(startTime);
  String get endTimeString => _formatDuration(endTime);

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    return "$hours:$minutes";
  }
}
