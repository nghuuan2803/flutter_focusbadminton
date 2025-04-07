import 'package:flutter/material.dart';
import 'package:focus_badminton/screens/fixed_booking_screen.dart';
import 'package:focus_badminton/screens/inday_booking_screen.dart';
import '../utils/colors.dart';

class SelectBookingType extends StatelessWidget {
  const SelectBookingType({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;

    return Container(
        color: AppColors.main,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                  ),
                  _buildPriceTable(screenWidth, screenHeight, isTablet),
                  SizedBox(height: 16),
                  _buildServiceCard(
                    title: 'Đặt Sân Trong Ngày',
                    description:
                        'Chọn sân và khung giờ ngay trong ngày, nhanh chóng và tiện lợi.',
                    icon: Icons.access_time,
                    buttonText: 'Đặt Ngay',
                    onPressed: () {
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
                  SizedBox(height: 16),
                  _buildServiceCard(
                    title: 'Đặt Sân Cố Định',
                    description:
                        'Đặt lịch cố định theo tuần, tháng hoặc năm với giá ưu đãi.',
                    icon: Icons.calendar_today,
                    buttonText: 'Đặt Ngay',
                    onPressed: () {
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
            ),
          ),
        ));
  }

  Widget _buildPriceTable(
      double screenWidth, double screenHeight, bool isTablet) {
    final List<Map<String, String>> priceData = [
      {
        'day': 'T2 - T6',
        'time': '6:00 - 17:00',
        'fixed': '80.000đ',
        'casual': '100.000đ'
      },
      {
        'day': 'T2 - T6',
        'time': '17:00 - 22:00',
        'fixed': '120.000đ',
        'casual': '150.000đ'
      },
      {
        'day': 'T7 - CN',
        'time': '6:00 - 17:00',
        'fixed': '100.000đ',
        'casual': '120.000đ'
      },
      {
        'day': 'T7 - CN',
        'time': '17:00 - 22:00',
        'fixed': '150.000đ',
        'casual': '180.000đ'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bảng Giá Đặt Sân',
          style: TextStyle(
            fontSize: isTablet ? 22 : 20,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[900],
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: screenHeight * 0.01),
        Table(
          border: TableBorder.all(
            color: Colors.grey[300]!,
            width: 1.5,
            borderRadius: BorderRadius.circular(8),
          ),
          columnWidths: {
            0: FlexColumnWidth(1.2), // Giảm diện tích cột "Thứ" từ 2 xuống 1.5
            1: FlexColumnWidth(1.8), // Giữ nguyên cột "Khung giờ"
            2: FlexColumnWidth(1.7), // Giữ nguyên cột "Cố định"
            3: FlexColumnWidth(1.4), // Giữ nguyên cột "Vãng lai"
          },
          children: [
            TableRow(
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              children: [
                _buildTableCell('Thứ', isTablet,
                    isHeader: true, textColor: Colors.white),
                _buildTableCell('Khung giờ', isTablet,
                    isHeader: true, textColor: Colors.white),
                _buildTableCell('Trong ngày', isTablet,
                    isHeader: true, textColor: Colors.white),
                _buildTableCell('Cố định', isTablet,
                    isHeader: true, textColor: Colors.white),
              ],
            ),
            ...priceData.map((row) {
              return TableRow(
                decoration: BoxDecoration(
                  color: row['day']!.contains('T7')
                      ? Colors.blue[50]
                      : Colors.white,
                ),
                children: [
                  _buildTableCell(row['day']!, isTablet),
                  _buildTableCell(row['time']!, isTablet),
                  _buildTableCell(
                    row['fixed']!,
                    isTablet,
                    textColor: Colors.green[700],
                  ),
                  _buildTableCell(
                    row['casual']!,
                    isTablet,
                    textColor: Colors.orange[800],
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  Widget _buildTableCell(String text, bool isTablet,
      {bool isHeader = false, Color? textColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 6.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: isTablet ? 16 : 14,
          fontWeight: isHeader
              ? FontWeight.bold
              : FontWeight.normal, // Bỏ in đậm cho nội dung
          color:
              textColor ?? (isHeader ? Colors.blueGrey[800] : Colors.black87),
        ),
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
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
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
          SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
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
