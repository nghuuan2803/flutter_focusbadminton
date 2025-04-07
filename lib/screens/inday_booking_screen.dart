import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:focus_badminton/api_services/auth_service.dart';
import '../api_services/booking_service.dart';
import '../api_services/payment_service.dart';
import '../api_services/schedule_service.dart';
import '../api_services/signalr_service.dart';
import '../api_services/slot_service.dart';
import '../api_services/vouchers_service.dart';
import '../main_screen.dart';
import '../mediators/booking_mediator.dart';
import '../models/booking.dart';
import '../models/slot.dart';
import '../models/voucher.dart';
import '../utils/deep_link_handler.dart';
import '../utils/format.dart';
import '../widgets/payment_result_modal.dart';
import '../widgets/slot_card.dart';
import 'booking_detail_screen.dart';
import '../utils/colors.dart';

class InDayBookingScreen extends StatefulWidget {
  final int courtId;
  final Voucher? initialVoucher;

  const InDayBookingScreen({
    required this.courtId,
    this.initialVoucher,
    Key? key,
  }) : super(key: key);

  @override
  _InDayBookingScreenState createState() => _InDayBookingScreenState();
}

class _InDayBookingScreenState extends State<InDayBookingScreen>
    with WidgetsBindingObserver {
  late ConcreteBookingMediator _mediator;
  List<Slot> schedules = [];
  List<Duration> timeSlots = [];
  bool isLoading = true;
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now().add(const Duration(days: 6));
  bool isTimeSlotVertical = false;
  List<BookingItem> selectedSlots = [];
  BookingDTO? currentBooking;
  PersistentBottomSheetController? _bottomSheetController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isProcessing = false;
  Voucher? selectedVoucher;
  List<Voucher> availableVouchers = [];
  AppLinks? _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  String selectedPaymentMethod = PaymentMethod.cash.name;

  String? _memberId;
  AuthService? authService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _mediator = ConcreteBookingMediator(
      scheduleService: ScheduleService(),
      slotService: SlotService(),
      bookingService: BookingService(),
      paymentService: PaymentService(),
      voucherService: VoucherService(),
      signalRService: SignalRService(),
      courtId: widget.courtId,
    );
    _mediator.setUICallback(_updateUI);
    selectedVoucher = widget.initialVoucher;

    _appLinks = AppLinks();
    _initDeepLink();
    _loadInitialData();
    _getMemberId();
  }

  Future<void> _getMemberId() async {
    _memberId = await AuthService.getMemberId();
  }

  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);
    try {
      await _mediator.loadSchedules(widget.courtId, startDate, endDate);
      availableVouchers = await _mediator.loadVouchers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải dữ liệu: $e')),
      );
    }
    setState(() => isLoading = false);
  }

  void _updateUI(List<Slot> newSchedules, List<BookingItem> newSelectedSlots,
      BookingDTO? newBooking) {
    setState(() {
      schedules = newSchedules;
      timeSlots = schedules.map((s) => s.startTime).toSet().toList()
        ..sort((a, b) => a.inMinutes.compareTo(b.inMinutes));
      selectedSlots = newSelectedSlots;
      currentBooking = newBooking;
      // Đồng bộ selectedPaymentMethod với currentBooking
      selectedPaymentMethod =
          currentBooking?.paymentMethod.name ?? PaymentMethod.cash.name;
      // Logic hiển thị/ẩn Bottom Sheet
      if (selectedSlots.isNotEmpty && _bottomSheetController == null) {
        _showPersistentBottomSheet();
      } else if (selectedSlots.isEmpty && _bottomSheetController != null) {
        _bottomSheetController!.close();
        _bottomSheetController = null;
      } else if (_bottomSheetController != null) {
        _bottomSheetController!.setState!(() {});
      }
    });
  }

  Future<void> _updateSlot(BuildContext context, Slot slot) async {
    try {
      print("screen -update slot - heldby: ${slot.heldBy}");
      print("screen -update slot - memberId: ${_memberId}");
      print("screen -update slot - status: ${slot.status}");
      int heldby = slot.heldBy == null ? 0 : int.parse(slot.heldBy!);
      int memberId = int.parse(_memberId!);
      if (slot.status == 1) {
        await _mediator.holdSlot(slot);
      } else if (slot.status == 2 && slot.heldBy! == _memberId!) {
        await _mediator.releaseSlot(slot);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xử lý slot: $e')),
      );
    }
  }

  Future<void> _handlePayment() async {
    if (isProcessing || currentBooking == null) return;
    setState(() => isProcessing = true);
    try {
      // Lưu paymentMethod trước khi gọi createBooking
      final paymentMethod = currentBooking!.paymentMethod;
      final bookingId = await _mediator.createBooking();
      if (bookingId != null) {
        if (paymentMethod == PaymentMethod.cash) {
          _showPaymentResultModal(true, bookingId); // Hiển thị modal
        } else {
          debugPrint(
              "Waiting for deep link callback for payment method: $paymentMethod");
        }
      } else {
        throw Exception("Booking ID is null");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đặt sân thất bại: $e')),
      );
    } finally {
      setState(() => isProcessing = false);
    }
  }

  void _initDeepLink() async {
    final Uri? initialUri = await _appLinks!.getInitialLink();
    if (initialUri != null &&
        !DeepLinkHandler.isProcessed(initialUri.toString())) {
      _handlePaymentCallback(initialUri);
      DeepLinkHandler.markAsProcessed(initialUri.toString());
    }
    _linkSubscription = _appLinks!.uriLinkStream.listen((Uri? uri) {
      if (uri != null && !DeepLinkHandler.isProcessed(uri.toString())) {
        _handlePaymentCallback(uri);
        DeepLinkHandler.markAsProcessed(uri.toString());
      }
    });
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

  void _showPersistentBottomSheet() {
    _bottomSheetController?.close();
    _bottomSheetController = _scaffoldKey.currentState!.showBottomSheet(
      (context) => DraggableScrollableSheet(
        initialChildSize: 0.2,
        minChildSize: 0.2,
        maxChildSize: 0.8,
        expand: false,
        builder: (_, scrollController) => StatefulBuilder(
          builder: (_, setBottomSheetState) {
            String selectedPaymentMethod =
                currentBooking?.paymentMethod.name ?? PaymentMethod.cash.name;

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
                          if (selectedSlots.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text('Chưa chọn lịch',
                                  style: TextStyle(color: Colors.grey)),
                            )
                          else
                            Column(
                              children: selectedSlots
                                  .map((slot) => Card(
                                        elevation: 2,
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 4),
                                        child: ListTile(
                                          title: Text(
                                              '${slot.courtName} - ${slot.beginAt?.toString().substring(0, 16)}'),
                                          subtitle: Text(
                                              'Giá: ${Format.formatVNCurrency(slot.price)}'), // Hiển thị giá từ API
                                          trailing: IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.red),
                                            onPressed: () async {
                                              final schedule =
                                                  schedules.firstWhere(
                                                (s) =>
                                                    s.timeSlotId ==
                                                        slot.timeSlotId &&
                                                    _isSameDay(s.scheduleDate,
                                                        slot.beginAt!),
                                              );
                                              await _mediator
                                                  .releaseSlot(schedule);
                                              setBottomSheetState(() {});
                                            },
                                          ),
                                        ),
                                      ))
                                  .toList(),
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
                                    (currentBooking?.amount ?? 0)),
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
                                if (currentBooking != null) {
                                  currentBooking!.applyVoucher(selectedVoucher);
                                  _mediator
                                      .updateUI(); // Cập nhật UI sau khi áp dụng voucher
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
                                  // Sửa logic hiển thị ở đây
                                  '-${_getFormattedDiscount()}',
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
                                _calculateFinalAmount(), // Sử dụng phương thức mới
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
                                    _mediator.updatePaymentMethod(
                                        method); // Gọi mediator để cập nhật
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
                              onPressed: (selectedSlots.isEmpty || isProcessing)
                                  ? null
                                  : _handlePayment,
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.green,
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
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDefaultTable() {
    final uniqueDates = schedules.map((s) => s.scheduleDate).toSet().toList()
      ..sort((a, b) => a.compareTo(b));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
                width: 70,
                height: 50,
                child: const Center(child: Text("Ngày"))),
            ...uniqueDates.map((date) => Container(
                  width: 70,
                  height: 50,
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 0.1)),
                  child: Center(
                    child: Text(
                      "${date.day}/${date.month}\n(${_getVietnameseDayOfWeek(date)})",
                      textAlign: TextAlign.center,
                    ),
                  ),
                )),
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
                      .map((time) => Container(
                            width: 70,
                            height: 50,
                            decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.black, width: 0.1)),
                            child: Center(
                              child: Text(
                                "${time.inHours.toString().padLeft(2, '0')}:${(time.inMinutes % 60).toString().padLeft(2, '0')}",
                              ),
                            ),
                          ))
                      .toList(),
                ),
                Column(
                  children: uniqueDates
                      .map((date) => Row(
                            children: timeSlots.map((time) {
                              final slot = schedules.firstWhere(
                                (s) =>
                                    _isSameDay(s.scheduleDate, date) &&
                                    s.startTime == time,
                                orElse: () => Slot(
                                  scheduleDate: date,
                                  courtId: widget.courtId,
                                  courtName: "Sân 1",
                                  timeSlotId: 0,
                                  startTime: time,
                                  endTime: time + const Duration(minutes: 30),
                                  status: 1,
                                  dayOfWeek: _getEnglishDayOfWeek(date),
                                ),
                              );
                              return SlotCard(
                                  userId: _memberId!,
                                  schedule: slot,
                                  onSlotUpdate: _updateSlot);
                            }).toList(),
                          ))
                      .toList(),
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
                  child: const Center(child: Text("Giờ"))),
              ...timeSlots.map((time) => Container(
                    width: 70,
                    height: 50,
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 0.1)),
                    child: Center(
                      child: Text(
                        "${time.inHours.toString().padLeft(2, '0')}:${(time.inMinutes % 60).toString().padLeft(2, '0')}",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )),
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
                        .map((date) => Container(
                              width: 70,
                              height: 50,
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.black, width: 0.1)),
                              child: Center(
                                child: Text(
                                  "${date.day}/${date.month}\n(${_getVietnameseDayOfWeek(date)})",
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  Column(
                    children: timeSlots
                        .map((time) => Row(
                              children: uniqueDates.map((date) {
                                final slot = schedules.firstWhere(
                                  (s) =>
                                      _isSameDay(s.scheduleDate, date) &&
                                      s.startTime == time,
                                  orElse: () => Slot(
                                    scheduleDate: date,
                                    courtId: widget.courtId,
                                    courtName: "Sân 1",
                                    timeSlotId: 0,
                                    startTime: time,
                                    endTime: time + const Duration(minutes: 30),
                                    status: 1,
                                    dayOfWeek: _getEnglishDayOfWeek(date),
                                  ),
                                );
                                return SlotCard(
                                    userId: _memberId!,
                                    schedule: slot,
                                    onSlotUpdate: _updateSlot);
                              }).toList(),
                            ))
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
        if (startDate.isAfter(endDate)) endDate = startDate;
        _mediator.loadSchedules(widget.courtId, startDate, endDate);
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: endDate,
      firstDate: startDate,
      lastDate: startDate.add(const Duration(days: 7)),
    );
    if (picked != null && picked != endDate) {
      setState(() {
        endDate = picked;
        _mediator.loadSchedules(widget.courtId, startDate, endDate);
      });
    }
  }

  void _resetDates() {
    setState(() {
      startDate = DateTime.now();
      endDate = DateTime.now().add(const Duration(days: 6));
      _mediator.loadSchedules(widget.courtId, startDate, endDate);
    });
  }

  void _toggleTableView(bool value) =>
      setState(() => isTimeSlotVertical = value);

  String _getVietnameseDayOfWeek(DateTime date) {
    const days = [
      "",
      "Thứ 2",
      "Thứ 3",
      "Thứ 4",
      "Thứ 5",
      "Thứ 6",
      "Thứ 7",
      "CN"
    ];
    return days[date.weekday];
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

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  String _getFormattedDiscount() {
    if (selectedVoucher == null || currentBooking == null) {
      return Format.formatVNCurrency(0);
    }

    final voucher = selectedVoucher!;
    final total = currentBooking!.amount;

    // Xử lý logic giảm giá
    if (voucher.discountType == 0) {
      // Loại cố định
      return Format.formatVNCurrency(voucher.value);
    } else {
      // Loại phần trăm + check maximum
      double discount = (total * voucher.value) / 100;
      if (voucher.maximumValue > 0 && discount > voucher.maximumValue) {
        discount = voucher.maximumValue;
      }
      return Format.formatVNCurrency(discount);
    }
  }

  String _calculateFinalAmount() {
    final total = currentBooking?.amount ?? 0;
    if (selectedVoucher == null) return Format.formatVNCurrency(total);

    double discount = 0;
    if (selectedVoucher!.discountType == 0) {
      // Giảm cố định
      discount = selectedVoucher!.value;
    } else {
      // Giảm phần trăm (kiểm tra giá trị tối đa)
      discount = (total * selectedVoucher!.value) / 100;
      if (selectedVoucher!.maximumValue > 0 &&
          discount > selectedVoucher!.maximumValue) {
        discount = selectedVoucher!.maximumValue;
      }
    }
    return Format.formatVNCurrency(total - discount);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSubscription?.cancel();
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
                    foregroundColor: AppColors.textColor,
                    backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _selectEndDate(context),
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                      "Đến ${endDate.day}/${endDate.month}/${endDate.year}"),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: AppColors.textColor,
                    backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const Spacer(), // Đẩy nút reset sang phải
                ElevatedButton(
                  onPressed: _resetDates,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.lightBlue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5)),
                    padding: const EdgeInsets.all(10),
                    minimumSize: const Size(40, 40),
                  ),
                  child: const Icon(Icons.refresh, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
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
            const SizedBox(height: 16),
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
}

extension StringExtension on String {
  String capitalize() {
    switch (toLowerCase()) {
      case 'cash':
        return 'Trả sau';
      case 'banktransfer':
        return 'Chuyển khoản';
      case 'momo':
        return 'MoMo';
      case 'vnpay':
        return 'VnPay';
      default:
        return this;
    }
  }
}
