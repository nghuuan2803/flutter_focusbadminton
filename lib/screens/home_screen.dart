import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:focus_badminton/api_services/auth_service.dart';
import 'package:focus_badminton/api_services/vouchers_service.dart';
import 'package:focus_badminton/models/banner_model.dart';
import 'package:focus_badminton/provider/cart_provider.dart';
import 'package:focus_badminton/provider/notification_provider.dart';
import 'package:provider/provider.dart';
import '../models/voucher.dart';
import '../models/product.dart';
import 'dart:convert';
import 'package:focus_badminton/screens/fixed_booking_screen.dart';
import 'package:focus_badminton/screens/inday_booking_screen.dart';
import '../utils/colors.dart';
import '../utils/format.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  _HomeWidgetState createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  @override
  void initState() {
    super.initState();
  }

  Future<List<Product>> _loadProducts(BuildContext context) async {
    final String response = await DefaultAssetBundle.of(context)
        .loadString('assets/files/product.json');
    final List<dynamic> data = jsonDecode(response);
    return data.map((json) => Product.fromJson(json)).toList();
  }

  String formatPrice(int price) {
    String priceStr = price.toString();
    String result = '';
    int count = 0;

    for (int i = priceStr.length - 1; i >= 0; i--) {
      count++;
      result = priceStr[i] + result;
      if (count % 3 == 0 && i != 0) {
        result = '.' + result;
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final voucherService = VoucherService();

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.main,
        elevation: 1,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: AppColors.accent),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: Text(
          'Focus ',
          style: TextStyle(
            color: AppColors.accent,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, child) => Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  icon: Icon(Icons.shopping_cart, color: AppColors.accent),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Mở giỏ hàng')),
                    );
                  },
                ),
                if (cart.itemCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.red,
                      child: Text(
                        cart.itemCount.toString(),
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Consumer<NotificationProvider>(
            builder: (context, notification, child) => Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  icon: Icon(Icons.notifications, color: AppColors.accent),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Mở thông báo')),
                    );
                  },
                ),
                if (notification.notificationCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.red,
                      child: Text(
                        notification.notificationCount.toString(),
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: AppColors.accent,
              ),
              child: FutureBuilder<Map<String, dynamic>?>(
                future: AuthService.getUserInfo(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final userInfo = snapshot.data ?? {'name': 'Khách'};
                  print("UserInfo: $userInfo");
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 45,
                        backgroundImage: NetworkImage(
                            'https://i.pinimg.com/736x/8f/1c/a2/8f1ca2029e2efceebd22fa05cca423d7.jpg'),
                      ),
                      SizedBox(height: 10),
                      Text(
                        userInfo['name'] ?? 'Khách',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            ListTile(
              leading: Icon(Icons.home, color: AppColors.textColor),
              title: Text('Trang chủ'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading:
                  Icon(Icons.schedule_outlined, color: AppColors.textColor),
              title: Text('Đặt sân'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.card_giftcard, color: AppColors.textColor),
              title: Text('Khuyến mãi'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.gamepad_outlined, color: AppColors.textColor),
              title: Text('Game'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.theater_comedy_rounded,
                  color: AppColors.textColor),
              title: Text('Đội nhóm'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: AppColors.textColor),
              title: Text('Đăng xuất'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm',
                            prefixIcon:
                                Icon(Icons.search, color: AppColors.textColor),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
              height: screenHeight * 0.25,
              width: double.infinity,
              child: FutureBuilder<List<BannerModel>>(
                future: _loadBanners(context),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                        child: Text('Lỗi khi tải banner: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('Không có banner nào'));
                  }

                  final banners = snapshot.data!;
                  return CarouselSlider(
                    options: CarouselOptions(
                      autoPlay: true,
                      aspectRatio: screenWidth / (screenHeight * 0.25),
                      enlargeCenterPage: true,
                      viewportFraction: 1.0,
                      autoPlayAnimationDuration:
                          const Duration(milliseconds: 800),
                    ),
                    items: banners.map((banner) {
                      return Builder(
                        builder: (BuildContext context) {
                          return Container(
                            width: screenWidth,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: AssetImage(banner.image),
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildIconButton(
                        context,
                        Icons.schedule_outlined,
                        'Đặt sân',
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(25.0)),
                            ),
                            builder: (context) => DraggableScrollableSheet(
                              initialChildSize: 0.6,
                              minChildSize: 0.3,
                              maxChildSize: 0.9,
                              expand: false,
                              builder: (context, scrollController) {
                                return SingleChildScrollView(
                                  controller: scrollController,
                                  child: _buildBookingOptions(
                                      context, screenWidth, screenHeight),
                                );
                              },
                            ),
                          );
                        },
                      ),
                      _buildIconButton(
                          context, Icons.account_balance_wallet, 'Dịch vụ'),
                      _buildIconButton(
                          context, Icons.gamepad_outlined, 'Mini game'),
                      _buildIconButton(
                          context, Icons.card_giftcard, 'Quà tặng'),
                      _buildIconButton(context, Icons.more_horiz, 'Xem thêm'),
                    ],
                  ),
                  _buildSectionTitle('Mã khuyến mãi'),
                  Container(
                    height: 122,
                    child: FutureBuilder<List<Voucher>>(
                      future: voucherService.getVouchers(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(child: Text('Không có voucher nào'));
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return Center(child: Text('Không có voucher nào'));
                        }

                        final vouchers = snapshot.data!.take(5).toList();
                        return CarouselSlider(
                          options: CarouselOptions(
                            autoPlay: true,
                            aspectRatio: (screenWidth * 0.8) / 100,
                            enlargeCenterPage: false,
                            viewportFraction: 1,
                            autoPlayAnimationDuration:
                                const Duration(milliseconds: 800),
                          ),
                          items: vouchers.map((voucher) {
                            return Builder(
                              builder: (BuildContext context) {
                                return _buildVoucherCard(
                                    context, voucher.name, voucher.expiry!);
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                  _buildSectionTitle('Sản phẩm'),
                  SizedBox(height: 8),
                  FutureBuilder<List<Product>>(
                    future: _loadProducts(context),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(child: Text('Không có sản phẩm nào'));
                      }

                      final products = snapshot.data!;
                      return Column(
                        children: List.generate(
                          (products.length + 1) ~/ 2,
                          (rowIndex) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: (rowIndex * 2 < products.length)
                                        ? _buildProductCard(
                                            context,
                                            products[rowIndex * 2].name,
                                            products[rowIndex * 2].image,
                                            products[rowIndex * 2].price,
                                          )
                                        : SizedBox.shrink(),
                                  ),
                                  SizedBox(width: 8.0),
                                  Expanded(
                                    child: (rowIndex * 2 + 1 < products.length)
                                        ? _buildProductCard(
                                            context,
                                            products[rowIndex * 2 + 1].name,
                                            products[rowIndex * 2 + 1].image,
                                            products[rowIndex * 2 + 1].price,
                                          )
                                        : SizedBox.shrink(),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(BuildContext context, IconData icon, String label,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: AppColors.main,
            child: Icon(icon, color: AppColors.accent, size: 30),
          ),
          SizedBox(height: 8),
          Text(label,
              style: TextStyle(fontSize: 12, color: AppColors.textColor)),
        ],
      ),
    );
  }

  Widget _buildBookingOptions(
      BuildContext context, double screenWidth, double screenHeight) {
    final isTablet = screenWidth > 600;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
            child: Text(
              'Chọn Loại Đặt Sân',
              style: TextStyle(
                fontSize: isTablet ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
          ),
          _buildServiceCard(
            title: 'Đặt Sân Trong Ngày',
            description:
                'Chọn sân và khung giờ ngay trong ngày, nhanh chóng và tiện lợi.',
            icon: Icons.access_time,
            buttonText: 'Đặt Ngay',
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => InDayBookingScreen(courtId: 1)));
            },
            screenWidth: screenWidth,
            screenHeight: screenHeight,
            isTablet: isTablet,
          ),
          SizedBox(height: screenHeight * 0.04),
          _buildServiceCard(
            title: 'Đặt Sân Cố Định',
            description:
                'Đặt lịch cố định theo tuần, tháng hoặc năm với giá ưu đãi.',
            icon: Icons.calendar_today,
            buttonText: 'Đặt Ngay',
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => FixedBookingScreen(courtId: 1)));
            },
            screenWidth: screenWidth,
            screenHeight: screenHeight,
            isTablet: isTablet,
          ),
          SizedBox(height: screenHeight * 0.02),
        ],
      ),
    );
  }

  Widget _buildServiceCard({
    required String title,
    required String description,
    required IconData icon,
    required String buttonText,
    required VoidCallback onPressed,
    required double screenWidth,
    required double screenHeight,
    required bool isTablet,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              spreadRadius: 5)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: screenWidth * 0.07,
                backgroundColor: Colors.blue[100],
                child: Icon(icon,
                    size: screenWidth * 0.08, color: AppColors.accent),
              ),
              SizedBox(width: screenWidth * 0.04),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                      fontSize: isTablet ? 24 : 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textColor),
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),
          Text(description,
              style: TextStyle(
                  fontSize: isTablet ? 18 : 16, color: Colors.grey[700])),
          SizedBox(height: screenHeight * 0.03),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: onPressed,
              child: Text(buttonText,
                  style: TextStyle(
                      fontSize: isTablet ? 18 : 16, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor)),
          Text('Xem thêm',
              style: TextStyle(color: AppColors.accent, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildVoucherCard(
      BuildContext context, String title, DateTime expiry) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(8.0)),
            child: Icon(Icons.discount, color: Colors.white, size: 30),
          ),
          SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor)),
                SizedBox(height: 8),
                Text(Format.formatDateTime(expiry),
                    style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          SizedBox(width: 16.0),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0)),
            ),
            child: Text('Dùng', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
      BuildContext context, String title, String imagePath, int price) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              image: imagePath.isNotEmpty
                  ? DecorationImage(
                      image: AssetImage(imagePath),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imagePath.isEmpty
                ? Center(
                    child: Text(title,
                        style: TextStyle(color: AppColors.textColor)))
                : null,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, color: AppColors.textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  '${formatPrice(price)} VNĐ',
                  style: TextStyle(
                      fontSize: 12,
                      color: const Color.fromARGB(255, 255, 57, 57),
                      fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: 94,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 4.0),
                        ),
                        child: Text(
                          'Mua ngay',
                          style: TextStyle(fontSize: 12, color: Colors.white),
                        ),
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        border: Border.all(color: AppColors.accent, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.add,
                            color: const Color.fromARGB(255, 255, 255, 255)),
                        onPressed: () {
                          Provider.of<CartProvider>(context, listen: false)
                              .addItem();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('$title đã được thêm vào giỏ hàng')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<List<BannerModel>> _loadBanners(BuildContext context) async {
  final String response = await DefaultAssetBundle.of(context)
      .loadString('assets/files/banner.json');
  final List<dynamic> data = jsonDecode(response);
  return data.map((json) => BannerModel.fromJson(json)).toList();
}
