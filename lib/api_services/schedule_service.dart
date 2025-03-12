import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/schedule.dart';
import '../utils/constants.dart';

class ScheduleService {
  final String baseUrl = "${Constants.baseUrl}api";

  // Lấy lịch sân trong khoảng thời gian
  Future<List<Schedule>> getCourtSchedulesInRange(
      int courtId, DateTime startDate, DateTime endDate) async {
    final url =
        '$baseUrl/schedules/court-range?CourtId=$courtId&StartDate=${_formatDate(startDate)}&EndDate=${_formatDate(endDate)}';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      print("Raw JSON: $data"); // Debug JSON
      return data.map((json) => Schedule.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load schedules: ${response.statusCode}');
    }
  }

  Future<List<int>> checkMultiDayAvailable(int courtId, DateTime startDate,
      DateTime? endDate, List<String> daysOfWeek) async {
    final response = await http.post(
      Uri.parse('${Constants.baseUrl}api/slot/check-multi-day-available'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'CourtId': courtId,
        'StartDate': startDate.toIso8601String(),
        'EndDate': endDate?.toIso8601String(),
        'DaysOfWeek': daysOfWeek,
      }),
    );
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List)
          .map((id) => id as int)
          .toList();
    }
    throw Exception('Failed to check available slots');
  }

  // Format ngày thành yyyy-MM-dd
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
