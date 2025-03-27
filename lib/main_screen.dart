import 'package:flutter/material.dart';
import 'package:focus_badminton/screens/home_screen.dart';
import 'package:focus_badminton/screens/booking.dart';
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
        return HomeWidget();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined), label: 'Đặt sân'),
          BottomNavigationBarItem(
              icon: Icon(Icons.discount_outlined), label: 'Ưu đãi'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_outlined), label: 'Tài khoản'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromARGB(255, 0, 115, 177),
        unselectedItemColor: const Color.fromARGB(255, 100, 100, 100),
        onTap: _onItemTapped,
      ),
      body: _loadWidget(_selectedIndex),
    );
  }
}
