import 'package:flutter/material.dart';
import '../api_services/schedule_service.dart';
import '../api_services/signalr_service.dart';
import '../api_services/slot_service.dart';
import '../models/schedule.dart';
import '../widgets/slot_card.dart';
// import 'package:flutter/foundation.dart'; // Để debugPrint
import '../models/booking.dart';
import '../api_services/booking_service.dart';

class ScheduleScreen extends StatefulWidget {
  final int courtId;

  const ScheduleScreen({required this.courtId, Key? key}) : super(key: key);

  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late ScheduleService _scheduleService;
  late SignalRService _signalRService;
  late SlotService _slotService;
  late BookingService _bookingService;
  List<Schedule> schedules = [];
  List<Duration> timeSlots = [];
  bool isLoading = true;
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now().add(const Duration(days: 6));
  bool isTimeSlotVertical = false;
  BookingDTO? currentBooking;
  final List<BookingItem> selectedSlots = [];
  final int memberId = 1; // Giả lập user ID
  final double pricePerSlot = 100000; // Giả lập giá16
  PersistentBottomSheetController? _bottomSheetController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _getVietnameseDayOfWeek(DateTime date) {
    switch (date.weekday) {
      case 1:
        return "Thứ 2";
      case 2:
        return "Thứ 3";
      case 3:
        return "Thứ 4";
      case 4:
        return "Thứ 5";
      case 5:
        return "Thứ 6";
      case 6:
        return "Thứ 7";
      case 7:
        return "CN";
      default:
        return "N/A";
    }
  }

  String _getEnglishDayOfWeek(DateTime date) {
    switch (date.weekday) {
      case 1:
        return "Monday";
      case 2:
        return "Tuesday";
      case 3:
        return "Wednesday";
      case 4:
        return "Thursday";
      case 5:
        return "Friday";
      case 6:
        return "Saturday";
      case 7:
        return "Sunday";
      default:
        return "N/A";
    }
  }

  @override
  void initState() {
    super.initState();
    _scheduleService = ScheduleService();
    _signalRService = SignalRService();
    _slotService = SlotService();
    _bookingService = BookingService();
    _setupSignalR();
    _loadSchedules();
  }

  void _setupSignalR() {
    _signalRService.onSlotHeld = _handleSlotHeld;
    _signalRService.onSlotReleased = _handleSlotReleased;
    _signalRService.onBookingCreated = _handleBookingCreated;
    _signalRService.startConnection();
  }

  Future<void> _loadSchedules() async {
    setState(() => isLoading = true);
    try {
      print(
          "Loading schedules for courtId: ${widget.courtId}, startDate: $startDate, endDate: $endDate");
      schedules = await _scheduleService.getCourtSchedulesInRange(
        widget.courtId,
        startDate,
        endDate,
      );
      timeSlots = schedules.map((s) => s.startTime).toSet().toList()
        ..sort((a, b) => a.inMinutes.compareTo(b.inMinutes));
    } catch (e) {
      debugPrint("Error loading schedules: $e");
    }
    setState(() => isLoading = false);
  }

  void _updateSlot(Schedule updatedSlot) {
    setState(() {
      final index = schedules.indexWhere(
        (s) =>
            s.timeSlotId == updatedSlot.timeSlotId &&
            _isSameDay(s.scheduleDate, updatedSlot.scheduleDate),
      );
      if (index != -1) {
        schedules[index] = updatedSlot;
        if (updatedSlot.status == 2 && updatedSlot.heldBy == "1") {
          // Tính beginAt theo local UTC+7
          final beginAtLocal =
              updatedSlot.scheduleDate.add(updatedSlot.startTime);
          // Lấy dayOfWeek theo UTC+7
          final beginAtUtc7 = beginAtLocal.toLocal(); // Đảm bảo local là UTC+7
          final dayOfWeek = _getEnglishDayOfWeek(beginAtUtc7);

          final bookingItem = BookingItem(
            courtId: updatedSlot.courtId,
            courtName: updatedSlot.courtName,
            timeSlotId: updatedSlot.timeSlotId,
            beginAt: beginAtLocal, // Giữ local để gửi lên API
            endAt: updatedSlot.scheduleDate.add(updatedSlot.endTime),
            dayOfWeek: dayOfWeek, // Thứ theo UTC+7
            price: pricePerSlot,
            amount: pricePerSlot,
          );
          selectedSlots.add(bookingItem);
          debugPrint(
              'Added slot to selected: ${bookingItem.beginAt} - ${bookingItem.dayOfWeek}');

          if (currentBooking == null) {
            currentBooking = BookingDTO(
              memberId: memberId,
              amount: pricePerSlot * selectedSlots.length,
              details: selectedSlots,
            );
          } else {
            currentBooking!.details = selectedSlots;
            currentBooking!.amount = pricePerSlot * selectedSlots.length;
          }
          debugPrint('Updated booking amount: ${currentBooking!.amount}');

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_bottomSheetController == null && selectedSlots.isNotEmpty) {
              _showPersistentBottomSheet();
            } else if (_bottomSheetController != null) {
              _bottomSheetController!.setState!(() {});
            }
          });
        }
      }
    });
  }

  void _handleSlotHeld(dynamic payload) {
    final slotData = payload as Map<String, dynamic>;
    final courtId = slotData['courtId'] as int?;
    if (courtId != widget.courtId) return;

    final scheduleDate =
        DateTime.parse(slotData['beginAt'] as String).toLocal();
    final timeSlotId = slotData['timeSlotId'] as int?;
    final holdId = slotData['holdSlotId'] as int?;
    final heldBy = slotData['heldBy'] as String?;

    setState(() {
      final index = schedules.indexWhere(
        (s) =>
            s.timeSlotId == timeSlotId &&
            _isSameDay(s.scheduleDate, scheduleDate),
      );
      if (index != -1) {
        schedules[index] = Schedule(
          scheduleDate: schedules[index].scheduleDate,
          dayOfWeek: schedules[index].dayOfWeek,
          courtId: schedules[index].courtId,
          courtName: schedules[index].courtName,
          timeSlotId: schedules[index].timeSlotId,
          startTime: schedules[index].startTime,
          endTime: schedules[index].endTime,
          status: 2,
          holdId: holdId,
          heldBy: heldBy,
          bookingId: null,
          bookingDetailId: null,
        );
        debugPrint('Slot held: ${schedules[index].startTime} by $heldBy');
      }
    });
  }

  void _handleSlotReleased(dynamic payload) {
    final slotData = payload as Map<String, dynamic>;
    final courtId = slotData['courtId'] as int?;
    if (courtId != widget.courtId) return;

    final scheduleDate =
        DateTime.parse(slotData['beginAt'] as String).toLocal();
    final timeSlotId = slotData['timeSlotId'] as int?;

    setState(() {
      final index = schedules.indexWhere(
        (s) =>
            s.timeSlotId == timeSlotId &&
            _isSameDay(s.scheduleDate, scheduleDate),
      );
      if (index != -1) {
        schedules[index] = Schedule(
          scheduleDate: schedules[index].scheduleDate,
          dayOfWeek: schedules[index].dayOfWeek,
          courtId: schedules[index].courtId,
          courtName: schedules[index].courtName,
          timeSlotId: schedules[index].timeSlotId,
          startTime: schedules[index].startTime,
          endTime: schedules[index].endTime,
          status: 1,
          holdId: null,
          heldBy: null,
          bookingId: null,
          bookingDetailId: null,
        );
        debugPrint('Slot released: ${schedules[index].startTime}');

        selectedSlots.removeWhere(
          (slot) =>
              slot.timeSlotId == timeSlotId &&
              slot.beginAt ==
                  schedules[index].scheduleDate.add(schedules[index].startTime),
        );
        if (selectedSlots.isEmpty) {
          currentBooking = null;
          _bottomSheetController?.close();
          _bottomSheetController = null;
        } else {
          currentBooking!.details = selectedSlots;
          currentBooking!.amount = pricePerSlot * selectedSlots.length;
          _bottomSheetController?.setState!(() {});
        }
        debugPrint('Remaining slots: ${selectedSlots.length}');
      }
    });
  }

  void _handleBookingCreated(dynamic payload) {
    print("Step 1: Booking created notify - Payload received: $payload");

    if (payload == null) {
      print("Step 2: Payload is null, aborting");
      return;
    }

    try {
      final bookingData = payload as Map<String, dynamic>;
      print("Step 2: Payload casted to Map: $bookingData");

      final details = bookingData['details'] as List<dynamic>? ?? [];
      final bookingStatus =
          bookingData['status'] as int? ?? 1; // Mặc định Pending nếu null
      final bookingId = bookingData['bookingId'] as int?;
      final bookBy = bookingData['bookBy']?.toString();

      print(
          "Step 3: Extracted - Details: $details, BookingStatus: $bookingStatus, BookingId: $bookingId, BookBy: $bookBy");

      if (details.isEmpty) {
        print("Step 4: Details is empty, no slots to process");
        return;
      }

      // Ánh xạ BookingStatus sang Schedule.status
      int scheduleStatus;
      switch (bookingStatus) {
        case 1: // Pending
          scheduleStatus = 3;
          break;
        case 2: // Approved
          scheduleStatus = 4;
          break;
        case 3: // Paused
          scheduleStatus = 6;
          break;
        case 4: // Completed
          scheduleStatus = 5;
          break;
        case 5: // Canceled
        case 6: // Rejected
          print("Step 4: Booking is Canceled or Rejected, no update needed");
          return; // Không cập nhật slot nếu booking bị hủy/từ chối
        default:
          print("Step 4: Unknown BookingStatus ($bookingStatus), default to 3");
          scheduleStatus = 3; // Mặc định Pending nếu status lạ
      }

      _updateSchedulesInRange(details, scheduleStatus, bookingId, bookBy);
    } catch (e) {
      print("Step ERROR: Exception - $e");
    }
  }

  void _updateSchedulesInRange(List<dynamic> details, int scheduleStatus,
      int? bookingId, String? bookBy) {
    setState(() {
      print("Step 5: Entering setState for updating schedules");
      for (var detail in details) {
        final detailData = detail as Map<String, dynamic>;
        print("Step 6: Processing detail: $detailData");

        final courtId = detailData['courtId'] as int?;
        print("Step 7: CourtId: $courtId, Widget CourtId: ${widget.courtId}");
        if (courtId != widget.courtId) {
          print("Step 8: CourtId mismatch, skipping");
          continue;
        }

        final timeSlotId = detailData['timeSlotId'] as int?;
        final beginAt = detailData['beginAt'] != null
            ? DateTime.parse(detailData['beginAt'] as String).toLocal()
            : null;
        final scheduleDate = beginAt != null
            ? DateTime(beginAt.year, beginAt.month, beginAt.day)
            : null;

        print(
            "Step 9: TimeSlotId: $timeSlotId, BeginAt: $beginAt, ScheduleDate: $scheduleDate");

        if (scheduleDate == null || timeSlotId == null) {
          print("Step 10: ScheduleDate or TimeSlotId is null, skipping");
          continue;
        }

        // Kiểm tra xem scheduleDate có trong range không
        if (scheduleDate.isBefore(startDate) || scheduleDate.isAfter(endDate)) {
          print(
              "Step 10.1: ScheduleDate $scheduleDate is outside range $startDate - $endDate, skipping");
          continue;
        }

        print(
            "Step 10.2: Current schedules: ${schedules.map((s) => 'TimeSlotId: ${s.timeSlotId}, ScheduleDate: ${s.scheduleDate}').toList()}");

        final index = schedules.indexWhere(
          (s) =>
              s.timeSlotId == timeSlotId &&
              _isSameDay(s.scheduleDate, scheduleDate),
        );
        print("Step 11: Index found: $index");

        if (index != -1) {
          // Cập nhật slot nếu tồn tại trong range
          print("Step 12: Updating schedule at index $index");
          schedules[index] = Schedule(
            scheduleDate: schedules[index].scheduleDate,
            dayOfWeek: schedules[index].dayOfWeek,
            courtId: schedules[index].courtId,
            courtName: schedules[index].courtName,
            timeSlotId: schedules[index].timeSlotId,
            startTime: schedules[index].startTime,
            endTime: schedules[index].endTime,
            status: scheduleStatus,
            holdId: null,
            heldBy: bookBy,
            bookingId: bookingId,
            bookingDetailId: null,
          );
          print(
              "Step 13: Updated slot - StartTime: ${schedules[index].startTime}, Status: $scheduleStatus");

          // Xóa khỏi selectedSlots nếu có
          selectedSlots.removeWhere(
            (slot) =>
                slot.timeSlotId == timeSlotId &&
                slot.beginAt ==
                    schedules[index]
                        .scheduleDate
                        .add(schedules[index].startTime),
          );
          print("Step 14: SelectedSlots after removal: $selectedSlots");

          if (selectedSlots.isEmpty) {
            print("Step 15: SelectedSlots is empty, resetting currentBooking");
            currentBooking = null;
            _bottomSheetController?.close();
            _bottomSheetController = null;
          } else {
            print("Step 15: Updating currentBooking with remaining slots");
            currentBooking!.details = selectedSlots;
            currentBooking!.amount = pricePerSlot * selectedSlots.length;
            _bottomSheetController?.setState!(() {});
          }
        } else {
          print(
              "Step 12: Slot not found in range - TimeSlotId: $timeSlotId, ScheduleDate: $scheduleDate");
        }
      }
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2026),
    );
    if (picked != null && picked != startDate) {
      setState(() {
        startDate = picked;
        // Nếu startDate lớn hơn endDate, set endDate bằng startDate
        if (startDate.isAfter(endDate)) {
          endDate = startDate;
        }
        // Nếu khoảng cách vượt quá 10 ngày, giới hạn endDate
        else if (endDate.difference(startDate).inDays > 10) {
          endDate = startDate.add(const Duration(days: 10));
        }
        _loadSchedules();
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: endDate,
      firstDate: startDate,
      lastDate: startDate.add(const Duration(days: 10)),
    );
    if (picked != null && picked != endDate) {
      setState(() {
        endDate = picked;
        _loadSchedules();
      });
    }
  }

  void _resetDates() {
    setState(() {
      startDate = DateTime.now();
      endDate = DateTime.now().add(const Duration(days: 6));
    });
    _loadSchedules();
  }

  void _toggleTableView(bool value) {
    setState(() {
      isTimeSlotVertical = value;
    });
  }

  Future<void> _handlePayment() async {
    if (currentBooking == null || selectedSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa chọn slot nào!')),
      );
      return;
    }

    try {
      final bookingId = await _bookingService.createBooking(currentBooking!);
      if (bookingId > 0) {
        debugPrint('Payment successful, Booking ID: $bookingId');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đặt sân thành công!')),
        );
        setState(() {
          selectedSlots.clear();
          currentBooking = null;
          _bottomSheetController?.close();
          _bottomSheetController = null;
        });
      } else {
        debugPrint('Payment failed: Invalid booking ID');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đặt sân thất bại!')),
        );
      }
    } catch (e) {
      debugPrint('Payment failed with error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đặt sân thất bại!')),
      );
    }
  }

  void _showPersistentBottomSheet() {
    if (_bottomSheetController != null) {
      _bottomSheetController!.close();
    }

    _bottomSheetController = _scaffoldKey.currentState!.showBottomSheet(
      (context) => DraggableScrollableSheet(
        initialChildSize: 0.15,
        minChildSize: 0.15,
        maxChildSize: 0.7,
        expand: false,
        builder: (BuildContext context, ScrollController scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const Text(
                      "Slot đã chọn",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    selectedSlots.isEmpty
                        ? const Text("Chưa có slot nào được chọn")
                        : Column(
                            children: selectedSlots.map((slot) {
                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  title: Text(
                                    "${slot.courtName} - ${slot.beginAt?.toString().substring(0, 16)}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500),
                                  ),
                                  subtitle: Text("Giá: ${slot.price} VND"),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () async {
                                      final index = schedules.indexWhere(
                                        (s) =>
                                            s.timeSlotId == slot.timeSlotId &&
                                            _isSameDay(s.scheduleDate,
                                                slot.beginAt ?? DateTime.now()),
                                      );
                                      if (index != -1 &&
                                          schedules[index].holdId != null) {
                                        // Gọi API nhả slot
                                        await _slotService.releaseSlot(
                                          schedules[index].holdId!,
                                        );
                                        debugPrint(
                                            'Released slot: ${slot.beginAt} manually');
                                      }
                                      setState(() {
                                        selectedSlots.remove(slot);
                                        if (selectedSlots.isEmpty) {
                                          currentBooking = null;
                                          // _bottomSheetController?.close();
                                          // _bottomSheetController = null;
                                        } else {
                                          currentBooking!.details =
                                              selectedSlots;
                                          currentBooking!.amount =
                                              pricePerSlot *
                                                  selectedSlots.length;
                                          _bottomSheetController
                                              ?.setState!(() {});
                                        }
                                        debugPrint('Removed slot manually');
                                      });
                                    },
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                    const SizedBox(height: 8),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Tổng tiền:",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          "${currentBooking?.amount ?? 0} VND",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Phương thức thanh toán:",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: "Tiền mặt",
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: ["Tiền mặt", "Chuyển khoản", "Ví điện tử"]
                          .map((String value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              ))
                          .toList(),
                      onChanged: (value) {
                        debugPrint('Selected payment method: $value');
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handlePayment,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Thanh toán",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildDefaultTable() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 70,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 0.1),
              ),
              child: const Center(child: Text("Ngày")),
            ),
            ...schedules.map((s) => s.scheduleDate).toSet().map(
                  (date) => Container(
                    width: 70,
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 0.1),
                    ),
                    child: Center(
                      child: Text(
                        "${date.day}/${date.month}\n(${_getVietnameseDayOfWeek(date)})",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: timeSlots
                      .map(
                        (time) => Container(
                          width: 70,
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black, width: 0.1),
                          ),
                          child: Center(
                            child: Text(
                              "${time.inHours.toString().padLeft(2, '0')}:${(time.inMinutes % 60).toString().padLeft(2, '0')}",
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                SingleChildScrollView(
                  child: Column(
                    children: schedules
                        .map((s) => s.scheduleDate)
                        .toSet()
                        .map(
                          (date) => Row(
                            children: timeSlots.map((time) {
                              final slot = schedules.firstWhere(
                                (s) =>
                                    _isSameDay(s.scheduleDate, date) &&
                                    s.startTime == time,
                                orElse: () => Schedule(
                                    scheduleDate: date,
                                    courtId: widget.courtId,
                                    courtName: "Sân 1",
                                    timeSlotId: 0,
                                    startTime: time,
                                    endTime: time + const Duration(minutes: 30),
                                    status: 1, // Đặt mặc định là trống
                                    dayOfWeek: _getEnglishDayOfWeek(date)),
                              );
                              return SlotCard(
                                schedule: slot,
                                onSlotUpdate: _updateSlot,
                              );
                            }).toList(),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalTimeSlotTable() {
    final uniqueDates = schedules.map((s) => s.scheduleDate).toSet().toList()
      ..sort((a, b) => a.compareTo(b));
    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 70,
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 0.1),
                ),
                child: const Center(child: Text("Giờ")),
              ),
              ...timeSlots.map(
                (time) => Container(
                  width: 70,
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 0.1),
                  ),
                  child: Center(
                    child: Text(
                      "${time.inHours.toString().padLeft(2, '0')}:${(time.inMinutes % 60).toString().padLeft(2, '0')}",
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: uniqueDates
                        .map(
                          (date) => Container(
                            width: 70,
                            height: 50,
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: Colors.black, width: 0.1),
                            ),
                            child: Center(
                              child: Text(
                                "${date.day}/${date.month}\n(${_getVietnameseDayOfWeek(date)})",
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  Column(
                    children: timeSlots
                        .map(
                          (time) => Row(
                            children: uniqueDates.map((date) {
                              final slot = schedules.firstWhere(
                                (s) =>
                                    _isSameDay(s.scheduleDate, date) &&
                                    s.startTime == time,
                                orElse: () => Schedule(
                                    scheduleDate: date,
                                    courtId: widget.courtId,
                                    courtName: "Sân 1",
                                    timeSlotId: 0,
                                    startTime: time,
                                    endTime: time + const Duration(minutes: 30),
                                    status: 1, // Đặt mặc định là trống
                                    dayOfWeek: _getEnglishDayOfWeek(date)),
                              );
                              return SlotCard(
                                schedule: slot,
                                onSlotUpdate: _updateSlot,
                              );
                            }).toList(),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _signalRService.dispose();
    _bottomSheetController?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("Lịch sân ${widget.courtId}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _selectStartDate(context),
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                      "Từ ${startDate.day}/${startDate.month}/${startDate.year}"),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.lightBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _selectEndDate(context),
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                      "Đến ${endDate.day}/${endDate.month}/${endDate.year}"),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.lightBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ElevatedButton.icon(
                  onPressed: _resetDates,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text("Đặt lại"),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.lightBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    const Text("Quay bảng", style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Switch(
                      value: isTimeSlotVertical,
                      onChanged: _toggleTableView,
                      activeColor: Colors.lightBlue,
                    ),
                  ],
                ),
              ],
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : schedules.isEmpty
                      ? const Center(child: Text("Không có dữ liệu lịch"))
                      : isTimeSlotVertical
                          ? _buildVerticalTimeSlotTable()
                          : _buildDefaultTable(),
            ),
          ],
        ),
      ),
    );
  }
}
