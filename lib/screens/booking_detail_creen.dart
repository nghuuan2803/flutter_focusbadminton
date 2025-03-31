import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api_services/booking_service.dart';
import '../models/booking.dart';

class BookingDetailScreen extends StatefulWidget {
  final int bookingId;

  const BookingDetailScreen({required this.bookingId, Key? key})
      : super(key: key);

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  late Future<BookingDTO> _bookingFuture;
  final BookingService _bookingService = BookingService();
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'VND', decimalDigits: 0);
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _bookingFuture = _bookingService.getBookingDetail(widget.bookingId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết đặt sân #${widget.bookingId}'),
        backgroundColor: Colors.blue[800],
        elevation: 0,
      ),
      body: FutureBuilder<BookingDTO>(
        future: _bookingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(
                child: Text('Không tìm thấy thông tin đặt sân'));
          }

          final booking = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildBookingInfo(booking),
                _buildCourtDetails(booking),
                _buildBackButton(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[800]!, Colors.blue[600]!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: const Text(
        'Thông tin đặt sân',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBookingInfo(BookingDTO booking) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoTile(
                icon: Icons.confirmation_number,
                title: 'Mã đặt sân',
                value: booking.id.toString(),
              ),
              _buildInfoTile(
                icon: Icons.person,
                title: 'Người đặt',
                value: booking.memberName ?? 'Chưa xác định',
              ),
              _buildInfoTile(
                icon: Icons.group,
                title: 'Team',
                value: booking.teamName ?? 'Không có',
              ),
              _buildInfoTile(
                icon: Icons.info,
                title: 'Trạng thái',
                value: _getStatusText(booking.status),
                valueColor: _getStatusColor(booking.status),
              ),
              _buildInfoTile(
                icon: Icons.payment,
                title: 'Phương thức thanh toán',
                value: _getVietnamesePaymentMethod(booking.paymentMethod.name),
              ),
              _buildInfoTile(
                icon: Icons.attach_money,
                title: 'Tổng tiền',
                value: _currencyFormat.format(booking.amount),
              ),
              _buildInfoTile(
                icon: Icons.account_balance_wallet,
                title: 'Tiền cọc',
                value: _currencyFormat.format(booking.deposit),
              ),
              _buildInfoTile(
                icon: Icons.discount,
                title: 'Giảm giá',
                value: _currencyFormat.format(booking.discount),
              ),
              if (booking.note != null)
                _buildInfoTile(
                  icon: Icons.note,
                  title: 'Ghi chú',
                  value: booking.note!,
                ),
              if (booking.adminNote != null)
                _buildInfoTile(
                  icon: Icons.admin_panel_settings,
                  title: 'Ghi chú admin',
                  value: booking.adminNote!,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourtDetails(BookingDTO booking) {
    final groupedDetails = _groupDetailsByTimeSlot(booking.details ?? []);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chi tiết sân',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 8),
          if (groupedDetails.isNotEmpty)
            ...groupedDetails.map((group) => Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 8.0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoTile(
                          icon: Icons.sports_tennis,
                          title: 'Tên sân',
                          value: group['courtName'] ?? 'Chưa xác định',
                        ),
                        _buildInfoTile(
                          icon: Icons.money,
                          title: 'Giá sân',
                          value: _currencyFormat.format(group['price']),
                        ),
                        _buildInfoTile(
                          icon: Icons.access_time,
                          title: 'Thời gian',
                          value:
                              '${_formatDuration(group['startTime'])} - ${_formatDuration(group['endTime'])}',
                        ),
                        ListTile(
                          leading: Icon(Icons.calendar_today,
                              color: Colors.blue[700], size: 24),
                          title: const Text(
                            'Ngày trong tuần',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Wrap(
                              spacing: 8.0,
                              runSpacing: 4.0,
                              children: (group['daysOfWeek'] as List<String>)
                                  .where((day) => day.isNotEmpty)
                                  .map((day) => Chip(
                                        label: Text(
                                          _getVietnameseDayOfWeek(day),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        backgroundColor: Colors.blue[100],
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0),
                                        labelPadding: EdgeInsets.zero,
                                      ))
                                  .toList(),
                            ),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 0),
                        ),
                        _buildInfoTile(
                          icon: Icons.calendar_month,
                          title: 'Ngày bắt đầu',
                          value: _formatDate(group['beginAt']),
                        ),
                        _buildInfoTile(
                          icon: Icons.calendar_month_outlined,
                          title: 'Ngày kết thúc',
                          value: booking.type == 2 && group['endAt'] != null
                              ? _formatDate(group['endAt'])
                              : 'Chưa xác định',
                        ),
                        _buildInfoTile(
                          icon: Icons.account_balance_wallet,
                          title: 'Tiền đặt sân',
                          value: _currencyFormat.format(booking.deposit),
                        ),
                      ],
                    ),
                  ),
                ))
          else
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Không có thông tin chi tiết sân',
                style: TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _groupDetailsByTimeSlot(
      List<BookingItem> details) {
    if (details.isEmpty) return [];

    // Sắp xếp theo timeSlotId để đảm bảo thứ tự
    details.sort((a, b) => a.timeSlotId.compareTo(b.timeSlotId));

    List<Map<String, dynamic>> grouped = [];
    List<BookingItem> currentGroup = [];

    for (var i = 0; i < details.length; i++) {
      final curr = details[i];
      if (i == 0) {
        currentGroup.add(curr);
      } else {
        final prev = details[i - 1];
        // Kiểm tra nếu cùng courtName và timeSlotId liên tiếp hoặc cùng timeSlotId
        if (curr.courtName == prev.courtName &&
            (curr.timeSlotId == prev.timeSlotId ||
                (curr.timeSlotId == prev.timeSlotId + 1 &&
                    curr.startTime == prev.endTime))) {
          currentGroup.add(curr);
        } else {
          grouped.add(_createGroup(currentGroup));
          currentGroup = [curr];
        }
      }
    }

    // Thêm nhóm cuối cùng
    if (currentGroup.isNotEmpty) {
      grouped.add(_createGroup(currentGroup));
    }

    print('Grouped Details: $grouped'); // Debug log
    return grouped;
  }

  Map<String, dynamic> _createGroup(List<BookingItem> group) {
    group.sort((a, b) => a.timeSlotId.compareTo(b.timeSlotId));
    print('Group: ${group.map((e) => e.toJson()).toList()}'); // Debug log
    return {
      'courtName': group.first.courtName,
      'startTime': group.first.startTime,
      'endTime': group.last.endTime,
      'beginAt': group.first.beginAt,
      'endAt': group.last.endAt,
      'price': group.first.price,
      'daysOfWeek': group.map((item) => item.dayOfWeek ?? '').toSet().toList(),
    };
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'Chưa xác định';
    return _dateFormat.format(dateTime);
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return 'Chưa xác định';
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  String _getVietnameseDayOfWeek(String day) {
    switch (day.toLowerCase()) {
      case 'monday':
        return 'Thứ Hai';
      case 'tuesday':
        return 'Thứ Ba';
      case 'wednesday':
        return 'Thứ Tư';
      case 'thursday':
        return 'Thứ Năm';
      case 'friday':
        return 'Thứ Sáu';
      case 'saturday':
        return 'Thứ Bảy';
      case 'sunday':
        return 'Chủ Nhật';
      default:
        return day;
    }
  }

  String _getVietnamesePaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Tiền mặt';
      case 'banktransfer':
      case 'bank_transfer':
        return 'Chuyển khoản ngân hàng';
      case 'momo':
        return 'MoMo';
      case 'vnpay':
      case 'vn_pay':
        return 'VNPay';
      default:
        return method;
    }
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue[700], size: 24),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 14,
          color: valueColor ?? Colors.black87,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 0),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text(
            'Quay lại',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
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
}
