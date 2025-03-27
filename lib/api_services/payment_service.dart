import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';

enum PaymentMethod {
  cash(1, 'Cash'),
  bankTransfer(2, 'BankTransfer'),
  momo(3, 'Momo'),
  vnPay(4, 'VnPay');

  final int value;
  final String name;
  const PaymentMethod(this.value, this.name);
}

class PaymentService {
  Future<void> processPayment(
      {required int bookingId,
      required double amount,
      required double deposit,
      required PaymentMethod method,
      String? paymentLink}) async {
    try {
      debugPrint(
          "PaymentService Step 1: Processing - BookingId: $bookingId, Amount: $amount, Deposit: $deposit, Method: ${method.name}, PyamentLink: $paymentLink");

      // Không gọi POST lại /api/bookings, vì booking đã được tạo
      switch (method) {
        case PaymentMethod.momo:
        case PaymentMethod.vnPay:
          final paymentUrl = paymentLink;
          if (paymentUrl != null && await canLaunchUrl(Uri.parse(paymentUrl))) {
            debugPrint("PaymentService Step 2: Launching URL: $paymentUrl");
            await launchUrl(Uri.parse(paymentUrl));
          } else {
            throw Exception('Unable to launch payment URL: $paymentUrl');
          }
          break;
        case PaymentMethod.cash:
        case PaymentMethod.bankTransfer:
          debugPrint(
              "PaymentService Step 2: Processed ${method.name} - No URL required");
          break;
      }
    } catch (e) {
      debugPrint('PaymentService Step ERROR: Error processing payment: $e');
      rethrow;
    }
  }

// Hàm giả lập để lấy paymentUrl (thay bằng API thật của backend nếu có)
  Future<String?> _fetchPaymentUrl(int bookingId, PaymentMethod method) async {
    // Ví dụ: Gọi API backend để lấy URL thanh toán
    // final response = await http.get(Uri.parse('${Constants.baseUrl}api/payments/$bookingId?urlType=${method.name}'));
    // return jsonDecode(response.body)['paymentUrl'];
    return method == PaymentMethod.momo
        ? "momo://pay?..."
        : "vnpay://pay?..."; // Fake URL cho test
  }

  // Polling để kiểm tra trạng thái thanh toán (nếu cần cho Flutter)
  Future<bool> checkPaymentStatus(int bookingId) async {
    final response = await http
        .get(Uri.parse('${Constants.baseUrl}api/bookings/$bookingId'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['status'] == 2; // Approved
    }
    return false;
  }
}
