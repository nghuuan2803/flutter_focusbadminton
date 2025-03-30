// File: ../services/voucher_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/voucher.dart';

class VoucherService {
  final String baseUrl = "${Constants.baseUrl}api";
  final String userId = "1";

  // Lấy danh sách voucher
  Future<List<Voucher>> getVouchers(int memberId) async {
    final url = '$baseUrl/Vouchers/get-by-member/$memberId';
    print('Url called: $url');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data.map((json) => Voucher.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load vouchers: ${response.statusCode}');
      }
    } catch (e) {
      print('Error details: $e');
      throw Exception('Error fetching vouchers: $e');
    }
  }
}
