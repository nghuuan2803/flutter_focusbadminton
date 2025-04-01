import 'package:flutter/material.dart';
import 'package:focus_badminton/screens/home_screen.dart';
import 'package:focus_badminton/screens/booking_screen.dart';
import 'package:focus_badminton/screens/profile_screen.dart';
import 'package:focus_badminton/screens/vouchers_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  _loadWidget(int index) {
    switch (index) {
      case 0:
        return const HomeWidget();
      case 1:
        return const SelectBookingType();
      case 2:
        return const VouchersScreen();
      case 3:
        return const ProfileScreen();
      default:
        return const HomeWidget();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loadWidget(_selectedIndex),
      bottomNavigationBar: Container(
        height: 70, // Chiều cao vừa phải, không quá lớn
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, 'Trang chủ', 0),
            _buildNavItem(
                Icons.calendar_today, 'Đặt sân', 1), // Thay icon phù hợp hơn
            _buildNavItem(
                Icons.local_offer, 'Ưu đãi', 2), // Thay icon thực tế hơn
            _buildNavItem(Icons.person, 'Tài khoản', 3), // Icon đơn giản hơn
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 26,
              color:
                  isSelected ? const Color(0xFF0288D1) : Colors.grey.shade600,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color:
                    isSelected ? const Color(0xFF0288D1) : Colors.grey.shade600,
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                height: 2,
                width: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF0288D1),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
