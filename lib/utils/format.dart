import 'package:intl/intl.dart';

class Format {
  static String formatVNCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN', // Locale Việt Nam
      symbol: 'VND', // Đơn vị tiền tệ
      decimalDigits: 0, // Không hiển thị số thập phân
    );
    return formatter.format(amount);
  }
}
