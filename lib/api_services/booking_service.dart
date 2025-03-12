import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // Để dùng debugPrint
import '../utils/constants.dart';
import '../models/booking.dart';

class BookingService {
  Future<int> createBooking(BookingDTO booking) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}api/bookings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'memberId': booking.memberId,
          'teamId': booking.teamId,
          'amount': booking.amount,
          'deposit': booking.deposit,
          'voucherId': booking.voucherId,
          'type': booking.type,
          'details': booking.details
                  ?.map((detail) => {
                        'courtId': detail.courtId,
                        'courtName': detail.courtName,
                        'timeSlotId': detail.timeSlotId,
                        'beginAt': detail.beginAt
                            ?.toIso8601String(), // Chuyển sang UTC
                        'endAt': detail.endAt?.toIso8601String(),
                        'dayOfWeek': detail.dayOfWeek, // Giữ thứ theo UTC+7
                        'price': detail.price,
                        'amount': detail.amount,
                      })
                  .toList() ??
              [],
        }),
      );
      debugPrint('Create booking request: ${jsonEncode({
            'memberId': booking.memberId,
            'amount': booking.amount,
            'details': booking.details
                    ?.map((detail) => {
                          'courtId': detail.courtId,
                          'courtName': detail.courtName,
                          'timeSlotId': detail.timeSlotId,
                          'beginAt': detail.beginAt?.toIso8601String(),
                          'endAt': detail.endAt?.toIso8601String(),
                          'dayOfWeek': detail.dayOfWeek,
                          'price': detail.price,
                          'amount': detail.amount,
                        })
                    .toList() ??
                [],
          })}');
      debugPrint(
          'Create booking response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final bookingId = data['id'] as int?;
        if (bookingId != null && bookingId > 0) {
          return bookingId;
        } else {
          throw Exception('Invalid booking ID in response');
        }
      } else {
        throw Exception(
            'Failed to create booking: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error creating booking: $e');
      rethrow;
    }
  }
}
