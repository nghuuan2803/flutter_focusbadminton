import 'package:flutter/material.dart';
import '../api_services/slot_service.dart';
import '../models/slot.dart';
import '../utils/constants.dart';

class SlotCard extends StatefulWidget {
  final Slot schedule;
  final Function(Slot) onSlotUpdate;

  const SlotCard({required this.schedule, required this.onSlotUpdate, Key? key})
      : super(key: key);

  @override
  _SlotCardState createState() => _SlotCardState();
}

class _SlotCardState extends State<SlotCard> {
  late SlotService _slotService;
  final String userId = "1"; // Giả lập, thay bằng logic auth của mày

  @override
  void initState() {
    super.initState();
    _slotService = SlotService();
  }

  Color _getStatusColor() {
    switch (widget.schedule.status) {
      case 0: // Quá giờ
        return Colors.grey;
      case 1: // Trống
        return Colors.white;
      case 2: // Đang giữ
        return widget.schedule.heldBy == userId
            ? Colors.cyan
            : Colors.orange; // Khóa nếu người khác giữ
      case 3: // Đã đặt (Pending)
      case 4: // Đã đặt (Booked)
      case 5: // Đã đặt (Completed)
      case 6: // Đã đặt (Paused)
        return Colors.red;
      case 7: // Chặn
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getDisplayText() {
    switch (widget.schedule.status) {
      case 0:
        return Constants.statusText[0]!;
      case 1:
        return Constants.statusText[1]!;
      case 2:
        return widget.schedule.heldBy == userId
            ? Constants.statusText[2]!
            : "Khóa";
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

  Future<void> _handleClick() async {
    switch (widget.schedule.status) {
      case 1: // Trống -> Đang giữ
        try {
          final holdId = await _slotService.holdSlot(
              courtId: widget.schedule.courtId,
              timeSlotId: widget.schedule.timeSlotId,
              beginAt:
                  widget.schedule.scheduleDate.add(widget.schedule.startTime),
              endAt: widget.schedule.scheduleDate.add(widget.schedule.endTime),
              bookingType: 1,
              dayOfWeek: widget.schedule.dayOfWeek);
          if (holdId > 0) {
            widget.onSlotUpdate(Slot(
              scheduleDate: widget.schedule.scheduleDate,
              dayOfWeek: widget.schedule.dayOfWeek,
              courtId: widget.schedule.courtId,
              courtName: widget.schedule.courtName,
              timeSlotId: widget.schedule.timeSlotId,
              startTime: widget.schedule.startTime,
              endTime: widget.schedule.endTime,
              status: 2,
              holdId: holdId,
              heldBy: userId,
              bookingId: widget.schedule.bookingId,
              bookingDetailId: widget.schedule.bookingDetailId,
            ));
          }
        } catch (e) {
          print("Error holding slot: $e");
        }
        break;

      case 2: // Đang giữ -> Trống (nếu user giữ)
        if (widget.schedule.heldBy == userId) {
          try {
            final success =
                await _slotService.releaseSlot(widget.schedule.holdId!);
            if (success) {
              widget.onSlotUpdate(Slot(
                scheduleDate: widget.schedule.scheduleDate,
                dayOfWeek: widget.schedule.dayOfWeek,
                courtId: widget.schedule.courtId,
                courtName: widget.schedule.courtName,
                timeSlotId: widget.schedule.timeSlotId,
                startTime: widget.schedule.startTime,
                endTime: widget.schedule.endTime,
                status: 1,
                holdId: null,
                heldBy: null,
                bookingId: widget.schedule.bookingId,
                bookingDetailId: widget.schedule.bookingDetailId,
              ));
            }
          } catch (e) {
            print("Error releasing slot: $e");
          }
        }
        break;

      case 3: // Đã đặt (Pending)
      case 4: // Đã đặt (Booked)
      case 5: // Đã đặt (Completed)
      case 6: // Đã đặt (Paused)
      case 7: // Chặn
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Chi tiết đặt sân"),
            content: Text(
              "Booking ID: ${widget.schedule.bookingId ?? 'N/A'}\n"
              "Ngày: ${widget.schedule.scheduleDate.toString().substring(0, 10)}\n"
              "Khung giờ: ${widget.schedule.startTime} - ${widget.schedule.endTime}\n"
              "Người đặt: ${widget.schedule.heldBy ?? 'N/A'}",
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

      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleClick,
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
