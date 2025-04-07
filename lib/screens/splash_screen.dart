import 'package:flutter/material.dart';
import 'package:focus_badminton/main_screen.dart';
import 'package:focus_badminton/screens/home_screen.dart';
import 'package:focus_badminton/utils/colors.dart'; // Đường dẫn đến HomeWidget

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome(); // Chuyển sang HomeWidget sau khi load
  }

  Future<void> _navigateToHome() async {
    // Giả lập thời gian load (có thể thay bằng logic tải dữ liệu thực tế)
    await Future.delayed(const Duration(seconds: 2));

    // Chuyển sang HomeWidget
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.main, // Màu nền của Splash Screen
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo hoặc hình ảnh
            Image.asset(
              'assets/images/logo.png', // Thay bằng đường dẫn đến logo của bạn
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 20),
            // Tên ứng dụng

            const SizedBox(height: 20),
            // Loading indicator
            const CircularProgressIndicator(
              color: Colors.blue, // Thay bằng màu thương hiệu
            ),
          ],
        ),
      ),
    );
  }
}
