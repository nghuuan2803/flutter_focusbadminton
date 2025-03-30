import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:focus_badminton/utils/constants.dart';
import 'package:http/http.dart' as http;
import 'login_screen.dart';
import '../utils/colors.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  // Controllers để lấy dữ liệu từ TextField
  final _phoneController = TextEditingController();
  final _fullnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false; // Trạng thái loading khi gửi request

  // Hàm gửi request đăng ký tới backend
  Future<void> _register() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Mật khẩu không khớp!');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('${Constants.baseUrl}api/auth/register');
    final body = jsonEncode({
      'phoneNumber': _phoneController.text,
      'fullname': _fullnameController.text,
      'email': _emailController.text,
      'password': _passwordController.text,
      'confirmPassword': _confirmPasswordController.text,
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _showSnackBar(data['message'] ?? 'Đăng ký thành công!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Login()),
        );
      } else {
        final data = jsonDecode(response.body);
        final errors = data['errors'] ?? 'Đăng ký thất bại!';
        _showSnackBar(errors is List ? errors.join(', ') : errors.toString());
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Lỗi: $e');
    }
  }

  // Hàm hiển thị thông báo
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _fullnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

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
                padding: const EdgeInsets.only(top: 40),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 200,
                  height: 200,
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
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
                              onPressed: () {
                                Navigator.pop(context);
                              },
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
                                  colorScheme: const ColorScheme.light(
                                    primary: Color.fromRGBO(0, 115, 177, 1.0),
                                  ),
                                ),
                                child: TextField(
                                  controller: _phoneController,
                                  cursorColor:
                                      const Color.fromRGBO(0, 115, 177, 1.0),
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.phone_outlined),
                                    labelText: 'Số điện thoại',
                                    border: OutlineInputBorder(),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color:
                                              Color.fromRGBO(0, 115, 177, 1.0),
                                          width: 2.0),
                                    ),
                                  ),
                                  keyboardType: TextInputType.phone,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Theme(
                                data: ThemeData(
                                  colorScheme: const ColorScheme.light(
                                    primary: Color.fromRGBO(0, 115, 177, 1.0),
                                  ),
                                ),
                                child: TextField(
                                  controller: _fullnameController,
                                  cursorColor:
                                      const Color.fromRGBO(0, 115, 177, 1.0),
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
                                  colorScheme: const ColorScheme.light(
                                    primary: Color.fromRGBO(0, 115, 177, 1.0),
                                  ),
                                ),
                                child: TextField(
                                  controller: _emailController,
                                  cursorColor:
                                      const Color.fromRGBO(0, 115, 177, 1.0),
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.email_outlined),
                                    labelText: 'Email',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Theme(
                                data: ThemeData(
                                  colorScheme: const ColorScheme.light(
                                    primary: Color.fromRGBO(0, 115, 177, 1.0),
                                  ),
                                ),
                                child: TextField(
                                  controller: _passwordController,
                                  cursorColor:
                                      const Color.fromRGBO(0, 115, 177, 1.0),
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.password_outlined),
                                    labelText: 'Nhập mật khẩu',
                                    border: OutlineInputBorder(),
                                  ),
                                  obscureText: true,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Theme(
                                data: ThemeData(
                                  colorScheme: const ColorScheme.light(
                                    primary: Color.fromRGBO(0, 115, 177, 1.0),
                                  ),
                                ),
                                child: TextField(
                                  controller: _confirmPasswordController,
                                  cursorColor:
                                      const Color.fromRGBO(0, 115, 177, 1.0),
                                  decoration: const InputDecoration(
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
                                  obscureText: true,
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
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0073B1), Color(0xFF00AEEF)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : const Text(
                                      "Đăng ký",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Container(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(width: 8),
                                  Image.asset(
                                    "assets/images/google.png",
                                    width: 30,
                                    height: 30,
                                  ),
                                  const Expanded(
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
                                  const SizedBox(width: 32),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          height: 50,
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Bạn đã có tài khoản?",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => const Login()),
                                  );
                                },
                                child: const Text(
                                  "Đăng nhập",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
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
