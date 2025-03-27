import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../utils/colors.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.main,
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 0),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 200,
                  height: 200,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                child: Center(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            children: [
                              const Text(
                                'Đăng ký',
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Theme(
                                data: ThemeData(
                                    colorScheme: ColorScheme.light(
                                  primary: Color.fromRGBO(0, 115, 177, 1.0),
                                )),
                                child: TextField(
                                  cursorColor: Color.fromRGBO(0, 115, 177, 1.0),
                                  decoration: InputDecoration(
                                    prefixIcon:
                                        const Icon(Icons.phone_outlined),
                                    labelText: 'Số điện thoại',
                                    border: const OutlineInputBorder(),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: const Color.fromRGBO(
                                              0, 115, 177, 1.0),
                                          width: 2.0),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Theme(
                                data: ThemeData(
                                    colorScheme: ColorScheme.light(
                                        primary:
                                            Color.fromRGBO(0, 115, 177, 1.0))),
                                child: TextField(
                                  cursorColor: Color.fromRGBO(0, 115, 177, 1.0),
                                  decoration: const InputDecoration(
                                    prefixIcon:
                                        Icon(Icons.account_circle_outlined),
                                    labelText: 'Họ và tên',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Theme(
                                data: ThemeData(
                                    colorScheme: ColorScheme.light(
                                        primary:
                                            Color.fromRGBO(0, 115, 177, 1.0))),
                                child: TextField(
                                  cursorColor: Color.fromRGBO(0, 115, 177, 1.0),
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.password_outlined),
                                    labelText: 'Nhập mật khẩu',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Theme(
                                data: ThemeData(
                                  colorScheme: ColorScheme.light(
                                    primary: Color.fromRGBO(
                                        0, 115, 177, 1.0), // Màu khi focus
                                  ),
                                ),
                                child: TextField(
                                  cursorColor: Color.fromRGBO(0, 115, 177, 1.0),
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.password_outlined),
                                    labelText: 'Nhập lại mật khẩu',
                                    border: OutlineInputBorder(),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color:
                                              Color.fromRGBO(0, 115, 177, 1.0),
                                          width: 2.0),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Container(
                            width: double.infinity,
                            height: 50, // Chiều cao của nút
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF0073B1),
                                  Color(0xFF00AEEF)
                                ], // Màu gradient
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const Login(),
                                    ));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors
                                    .transparent, // Đặt màu nền trong suốt để giữ gradient
                                shadowColor: Colors.transparent, // Bỏ bóng
                                padding: EdgeInsets
                                    .zero, // Loại bỏ padding mặc định để gradient phủ toàn bộ nút
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      6), // Bo góc giống Container
                                ),
                              ),
                              child: Text(
                                "Đăng ký",
                                style: TextStyle(
                                  fontSize: 18, // Cỡ chữ
                                  fontWeight: FontWeight.bold, // In đậm
                                  color: Colors.white, // Màu chữ
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Container(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 255, 255, 255),
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(width: 8),
                                  Image.asset(
                                    "assets/images/google.png",
                                    width: 30,
                                    height: 30,
                                  ),
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        "Đăng nhập với Google",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 32),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity, // Để phù hợp với mọi màn hình
                          height: 50,
                          alignment: Alignment.center, // Căn giữa nội dung
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Bạn đã có tài khoản?",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => Login()),
                                  );
                                },
                                child: Text(
                                  "Đăng nhập",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue, // Màu có thể tùy chỉnh
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
