import 'dart:async';
import 'dart:convert';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:focus_badminton/api_services/payment_service.dart';
import 'package:focus_badminton/api_services/vouchers_service.dart';
import 'package:focus_badminton/models/voucher.dart';
import 'package:focus_badminton/utils/format.dart';
import 'package:focus_badminton/widgets/payment_result_modal.dart';
import '../api_services/schedule_service.dart';
import '../api_services/signalr_service.dart';
import '../api_services/slot_service.dart';
import '../models/schedule.dart';
import '../widgets/slot_card.dart';
// import 'package:flutter/foundation.dart'; // Để debugPrint
import '../models/booking.dart';
import '../api_services/booking_service.dart';
import '../utils/deep_link_handler.dart'; // Import DeepLinkHandler
import 'booking_detail_creen.dart'; // Import BookingDetailScreen

class ScheduleScreen extends StatefulWidget {
  final int courtId;
  final Voucher? selectedVoucher;

  const ScheduleScreen({
    required this.courtId,
    this.selectedVoucher, // Có thể null nếu không chuyển từ VoucherScreen
    Key? key,
  }) : super(key: key);

  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with WidgetsBindingObserver {
  late ScheduleService _scheduleService;
  late SignalRService _signalRService;
  late SlotService _slotService;
  late BookingService _bookingService;
  late VoucherService _voucherService;
  List<Schedule> schedules = [];
  List<Duration> timeSlots = [];
  bool isLoading = true;
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now().add(const Duration(days: 6));
  bool isTimeSlotVertical = false;
  BookingDTO? currentBooking;
  final List<BookingItem> selectedSlots = [];
  final int memberId = 1; // Giả lập user ID
  final double pricePerSlot = 100000; // Giả lập giá
  PersistentBottomSheetController? _bottomSheetController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late PaymentService _paymentService;
  bool isProcessing = false; // Cờ kiểm soát request
  Voucher? selectedVoucher; // Biến lưu voucher được chọn
  List<Voucher> availableVouchers = [];
  AppLinks? _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

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
    WidgetsBinding.instance.addObserver(this); // Đăng ký observer
    _scheduleService = ScheduleService();
    _signalRService = SignalRService();
    _slotService = SlotService();
    _bookingService = BookingService();
    _paymentService = PaymentService();
    _voucherService = VoucherService(); // Khởi tạo VoucherService
    selectedVoucher = widget.selectedVoucher; // Lấy voucher từ widget

    _appLinks = AppLinks();
    _setupSignalR();
    _initDeepLink();
    _loadSchedules();
    _loadVouchers();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint("App lifecycle state changed: $state");
    // Không cần kiểm tra deep link ở đây nữa, để _initDeepLink xử lý
  }

  void _initDeepLink() async {
    if (_appLinks == null) return;

    try {
      final Uri? initialUri = await _appLinks!.getInitialLink();
      if (initialUri != null &&
          !DeepLinkHandler.isProcessed(initialUri.toString())) {
        debugPrint("Initial deep link: $initialUri");
        _handlePaymentCallback(initialUri);
        DeepLinkHandler.markAsProcessed(initialUri.toString());
      }

      _linkSubscription = _appLinks!.uriLinkStream.listen((Uri? uri) {
        if (uri != null && !DeepLinkHandler.isProcessed(uri.toString())) {
          debugPrint("Stream deep link: $uri");
          _handlePaymentCallback(uri);
          DeepLinkHandler.markAsProcessed(uri.toString());
        }
      }, onError: (err) {
        debugPrint("Deep link error: $err");
      });
    } catch (e) {
      debugPrint("Error initializing deep link: $e");
    }
  }

  Future<void> _loadVouchers() async {
    try {
      availableVouchers = await _voucherService.getVouchers(memberId);
      setState(() {});
    } catch (e) {
      debugPrint('Error loading vouchers: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải danh sách voucher: $e')),
      );
    }
  }

  void _handlePaymentCallback(Uri uri) {
    debugPrint("Handling payment callback: $uri");
    final bookingIdStr = uri.queryParameters['bookingId'];
    final resultCode = uri.queryParameters['resultCode'];
    if (bookingIdStr != null && resultCode != null) {
      final bookingId = int.tryParse(bookingIdStr);
      if (bookingId != null) {
        debugPrint(
            "Payment callback - BookingId: $bookingId, ResultCode: $resultCode");
        final isSuccess = resultCode == "0";
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showPaymentResultModal(isSuccess, bookingId);
        });
      }
    }
  }

  void _showPaymentResultModal(bool isSuccess, int bookingId) {
    debugPrint(
        "Showing payment result dialog - Success: $isSuccess, BookingId: $bookingId");
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => WillPopScope(
        onWillPop: () async => false,
        child: PaymentResultModal(
          isSuccess: isSuccess,
          bookingId: bookingId,
          onDismiss: () {
            Navigator.of(dialogContext).pop(); // Đóng dialog
            // Điều hướng tới BookingDetailScreen
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => BookingDetailScreen(bookingId: bookingId),
              ),
            );
          },
        ),
      ),
    );
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
          final beginAtLocal =
              updatedSlot.scheduleDate.add(updatedSlot.startTime);
          final dayOfWeek = _getEnglishDayOfWeek(beginAtLocal.toLocal());
          final bookingItem = BookingItem(
            courtId: updatedSlot.courtId,
            courtName: updatedSlot.courtName,
            timeSlotId: updatedSlot.timeSlotId,
            beginAt: beginAtLocal,
            endAt: updatedSlot.scheduleDate.add(updatedSlot.endTime),
            dayOfWeek: dayOfWeek,
            price: pricePerSlot,
            amount: pricePerSlot,
          );
          selectedSlots.add(bookingItem);
          if (currentBooking == null) {
            currentBooking = BookingDTO(
              memberId: memberId,
              amount: pricePerSlot * selectedSlots.length,
              deposit: pricePerSlot * selectedSlots.length * 0.5,
              details: selectedSlots,
              paymentMethod: PaymentMethod.cash,
              type: 1,
            );
            if (selectedVoucher != null) {
              currentBooking!.applyVoucher(selectedVoucher);
            }
          } else {
            currentBooking = BookingDTO(
              memberId: currentBooking!.memberId,
              amount: pricePerSlot * selectedSlots.length,
              deposit: pricePerSlot * selectedSlots.length * 0.5,
              details: selectedSlots,
              paymentMethod: currentBooking!.paymentMethod,
              type: currentBooking!.type,
            );
            if (selectedVoucher != null) {
              currentBooking!.applyVoucher(selectedVoucher);
            }
          }
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
    if (courtId != widget.courtId) {
      debugPrint("CourtId mismatch: $courtId != ${widget.courtId}");
      return;
    }

    final beginAt = DateTime.parse(slotData['beginAt'] as String).toLocal();
    final timeSlotId = slotData['timeSlotId'] as int?;
    final holdId = slotData['holdSlotId'] as int?;
    final heldBy = slotData['heldBy'] as String?;
    final bookingType = slotData['bookingType'] as int? ?? 1;
    final dayOfWeek = slotData['dayOfWeek'] as String?;

    debugPrint(
        "Processing SlotHeld: beginAt=$beginAt, bookingType=$bookingType, dayOfWeek=$dayOfWeek");

    // Danh sách các ngày cần cập nhật
    final affectedDates = _getAffectedDates(bookingType, beginAt, dayOfWeek);

    setState(() {
      for (var scheduleDate in affectedDates) {
        if (scheduleDate.isBefore(startDate) || scheduleDate.isAfter(endDate)) {
          debugPrint(
              "Skipping $scheduleDate: outside range $startDate - $endDate");
          continue;
        }

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
            status: 2, // Đang giữ
            holdId: holdId,
            heldBy: heldBy,
            bookingId: null,
            bookingDetailId: null,
          );
          debugPrint(
              'Slot held: ${schedules[index].startTime} on ${schedules[index].scheduleDate} by $heldBy');
        } else {
          debugPrint(
              "Slot not found for $scheduleDate, timeSlotId=$timeSlotId");
        }
      }
    });
  }

  List<DateTime> _getAffectedDates(
      int bookingType, DateTime beginAt, String? dayOfWeek) {
    final affectedDates = <DateTime>[];
    final start = DateTime(beginAt.year, beginAt.month, beginAt.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    debugPrint(
        "Calling _getAffectedDates: bookingType=$bookingType, beginAt=$beginAt, dayOfWeek=$dayOfWeek, endDate=$end");

    switch (bookingType) {
      case 1: // InDay
        affectedDates.add(start);
        break;

      case 2: // Fixed
      case 3: // Fixed_Unset_EndDate
        for (var date = start;
            !date.isAfter(end);
            date = date.add(const Duration(days: 1))) {
          if (dayOfWeek == null || _getEnglishDayOfWeek(date) == dayOfWeek) {
            affectedDates.add(DateTime(date.year, date.month, date.day));
          }
        }
        break;

      default:
        debugPrint("Unknown BookingType: $bookingType");
    }

    debugPrint(
        "Affected dates: ${affectedDates.map((d) => d.toString()).join(', ')}");
    return affectedDates;
  }

  void _handleSlotReleased(dynamic payload) {
    final slotData = payload as Map<String, dynamic>;
    final courtId = slotData['courtId'] as int?;
    if (courtId != widget.courtId) {
      debugPrint("CourtId mismatch: $courtId != ${widget.courtId}");
      return;
    }

    final beginAt = DateTime.parse(slotData['beginAt'] as String).toLocal();
    final timeSlotId = slotData['timeSlotId'] as int?;
    final bookingType = slotData['bookingType'] as int? ?? 1;
    final dayOfWeek = slotData['dayOfWeek'] as String?;

    debugPrint(
        "Processing SlotReleased: beginAt=$beginAt, bookingType=$bookingType, dayOfWeek=$dayOfWeek");

    // Danh sách các ngày cần cập nhật
    final affectedDates = _getAffectedDates(bookingType, beginAt, dayOfWeek);

    setState(() {
      for (var scheduleDate in affectedDates) {
        if (scheduleDate.isBefore(startDate) || scheduleDate.isAfter(endDate)) {
          debugPrint(
              "Skipping $scheduleDate: outside range $startDate - $endDate");
          continue;
        }

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
            status: 1, // Trống
            holdId: null,
            heldBy: null,
            bookingId: null,
            bookingDetailId: null,
          );
          debugPrint(
              'Slot released: ${schedules[index].startTime} on ${schedules[index].scheduleDate}');

          selectedSlots.removeWhere(
            (slot) =>
                slot.timeSlotId == timeSlotId &&
                slot.beginAt ==
                    schedules[index]
                        .scheduleDate
                        .add(schedules[index].startTime),
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
        } else {
          debugPrint(
              "Slot not found for $scheduleDate, timeSlotId=$timeSlotId");
        }
      }
    });
  }

  void _handleBookingCreated(dynamic payload) {
    debugPrint("BookingCreated received: $payload");
    if (payload == null) {
      debugPrint("Payload is null, aborting");
      return;
    }

    try {
      final bookingData = payload as Map<String, dynamic>;
      final details = bookingData['details'] as List<dynamic>? ?? [];
      final bookingStatus = bookingData['status'] as int? ?? 1;
      final bookingId = bookingData['bookingId'] as int?;
      final bookBy = bookingData['bookBy']?.toString();
      final bookingType =
          bookingData['bookingType'] as int? ?? 1; // Đảm bảo key đúng

      if (details.isEmpty) {
        debugPrint("Details is empty, no slots to process");
        return;
      }

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
          return;
        default:
          scheduleStatus = 3;
      }

      debugPrint("BookingType received: $bookingType"); // Thêm log kiểm tra
      _updateSchedulesInRange(
          details, scheduleStatus, bookingId, bookBy, bookingType);

      if (currentBooking != null &&
          details.any((d) => currentBooking!.details!
              .any((item) => item.timeSlotId == d['timeSlotId']))) {
        debugPrint("Skipping state reset - Booking matches currentBooking");
      } else {
        setState(() {
          selectedSlots.clear();
          currentBooking = null;
          _bottomSheetController?.close();
          _bottomSheetController = null;
        });
      }
    } catch (e) {
      debugPrint("Exception in handleBookingCreated: $e");
    }
  }

  void _updateSchedulesInRange(List<dynamic> details, int scheduleStatus,
      int? bookingId, String? bookBy, int bookingType) {
    setState(() {
      final startDateOnly =
          DateTime(startDate.year, startDate.month, startDate.day);
      final endDateOnly = DateTime(endDate.year, endDate.month, endDate.day);

      for (var detail in details) {
        final detailData = detail as Map<String, dynamic>;
        final courtId = detailData['courtId'] as int?;
        if (courtId != widget.courtId) {
          debugPrint("CourtId mismatch: $courtId != ${widget.courtId}");
          continue;
        }

        final timeSlotId = detailData['timeSlotId'] as int?;
        final beginAt = detailData['beginAt'] != null
            ? DateTime.parse(detailData['beginAt'] as String).toLocal()
            : null;
        final dayOfWeek = detailData['dayOfWeek'] as String?;

        if (beginAt == null || timeSlotId == null) {
          debugPrint("beginAt or timeSlotId is null, skipping");
          continue;
        }

        final affectedDates =
            _getAffectedDates(bookingType, beginAt, dayOfWeek);
        final timeSlot = Duration(hours: beginAt.hour, minutes: beginAt.minute);

        for (var scheduleDate in affectedDates) {
          if (scheduleDate.isBefore(startDateOnly) ||
              scheduleDate.isAfter(endDateOnly)) {
            debugPrint(
                "Skipping $scheduleDate: outside range $startDateOnly - $endDateOnly");
            continue;
          }

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
              status: scheduleStatus,
              holdId: null,
              heldBy: bookBy,
              bookingId: bookingId,
              bookingDetailId: null,
            );
            debugPrint(
                'Slot updated: ${schedules[index].startTime} on ${schedules[index].scheduleDate}, Status: $scheduleStatus');
          } else {
            schedules.add(Schedule(
              scheduleDate: scheduleDate,
              dayOfWeek: _getEnglishDayOfWeek(scheduleDate),
              courtId: widget.courtId,
              courtName:
                  schedules.isNotEmpty ? schedules[0].courtName : "Sân 1",
              timeSlotId: timeSlotId,
              startTime: timeSlot,
              endTime: timeSlot + const Duration(minutes: 30),
              status: scheduleStatus,
              holdId: null,
              heldBy: bookBy,
              bookingId: bookingId,
              bookingDetailId: null,
            ));
            debugPrint(
                'Added new slot for $scheduleDate, timeSlotId=$timeSlotId, Status: $scheduleStatus');
          }

          // Cập nhật timeSlots nếu cần
          if (!timeSlots.contains(timeSlot)) {
            timeSlots.add(timeSlot);
            timeSlots.sort((a, b) => a.inMinutes.compareTo(b.inMinutes));
          }
        }
      }
      debugPrint(
          "Updated schedules: ${schedules.map((s) => 'Date: ${s.scheduleDate}, Time: ${s.startTime}, Status: ${s.status}').toList()}");
    });
  }

  bool _isSlotMatching(
      int bookingType, DateTime scheduleDate, String? dayOfWeek) {
    switch (bookingType) {
      case 1: // InDay
        return true; // Chỉ cần scheduleDate nằm trong range là đủ
      case 2: // Fixed
      case 3: // Fixed_Unset_EndDate
        return dayOfWeek == null ||
            dayOfWeek == _getEnglishDayOfWeek(scheduleDate);
      default:
        debugPrint("Unknown BookingType: $bookingType");
        return false;
    }
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
    if (isProcessing || currentBooking == null || selectedSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa chọn slot hoặc đang xử lý!')),
      );
      return;
    }

    final bookingToProcess = currentBooking!;
    setState(() => isProcessing = true);
    try {
      debugPrint("Step 1: Current booking data: ${bookingToProcess.toJson()}");
      debugPrint("Step 2: Creating booking...");
      final dynamicData = await _bookingService.createBooking(bookingToProcess);
      final data = jsonDecode(dynamicData) as Map<String, dynamic>;
      final bookingId = data['id'] as int?;
      debugPrint("Step 3: Booking created successfully: $bookingId");

      if (bookingId != null && bookingId > 0) {
        debugPrint(
            "Step 4: Preparing payment - Amount: ${bookingToProcess.amount}, Deposit: ${bookingToProcess.deposit}, Method: ${bookingToProcess.paymentMethod.name}, PaymentLink: ${data['paymentLink']}");
        await _paymentService.processPayment(
          bookingId: bookingId,
          amount: bookingToProcess.amount,
          deposit: bookingToProcess.deposit,
          method: bookingToProcess.paymentMethod,
          paymentLink: data['paymentLink'],
        );
        debugPrint("Step 5: Payment processed successfully");

        // Thêm logic cho Cash sau khi xử lý payment
        if (bookingToProcess.paymentMethod == PaymentMethod.cash) {
          debugPrint("Step 6: Cash payment - Showing success modal");
          _showPaymentResultModal(true, bookingId); // Hiển thị modal thành công
        }
      } else {
        throw Exception("Invalid booking ID");
      }
    } catch (e) {
      debugPrint('Step ERROR: Payment failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đặt sân thất bại: $e')),
      );
    } finally {
      setState(() => isProcessing = false);
    }
  }

  void _showPersistentBottomSheet() {
    _bottomSheetController?.close();
    _bottomSheetController = _scaffoldKey.currentState!
        .showBottomSheet((context) => DraggableScrollableSheet(
              initialChildSize: 0.2,
              minChildSize: 0.2,
              maxChildSize: 0.8,
              expand: false,
              builder:
                  (BuildContext context, ScrollController scrollController) {
                return StatefulBuilder(
                  builder:
                      (BuildContext context, StateSetter setBottomSheetState) {
                    String selectedPaymentMethod =
                        currentBooking?.paymentMethod.name ??
                            PaymentMethod.cash.name;

                    return Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, -2))
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(2)),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              controller: scrollController,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Slot đã chọn',
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 12),
                                  if (selectedSlots.isEmpty)
                                    const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 8),
                                      child: Text('Chưa có slot nào được chọn',
                                          style: TextStyle(color: Colors.grey)),
                                    )
                                  else
                                    Column(
                                      children: selectedSlots.map((slot) {
                                        return Card(
                                          elevation: 2,
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 4),
                                          child: ListTile(
                                            title: Text(
                                                '${slot.courtName} - ${slot.beginAt?.toString().substring(0, 16)}'),
                                            subtitle: Text(
                                                'Giá: ${Format.formatVNCurrency(slot.price)}'),
                                            trailing: IconButton(
                                              icon: const Icon(Icons.delete,
                                                  color: Colors.red),
                                              onPressed: () async {
                                                final index =
                                                    schedules.indexWhere(
                                                  (s) =>
                                                      s.timeSlotId ==
                                                          slot.timeSlotId &&
                                                      _isSameDay(
                                                          s.scheduleDate,
                                                          slot.beginAt ??
                                                              DateTime.now()),
                                                );
                                                if (index != -1 &&
                                                    schedules[index].holdId !=
                                                        null) {
                                                  try {
                                                    await _slotService
                                                        .releaseSlot(
                                                            schedules[index]
                                                                .holdId!);
                                                    debugPrint(
                                                        'Released slot: ${slot.beginAt}');
                                                  } catch (e) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(SnackBar(
                                                            content: Text(
                                                                'Lỗi khi nhả slot: $e')));
                                                    return;
                                                  }
                                                }
                                                setBottomSheetState(() {
                                                  selectedSlots.remove(slot);
                                                  if (selectedSlots.isEmpty) {
                                                    currentBooking = null;
                                                    _bottomSheetController
                                                        ?.close();
                                                    _bottomSheetController =
                                                        null;
                                                  } else {
                                                    currentBooking!.details =
                                                        selectedSlots;
                                                    currentBooking!.amount =
                                                        pricePerSlot *
                                                            selectedSlots
                                                                .length;
                                                    if (selectedVoucher !=
                                                        null) {
                                                      currentBooking!
                                                          .applyVoucher(
                                                              selectedVoucher);
                                                    }
                                                  }
                                                });
                                                setState(() {});
                                              },
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  const SizedBox(height: 12),
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Tổng tiền gốc:',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600)),
                                      Text(
                                          '${Format.formatVNCurrency(pricePerSlot * selectedSlots.length)}',
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  const Text('Chọn Voucher:',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<Voucher>(
                                    value: selectedVoucher,
                                    decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8)),
                                    items: [
                                      const DropdownMenuItem<Voucher>(
                                        value: null,
                                        child: Text('Không sử dụng voucher'),
                                      ),
                                      ...availableVouchers.map((voucher) =>
                                          DropdownMenuItem<Voucher>(
                                            value: voucher,
                                            child: Text('${voucher.name}'),
                                          ))
                                    ],
                                    onChanged: (Voucher? value) {
                                      setBottomSheetState(() {
                                        selectedVoucher = value;
                                        if (currentBooking != null) {
                                          currentBooking!
                                              .applyVoucher(selectedVoucher);
                                        }
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  if (selectedVoucher != null) ...[
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Giảm giá:',
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600)),
                                        Text(
                                            '-${Format.formatVNCurrency(currentBooking?.discount ?? 0)}',
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red)),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Tổng tiền sau giảm:',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600)),
                                      Text(
                                          '${Format.formatVNCurrency((currentBooking?.amount ?? 0) - (currentBooking?.discount ?? 0))}',
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  const Text('Phương thức thanh toán:',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  GridView.count(
                                    crossAxisCount: 2,
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    childAspectRatio: 3,
                                    mainAxisSpacing: 8,
                                    crossAxisSpacing: 8,
                                    children:
                                        PaymentMethod.values.map((method) {
                                      final isSelected =
                                          selectedPaymentMethod == method.name;
                                      return GestureDetector(
                                        onTap: () {
                                          setBottomSheetState(() {
                                            selectedPaymentMethod = method.name;
                                            if (currentBooking != null) {
                                              currentBooking = BookingDTO(
                                                memberId:
                                                    currentBooking!.memberId,
                                                amount: currentBooking!.amount,
                                                deposit:
                                                    currentBooking!.deposit,
                                                details:
                                                    currentBooking!.details,
                                                paymentMethod: method,
                                                type: currentBooking!.type,
                                                voucherId:
                                                    currentBooking!.voucherId,
                                                discount:
                                                    currentBooking!.discount,
                                              );
                                            }
                                          });
                                        },
                                        child: Card(
                                          elevation: isSelected ? 4 : 2,
                                          color: isSelected
                                              ? Colors.blue[50]
                                              : Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            side: BorderSide(
                                              color: isSelected
                                                  ? Colors.blue
                                                  : Colors.grey,
                                              width: 1,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                _getPaymentIcon(method,
                                                    isSelected: isSelected),
                                                const SizedBox(width: 8),
                                                Text(
                                                  method.name.capitalize(),
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                    color: isSelected
                                                        ? Colors.blue
                                                        : Colors.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: (selectedSlots.isEmpty ||
                                              isProcessing)
                                          ? null
                                          : () async {
                                              await _handlePayment();
                                            },
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: Colors.green,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        disabledBackgroundColor: Colors.grey,
                                      ),
                                      child: const Text('Thanh toán',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ));
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
    WidgetsBinding.instance.removeObserver(this); // Hủy observer
    _linkSubscription?.cancel();
    _signalRService.dispose();
    _bottomSheetController?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(title: Text("Lịch sân ${widget.courtId}")),
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
                            borderRadius: BorderRadius.circular(5)))),
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
                            borderRadius: BorderRadius.circular(5)))),
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
                            borderRadius: BorderRadius.circular(5)))),
                const SizedBox(width: 16),
                Row(children: [
                  const Text("Quay bảng", style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Switch(
                      value: isTimeSlotVertical,
                      onChanged: _toggleTableView,
                      activeColor: Colors.lightBlue)
                ]),
              ],
            ),
            Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : schedules.isEmpty
                        ? const Center(child: Text("Không có dữ liệu lịch"))
                        : isTimeSlotVertical
                            ? _buildVerticalTimeSlotTable()
                            : _buildDefaultTable()),
          ],
        ),
      ),
    );
  }

  Widget _getPaymentIcon(PaymentMethod method, {bool isSelected = false}) {
    final color = isSelected ? Colors.blue : Colors.grey;
    switch (method) {
      case PaymentMethod.cash:
        return Icon(Icons.money, color: color, size: 24);
      case PaymentMethod.vnPay:
        return Image.asset(
          'assets/images/vnpay.png',
          width: 24,
          height: 24,
          color: color, // Tùy chọn: áp dụng màu nếu hình ảnh hỗ trợ
        );
      case PaymentMethod.momo:
        return Image.asset(
          'assets/images/momo.png',
          width: 24,
          height: 24,
          color: color, // Tùy chọn: áp dụng màu nếu hình ảnh hỗ trợ
        );
      default:
        return Icon(Icons.payment, color: color, size: 24);
    }
  }
}

// Thêm extension để debug dễ hơn
extension BookingDTOExtension on BookingDTO {
  Map<String, dynamic> toJson() => {
        'memberId': memberId,
        'amount': amount,
        'deposit': deposit,
        'paymentMethod': paymentMethod.name,
        'type': type,
        'details': details
            ?.map((item) => {
                  'courtId': item.courtId,
                  'courtName': item.courtName,
                  'timeSlotId': item.timeSlotId,
                  'beginAt': item.beginAt?.toIso8601String(),
                  'endAt': item.endAt?.toIso8601String(),
                  'dayOfWeek': item.dayOfWeek,
                  'price': item.price,
                  'amount': item.amount,
                })
            .toList(),
      };
}

extension StringExtension on String {
  String capitalize() {
    String methodName = this.toLowerCase();
    switch (methodName) {
      case 'cash':
        return 'Trả sau';
      case 'banktransfer':
        return 'Chuyển khoản';
      case 'momo':
        return 'MoMo';
      case 'vnpay':
        return 'VnPay';
      default:
        return methodName;
    }
  }
}
