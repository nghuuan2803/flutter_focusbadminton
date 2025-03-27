import 'package:flutter/material.dart';

class PaymentResultModal extends StatefulWidget {
  final bool isSuccess;
  final int bookingId;
  final VoidCallback onDismiss;

  const PaymentResultModal({
    required this.isSuccess,
    required this.bookingId,
    required this.onDismiss,
    Key? key,
  }) : super(key: key);

  @override
  _PaymentResultModalState createState() => _PaymentResultModalState();
}

class _PaymentResultModalState extends State<PaymentResultModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

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

    _controller.forward(); // Bắt đầu animation fade-in

    // Tự động đóng sau 2 giây
    Future.delayed(const Duration(seconds: 2), () {
      _controller.reverse().then((_) {
        widget.onDismiss();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.isSuccess ? Icons.check_circle : Icons.error,
                color: widget.isSuccess ? Colors.green : Colors.red,
                size: 50,
              ),
              const SizedBox(height: 10),
              Text(
                widget.isSuccess
                    ? 'Thanh toán thành công!'
                    : 'Thanh toán thất bại',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Booking ID: ${widget.bookingId}',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
