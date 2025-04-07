import 'package:flutter/material.dart';
import 'package:focus_badminton/api_services/vouchers_service.dart';
import 'package:focus_badminton/utils/colors.dart';
import '../models/voucher.dart';
import 'package:focus_badminton/screens/fixed_booking_screen.dart';
import 'package:focus_badminton/screens/inday_booking_screen.dart';

class VouchersScreen extends StatelessWidget {
  const VouchersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final voucherService = VoucherService();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.accent,
        elevation: 0,
        title: Text(
          'Quà tặng & Ưu đãi',
          style: TextStyle(
            fontSize: isTablet ? 32 : 24,
            color: AppColors.textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: Colors.blue[50],
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              sliver: FutureBuilder<List<Voucher>>(
                future: voucherService.getVouchers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  } else if (snapshot.hasError) {
                    return SliverToBoxAdapter(
                      child: Center(child: Text('Error: ${snapshot.error}')),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Center(child: Text('Không có voucher nào')),
                    );
                  }

                  final vouchers = snapshot.data!;
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildVoucherCard(
                          vouchers[index], screenWidth, screenHeight, context),
                      childCount: vouchers.length,
                    ),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                child: Text(
                  'Nhanh tay đặt sân để nhận ưu đãi!',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    color: Colors.blueGrey[700],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoucherCard(Voucher voucher, double screenWidth,
      double screenHeight, BuildContext context) {
    // Định nghĩa bảng màu giống HomeWidget
    const Color accent = Color.fromARGB(255, 57, 179, 255);
    const Color textColor = Color.fromARGB(255, 20, 40, 60);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 8), // Giữ margin giống HomeWidget
      padding: EdgeInsets.all(screenWidth * 0.04), // Điều chỉnh padding
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
                  voucher.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'HSD: ${voucher.expiry != null ? voucher.expiry!.toString().substring(0, 10) : 'Không xác định'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16.0),
          ElevatedButton(
            onPressed: () {
              // Hiển thị bottom sheet với 2 lựa chọn
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(25.0)),
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
                color: Colors.blueGrey[800],
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
                  color: Colors.blue[700],
                ),
              ),
              SizedBox(width: screenWidth * 0.04),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isTablet ? 24 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
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
                backgroundColor: Colors.blue[700],
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
}
