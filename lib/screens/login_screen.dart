import 'package:flutter/material.dart';
import 'package:focus_badminton/api_services/auth_service.dart';
import 'package:focus_badminton/main_screen.dart';
import '../utils/colors.dart';
import 'register_screen.dart';

class Login extends StatefulWidget {
  const Login({super.key});
  @override
  State<Login> createState() => _Login();
}

class _Login extends State<Login> {
  final AuthService _authService = AuthService();
  final _identifierController =
      TextEditingController(); // Thay vì _phoneController
  final _passwordController = TextEditingController();
  bool isObscure = true;
  bool _isLoading = false;

  Future<void> _loginWithPassword() async {
    setState(() => _isLoading = true);
    final identifier =
        _identifierController.text.trim(); // Email hoặc số điện thoại
    final password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Vui lòng nhập email/số điện thoại và mật khẩu")),
      );
      setState(() => _isLoading = false);
      return;
    }

    bool success = await _authService.passwordSignIn(identifier, password);
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đăng nhập thất bại. Kiểm tra thông tin đăng nhập"),
        ),
      );
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
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
                padding: const EdgeInsets.all(0),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 200,
                  height: 200,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
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
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                            )
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : Column(
                                  children: [
                                    const Text(
                                      'Đăng nhập',
                                      style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Theme(
                                      data: ThemeData(
                                        colorScheme: const ColorScheme.light(
                                          primary:
                                              Color.fromRGBO(0, 115, 177, 1.0),
                                        ),
                                      ),
                                      child: TextField(
                                        controller: _identifierController,
                                        cursorColor: const Color.fromRGBO(
                                            0, 115, 177, 1.0),
                                        keyboardType: TextInputType
                                            .text, // Cho phép nhập cả email và số
                                        decoration: const InputDecoration(
                                          prefixIcon:
                                              Icon(Icons.person_outline),
                                          labelText: 'Email hoặc số điện thoại',
                                          border: OutlineInputBorder(),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Color.fromRGBO(
                                                  0, 115, 177, 1.0),
                                              width: 2.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Theme(
                                      data: ThemeData(
                                        colorScheme: const ColorScheme.light(
                                          primary:
                                              Color.fromRGBO(0, 115, 177, 1.0),
                                        ),
                                      ),
                                      child: StatefulBuilder(
                                        builder: (context, setState) =>
                                            TextField(
                                          controller: _passwordController,
                                          cursorColor: const Color.fromRGBO(
                                              0, 115, 177, 1.0),
                                          obscureText: isObscure,
                                          decoration: InputDecoration(
                                            prefixIcon: const Icon(
                                              Icons.password_outlined,
                                              color: Color.fromRGBO(
                                                  0, 115, 177, 1.0),
                                            ),
                                            labelText: 'Nhập mật khẩu',
                                            border: const OutlineInputBorder(),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                isObscure
                                                    ? Icons.visibility_off
                                                    : Icons.visibility,
                                                color: const Color.fromRGBO(
                                                    0, 115, 177, 1.0),
                                              ),
                                              onPressed: () {
                                                setState(() =>
                                                    isObscure = !isObscure);
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () {
                                          // Xử lý quên mật khẩu sau
                                        },
                                        child: const Text(
                                          "Quên mật khẩu?",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color.fromRGBO(
                                                0, 115, 177, 1.0),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFF00AEEF),
                                            Color(0xFF0073B1)
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _loginWithPassword,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                        ),
                                        child: const Text(
                                          "Đăng nhập",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
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
                                          onPressed: () async {
                                            bool rs = await _authService
                                                .googleSignIn();
                                            if (rs) {
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        const MainScreen()),
                                              );
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color.fromARGB(
                                                    255, 255, 255, 255),
                                            padding: EdgeInsets.zero,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
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
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            "Bạn chưa có tài khoản?",
                                            style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.black),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        const Register()),
                                              );
                                            },
                                            child: const Text(
                                              "Đăng ký",
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
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
