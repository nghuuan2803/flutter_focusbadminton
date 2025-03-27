import 'package:flutter/material.dart';
import 'package:focus_badminton/screens/fixed_booking_screen.dart';
import 'package:focus_badminton/screens/schedule_screen.dart';

class BookingTypeCard extends StatelessWidget {
  final int type;

  BookingTypeCard({required this.type, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(0),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => type == 1
                    ? ScheduleScreen(courtId: 1)
                    : FixedBookingScreen(courtId: 1)),
          );
        },
        child: Text(type == 1 ? 'Đặt trong ngày' : 'Đặt cố định'),
      ),
    );
  }
}
