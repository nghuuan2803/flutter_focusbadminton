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

  static String formatDateTime(DateTime date) {
    try {
      String formattedDate = DateFormat('dd/MM/yyyy').format(date);
      return formattedDate;
    } catch (e) {
      return '01-01-0001';
    }
  }

  static String formatDateString(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      String formattedDate = DateFormat('dd/MM/yyyy').format(date);
      return formattedDate;
    } catch (e) {
      return '01-01-0001';
    }
  }
}
