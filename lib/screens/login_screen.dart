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
  final _phoneController =
      TextEditingController(); // Controller cho số điện thoại
  final _passwordController =
      TextEditingController(); // Controller cho mật khẩu
  bool isObscure = true;
  bool _isLoading = false; // Trạng thái loading

  Future<void> _loginWithPassword() async {
    setState(() => _isLoading = true);
    final phoneNumber = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (phoneNumber.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Vui lòng nhập số điện thoại và mật khẩu")),
      );
      setState(() => _isLoading = false);
      return;
    }

    bool success = await _authService.passwordSignIn(phoneNumber, password);
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => MainScreen()), // Chuyển đến ProfileScreen
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Đăng nhập thất bại. Kiểm tra số điện thoại hoặc mật khẩu")),
      );
    }
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
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                            )
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: _isLoading
                              ? Center(child: CircularProgressIndicator())
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
                                        colorScheme: ColorScheme.light(
                                          primary:
                                              Color.fromRGBO(0, 115, 177, 1.0),
                                        ),
                                      ),
                                      child: TextField(
                                        controller: _phoneController,
                                        cursorColor:
                                            Color.fromRGBO(0, 115, 177, 1.0),
                                        keyboardType: TextInputType
                                            .phone, // Đảm bảo bàn phím số
                                        decoration: InputDecoration(
                                          prefixIcon:
                                              const Icon(Icons.phone_outlined),
                                          labelText: 'Số điện thoại',
                                          border: const OutlineInputBorder(),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: const Color.fromRGBO(
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
                                        colorScheme: ColorScheme.light(
                                          primary:
                                              Color.fromRGBO(0, 115, 177, 1.0),
                                        ),
                                      ),
                                      child: StatefulBuilder(
                                        builder: (context, setState) =>
                                            TextField(
                                          controller: _passwordController,
                                          cursorColor:
                                              Color.fromRGBO(0, 115, 177, 1.0),
                                          obscureText: isObscure,
                                          decoration: InputDecoration(
                                            prefixIcon: Icon(
                                              Icons.password_outlined,
                                              color: Color.fromRGBO(
                                                  0, 115, 177, 1.0),
                                            ),
                                            labelText: 'Nhập mật khẩu',
                                            border: OutlineInputBorder(),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                isObscure
                                                    ? Icons.visibility_off
                                                    : Icons.visibility,
                                                color: Color.fromRGBO(
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
                                        child: Text(
                                          "Quên mật khẩu ?",
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
                                        onPressed:
                                            _loginWithPassword, // Gọi hàm đăng nhập
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                        ),
                                        child: Text(
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
                                      padding: EdgeInsets.all(8),
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
                                                        MainScreen()),
                                              );
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Color.fromARGB(
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
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                      width: double.infinity,
                                      height: 50,
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
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
                                                        Register()),
                                              );
                                            },
                                            child: Text(
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
