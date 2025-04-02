import 'package:flutter/material.dart';
import '../models/slot.dart';
import '../utils/constants.dart';

class SlotCard extends StatelessWidget {
  final Slot schedule;
  final Function(BuildContext, Slot) onSlotUpdate;

  const SlotCard({
    required this.schedule,
    required this.onSlotUpdate,
    Key? key,
  }) : super(key: key);

  static const String userId = "1"; // Giả lập userId

  Color _getStatusColor() {
    switch (schedule.status) {
      case 0:
        return Colors.grey; // Quá giờ
      case 1:
        return Colors.white; // Trống
      case 2:
        return schedule.heldBy == userId
            ? Colors.cyan
            : Colors.orange; // Đang giữ
      case 3:
      case 4:
      case 5:
      case 6:
        return Colors.red; // Đã đặt
      case 7:
        return Colors.orange; // Chặn
      default:
        return Colors.grey;
    }
  }

  String _getDisplayText() {
    switch (schedule.status) {
      case 0:
        return Constants.statusText[0]!;
      case 1:
        return Constants.statusText[1]!;
      case 2:
        return schedule.heldBy == userId ? Constants.statusText[2]! : "Khóa";
      case 3:
      case 4:
      case 5:
      case 6:
        return Constants.statusText[3]!;
      case 7:
        return Constants.statusText[7]!;
      default:
        return "Quá giờ";
    }
  }

  void _handleClick(BuildContext context) {
    switch (schedule.status) {
      case 1: // Trống -> Gửi yêu cầu giữ slot
        onSlotUpdate(context, schedule);
        break;
      case 2: // Đang giữ -> Nhả slot nếu là của user
        if (schedule.heldBy == userId && schedule.holdId != null) {
          onSlotUpdate(context, schedule);
        }
        break;
      case 3:
      case 4:
      case 5:
      case 6:
      case 7: // Đã đặt hoặc chặn -> Hiển thị thông tin
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Chi tiết đặt sân"),
            content: Text(
              "Booking ID: ${schedule.bookingId ?? 'N/A'}\n"
              "Ngày: ${schedule.scheduleDate.toString().substring(0, 10)}\n"
              "Khung giờ: ${schedule.startTimeString} - ${schedule.endTimeString}\n"
              "Người đặt: ${schedule.heldBy ?? 'N/A'}",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Đóng"),
              ),
            ],
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleClick(context),
      child: Container(
        width: 70,
        height: 50,
        decoration: BoxDecoration(
          color: _getStatusColor(),
          border: Border.all(color: Colors.black, width: 0.1),
        ),
        child: Center(
          child: Text(
            _getDisplayText(),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
