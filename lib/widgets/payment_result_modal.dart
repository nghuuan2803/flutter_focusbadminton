import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api_services/booking_service.dart';
import '../main_screen.dart';
import '../models/booking.dart';
import '../screens/booking_detail_screen.dart';

class PaymentResultModal extends StatefulWidget {
  final bool isSuccess;
  final int bookingId;

  const PaymentResultModal({
    required this.isSuccess,
    required this.bookingId,
    Key? key,
  }) : super(key: key);

  @override
  _PaymentResultModalState createState() => _PaymentResultModalState();
}

class _PaymentResultModalState extends State<PaymentResultModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Future<BookingDTO> _bookingFuture;

  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'VND', decimalDigits: 0);
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final BookingService _bookingService = BookingService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _bookingFuture = _bookingService.getBookingDetail(widget.bookingId);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: screenWidth * 0.9,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Colors.grey[50]!,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: FutureBuilder<BookingDTO>(
            future: _bookingFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _buildContent(
                  errorMessage: 'Lỗi tải thông tin: ${snapshot.error}',
                );
              }
              if (!snapshot.hasData) {
                return _buildContent(errorMessage: 'Không tìm thấy thông tin');
              }

              final booking = snapshot.data!;
              return _buildContent(booking: booking);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent({BookingDTO? booking, String? errorMessage}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Header với icon và tiêu đề
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.isSuccess ? Colors.green[50] : Colors.red[50],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.isSuccess ? Icons.check_circle : Icons.error,
                color: widget.isSuccess ? Colors.green : Colors.red,
                size: 40,
              ),
              const SizedBox(width: 12),
              Text(
                widget.isSuccess ? 'Đặt thành công' : 'Đặt thất bại',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: widget.isSuccess ? Colors.green[800] : Colors.red[800],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Thông tin chi tiết
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          )
        else if (booking != null) ...[
          _buildInfoRow(
            icon: Icons.confirmation_number,
            label: 'Mã đặt sân',
            value: booking.id.toString(),
          ),
          const Divider(height: 20),
          _buildInfoRow(
            icon: Icons.attach_money,
            label: 'Số tiền thanh toán',
            value: _currencyFormat.format(booking.amount),
          ),
          const Divider(height: 20),
          _buildInfoRow(
            icon: Icons.calendar_today,
            label: 'Ngày thanh toán',
            value: booking.completedAt != null
                ? _dateFormat.format(booking.completedAt!)
                : _dateFormat.format(DateTime.now()),
          ),
          const Divider(height: 20),
          _buildInfoRow(
            icon: Icons.info,
            label: 'Trạng thái',
            value: _getStatusText(booking.status),
            valueColor:
                _getStatusColor(booking.status), // Thêm màu cho trạng thái
          ),
        ],
        const SizedBox(height: 24),
        // Nút điều hướng
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MainScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[700],
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
              ),
              child: const Text(
                'Quay lại',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        BookingDetailScreen(bookingId: widget.bookingId),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
              ),
              child: const Text(
                'Chi tiết',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Colors.blueGrey[700],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
}
