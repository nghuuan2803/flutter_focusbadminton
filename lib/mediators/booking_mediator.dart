import 'dart:convert';
import '../api_services/auth_service.dart';
import '../api_services/booking_service.dart';
import '../api_services/payment_service.dart';
import '../api_services/schedule_service.dart';
import '../api_services/signalr_service.dart';
import '../api_services/slot_service.dart';
import '../api_services/vouchers_service.dart';
import '../models/booking.dart';
import '../models/slot.dart';
import '../models/voucher.dart';

abstract class BookingMediator {
  Future<void> loadSchedules(int courtId, DateTime startDate, DateTime endDate);
  Future<void> holdSlot(Slot slot);
  Future<void> releaseSlot(Slot slot);
  Future<int?> createBooking();
  void setUICallback(
      Function(List<Slot>, List<BookingItem>, BookingDTO?) callback);
  void updateUI();
  Future<List<Voucher>> loadVouchers(int memberId);
}

class ConcreteBookingMediator implements BookingMediator {
  final ScheduleService _scheduleService;
  final SlotService _slotService;
  final BookingService _bookingService;
  final PaymentService _paymentService;
  final VoucherService _voucherService;
  final SignalRService _signalRService;
  final int _courtId;
  List<Voucher> availableVouchers = [];
  late Function(List<Slot>, List<BookingItem>, BookingDTO?) _updateUICallback;

  List<Slot> _schedules = [];
  List<BookingItem> _selectedSlots = [];
  BookingDTO? _currentBooking;
  final double _pricePerSlot = 100000; // Giả lập giá
  late String? _memberId; // Giả lập userId

  ConcreteBookingMediator({
    required ScheduleService scheduleService,
    required SlotService slotService,
    required BookingService bookingService,
    required PaymentService paymentService,
    required VoucherService voucherService,
    required SignalRService signalRService,
    required int courtId,
  })  : _scheduleService = scheduleService,
        _slotService = slotService,
        _bookingService = bookingService,
        _paymentService = paymentService,
        _voucherService = voucherService,
        _signalRService = signalRService,
        _courtId = courtId {
    _initializeUserId(); // Khởi tạo userId
    _setupSignalR();
  }

  Future<void> _initializeUserId() async {
    _memberId = await AuthService.getMemberId();
    if (_memberId == null) {
      print(
          "⚠ Warning: Could not retrieve memberId. User may not be logged in.");
    }
  }

  @override
  void setUICallback(
      Function(List<Slot>, List<BookingItem>, BookingDTO?) callback) {
    _updateUICallback = callback;
  }

  @override
  Future<void> loadSchedules(
      int courtId, DateTime startDate, DateTime endDate) async {
    try {
      print("Mediator: Loading schedules for courtId: $courtId");
      _schedules = await _scheduleService.getCourtSchedulesInRange(
          courtId, startDate, endDate);
      updateUI();
    } catch (e) {
      print("Mediator: Error loading schedules: $e");
      rethrow;
    }
  }

  @override
  Future<void> holdSlot(Slot slot) async {
    try {
      print("Mediator: Holding slot - TimeSlotId: ${slot.timeSlotId}");
      final result = await _slotService.holdSlot(
        courtId: slot.courtId,
        timeSlotId: slot.timeSlotId,
        beginAt: slot.scheduleDate.add(slot.startTime),
        endAt: slot.scheduleDate.add(slot.endTime),
        bookingType: 1,
        dayOfWeek: slot.dayOfWeek,
      );
      final holdId = result['holdId'] as int;
      final estimatedCost = result['estimatedCost'] as double;

      if (holdId > 0) {
        final updatedSlot =
            slot.copyWith(status: 2, holdId: holdId, heldBy: _memberId);
        _updateSchedule(updatedSlot);
        final bookingItem = BookingItem(
          courtId: slot.courtId,
          courtName: slot.courtName,
          timeSlotId: slot.timeSlotId,
          beginAt: slot.scheduleDate.add(slot.startTime),
          endAt: slot.scheduleDate.add(slot.endTime),
          dayOfWeek: _getEnglishDayOfWeek(slot.scheduleDate),
          price: estimatedCost, // Sử dụng giá từ API
          amount: estimatedCost, // Sử dụng giá từ API
          holdId: holdId,
        );
        _selectedSlots.add(bookingItem);
        _updateBooking();
        updateUI();
      }
    } catch (e) {
      print("Mediator: Error holding slot: $e");
      rethrow;
    }
  }

  @override
  Future<void> releaseSlot(Slot slot) async {
    try {
      if (slot.holdId == null) return;
      print("Mediator: Releasing slot - HoldId: ${slot.holdId}");
      final success = await _slotService.releaseSlot(slot.holdId!);
      if (success) {
        final updatedSlot =
            slot.copyWith(status: 1, holdId: null, heldBy: null);
        _updateSchedule(updatedSlot);
        _selectedSlots.removeWhere(
          (s) =>
              s.timeSlotId == slot.timeSlotId &&
              _isSameDay(s.beginAt!, slot.scheduleDate),
        );
        if (_selectedSlots.isEmpty) {
          _currentBooking = null;
        } else {
          _updateBooking();
        }
        updateUI();
      }
    } catch (e) {
      print("Mediator: Error releasing slot: $e");
      rethrow;
    }
  }

  Future<int?> createBooking() async {
    try {
      if (_currentBooking == null) throw Exception("No booking to process");
      print("Mediator: Creating booking...");

      // Sao chép _currentBooking trước khi gửi request để tránh bị thay đổi
      final bookingCopy = BookingDTO(
        memberId: _currentBooking!.memberId,
        amount: _currentBooking!.amount,
        deposit: _currentBooking!.deposit,
        details: List.from(_currentBooking!.details ?? []),
        paymentMethod: _currentBooking!.paymentMethod,
        type: _currentBooking!.type,
        voucherId: _currentBooking!.voucherId,
        discount: _currentBooking!.discount,
      );

      print("Create booking request: ${jsonEncode(bookingCopy.toJson())}");
      final dynamicData = await _bookingService.createBooking(bookingCopy);
      print("Create booking response: 200 - $dynamicData");
      final data = jsonDecode(dynamicData) as Map<String, dynamic>;
      final bookingId = data['id'] as int?;

      if (bookingId != null && bookingId > 0) {
        // Xử lý thanh toán với bookingCopy đã sao chép
        await _paymentService.processPayment(
          bookingId: bookingId,
          amount: bookingCopy.amount,
          deposit: bookingCopy.deposit,
          method: bookingCopy.paymentMethod,
          paymentLink: data['paymentLink'] as String?,
        );

        // Xóa dữ liệu sau khi hoàn tất
        _selectedSlots.clear();
        _currentBooking = null;
        updateUI();

        return bookingId;
      }
      throw Exception("Invalid booking ID");
    } catch (e) {
      print("Mediator: Error creating booking: $e");
      rethrow;
    }
  }

  @override
  void updateUI() {
    _updateUICallback(_schedules, _selectedSlots, _currentBooking);
  }

  @override
  Future<List<Voucher>> loadVouchers(int memberId) async {
    try {
      availableVouchers = await _voucherService.getVouchers();
      return availableVouchers;
    } catch (e) {
      print("Mediator: Error loading vouchers: $e");
      rethrow;
    }
  }

  void _setupSignalR() {
    _signalRService.onSlotHeld = (payload) {
      final slotData = payload as Map<String, dynamic>;
      if (slotData['courtId'] != _courtId) return;
      final beginAt = DateTime.parse(slotData['beginAt'] as String).toLocal();
      final timeSlotId = slotData['timeSlotId'] as int?;
      final holdId = slotData['holdSlotId'] as int?;
      final heldBy = slotData['heldBy'] as String?;
      final index = _schedules.indexWhere(
        (s) =>
            s.timeSlotId == timeSlotId && _isSameDay(s.scheduleDate, beginAt),
      );
      if (index != -1) {
        _schedules[index] = _schedules[index]
            .copyWith(status: 2, holdId: holdId, heldBy: heldBy);
        updateUI();
      }
    };
    _signalRService.onSlotReleased = (payload) {
      final slotData = payload as Map<String, dynamic>;
      if (slotData['courtId'] != _courtId) return;
      final beginAt = DateTime.parse(slotData['beginAt'] as String).toLocal();
      final timeSlotId = slotData['timeSlotId'] as int?;
      final index = _schedules.indexWhere(
        (s) =>
            s.timeSlotId == timeSlotId && _isSameDay(s.scheduleDate, beginAt),
      );
      if (index != -1) {
        _schedules[index] =
            _schedules[index].copyWith(status: 1, holdId: null, heldBy: null);
        _selectedSlots.removeWhere(
          (s) => s.timeSlotId == timeSlotId && _isSameDay(s.beginAt!, beginAt),
        );
        if (_selectedSlots.isEmpty) _currentBooking = null;
        updateUI();
      }
    };
    _signalRService.onBookingCreated = (payload) {
      final bookingData = payload as Map<String, dynamic>;
      final details = bookingData['details'] as List<dynamic>? ?? [];
      for (var detail in details) {
        final detailData = detail as Map<String, dynamic>;
        if (detailData['courtId'] != _courtId) continue;
        final timeSlotId = detailData['timeSlotId'] as int?;
        final beginAt =
            DateTime.parse(detailData['beginAt'] as String).toLocal();
        final index = _schedules.indexWhere(
          (s) =>
              s.timeSlotId == timeSlotId && _isSameDay(s.scheduleDate, beginAt),
        );
        if (index != -1) {
          _schedules[index] =
              _schedules[index].copyWith(status: 3, holdId: null);
          _selectedSlots.removeWhere(
            (s) =>
                s.timeSlotId == timeSlotId && _isSameDay(s.beginAt!, beginAt),
          );
          if (_selectedSlots.isEmpty) _currentBooking = null;
          updateUI();
        }
      }
    };
    _signalRService.startConnection();
  }

  void _updateSchedule(Slot updatedSlot) {
    final index = _schedules.indexWhere(
      (s) =>
          s.timeSlotId == updatedSlot.timeSlotId &&
          _isSameDay(s.scheduleDate, updatedSlot.scheduleDate),
    );
    if (index != -1) {
      _schedules[index] = updatedSlot;
    } else {
      _schedules.add(updatedSlot);
    }
  }

  void updatePaymentMethod(PaymentMethod newMethod) {
    if (_currentBooking != null) {
      _currentBooking = BookingDTO(
        memberId: _currentBooking!.memberId,
        amount: _currentBooking!.amount,
        deposit: _currentBooking!.deposit,
        details: _currentBooking!.details,
        paymentMethod: newMethod,
        type: _currentBooking!.type,
        voucherId: _currentBooking!.voucherId,
        discount: _currentBooking!.discount,
      );
      updateUI();
    }
  }

  void _updateBooking() {
    if (_selectedSlots.isNotEmpty) {
      // Tính tổng tiền dựa trên estimatedCost của từng slot
      final totalAmount =
          _selectedSlots.fold<double>(0, (sum, slot) => sum + slot.amount);
      _currentBooking = BookingDTO(
        memberId: 1,
        amount: totalAmount,
        deposit: totalAmount * 0.5, // 50% tiền cọc
        details: List.from(_selectedSlots),
        paymentMethod: _currentBooking?.paymentMethod ?? PaymentMethod.cash,
        type: 1,
        voucherId: _currentBooking?.voucherId,
        discount: _currentBooking?.discount ?? 0.0,
      );
      if (_currentBooking!.voucherId != null) {
        _currentBooking!.applyVoucher(availableVouchers
            .firstWhere((v) => v.id == _currentBooking!.voucherId));
      }
    } else {
      _currentBooking = null;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getEnglishDayOfWeek(DateTime date) {
    const days = [
      "",
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday"
    ];
    return days[date.weekday];
  }
}

extension SlotExtension on Slot {
  Slot copyWith({
    DateTime? scheduleDate,
    String? dayOfWeek,
    int? courtId,
    String? courtName,
    int? timeSlotId,
    Duration? startTime,
    Duration? endTime,
    int? status,
    int? holdId,
    String? heldBy,
    int? bookingId,
    int? bookingDetailId,
  }) {
    return Slot(
      scheduleDate: scheduleDate ?? this.scheduleDate,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      courtId: courtId ?? this.courtId,
      courtName: courtName ?? this.courtName,
      timeSlotId: timeSlotId ?? this.timeSlotId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      holdId: holdId ?? this.holdId,
      heldBy: heldBy ?? this.heldBy,
      bookingId: bookingId ?? this.bookingId,
      bookingDetailId: bookingDetailId ?? this.bookingDetailId,
    );
  }
}
