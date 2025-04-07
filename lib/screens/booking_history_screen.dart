import 'package:flutter/material.dart';
import 'package:focus_badminton/main_screen.dart';
import 'package:focus_badminton/screens/profile_screen.dart';
import 'package:focus_badminton/utils/colors.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart';
import '../api_services/booking_service.dart';
import 'booking_detail_screen.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({Key? key}) : super(key: key);

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  late Future<List<BookingDTO>> _bookingHistoryFuture;
  final BookingService _bookingService = BookingService();
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'VND', decimalDigits: 0);
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _bookingHistoryFuture = _bookingService.getBookingHistory();
  }

  void _refreshHistory() {
    setState(() {
      _bookingHistoryFuture = _bookingService.getBookingHistory();
    });
  }

  void _handlePop() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể quay lại')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Ngăn pop mặc định
      onPopInvoked: (didPop) {
        if (!didPop) {
          _handlePop(); // Gọi logic điều hướng khi bấm back
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lịch sử đặt sân'),
          backgroundColor: AppColors.accent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handlePop, // Gọi hàm xử lý back khi bấm nút trên AppBar
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: FutureBuilder<List<BookingDTO>>(
                future: _bookingHistoryFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _buildErrorState(snapshot.error);
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState();
                  }

                  final bookings = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final booking = bookings[index];
                      return _buildBookingItem(booking);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingItem(BookingDTO booking) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookingDetailScreen(bookingId: booking.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    _getStatusColor(booking.status).withOpacity(0.1),
                child: Icon(
                  Icons.sports_tennis,
                  color: _getStatusColor(booking.status),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking #${booking.id}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sân: ${booking.details?.first.courtName ?? 'Chưa xác định'}',
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    Text(
                      'Ngày: ${_formatDateTime(booking.details?.first.beginAt)}',
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    Text(
                      'Loại: ${_getTypeText(booking.type)}',
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    Text(
                      'Trạng thái: ${_getStatusText(booking.status)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: _getStatusColor(booking.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _currencyFormat.format(booking.amount),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(Object? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Lỗi: $error',
            style: const TextStyle(fontSize: 16, color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshHistory,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Tải lại',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history_toggle_off, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Không có lịch sử đặt sân',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshHistory,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Tải lại',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Chưa xác định';
    return _dateFormat.format(dateTime);
  }

  String _getStatusText(int status) {
    switch (status) {
      case 1:
        return 'Đang chờ';
      case 2:
        return 'Đã duyệt';
      case 3:
        return 'Tạm dừng';
      case 4:
        return 'Hoàn thành';
      case 5:
        return 'Đã hủy';
      case 6:
        return 'Từ chối';
      default:
        return 'Không xác định';
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
        return Colors.orange;
      case 2:
        return Colors.green;
      case 3:
        return Colors.blue;
      case 4:
        return Colors.teal;
      case 5:
        return Colors.red;
      case 6:
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  String _getTypeText(int type) {
    switch (type) {
      case 1:
        return 'Đặt trong ngày';
      case 2:
        return 'Đặt cố định';
      case 3:
        return 'Đặt cố định (Không giới hạn)';
      default:
        return 'Không xác định';
    }
  }
}
