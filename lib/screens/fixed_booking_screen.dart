import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/booking.dart';
import '../api_services/slot_service.dart';
import '../api_services/booking_service.dart';
import '../api_services/schedule_service.dart';
import '../utils/constants.dart';

class FixedBookingScreen extends StatefulWidget {
  final int courtId;

  const FixedBookingScreen({Key? key, required this.courtId}) : super(key: key);

  @override
  _FixedBookingScreenState createState() => _FixedBookingScreenState();
}

class _FixedBookingScreenState extends State<FixedBookingScreen> {
  DateTime? _startDate = DateTime.now().add(Duration(days: 1));
  DateTime? _endDate = DateTime.now().add(Duration(days: 30));
  List<String> _selectedDays = [];
  List<TimeSlotDTO> _allTimeSlots = [];
  List<int> _availableTimeSlotIds = [];
  List<int> _selectedTimeSlotIds = [];
  Map<int, List<DateTime>> _availableDates = {};
  Map<int, List<DateTime>> _lockedDates = {};
  Map<int, List<int>> _holdIds = {}; // Sửa thành Map<int, List<int>>
  BookingDTO? _currentBooking;
  final SlotService _slotService = SlotService();
  final BookingService _bookingService = BookingService();
  final ScheduleService _scheduleService = ScheduleService();

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
    _fetchTimeSlots();
  }

  Future<void> _fetchTimeSlots() async {
    try {
      final response =
          await http.get(Uri.parse('${Constants.baseUrl}api/timeslots'));
      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _allTimeSlots = data
              .map((json) => TimeSlotDTO.fromJson(json))
              .where((slot) => slot.isApplied && !slot.isDeleted)
              .toList();
          print('Loaded TimeSlots: ${_allTimeSlots.length}');
          for (var slot in _allTimeSlots) {
            print(
                'Slot ID: ${slot.id}, Time: ${slot.startTimeString} - ${slot.endTimeString}');
          }
        });
      } else {
        throw Exception('Failed to load time slots: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching time slots: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải khung giờ: $e')),
      );
    }
  }

  Future<void> _fetchSlotAvailability() async {
    if (_startDate == null || _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng chọn ngày bắt đầu và ngày trong tuần')),
      );
      return;
    }

    try {
      final requestBody = jsonEncode({
        'CourtId': widget.courtId,
        'StartDate': _startDate!.toUtc().toIso8601String(),
        'EndDate': _endDate?.toUtc().toIso8601String(),
        'DaysOfWeek': _selectedDays,
      });
      print('Request Body: $requestBody');

      final response = await http.post(
        Uri.parse(
            '${Constants.baseUrl}api/schedules/check-multi-day-available'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );
      print('CheckMultiDay Response Status: ${response.statusCode}');
      print('CheckMultiDay Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _availableTimeSlotIds = data.map((id) => id as int).toList();
          _availableDates.clear();
          _lockedDates.clear();
          print('Updated _availableTimeSlotIds: $_availableTimeSlotIds');
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
      print('Error checking availability: $e');
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
        if (_endDate != null && _startDate!.isAfter(_endDate!)) {
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
      if (_startDate == null || _endDate == null || _selectedDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Vui lòng chọn đầy đủ ngày bắt đầu, ngày kết thúc và ngày trong tuần')));
        return false;
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

      final endAtLocal = DateTime(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day,
        slot.endTime.inHours,
        slot.endTime.inMinutes % 60,
      );

      final response = await http.post(
        Uri.parse('${Constants.baseUrl}api/slot/check-fixed-booking-hold'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'courtId': widget.courtId,
          'timeSlotId': timeSlotId,
          'beginAt': adjustedBeginAt.toUtc().toIso8601String(),
          'endAt': endAtLocal.toUtc().toIso8601String(),
          'daysOfWeek': _selectedDays,
          'bookingType': 2,
          'heldBy': '1',
        }),
      );

      print(
          'CheckFixedBookingHold Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['succeeded'] == true) {
          final holdResults = (data['data'] as List)
              .map((item) => {
                    'dayOfWeek': item['dayOfWeek'],
                    'holdId': item['holdId'] as int
                  })
              .toList();
          print('Hold Results: $holdResults');

          if (holdResults.every((result) => result['holdId'] == 0)) {
            throw Exception('Backend trả về holdId không hợp lệ (0)');
          }

          final holdIds =
              holdResults.map((result) => result['holdId'] as int).toList();
          setState(() {
            _holdIds[timeSlotId] = holdIds; // Lưu toàn bộ danh sách holdIds
            print('Stored holdIds for $timeSlotId: $holdIds');
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
      print('Error holding slot: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi khi giữ khung giờ: $e')));

      setState(() {
        _fetchSlotAvailability();
      });
      return false;
    }
  }

  int _calculateExpectedDays() {
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Vui lòng chọn đầy đủ thông tin và khung giờ')));
      return;
    }

    List<BookingItem> details = [];
    for (var timeSlotId in _selectedTimeSlotIds) {
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

      final endAtLocal = DateTime(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day,
        slot.endTime.inHours,
        slot.endTime.inMinutes % 60,
      );

      for (var dayOfWeek in _selectedDays) {
        details.add(BookingItem(
          courtId: widget.courtId,
          timeSlotId: timeSlotId,
          beginAt: adjustedBeginAt.toUtc(),
          endAt: endAtLocal.toUtc(),
          dayOfWeek: dayOfWeek,
          price: slot.price,
          amount: slot.price * _calculateExpectedDays(),
        ));
      }
    }

    setState(() {
      _currentBooking = BookingDTO(
        memberId: 1,
        type: 2,
        amount: details.fold(0.0, (sum, item) => sum + item.amount),
        deposit: details.length * 10000,
        details: details,
      );
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (modalContext) {
        String? selectedPaymentMethod;
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Xác nhận đặt sân',
                      style: Theme.of(modalContext).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  Text('Sân: ${widget.courtId}'),
                  Text(
                      'Bắt đầu: ${DateFormat('dd/MM/yyyy').format(_startDate!)}'),
                  Text(
                      'Kết thúc: ${_endDate != null ? DateFormat('dd/MM/yyyy').format(_endDate!) : 'Không xác định'}'),
                  Text('Các ngày: ${_selectedDays.join(', ')}'),
                  const Text('Khung giờ:'),
                  ..._selectedTimeSlotIds.map((id) {
                    final slot = _allTimeSlots.firstWhere((s) => s.id == id);
                    return Text(
                        '${slot.startTimeString} - ${slot.endTimeString}');
                  }),
                  Text(
                      'Tổng số giờ: ${details.length * (_allTimeSlots.first.duration) * _calculateExpectedDays()} giờ'),
                  Text('Tổng tiền: ${_currentBooking!.amount} VNĐ'),
                  Text('Đặt cọc: ${_currentBooking!.deposit} VNĐ'),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                        labelText: 'Phương thức thanh toán'),
                    value: selectedPaymentMethod,
                    items: ['Cash', 'BankTransfer', 'Momo', 'VnPay']
                        .map((method) => DropdownMenuItem(
                            value: method, child: Text(method)))
                        .toList(),
                    onChanged: (value) {
                      setModalState(() {
                        selectedPaymentMethod = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          if (selectedPaymentMethod == null) {
                            ScaffoldMessenger.of(modalContext).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Vui lòng chọn phương thức thanh toán')));
                            return;
                          }
                          try {
                            final bookingId = await _bookingService
                                .createBooking(_currentBooking!);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(
                                    'Đặt sân thành công! ID: $bookingId')));
                            Navigator.pop(modalContext);
                            _resetSelections();
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Lỗi khi đặt sân: $e')));
                          }
                        },
                        child: const Text('Xác nhận'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(modalContext);
                          _releaseHeldSlots();
                        },
                        child: const Text('Hủy'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
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

  Future<void> _releaseHeldSlots() async {
    if (_holdIds.isEmpty) return;

    try {
      final allHoldIds = _holdIds.values.expand((ids) => ids).toList();
      print('Releasing holdIds: $allHoldIds');
      final success = await _slotService.releaseMultipleSlots(allHoldIds);
      if (success) {
        setState(() {
          _holdIds.clear();
          _selectedTimeSlotIds.clear();
          _currentBooking = null;
          print('All slots released successfully');
        });
        await _fetchSlotAvailability();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể nhả tất cả slot')),
        );
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
      appBar: AppBar(title: const Text('Đặt sân cố định')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Container chứa 2 nút ngày float trái
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Nút chọn ngày bắt đầu
                    SizedBox(
                      width: 140, // Giới hạn chiều rộng để giống TextField
                      height: 40,
                      child: TextField(
                        readOnly: true, // Chỉ đọc, không cho nhập tay
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
                    const SizedBox(width: 8), // Khoảng cách giữa 2 nút ngày
                    // Nút chọn ngày kết thúc
                    SizedBox(
                      width: 140, // Giới hạn chiều rộng để giống TextField
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
                // Nút reset float phải
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
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: const Text('Chọn lịch'),
              ),
            ),
            const SizedBox(height: 20),
            if (_allTimeSlots.isNotEmpty) ...[
              Text('Chọn khung giờ:',
                  style: Theme.of(context).textTheme.titleMedium),
              SizedBox(
                height: 300,
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: _allTimeSlots.map((slot) {
                      final isSelected = _selectedTimeSlotIds.contains(slot.id);
                      final isAvailable =
                          _availableTimeSlotIds.contains(slot.id);

                      return FilterChip(
                        showCheckmark: false,
                        label: Text(
                          // '${slot.startTimeString}',
                          '${slot.startTimeString} - ${slot.endTimeString}',
                          style: TextStyle(
                            fontSize: 12,
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
                        onSelected: isAvailable
                            ? (selected) async {
                                if (selected) {
                                  final success =
                                      await _checkAndHoldSlot(slot.id);
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
                                        await _fetchSlotAvailability();
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Không thể bỏ giữ slot')),
                                        );
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Lỗi khi bỏ giữ slot: $e')),
                                      );
                                    }
                                  }
                                }
                              }
                            : null,
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _showBookingBottomSheet,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Đặt sân'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

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
