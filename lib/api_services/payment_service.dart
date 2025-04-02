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
  Future<void> processPayment({
    required int bookingId,
    required double amount,
    required double deposit,
    required PaymentMethod method,
    String? paymentLink,
  }) async {
    try {
      debugPrint(
          "Processing - BookingId: $bookingId, Method: ${method.name}, PaymentLink: $paymentLink");
      switch (method) {
        case PaymentMethod.momo:
          if (paymentLink != null) {
            final Uri uri = Uri.parse(paymentLink);
            debugPrint("Launching Momo deep link: $uri");
            await launchUrl(uri); // Giữ nguyên để mở app Momo
            debugPrint("Momo launched successfully");
          } else {
            throw Exception('Payment link is null');
          }
          break;
        case PaymentMethod.vnPay:
          if (paymentLink != null) {
            final Uri uri = Uri.parse(paymentLink);
            debugPrint("Launching VnPay URL: $uri");
            await launchUrl(
              uri,
              mode: LaunchMode.externalApplication, // Ép mở trong trình duyệt
            );
            debugPrint("VnPay URL launched successfully");
          } else {
            throw Exception('Payment link is null');
          }
          break;
        case PaymentMethod.cash:
        case PaymentMethod.bankTransfer:
          debugPrint("Processed ${method.name} - No URL required");
          break;
      }
    } catch (e) {
      debugPrint('Error processing payment: $e');
      rethrow;
    }
  }
}
