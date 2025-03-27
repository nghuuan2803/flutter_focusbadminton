import 'package:flutter/material.dart';
import 'package:focus_badminton/api_services/auth_service.dart';
import 'package:focus_badminton/screens/login_screen.dart';
import 'package:focus_badminton/screens/personal_info.dart';
import 'package:focus_badminton/screens/register_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'booking_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final int memberId = 1;
  // Hàm chọn ảnh từ thư viện
  File? _profileImage;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await AuthService.isLoggedIn();
    final userInfo = await AuthService.getUserInfo();
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
                        BorderRadius.vertical(top: Radius.circular(30)),
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
                                  builder: (context) => PersonalInfoScreen()),
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
                                builder: (context) => BookingHistoryScreen(
                                  memberId: memberId,
                                ),
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
                        _buildOptionTile(
                          icon: Icons.card_giftcard,
                          title: 'Ưu Đãi Của Tôi',
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
                            _buildStatCard('Sân Đã Đặt', '12',
                                Icons.sports_tennis, screenWidth),
                            _buildStatCard(
                                'Giờ Chơi', '25h', Icons.timer, screenWidth),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[600],
                              padding: EdgeInsets.symmetric(
                                  vertical: screenHeight * 0.02),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              FutureBuilder<Map<String, dynamic>?>(
                future: AuthService.getUserInfo(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    print("Error loading userInfo: ${snapshot.error}");
                    return Icon(Icons.error,
                        size: screenWidth * 0.15, color: Colors.red);
                  }
                  if (snapshot.hasData) {
                    final userInfo = snapshot.data!;
                    print("Displaying avatar: ${userInfo['avatar']}"); // Debug
                    return CircleAvatar(
                      radius: isTablet ? screenWidth * 0.1 : screenWidth * 0.14,
                      backgroundColor: Colors.white,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : (userInfo['avatar'] != null &&
                                  userInfo['avatar'].isNotEmpty
                              ? NetworkImage(userInfo['avatar'])
                                  as ImageProvider
                              : null),
                      child: _profileImage == null &&
                              (userInfo['avatar'] == null ||
                                  userInfo['avatar'].isEmpty)
                          ? Icon(
                              Icons.person,
                              size: isTablet
                                  ? screenWidth * 0.12
                                  : screenWidth * 0.18,
                              color: Colors.blue[700],
                            )
                          : null,
                    );
                  }
                  return Icon(Icons.error,
                      size: screenWidth * 0.15, color: Colors.red);
                },
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
        FutureBuilder<Map<String, dynamic>?>(
          future: AuthService.getUserInfo(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }
            if (snapshot.hasData) {
              final userInfo = snapshot.data!;
              return Column(
                children: [
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
            }
            return Text("Error loading user info",
                style: TextStyle(color: Colors.red));
          },
        ),
      ],
    );
  }

  Widget _buildNotLoggedInHeader(double screenWidth, double screenHeight) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.lock_outline,
          size: screenWidth * 0.15,
          color: Colors.white,
        ),
        SizedBox(height: screenHeight * 0.02),
        Text(
          'Vui lòng đăng nhập để trải nghiệm đầy đủ!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: screenHeight * 0.01),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          child: Text(
            'Đăng nhập để tích điểm, nhận voucher và quản lý lịch sử đặt sân dễ dàng.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: screenHeight * 0.02),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Register()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue[700],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text('Đăng ký'),
            ),
            SizedBox(width: screenWidth * 0.04),
            ElevatedButton(
              onPressed: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Login()),
                ).then((_) =>
                    _checkLoginStatus()); // Cập nhật trạng thái sau khi đăng nhập
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text('Đăng nhập'),
            ),
          ],
        ),
      ],
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
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: screenWidth * 0.04,
        color: Colors.grey,
      ),
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              spreadRadius: 1),
        ],
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
