import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:focus_badminton/api_services/vouchers_service.dart';
import '../models/voucher.dart';
import '../models/product.dart';
import 'dart:convert';
import 'package:focus_badminton/screens/fixed_booking_screen.dart';
import 'package:focus_badminton/screens/inday_booking_screen.dart';

import '../utils/format.dart';

class HomeWidget extends StatelessWidget {
  const HomeWidget({super.key});

  // Định nghĩa bảng màu
  static const Color main = Color.fromARGB(255, 219, 244, 255);
  static const Color accent = Color.fromARGB(255, 57, 179, 255);
  static const Color secondary = Color.fromARGB(255, 120, 200, 255);
  static const Color darkBackground = Color.fromARGB(255, 30, 60, 90);
  static const Color textColor = Color.fromARGB(255, 20, 40, 60);
  static const Color highlight = Color.fromARGB(255, 255, 185, 0);

  // Hàm đọc file JSON và parse thành danh sách Product
  Future<List<Product>> _loadProducts(BuildContext context) async {
    final String response = await DefaultAssetBundle.of(context)
        .loadString('assets/files/product.json');
    final List<dynamic> data = jsonDecode(response);
    return data.map((json) => Product.fromJson(json)).toList();
  }

  // Hàm định dạng giá tiền thủ công
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
      backgroundColor: main,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 8),
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
                      prefixIcon: Icon(Icons.search, color: textColor),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(16),
              height: screenHeight * 0.25,
              width: double.infinity,
              child: CarouselSlider(
                options: CarouselOptions(
                  autoPlay: true,
                  aspectRatio: screenWidth / (screenHeight * 0.25),
                  enlargeCenterPage: true,
                  viewportFraction: 1.0,
                  autoPlayAnimationDuration: const Duration(milliseconds: 800),
                ),
                items: [1, 2, 3].map((i) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                        width: screenWidth,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [secondary, accent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'Khuyến mãi $i\nGiảm giá 20%',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
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
                          // Hiển thị bottom sheet khi nhấn nút "Đặt sân"
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
                      _buildIconButton(context, Icons.gamepad, 'Mini game'),
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
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
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
                                  context,
                                  voucher.name,
                                  voucher.expiry!,
                                );
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                  _buildSectionTitle('Sản phẩm'),
                  SizedBox(
                    height: 8,
                  ),
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
      onTap: onTap, // Thêm sự kiện onTap
      child: Column(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white,
            child: Icon(icon, color: accent, size: 30),
          ),
          SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: textColor)),
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
                color: textColor,
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
                  builder: (context) => InDayBookingScreen(courtId: 1),
                ),
              );
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
                  builder: (context) => FixedBookingScreen(courtId: 1),
                ),
              );
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
            spreadRadius: 5,
          ),
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
                child: Icon(
                  icon,
                  size: screenWidth * 0.08,
                  color: accent,
                ),
              ),
              SizedBox(width: screenWidth * 0.04),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isTablet ? 24 : 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),
          Text(
            description,
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: screenHeight * 0.03),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: onPressed,
              child: Text(
                buttonText,
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  color: Colors.white,
                ),
              ),
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
          Text(
            title,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
          ),
          Text(
            'Xem thêm',
            style: TextStyle(color: accent, fontSize: 14),
          ),
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
              color: accent,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(
              Icons.discount,
              color: Colors.white,
              size: 30,
            ),
          ),
          SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  Format.formatDateTime(expiry),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16.0),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: Text(
              'Dùng',
              style: TextStyle(color: Colors.white),
            ),
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
          // Hình ảnh sản phẩm
          Container(
            height: 150,
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
                ? Center(child: Text(title, style: TextStyle(color: textColor)))
                : null,
          ),
          // Nội dung: Tên, giá, nút "Mua ngay"
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, color: textColor),
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
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Xử lý khi nhấn nút "Mua ngay"
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                    ),
                    child: Text(
                      'Mua ngay',
                      style: TextStyle(fontSize: 12, color: Colors.white),
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
}
