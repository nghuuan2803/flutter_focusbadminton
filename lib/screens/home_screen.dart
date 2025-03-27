import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromRGBO(219, 244, 255, 1),
                  Color.fromARGB(130, 255, 255, 255),
                ],
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
              // Header Carousel
              SliverToBoxAdapter(
                child: SizedBox(
                  height: screenHeight * 0.55, // Responsive height
                  child: CarouselSlider(
                    options: CarouselOptions(
                      autoPlay: true,
                      aspectRatio: isTablet ? 2.0 : 1.0,
                      enlargeCenterPage: true,
                      viewportFraction: isTablet ? 0.7 : 0.9,
                      autoPlayAnimationDuration: const Duration(
                        milliseconds: 800,
                      ),
                    ),
                    items: [1, 2, 3].map((i) {
                      return Builder(
                        builder: (BuildContext context) {
                          return FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Container(
                                margin: EdgeInsets.symmetric(
                                  vertical: screenHeight * 0.02,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 15,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(30),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.asset(
                                        'assets/images/court$i.jpg',
                                        fit: BoxFit.cover,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Container(
                                            color: Colors.grey[300],
                                            child: const Center(
                                              child: Text(
                                                'Không tải được ảnh',
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withOpacity(0.7),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(
                                          screenWidth * 0.04,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Sân $i',
                                              style: TextStyle(
                                                fontSize: isTablet ? 36 : 32,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(
                                              height: screenHeight * 0.01,
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.blue[700],
                                                padding: EdgeInsets.symmetric(
                                                  horizontal:
                                                      screenWidth * 0.08,
                                                  vertical: screenHeight * 0.02,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    50,
                                                  ),
                                                ),
                                              ),
                                              onPressed: () {},
                                              child: Text(
                                                'Đặt ngay',
                                                style: TextStyle(
                                                  fontSize: isTablet ? 20 : 18,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              // Nearby Courts
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.025,
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Giá của các sân',
                                style: TextStyle(
                                  fontSize: isTablet ? 28 : 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {},
                                child: Text(
                                  'Xem thêm',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isTablet ? 18 : 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: screenHeight * 0.025),
                          SizedBox(
                            height: screenHeight * 0.28,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: 4,
                              itemBuilder: (context, index) =>
                                  _buildCourtCard(index, screenWidth),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Skill Booster
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.025,
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kĩ năng cho người chơi ',
                            style: TextStyle(
                              fontSize: isTablet ? 28 : 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.025),
                          SizedBox(
                            height: screenHeight * 0.22,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: 4,
                              itemBuilder: (context, index) =>
                                  _buildSkillCard(index, screenWidth),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Popular Courts
              SliverPadding(
                padding: EdgeInsets.all(screenWidth * 0.04),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isTablet ? 3 : 2,
                    childAspectRatio: isTablet ? 0.85 : 0.75,
                    crossAxisSpacing: screenWidth * 0.04,
                    mainAxisSpacing: screenHeight * 0.02,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _buildPopularCourtCard(index, screenWidth),
                    childCount: 6,
                  ),
                ),
              ),
              // Why Book With Us
              // Trong phần "Why Book With Us" của build method
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.025,
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tại sao lại chọn chúng tôi?',
                            style: TextStyle(
                              fontSize: isTablet ? 28 : 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.025),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Expanded(
                                child: _buildFeatureCard(
                                  'Dễ dàng',
                                  Icons.book_online,
                                  'Hiệu quả',
                                  screenWidth / 3, // Chia đều cho 3 cột
                                ),
                              ),
                              Expanded(
                                child: _buildFeatureCard(
                                  'Giá tốt',
                                  Icons.price_check,
                                  'Giá cả hợp lý',
                                  screenWidth / 3,
                                ),
                              ),
                              Expanded(
                                child: _buildFeatureCard(
                                  'Hỗ trợ 24/7',
                                  Icons.support_agent,
                                  'Luôn ở đây',
                                  screenWidth / 3,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Footer Banner
              SliverToBoxAdapter(
                child: Container(
                  margin: EdgeInsets.all(screenWidth * 0.04),
                  padding: EdgeInsets.all(screenWidth * 0.06),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[800]!, Colors.blue[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Đặt lịch cố định!',
                        style: TextStyle(
                          fontSize: isTablet ? 28 : 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      Text(
                        'Đặt lịch theo tuần, tháng, năm',
                        style: TextStyle(
                          fontSize: isTablet ? 18 : 16,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: screenHeight * 0.025),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue[700],
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.1,
                            vertical: screenHeight * 0.02,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () {},
                        child: Text(
                          'Đặt ngay',
                          style: TextStyle(fontSize: isTablet ? 18 : 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      //   onPressed: _launchSMS,
      //   child: const Icon(Icons.chat, size: 28),
      //   elevation: 6,
      // ),
    );
  }

  // void _launchSMS() async {
  //   const phoneNumber = '+84947398426';
  //   final Uri smsUri = Uri.parse('sms:$phoneNumber'); // Thử với Uri.parse
  //   if (await canLaunchUrl(smsUri)) {
  //     debugPrint('Có thể mở SMS, đang thực hiện...');
  //     await launchUrl(smsUri, mode: LaunchMode.externalApplication);
  //   } else {
  //     debugPrint('Không mở được SMS. URI: $smsUri');
  //     debugPrint(
  //       'Kiểm tra: 1. Đã cài và đặt ứng dụng SMS mặc định chưa? (VD: Google Messages)',
  //     );
  //     debugPrint('2. Thiết bị có SIM và hỗ trợ SMS không?');
  //   }
  // }

  Widget _buildCourtCard(int index, double screenWidth) {
    return Container(
      width: screenWidth * 0.5,
      margin: EdgeInsets.only(right: screenWidth * 0.04),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Image.asset(
                'assets/images/court${index + 1}.jpg',
                height: screenWidth * 0.35,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: screenWidth * 0.35,
                    color: Colors.grey[300],
                    child: const Center(child: Text('Không tải được hình ảnh')),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.03),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sân ${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.045,
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.015),
                  Text(
                    '${(index + 1) * 50}K/Giờ',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.04,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillCard(int index, double screenWidth) {
    final skills = [
      'Người chơi kém',
      'Người chơi yếu',
      'Người chơi khá',
      'Người chơi giỏi',
    ];
    final videoUrls = [
      'https://youtu.be/6fVENMVhI34?si=GPn1BqKbGGhO3LJq',
      'https://youtu.be/_cQpUs8ut0s?si=Fn6pz9ldwluT2UIF',
      'https://youtu.be/ngNzwGaWk2M?si=GV5VyBRoAHCH1vj9',
      'https://youtu.be/De5otYjoLXg?si=mTGnYCill0naiWUN',
    ];
    return Container(
      width: screenWidth * 0.6,
      margin: EdgeInsets.only(right: screenWidth * 0.04),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.sports_tennis,
                    color: Colors.blue[700],
                    size: screenWidth * 0.08,
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  Flexible(
                    child: Text(
                      skills[index],
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenWidth * 0.03),
              Text(
                'Xem hướng dẫn nhanh để nâng cấp kỹ năng!',
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  color: Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: screenWidth * 0.04),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenWidth * 0.02,
                    ),
                  ),
                  onPressed: () async {
                    final url = Uri.parse(videoUrls[index]);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      debugPrint('Could not launch $url');
                    }
                  },
                  icon: Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: screenWidth * 0.05,
                  ),
                  label: Text(
                    'Xem',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.04,
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

  Widget _buildPopularCourtCard(int index, double screenWidth) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            child: Container(
              height: screenWidth * 0.20,
              color: Colors.grey[300],
              child: Center(
                child: Icon(
                  Icons.sports_tennis,
                  size: screenWidth * 0.12,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.03),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Court ${index + 1} Pro',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: screenWidth * 0.015),
                Text(
                  '${(index + 1) * 60}K/hour',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.04,
                  ),
                ),
                SizedBox(height: screenWidth * 0.025),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: screenWidth * 0.025,
                      ),
                    ),
                    onPressed: () {},
                    child: Text(
                      'Mua Ngay',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.035,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    String title,
    IconData icon,
    String subtitle,
    double maxWidth,
  ) {
    return Container(
      width: maxWidth,
      padding: EdgeInsets.all(maxWidth * 0.05),
      child: Column(
        children: [
          CircleAvatar(
            radius: maxWidth * 0.15,
            backgroundColor: Colors.blue[100],
            child: Icon(icon, size: maxWidth * 0.15, color: Colors.blue[700]),
          ),
          SizedBox(height: maxWidth * 0.05),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: maxWidth * 0.09,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: maxWidth * 0.07,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
