import 'package:flutter/material.dart';
import 'package:focus_badminton/api_services/vouchers_service.dart';
import '../models/voucher_template.dart';
import 'package:focus_badminton/screens/fixed_booking_screen.dart';
import 'package:focus_badminton/screens/schedule_screen.dart';

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
        backgroundColor: Colors.blue[900],
        elevation: 0,
        title: Text(
          'Ưu Đãi & Voucher',
          style: TextStyle(
            fontSize: isTablet ? 32 : 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
              sliver: FutureBuilder<List<VoucherTemplate>>(
                future: voucherService.getVoucherTemplates(),
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

                  final voucherTemplates = snapshot.data!;
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildVoucherCard(
                          voucherTemplates[index],
                          screenWidth,
                          screenHeight,
                          context),
                      childCount: voucherTemplates.length,
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

  Widget _buildVoucherCard(VoucherTemplate voucherTemplate, double screenWidth,
      double screenHeight, BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.02),
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth * 0.03),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              Icons.local_offer,
              size: screenWidth * 0.1,
              color: Colors.blue[700],
            ),
          ),
          SizedBox(width: screenWidth * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  voucherTemplate.name,
                  style: TextStyle(
                    fontSize: screenWidth * 0.05,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                Text(
                  'Giá trị: ${voucherTemplate.value}',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                Text(
                  'Thời hạn: ${voucherTemplate.duration} ngày',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: Colors.red[600],
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.015,
              ),
            ),
            onPressed: () {
              // Hiển thị bottom sheet với 2 lựa chọn
              showModalBottomSheet(
                context: context,
                isScrollControlled:
                    true, // Cho phép bottom sheet chiếm toàn màn hình nếu cần
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(25.0)),
                ),
                builder: (context) => DraggableScrollableSheet(
                  initialChildSize: 0.6, // Chiều cao ban đầu của bottom sheet
                  minChildSize: 0.3, // Chiều cao tối thiểu
                  maxChildSize: 0.9, // Chiều cao tối đa
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
            child: Text(
              'Dùng',
              style: TextStyle(
                color: Colors.white,
                fontSize: screenWidth * 0.04,
              ),
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
          // Tiêu đề của bottom sheet
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
          // Đặt Sân Trong Ngày (type: 1)
          _buildServiceCard(
            title: 'Đặt Sân Trong Ngày',
            description:
                'Chọn sân và khung giờ ngay trong ngày, nhanh chóng và tiện lợi.',
            icon: Icons.access_time,
            buttonText: 'Đặt Ngay',
            onPressed: () {
              Navigator.pop(context); // Đóng bottom sheet
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ScheduleScreen(courtId: 1),
                ),
              );
            },
            screenWidth: screenWidth,
            screenHeight: screenHeight,
            isTablet: isTablet,
          ),
          SizedBox(height: screenHeight * 0.04),
          // Đặt Sân Cố Định (type: 2)
          _buildServiceCard(
            title: 'Đặt Sân Cố Định',
            description:
                'Đặt lịch cố định theo tuần, tháng hoặc năm với giá ưu đãi.',
            icon: Icons.calendar_today,
            buttonText: 'Đặt Ngay',
            onPressed: () {
              Navigator.pop(context); // Đóng bottom sheet
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
          SizedBox(height: screenHeight * 0.02), // Khoảng cách dưới cùng
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
