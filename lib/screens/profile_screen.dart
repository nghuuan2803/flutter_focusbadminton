import 'package:flutter/material.dart';
import 'package:focus_badminton/api_services/auth_service.dart';
import 'package:focus_badminton/screens/login_screen.dart';
import 'package:focus_badminton/screens/personal_info.dart';
import 'package:focus_badminton/screens/register_screen.dart';
import 'package:focus_badminton/screens/team_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';
import 'booking_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final int memberId = 1;
  File? _profileImage;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // Kiểm tra trạng thái đăng nhập
  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await AuthService.isLoggedIn();
    setState(() {
      _isLoggedIn = isLoggedIn;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[900]!, Colors.blue[50]!],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false, // Ẩn nút Back
              expandedHeight: screenHeight * 0.35,
              flexibleSpace: FlexibleSpaceBar(
                background: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: _isLoggedIn
                      ? _buildLoggedInHeader(
                          screenWidth, screenHeight, isTablet)
                      : _buildNotLoggedInHeader(screenWidth, screenHeight),
                ),
              ),
            ),
            if (_isLoggedIn)
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: screenHeight * 0.02),
                        Text(
                          'Tài Khoản Của Bạn',
                          style: TextStyle(
                            fontSize: isTablet ? 26 : 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey[800],
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        _buildOptionTile(
                          icon: Icons.person_outline,
                          title: 'Thông Tin Cá Nhân',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const PersonalInfoScreen()),
                            );
                          },
                          screenWidth: screenWidth,
                        ),
                        _buildOptionTile(
                          icon: Icons.group,
                          title: 'Đội Nhóm',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const TeamScreen()),
                            );
                          },
                          screenWidth: screenWidth,
                        ),
                        _buildOptionTile(
                          icon: Icons.history,
                          title: 'Lịch Sử Đặt Sân',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookingHistoryScreen(),
                              ),
                            );
                          },
                          screenWidth: screenWidth,
                        ),
                        _buildOptionTile(
                          icon: Icons.settings,
                          title: 'Cài Đặt',
                          onTap: () {},
                          screenWidth: screenWidth,
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        Text(
                          'Thống Kê',
                          style: TextStyle(
                            fontSize: isTablet ? 26 : 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey[800],
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatCard('Điểm tích lũy', '7900',
                                Icons.sports_tennis, screenWidth),
                            _buildStatCard(
                                'Giờ Chơi', '129h', Icons.timer, screenWidth),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        SizedBox(
                          height: 45,
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[600],
                              padding: EdgeInsets.symmetric(
                                  vertical: screenHeight * 0.01),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () async {
                              await AuthService().LogOut();
                              setState(() {
                                _isLoggedIn = false;
                              });
                            },
                            child: Text(
                              'Đăng Xuất',
                              style: TextStyle(
                                  fontSize: isTablet ? 18 : 16,
                                  color: Colors.white),
                            ),
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
    );
  }

  Widget _buildLoggedInHeader(
      double screenWidth, double screenHeight, bool isTablet) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: AuthService.getUserInfo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final userInfo = snapshot.data ??
            {'name': 'Unknown', 'email': 'Unknown', 'avatar': ''};

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: isTablet ? screenWidth * 0.1 : screenWidth * 0.14,
                    backgroundColor: Colors.white,
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : (userInfo['avatar']?.isNotEmpty ?? false
                            ? NetworkImage(userInfo['avatar']) as ImageProvider
                            : null),
                    child: _profileImage == null &&
                            (userInfo['avatar']?.isEmpty ?? true)
                        ? Icon(
                            Icons.person,
                            size: isTablet
                                ? screenWidth * 0.12
                                : screenWidth * 0.18,
                            color: Colors.blue[700],
                          )
                        : null,
                  ),
                  Container(
                    padding: EdgeInsets.all(screenWidth * 0.015),
                    decoration: BoxDecoration(
                      color: Colors.blue[700],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: screenWidth * 0.05,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              userInfo['name'] ?? 'Unknown',
              style: TextStyle(
                fontSize: isTablet ? 28 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              userInfo['email'] ?? 'Unknown',
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                color: Colors.white70,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotLoggedInHeader(double screenWidth, double screenHeight) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.06,
          vertical: screenHeight * 0.02), // Giảm từ 0.06 xuống 0.02
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Hình minh họa
          Image.asset(
            'assets/images/NotLoggedInImage.png', // Thay bằng tên file của bạn
            width: screenWidth * 0.25, // Giảm từ 0.3 xuống 0.25
            height: screenWidth * 0.25,
            fit: BoxFit.contain,
          )
              .animate()
              .fadeIn(duration: Duration(milliseconds: 800))
              .scaleX(begin: 0.8)
              .scaleY(begin: 0.8),

          SizedBox(height: screenHeight * 0.01),

          // Tiêu đề
          const Text(
            'Tham Gia Ngay Hôm Nay!',
            style: TextStyle(
              fontSize: 24, // Giảm từ 26 xuống 24
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black45,
                  blurRadius: 3,
                  offset: Offset(0.1, 0.1),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(
              duration: Duration(milliseconds: 1000),
              delay: Duration(milliseconds: 200)),

          SizedBox(height: screenHeight * 0.01), // Giảm từ 0.015 xuống 0.01

          // Mô tả
          const Text(
            'Đăng nhập để khám phá ưu đãi, tích điểm và quản lý sân cầu lông dễ dàng.',
            style: TextStyle(
              fontSize: 13, // Giảm từ 14 xuống 13
              color: Colors.white70,
              height: 1.2, // Giảm từ 1.3 xuống 1.2
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(
              duration: Duration(milliseconds: 1200),
              delay: Duration(milliseconds: 400)),

          SizedBox(height: screenHeight * 0.015), // Giảm từ 0.02 xuống 0.015

          // Nút hành động
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Nút Đăng ký
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Register()),
                  ).then((_) => _checkLoginStatus());
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04, // Giảm từ 0.05 xuống 0.04
                    vertical: screenHeight * 0.01, // Giảm từ 0.012 xuống 0.01
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[400]!, Colors.blue[700]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                        color: const Color.fromARGB(255, 125, 173, 221)!,
                        width: 2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Text(
                    'Đăng Ký Ngay',
                    style: TextStyle(
                      fontSize: 13, // Giảm từ 14 xuống 13
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(
                      duration: Duration(milliseconds: 800),
                      delay: Duration(milliseconds: 600))
                  .moveY(begin: 10), // Giảm từ 15 xuống 10

              SizedBox(width: screenWidth * 0.02), // Giảm từ 0.03 xuống 0.02

              // Nút Đăng nhập
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Login()),
                  ).then((_) => _checkLoginStatus());
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04, // Giảm từ 0.05 xuống 0.04
                    vertical: screenHeight * 0.01, // Giảm từ 0.012 xuống 0.01
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.blue[700]!, width: 2),
                  ),
                  child: Text(
                    'Đăng Nhập',
                    style: TextStyle(
                      fontSize: 13, // Giảm từ 14 xuống 13
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(
                      duration: Duration(milliseconds: 800),
                      delay: Duration(milliseconds: 600))
                  .moveY(begin: 10), // Giảm từ 15 xuống 10
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required double screenWidth,
  }) {
    return ListTile(
      leading: CircleAvatar(
        radius: screenWidth * 0.05,
        backgroundColor: Colors.blue[100],
        child: Icon(icon, size: screenWidth * 0.06, color: Colors.blue[700]),
      ),
      title: Text(
        title,
        style: TextStyle(
            fontSize: screenWidth * 0.045, fontWeight: FontWeight.w500),
      ),
      trailing: Icon(Icons.arrow_forward_ios,
          size: screenWidth * 0.04, color: Colors.grey),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(vertical: screenWidth * 0.01),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, double screenWidth) {
    return Container(
      width: screenWidth * 0.4,
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: screenWidth * 0.08, color: Colors.blue[700]),
          SizedBox(height: screenWidth * 0.02),
          Text(
            value,
            style: TextStyle(
              fontSize: screenWidth * 0.06,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          Text(
            title,
            style: TextStyle(
                fontSize: screenWidth * 0.04, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
