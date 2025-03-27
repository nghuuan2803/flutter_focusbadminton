import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class SlotService {
  final String baseUrl = "${Constants.baseUrl}api";
  final String userId = "1"; // Giả lập userId, thay bằng logic lấy từ auth

  // Giữ slot
  Future<int> holdSlot({
    required int courtId,
    required int timeSlotId,
    required DateTime beginAt,
    DateTime? endAt, // Có thể null nếu là đặt không xác định kết thúc
    String? dayOfWeek, // Dùng cho đặt cố định
    required int bookingType, // 1: InDay, 2: Fixed with end, 3: Fixed no end
  }) async {
    final url = '$baseUrl/slot/hold';
    final body = jsonEncode({
      'CourtId': courtId,
      'TimeSlotId': timeSlotId,
      'HoldBy': userId,
      'BookingType': bookingType,
      'BeginAt': beginAt.toIso8601String(),
      if (endAt != null) 'EndAt': endAt.toIso8601String(),
      'DayOfWeek': dayOfWeek,
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['holdId'] as int;
      } else {
        throw Exception('Failed to hold slot: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error holding slot: $e');
    }
  }

  // Nhả slot
  Future<bool> releaseSlot(int holdId) async {
    final url = '$baseUrl/slot/release';
    print('Url called: $url');
    final body = jsonEncode({
      'HoldId': holdId,
      'HeldBy': userId,
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to release slot: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error releasing slot: $e');
    }
  }

  Future<bool> releaseMultipleSlots(List<int> holdIds) async {
    final url = '$baseUrl/slot/release-multi';
    print('Url called: $url');
    final body = jsonEncode({
      'HoldIds': holdIds,
      'HeldBy': userId,
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception(
            'Failed to release multiple slots: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error releasing multiple slots: $e');
    }
  }
}
