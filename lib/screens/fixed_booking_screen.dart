import 'dart:async';
import 'package:flutter/material.dart';
import 'package:focus_badminton/api_services/payment_service.dart';
import 'package:focus_badminton/screens/inday_booking_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../api_services/vouchers_service.dart';
import '../main_screen.dart';
import '../models/booking.dart';
import '../api_services/slot_service.dart';
import '../api_services/booking_service.dart';
import '../api_services/schedule_service.dart';
import '../api_services/signalr_service.dart';
import '../models/voucher.dart';
import '../utils/constants.dart';
import 'package:app_links/app_links.dart';
import '../utils/deep_link_handler.dart';
import '../utils/format.dart';
import '../widgets/payment_result_modal.dart';
import 'booking_detail_screen.dart';
import '../utils/colors.dart';

class FixedBookingScreen extends StatefulWidget {
  final int courtId;

  const FixedBookingScreen({Key? key, required this.courtId}) : super(key: key);

  @override
  _FixedBookingScreenState createState() => _FixedBookingScreenState();
}

class _FixedBookingScreenState extends State<FixedBookingScreen>
    with WidgetsBindingObserver {
  DateTime? _startDate = DateTime.now().add(Duration(days: 1));
  DateTime? _endDate = DateTime.now().add(Duration(days: 30));
  List<String> _selectedDays = [];
  List<TimeSlotDTO> _allTimeSlots = [];
  List<int> _availableTimeSlotIds = [];
  List<int> _selectedTimeSlotIds = [];
  Map<int, List<DateTime>> _availableDates = {};
  Map<int, List<DateTime>> _lockedDates = {};

  Map<int, bool> _slotAvailability = {}; // Trạng thái khả dụng ban đầu
  Map<int, bool> _slotSelection = {}; // Trạng thái đã chọn
  Map<int, List<int>> _holdIds = {}; // Danh sách holdId cho từng slot

  BookingDTO? _currentBooking;
  bool _isFixedWithEndDate = true;
  final SlotService _slotService = SlotService();
  final PaymentService _paymentService = PaymentService();
  final BookingService _bookingService = BookingService();
  final ScheduleService _scheduleService = ScheduleService();
  late SignalRService _signalRService; // Khai báo SignalR Service
  final VoucherService _voucherService = VoucherService(); // K

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Voucher> availableVouchers = []; // Danh sách voucher
  Voucher? selectedVoucher; // Voucher được
  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appLinks = AppLinks();
    _signalRService = SignalRService();
    _setupSignalRListeners(); // Gán listener trước
    _signalRService.startConnection().then((_) {
      print("SignalR connection started");
    }).catchError((e) {
      print("SignalR connection failed: $e");
    });
    // _fetchTimeSlots();
    _fetchInitialData();
    _initDeepLink();
  }

  Future<void> _fetchInitialData() async {
    await _fetchTimeSlots();
    await _fetchSlotAvailability(); // Chỉ gọi 1 lần ban đầu
    availableVouchers = await _voucherService.getVouchers(); // Load voucher
  }

  void _setupSignalRListeners() {
    print("Setting up SignalR listeners");
    _signalRService.onSlotHeld = (payload) {
      print("onSlotHeld triggered");
      _handleSlotEvent('held', payload);
    };
    _signalRService.onSlotReleased = (payload) {
      print("onSlotReleased triggered");
      _handleSlotEvent('released', payload);
    };
    _signalRService.onBookingCreated = (payload) {
      print("onBookingCreated triggered");
      _handleSlotEvent('booked', payload);
    };
  }

  void _handleSlotEvent(String eventType, dynamic payload) {
    print(
        "Entering _handleSlotEvent with eventType=$eventType, payload=$payload");

    final courtId = payload['courtId'] as int?;
    final timeSlotId = payload['timeSlotId'] as int?;
    final bookingType = payload['bookingType'] as int?;
    final heldBy = payload['heldBy'] as String?;
    final dayOfWeek = payload['dayOfWeek'] as String?;
    final beginAtStr = payload['beginAt'] as String?;
    final endAtStr = payload['endAt'] as String?;

    if (courtId != widget.courtId || timeSlotId == null) {
      print(
          "Event ignored: courtId=$courtId, widget.courtId=${widget.courtId}, timeSlotId=$timeSlotId");
      return;
    }

    DateTime? beginAt = beginAtStr != null ? DateTime.parse(beginAtStr) : null;
    DateTime? endAt = endAtStr != null ? DateTime.parse(endAtStr) : null;

    String? effectiveDayOfWeek = dayOfWeek ??
        (beginAt != null ? _daysOfWeek[beginAt.weekday - 1] : null);

    print(
        "Handling $eventType: timeSlotId=$timeSlotId, effectiveDayOfWeek=$effectiveDayOfWeek, "
        "selectedDays=$_selectedDays, startDate=$_startDate, endDate=$_endDate");

    setState(() {
      // Sửa logic isRelevant: Chỉ cần ngày trong tuần khớp và nằm trong khoảng _startDate đến _endDate (nếu có)
      bool isRelevant = (effectiveDayOfWeek == null ||
              _selectedDays.contains(effectiveDayOfWeek)) &&
          _startDate != null &&
          (beginAt == null ||
              (beginAt.isBefore(
                      _endDate?.add(Duration(days: 1)) ?? DateTime(2100)) &&
                  beginAt.isAfter(_startDate!.subtract(Duration(days: 1))))) &&
          (endAt == null ||
              (_isFixedWithEndDate &&
                  _endDate != null &&
                  endAt.isAfter(_startDate!)));

      print("isRelevant=$isRelevant");

      if (!isRelevant) {
        print(
            "Event ignored: beginAt=$beginAt is outside selected range ($_startDate - $_endDate)");
        return;
      }

      switch (eventType) {
        case 'held':
          if (_availableTimeSlotIds.contains(timeSlotId)) {
            _availableTimeSlotIds.remove(timeSlotId);
            print("Slot $timeSlotId removed from availableTimeSlotIds");
          }
          if (_selectedTimeSlotIds.contains(timeSlotId) && heldBy != '1') {
            _selectedTimeSlotIds.remove(timeSlotId);
            _holdIds.remove(timeSlotId);
            print(
                "Slot $timeSlotId removed from selectedTimeSlotIds and holdIds");
          }
          if (heldBy == '1' && !_selectedTimeSlotIds.contains(timeSlotId)) {
            _selectedTimeSlotIds.add(timeSlotId);
            print("Slot $timeSlotId added to selectedTimeSlotIds by user");
          }
          break;
        case 'released':
          if (!_availableTimeSlotIds.contains(timeSlotId) &&
              !_selectedTimeSlotIds.contains(timeSlotId)) {
            _availableTimeSlotIds.add(timeSlotId);
            print("Slot $timeSlotId added back to availableTimeSlotIds");
          }
          if (_selectedTimeSlotIds.contains(timeSlotId)) {
            _selectedTimeSlotIds.remove(timeSlotId);
            _holdIds.remove(timeSlotId);
            print(
                "Slot $timeSlotId removed from selectedTimeSlotIds on release");
          }
          break;
        case 'booked':
          _availableTimeSlotIds.remove(timeSlotId);
          _holdIds.remove(timeSlotId);
          _selectedTimeSlotIds.remove(timeSlotId);
          print("Slot $timeSlotId removed due to booking");
          break;
      }

      print("Updated: availableTimeSlotIds=$_availableTimeSlotIds, "
          "selectedTimeSlotIds=$_selectedTimeSlotIds");
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSubscription?.cancel();
    _signalRService.dispose(); // Hủy SignalR khi dispose
    super.dispose();
  }

  void _initDeepLink() async {
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null &&
          !DeepLinkHandler.isProcessed(initialUri.toString())) {
        print("Initial deep link received: $initialUri");
        _handlePaymentCallback(initialUri);
        DeepLinkHandler.markAsProcessed(initialUri.toString());
      }

      _linkSubscription = _appLinks.uriLinkStream.listen((Uri? uri) {
        if (uri != null && !DeepLinkHandler.isProcessed(uri.toString())) {
          print("Stream deep link received: $uri");
          _handlePaymentCallback(uri);
          DeepLinkHandler.markAsProcessed(uri.toString());
        }
      }, onError: (err) {
        print("Deep link error: $err");
      });
    } catch (e) {
      print("Error initializing deep link: $e");
    }
  }

  Future<void> _handlePayment() async {
    if (_currentBooking == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có booking để xử lý')),
      );
      return;
    }

    try {
      print("Create booking request: ${jsonEncode(_currentBooking!.toJson())}");

      final dynamicBooking =
          await _bookingService.createBooking(_currentBooking!);
      final bookingData = jsonDecode(dynamicBooking) as Map<String, dynamic>;
      final bookingId = bookingData['id'] as int;
      final paymentLink = bookingData['paymentLink'] as String?;

      await _paymentService.processPayment(
        bookingId: bookingId,
        amount: _currentBooking!.amount,
        deposit: _currentBooking!.deposit,
        method: _currentBooking!.paymentMethod,
        paymentLink: paymentLink,
      );

      Navigator.pop(context); // Đóng bottom sheet

      if (!mounted) return;

      if (_currentBooking!.paymentMethod == PaymentMethod.cash) {
        _showPaymentResultModal(true, bookingId);
      } else {
        print(
            "Waiting for deep link callback for payment method: ${_currentBooking!.paymentMethod}");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi đặt sân: $e')),
      );
    }
  }

  void _handlePaymentCallback(Uri uri) {
    final bookingIdStr = uri.queryParameters['bookingId'];
    final resultCode = uri.queryParameters['resultCode'];
    if (bookingIdStr != null && resultCode != null) {
      final bookingId = int.tryParse(bookingIdStr);
      if (bookingId != null) {
        final isSuccess = resultCode == "0";
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showPaymentResultModal(isSuccess, bookingId);
        });
      } else {
        print("Error: Invalid bookingId from deep link: $bookingIdStr");
      }
    }
  }

  void _showPaymentResultModal(bool isSuccess, int bookingId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false, // Ngăn back mặc định
        onPopInvoked: (didPop) {
          if (!didPop) {
            Navigator.of(dialogContext).pop(); // Đóng modal khi bấm back
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MainScreen()),
            );
          }
        },
        child: PaymentResultModal(isSuccess: isSuccess, bookingId: bookingId),
      ),
    );
  }

  Future<void> _fetchTimeSlots() async {
    try {
      final response =
          await http.get(Uri.parse('${Constants.baseUrl}api/timeslots'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _allTimeSlots = data
              .map((json) => TimeSlotDTO.fromJson(json))
              .where((slot) => slot.isApplied && !slot.isDeleted)
              .toList();
        });
      } else {
        throw Exception('Failed to load time slots: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải khung giờ: $e')),
      );
    }
  }

  Future<void> _fetchSlotAvailability() async {
    if (_startDate == null || _selectedDays.isEmpty) {
      print(
          "Fetch slot availability skipped: startDate or selectedDays is empty");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng chọn ngày bắt đầu và ngày trong tuần')),
      );
      return;
    }

    try {
      print("Fetching slot availability...");
      final String endpoint = _isFixedWithEndDate
          ? '${Constants.baseUrl}api/schedules/check-multi-day-available'
          : '${Constants.baseUrl}api/slot/check-multi-day-unset-end-date';

      final requestBody = jsonEncode({
        'CourtId': widget.courtId,
        'StartDate': _startDate!.toUtc().toIso8601String(),
        'EndDate': _isFixedWithEndDate ? _endDate?.toIso8601String() : null,
        'DaysOfWeek': _selectedDays,
      });

      print("Request body: $requestBody");

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _availableTimeSlotIds = data.map((id) => id as int).toList();
          _availableDates.clear();
          _lockedDates.clear();
          print("Updated availableTimeSlotIds: $_availableTimeSlotIds");
        });
        if (_availableTimeSlotIds.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không có khung giờ nào khả dụng')),
          );
        }
      } else {
        throw Exception('Failed to check availability: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching slot availability: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi kiểm tra trạng thái slot: $e')),
      );
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        if (_isFixedWithEndDate &&
            _endDate != null &&
            _startDate!.isAfter(_endDate!)) {
          _endDate = _startDate!.add(const Duration(days: 30));
        }
        _availableTimeSlotIds.clear();
        _availableDates.clear();
        _lockedDates.clear();
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime initialDate = _endDate ?? (_startDate ?? DateTime.now());
    final DateTime adjustedInitialDate =
        (_startDate != null && initialDate.isBefore(_startDate!))
            ? _startDate!
            : initialDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: adjustedInitialDate,
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
        _availableTimeSlotIds.clear();
        _availableDates.clear();
        _lockedDates.clear();
      });
    }
  }

  void _resetSelections() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedDays.clear();
      _selectedTimeSlotIds.clear();
      _holdIds.clear();
      _availableDates.clear();
      _lockedDates.clear();
      _availableTimeSlotIds.clear();
      _currentBooking = null;
      _isFixedWithEndDate = true;
    });
  }

  void _selectAllDays() {
    setState(() {
      _selectedDays = List.from(_daysOfWeek);
      _availableTimeSlotIds.clear();
      _availableDates.clear();
      _lockedDates.clear();
    });
  }

  Future<bool> _checkAndHoldSlot(int timeSlotId) async {
    try {
      if (_startDate == null || _selectedDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Vui lòng chọn đầy đủ ngày bắt đầu và ngày trong tuần')));
        return false;
      }
      if (_isFixedWithEndDate && _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Vui lòng chọn ngày kết thúc cho đặt sân cố định')));
        return false;
      }

      // Kiểm tra nếu slot đã được giữ thì không cần gọi lại API
      if (_holdIds.containsKey(timeSlotId) &&
          _selectedTimeSlotIds.contains(timeSlotId)) {
        return true;
      }

      final slot = _allTimeSlots.firstWhere((s) => s.id == timeSlotId);
      final now = DateTime.now();
      final beginAtLocal = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
        slot.startTime.inHours,
        slot.startTime.inMinutes % 60,
      );
      final adjustedBeginAt = beginAtLocal.isBefore(now)
          ? beginAtLocal.add(const Duration(days: 1))
          : beginAtLocal;

      final endAtLocal = _isFixedWithEndDate && _endDate != null
          ? DateTime(
              _endDate!.year,
              _endDate!.month,
              _endDate!.day,
              slot.endTime.inHours,
              slot.endTime.inMinutes % 60,
            )
          : null;

      final String endpoint = _isFixedWithEndDate
          ? '${Constants.baseUrl}api/slot/check-fixed-booking-hold'
          : '${Constants.baseUrl}api/slot/check-unset-end-date-booking-hold';

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'courtId': widget.courtId,
          'timeSlotId': timeSlotId,
          'beginAt': adjustedBeginAt.toUtc().toIso8601String(),
          'endAt': endAtLocal?.toUtc().toIso8601String(),
          'daysOfWeek': _selectedDays,
          'bookingType': _isFixedWithEndDate ? 2 : 3,
          'heldBy': '1',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['succeeded'] == true) {
          final holdResults = (data['data'] as List)
              .map((item) => {
                    'dayOfWeek': item['dayOfWeek'],
                    'holdId': item['holdId'],
                    'estimatedCost': item['estimatedCost'] / 1
                  })
              .toList();

          final holdIds =
              holdResults.map((result) => result['holdId'] as int).toList();
          setState(() {
            _holdIds[timeSlotId] = holdIds;
            if (!_selectedTimeSlotIds.contains(timeSlotId)) {
              _selectedTimeSlotIds.add(timeSlotId); // Chỉ thêm nếu chưa có
            }
          });
          return true;
        } else {
          throw Exception('Failed to hold slots: ${data['errors'].join(', ')}');
        }
      } else {
        throw Exception(
            'Failed to hold slots: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi khi giữ khung giờ: $e')));
      setState(() {
        _fetchSlotAvailability();
      });
      return false;
    }
  }

  int _calculateExpectedDays() {
    if (!_isFixedWithEndDate) return 1;
    final end = _endDate ?? _startDate!;
    int count = 0;
    for (var date = _startDate!;
        date.isBefore(end.add(const Duration(days: 1)));
        date = date.add(const Duration(days: 1))) {
      if (_selectedDays.contains(_daysOfWeek[date.weekday - 1])) {
        count++;
      }
    }
    return count;
  }

  void _showBookingBottomSheet() {
    if (_selectedTimeSlotIds.isEmpty ||
        _startDate == null ||
        _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng chọn đầy đủ thông tin và khung giờ')),
      );
      return;
    }
    if (_isFixedWithEndDate && _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng chọn ngày kết thúc cho đặt sân cố định')),
      );
      return;
    }

    List<BookingItem> details = [];
    double totalAmount = 0.0;

    final uniqueTimeSlotIds = _selectedTimeSlotIds.toSet();
    for (var timeSlotId in uniqueTimeSlotIds) {
      final slot = _allTimeSlots.firstWhere((s) => s.id == timeSlotId);
      final holdIds = _holdIds[timeSlotId];
      if (holdIds == null || holdIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Slot chưa được giữ, vui lòng thử lại')),
        );
        return;
      }

      final now = DateTime.now();
      final beginAtLocal = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
        slot.startTime.inHours,
        slot.startTime.inMinutes % 60,
      );
      final adjustedBeginAt = beginAtLocal.isBefore(now)
          ? beginAtLocal.add(const Duration(days: 1))
          : beginAtLocal;
      final endAtLocal = _isFixedWithEndDate && _endDate != null
          ? DateTime(
              _endDate!.year,
              _endDate!.month,
              _endDate!.day,
              slot.endTime.inHours,
              slot.endTime.inMinutes % 60,
            )
          : null;

      for (var dayOfWeek in _selectedDays) {
        int dayCount = 0;
        final end = _endDate ?? _startDate!;
        for (var date = _startDate!;
            date.isBefore(end.add(const Duration(days: 1)));
            date = date.add(const Duration(days: 1))) {
          if (_daysOfWeek[date.weekday - 1] == dayOfWeek) {
            dayCount++;
          }
        }

        final amount = slot.price * dayCount;
        totalAmount += amount;

        details.add(BookingItem(
          courtId: widget.courtId,
          timeSlotId: timeSlotId,
          beginAt: adjustedBeginAt.toUtc(),
          endAt: endAtLocal?.toUtc(),
          dayOfWeek: dayOfWeek,
          price: slot.price,
          amount: amount,
        ));
      }
    }

    // Gom nhóm các BookingItem theo timeSlotId
    Map<int, List<BookingItem>> groupedDetails = {};
    for (var detail in details) {
      groupedDetails.putIfAbsent(detail.timeSlotId, () => []).add(detail);
    }

    setState(() {
      _currentBooking = BookingDTO(
        memberId: 1,
        type: _isFixedWithEndDate ? 2 : 3,
        approvedAt: null,
        completedAt: null,
        amount: totalAmount,
        deposit:
            uniqueTimeSlotIds.length * 10000, // Tính deposit theo số khung giờ
        voucherId: null,
        discount: 0,
        paymentMethod: PaymentMethod.cash,
        note: "string",
        adminNote: "string",
        details: details,
      );
    });

    _scaffoldKey.currentState!.showBottomSheet(
      (context) => DraggableScrollableSheet(
        initialChildSize: 1,
        minChildSize: 1,
        maxChildSize: 1,
        expand: false,
        builder: (_, scrollController) => StatefulBuilder(
          builder: (_, setBottomSheetState) {
            String selectedPaymentMethod = _currentBooking!.paymentMethod.name;

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                          const Text('Lịch đã chọn',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          if (_currentBooking!.details!.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text('Chưa chọn lịch',
                                  style: TextStyle(color: Colors.grey)),
                            )
                          else
                            Column(
                              children: groupedDetails.entries.map((entry) {
                                final slot = _allTimeSlots
                                    .firstWhere((s) => s.id == entry.key);
                                final daysOfWeek = entry.value
                                    .map((d) => d.dayOfWeek!)
                                    .toSet()
                                    .toList();
                                return Card(
                                  elevation: 2,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Sân ${widget.courtId} [${slot.startTimeString} - ${slot.endTimeString}]',
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        // const SizedBox(height: 4),
                                        // Text(
                                        //   'Giá mỗi ngày: ${Format.formatVNCurrency(slot.price)}',
                                        //   style: const TextStyle(fontSize: 14),
                                        // ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 6.0,
                                          runSpacing: 4.0,
                                          children: daysOfWeek
                                              .map((day) => Chip(
                                                    label: Text(
                                                      _getVnDay(day),
                                                      style: const TextStyle(
                                                          fontSize: 12),
                                                    ),
                                                    backgroundColor:
                                                        Colors.blue[100],
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 6),
                                                  ))
                                              .toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          const SizedBox(height: 12),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Tổng tiền gốc:',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                              Text(
                                Format.formatVNCurrency(
                                    _currentBooking!.amount),
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text('Chọn Voucher:',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<Voucher>(
                            value: selectedVoucher,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            items: [
                              const DropdownMenuItem<Voucher>(
                                  value: null,
                                  child: Text('Không sử dụng voucher')),
                              ...availableVouchers
                                  .map((voucher) => DropdownMenuItem<Voucher>(
                                        value: voucher,
                                        child: Text(voucher.name),
                                      )),
                            ],
                            onChanged: (value) {
                              setBottomSheetState(() {
                                selectedVoucher = value;
                                if (_currentBooking != null) {
                                  _currentBooking = BookingDTO(
                                    memberId: _currentBooking!.memberId,
                                    type: _currentBooking!.type,
                                    approvedAt: _currentBooking!.approvedAt,
                                    completedAt: _currentBooking!.completedAt,
                                    amount: _currentBooking!.amount,
                                    deposit: _currentBooking!.deposit,
                                    voucherId: value?.id,
                                    discount: _calculateDiscount(),
                                    paymentMethod:
                                        _currentBooking!.paymentMethod,
                                    note: _currentBooking!.note,
                                    adminNote: _currentBooking!.adminNote,
                                    details: _currentBooking!.details,
                                  );
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          if (selectedVoucher != null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Giảm giá:',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)),
                                Text(
                                  '-${Format.formatVNCurrency(_calculateDiscount())}',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Tổng tiền sau giảm:',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                              Text(
                                Format.formatVNCurrency(
                                    _currentBooking!.amount -
                                        _calculateDiscount()),
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text('Phương thức thanh toán:',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: 3,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            children: PaymentMethod.values.map((method) {
                              final isSelected =
                                  selectedPaymentMethod == method.name;
                              return GestureDetector(
                                onTap: () {
                                  setBottomSheetState(() {
                                    selectedPaymentMethod = method.name;
                                    _currentBooking = BookingDTO(
                                      memberId: _currentBooking!.memberId,
                                      type: _currentBooking!.type,
                                      approvedAt: _currentBooking!.approvedAt,
                                      completedAt: _currentBooking!.completedAt,
                                      amount: _currentBooking!.amount,
                                      deposit: _currentBooking!.deposit,
                                      voucherId: _currentBooking!.voucherId,
                                      discount: _currentBooking!.discount,
                                      paymentMethod: method,
                                      note: _currentBooking!.note,
                                      adminNote: _currentBooking!.adminNote,
                                      details: _currentBooking!.details,
                                    );
                                  });
                                },
                                child: Card(
                                  elevation: isSelected ? 4 : 2,
                                  color: isSelected
                                      ? Colors.blue[50]
                                      : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
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
                            height: 45,
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _currentBooking!.details!.isEmpty
                                  ? null
                                  : _handlePayment,
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: AppColors.accent,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
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
                  )
                ],
              ),
            );
          },
        ),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  double _calculateDiscount() {
    if (selectedVoucher == null || _currentBooking == null) return 0.0;

    final voucher = selectedVoucher!;
    final total = _currentBooking!.amount;

    if (voucher.discountType == 0) {
      // Giảm cố định
      return voucher.value;
    } else {
      // Giảm phần trăm
      double discount = (total * voucher.value) / 100;
      if (voucher.maximumValue > 0 && discount > voucher.maximumValue) {
        discount = voucher.maximumValue;
      }
      return discount;
    }
  }

  String _getVnDay(String day) {
    switch (day) {
      case "Monday":
        return "Thứ Hai";
      case "Tuesday":
        return "Thứ Ba";
      case "Wednesday":
        return "Thứ Tư";
      case "Thursday":
        return "Thứ Năm";
      case "Friday":
        return "Thứ Sáu";
      case "Saturday":
        return "Thứ Bảy";
      case "Sunday":
        return "Chủ nhật";
      default:
        return "Invalid";
    }
  }

  Widget _getPaymentIcon(PaymentMethod method, {bool isSelected = false}) {
    final color = isSelected ? Colors.blue : Colors.grey;
    switch (method) {
      case PaymentMethod.cash:
        return Icon(Icons.money, color: color, size: 24);
      case PaymentMethod.vnPay:
        return Image.asset('assets/images/vnpay.png', width: 24, height: 24);
      case PaymentMethod.momo:
        return Image.asset('assets/images/momo.png', width: 24, height: 24);
      default:
        return Icon(Icons.payment, color: color, size: 24);
    }
  }

  Future<void> _releaseHeldSlots([int? timeSlotId]) async {
    try {
      // Nếu không truyền timeSlotId, nhả tất cả slot trong _holdIds
      if (timeSlotId == null) {
        if (_holdIds.isEmpty) return;

        final allHoldIds = _holdIds.values.expand((ids) => ids).toList();
        if (allHoldIds.isNotEmpty) {
          final success = await _slotService.releaseMultipleSlots(allHoldIds);
          if (success) {
            setState(() {
              _holdIds.clear();
              _slotSelection.updateAll((key, value) => false);
              _slotAvailability.updateAll((key, value) => true);
            });
          } else {
            throw Exception('Failed to release all slots');
          }
        }
      }
      // Nếu truyền timeSlotId, nhả slot cụ thể
      else {
        final holdIds = _holdIds[timeSlotId];
        if (holdIds != null && holdIds.isNotEmpty) {
          final success = await _slotService.releaseMultipleSlots(holdIds);
          if (success) {
            setState(() {
              _holdIds.remove(timeSlotId);
              _slotSelection[timeSlotId] = false;
              _slotAvailability[timeSlotId] = true;
            });
          } else {
            throw Exception('Failed to release slot $timeSlotId');
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi nhả slot: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(title: const Text('Đặt sân cố định')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 136,
                      height: 40,
                      child: TextField(
                        readOnly: true,
                        onTap: () => _selectStartDate(context),
                        controller: TextEditingController(
                          text: _startDate == null
                              ? ''
                              : DateFormat('dd/MM/yyyy').format(_startDate!),
                        ),
                        decoration: InputDecoration(
                          labelText: 'Bắt đầu',
                          prefixIcon:
                              const Icon(Icons.calendar_today, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_isFixedWithEndDate)
                      SizedBox(
                        width: 136,
                        height: 40,
                        child: TextField(
                          readOnly: true,
                          onTap: () => _selectEndDate(context),
                          controller: TextEditingController(
                            text: _endDate == null
                                ? ''
                                : DateFormat('dd/MM/yyyy').format(_endDate!),
                          ),
                          decoration: InputDecoration(
                            labelText: 'Kết thúc',
                            prefixIcon:
                                const Icon(Icons.calendar_today, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                  ],
                ),
                IconButton(
                  onPressed: _resetSelections,
                  icon: const Icon(Icons.refresh),
                  color: Colors.red,
                  iconSize: 24,
                  tooltip: 'Reset',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: const Size(40, 40),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Đặt cố định không thời hạn',
                    style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Switch(
                  value: !_isFixedWithEndDate,
                  onChanged: (value) {
                    setState(() {
                      _isFixedWithEndDate = !value;
                      if (!_isFixedWithEndDate) _endDate = null;
                      _availableTimeSlotIds.clear();
                      _availableDates.clear();
                      _lockedDates.clear();
                    });
                  },
                  activeColor: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Chọn ngày trong tuần:',
                style: Theme.of(context).textTheme.titleMedium),
            Wrap(
              spacing: 8.0,
              children: [
                ..._daysOfWeek.map((day) {
                  final isSelected = _selectedDays.contains(day);
                  return FilterChip(
                    showCheckmark: true,
                    label: Text(_getVnDay(day)),
                    selected: isSelected,
                    selectedColor: AppColors.accent,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Colors.black, // Đổi màu chữ cho dễ đọc
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedDays.add(day);
                        } else {
                          _selectedDays.remove(day);
                        }
                        _availableTimeSlotIds.clear();
                        _availableDates.clear();
                        _lockedDates.clear();
                      });
                    },
                  );
                }),
                FilterChip(
                  showCheckmark: false,
                  label: const Text('Tất cả'),
                  selected: _selectedDays.length == _daysOfWeek.length,
                  selectedColor: AppColors.accent,
                  labelStyle: TextStyle(
                    color: _selectedDays.length == _daysOfWeek.length
                        ? Colors.white
                        : Colors.black, // Đổi màu chữ
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedDays = List.from(_daysOfWeek);
                      } else {
                        _selectedDays.clear();
                      }
                      _availableTimeSlotIds.clear();
                      _availableDates.clear();
                      _lockedDates.clear();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _fetchSlotAvailability,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: Colors.blue, // Đổi màu nền thành xanh
                ),
                child: const Text(
                  'Tiếp tục',
                  style: TextStyle(
                      color:
                          Colors.white), // Đổi màu chữ thành trắng cho dễ đọc
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_allTimeSlots.isNotEmpty) ...[
              Text('Chọn khung giờ:',
                  style: Theme.of(context).textTheme.titleMedium),
              SizedBox(
                height: 250,
                child: GridView.count(
                  crossAxisCount: 3, // Chia thành 3 cột
                  crossAxisSpacing: 8.0, // Khoảng cách ngang giữa các cột
                  mainAxisSpacing: 8.0, // Khoảng cách dọc giữa các hàng
                  childAspectRatio: 3.0, // Tỷ lệ chiều rộng/chiều cao của mỗi ô
                  children: _allTimeSlots.map((slot) {
                    final isSelected = _selectedTimeSlotIds.contains(slot.id);
                    final isAvailable = _availableTimeSlotIds.contains(slot.id);
                    print(
                        "Grid slot ${slot.id}: isAvailable=$isAvailable, isSelected=$isSelected");

                    return FilterChip(
                      showCheckmark: false,
                      label: Text(
                        '${slot.startTimeString} - ${slot.endTimeString}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? Colors.white
                              : (isAvailable ? Colors.black : Colors.grey),
                        ),
                      ),
                      selected: isSelected,
                      backgroundColor: isAvailable ? null : Colors.grey[300],
                      selectedColor: Colors.blue,
                      labelPadding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 0.0),
                      onSelected: (selected) async {
                        // Loại bỏ điều kiện isAvailable để luôn cho phép nhả
                        if (selected) {
                          final success = await _checkAndHoldSlot(slot.id);
                          if (success) {
                            setState(() {
                              _selectedTimeSlotIds.add(slot.id);
                            });
                          }
                        } else {
                          final holdIds = _holdIds[slot.id];
                          if (holdIds != null && holdIds.isNotEmpty) {
                            try {
                              final success = await _slotService
                                  .releaseMultipleSlots(holdIds);
                              if (success) {
                                setState(() {
                                  _selectedTimeSlotIds.remove(slot.id);
                                  _holdIds.remove(slot.id);
                                });
                                await _fetchSlotAvailability(); // Cập nhật lại danh sách
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Không thể bỏ giữ slot')),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Lỗi khi bỏ giữ slot: $e')),
                              );
                            }
                          }
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _showBookingBottomSheet,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: Colors.blue, // Đổi màu nền thành xanh
                  ),
                  child: const Text(
                    'Thanh toán',
                    style: TextStyle(
                        color: Colors.white), // Đổi màu chữ thành trắng
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Định nghĩa TimeSlotDTO và các phần còn lại giữ nguyên như trong code gốc
class TimeSlotDTO {
  final int id;
  final Duration startTime;
  final Duration endTime;
  final double price;
  final double duration;
  final bool isApplied;
  final bool isDeleted;

  TimeSlotDTO({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.price,
    required this.duration,
    required this.isApplied,
    required this.isDeleted,
  });

  factory TimeSlotDTO.fromJson(Map<String, dynamic> json) {
    return TimeSlotDTO(
      id: json['id'] ?? json['Id'] ?? 0,
      startTime: _parseTimeSpan(json['startTime'] ?? json['StartTime']),
      endTime: _parseTimeSpan(json['endTime'] ?? json['EndTime']),
      price: (json['price'] ?? json['Price'] as num?)?.toDouble() ?? 50000,
      duration:
          (json['duration'] ?? json['Duration'] as num?)?.toDouble() ?? 1.0,
      isApplied: json['isApplied'] ?? json['IsApplied'] ?? true,
      isDeleted: json['isDeleted'] ?? json['IsDeleted'] ?? false,
    );
  }

  static Duration _parseTimeSpan(String? timeSpan) {
    if (timeSpan == null || timeSpan.isEmpty) return const Duration(hours: 0);
    final parts = timeSpan.split(':');
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    final seconds = int.tryParse(parts[2]) ?? 0;
    return Duration(hours: hours, minutes: minutes, seconds: seconds);
  }

  String get startTimeString => _formatDuration(startTime);
  String get endTimeString => _formatDuration(endTime);

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    return "$hours:$minutes";
  }
}

class SlotChip extends StatefulWidget {
  final TimeSlotDTO slot;
  final bool isInitiallyAvailable;
  final Function(int, bool) onSelectionChanged;

  const SlotChip({
    Key? key,
    required this.slot,
    required this.isInitiallyAvailable,
    required this.onSelectionChanged,
  }) : super(key: key);

  @override
  _SlotChipState createState() => _SlotChipState();
}

class _SlotChipState extends State<SlotChip> {
  late bool _isAvailable;
  bool _isSelected = false;

  @override
  void initState() {
    super.initState();
    _isAvailable = widget.isInitiallyAvailable;
  }

  void updateState({bool? isAvailable, bool? isSelected}) {
    setState(() {
      if (isAvailable != null) _isAvailable = isAvailable;
      if (isSelected != null) _isSelected = isSelected;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      showCheckmark: false,
      label: Text(
        '${widget.slot.startTimeString} - ${widget.slot.endTimeString}',
        style: TextStyle(
          fontSize: 12,
          color: _isSelected
              ? Colors.white
              : (_isAvailable ? Colors.black : Colors.grey),
        ),
      ),
      selected: _isSelected,
      backgroundColor: _isAvailable ? null : Colors.grey[300],
      selectedColor: Colors.blue,
      labelPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
      onSelected: (selected) {
        widget.onSelectionChanged(widget.slot.id, selected);
      },
    );
  }
}
