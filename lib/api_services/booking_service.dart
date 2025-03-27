import 'dart:convert';
import 'package:focus_badminton/api_services/payment_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // Để dùng debugPrint
import '../utils/constants.dart';
import '../models/booking.dart';

class BookingService {
  Future<dynamic> createBooking(BookingDTO booking) async {
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
          'paymentMethod': booking.paymentMethod.value,
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
          return response.body;
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

  Future<void> cancelBooking(int bookingId) async {
    final response = await http.post(
        Uri.parse('${Constants.baseUrl}api/bookings/cancel'),
        body: jsonEncode({"bookingId": bookingId}));
    if (response.statusCode != 200) {
      throw Exception('Failed to cancel booking: ${response.statusCode}');
    }
  }

  Future<dynamic> getBookingInfo(int id) async {
    final resposne =
        await http.get(Uri.parse('${Constants.baseUrl}api/bookings/$id'));
    if (resposne.statusCode == 200) {
      final data = jsonDecode(resposne.body);
      if (data != null) return data;
    }
    throw Exception('Fail to load booking info id: $id');
  }

  Future<List<BookingDTO>> getBookingHistory(int memberId) async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}api/bookings/history/$memberId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => _parseBookingDTO(json)).toList();
      }
      throw Exception('Failed to load booking history');
    } catch (e) {
      debugPrint('Error fetching booking history: $e');
      rethrow;
    }
  }

  Future<BookingDTO> getBookingDetail(int bookingId) async {
    try {
      final response = await getBookingInfo(bookingId);
      // response đã là Map<String, dynamic> từ getBookingInfo
      // Kiểm tra xem có key 'data' hay không
      final json =
          response is Map<String, dynamic> && response.containsKey('data')
              ? response['data']
              : response;
      return _parseBookingDTO(json);
    } catch (e) {
      debugPrint('Error fetching booking detail: $e');
      rethrow;
    }
  }

  BookingDTO _parseBookingDTO(Map<String, dynamic> json) {
    return BookingDTO(
      id: json['id'] ?? 0,
      memberId: json['memberId'] ?? 0,
      memberName: json['memberName'],
      teamId: json['teamId'],
      teamName: json['teamName'],
      type: json['type'] ?? 1,
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      amount: (json['amount'] ?? 0.0).toDouble(),
      deposit: (json['deposit'] ?? 0.0).toDouble(),
      voucherId: json['voucherId'],
      promotionId: json['promotionId'],
      discount: (json['discount'] ?? 0.0).toDouble(),
      pausedDate: json['pausedDate'] != null
          ? DateTime.parse(json['pausedDate'])
          : null,
      resumeDate: json['resumeDate'] != null
          ? DateTime.parse(json['resumeDate'])
          : null,
      note: json['note'],
      adminNote: json['adminNote'],
      status: json['status'] ?? 1,
      paymentMethod: PaymentMethod.values
          .firstWhere((e) => e.value == json['paymentMethod']),
      paymentLink: json['paymentLink'],
      details: (json['details'] as List<dynamic>?)
          ?.map((item) => BookingItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

// Helper method to parse BookingItem
  BookingItem _parseBookingItem(Map<String, dynamic> json) {
    return BookingItem(
      id: json['id'] ?? 0,
      courtId: json['courtId'] ?? 0,
      courtName: json['courtName'],
      timeSlotId: json['timeSlotId'] ?? 0,
      beginAt: json['beginAt'] != null ? DateTime.parse(json['beginAt']) : null,
      endAt: json['endAt'] != null ? DateTime.parse(json['endAt']) : null,
      dayOfWeek: json['dayOfWeek'],
      price: (json['price'] ?? 0.0).toDouble(),
      amount: (json['amount'] ?? 0.0).toDouble(),
    );
  }
}
