import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'auth_service.dart';

class SlotService {
  final String baseUrl = "${Constants.baseUrl}api";

  // Giữ slot
  Future<Map<String, dynamic>> holdSlot({
    required int courtId,
    required int timeSlotId,
    required DateTime beginAt,
    DateTime? endAt,
    String? dayOfWeek,
    required int bookingType,
  }) async {
    final memberId = await AuthService.getMemberId();
    print("hold slot service - memberId: $memberId");
    final url = '$baseUrl/slot/hold';
    final body = jsonEncode({
      'CourtId': courtId,
      'TimeSlotId': timeSlotId,
      'HoldBy': memberId,
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
        return {
          'holdId': body['holdId'] as int,
          'estimatedCost': (body['estimatedCost'] as num).toDouble(),
        };
      } else {
        throw Exception('Failed to hold slot: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error holding slot: $e');
    }
  }

  // Nhả slot
  Future<bool> releaseSlot(int holdId) async {
    final memberId = await AuthService.getMemberId();
    final url = '$baseUrl/slot/release';
    print('Url called: $url');
    final body = jsonEncode({
      'HoldId': holdId,
      'HeldBy': memberId,
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
    final memberId = await AuthService.getMemberId();
    final url = '$baseUrl/slot/release-multi';
    print('Url called: $url');
    final body = jsonEncode({
      'HoldIds': holdIds,
      'HeldBy': memberId,
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
