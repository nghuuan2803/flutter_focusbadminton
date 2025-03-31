// import 'package:flutter/material.dart';
// import 'package:focus_badminton/screens/fixed_booking_screen.dart';
// import 'package:focus_badminton/screens/schedule_screen.dart';

// class SelectBookingType extends StatelessWidget {
//   const SelectBookingType({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//     final isTablet = screenWidth > 600;

//     return Padding(
//       padding: EdgeInsets.symmetric(
//           horizontal: screenWidth * 0.05), // Thêm padding trái và phải
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           // Đặt Sân Trong Ngày (type: 1)
//           _buildServiceCard(
//             title: 'Đặt Sân Trong Ngày',
//             description:
//                 'Chọn sân và khung giờ ngay trong ngày, nhanh chóng và tiện lợi.',
//             icon: Icons.access_time,
//             buttonText: 'Đặt Ngay',
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => ScheduleScreen(courtId: 1),
//                 ),
//               );
//             },
//             screenWidth: screenWidth,
//             screenHeight: screenHeight,
//             isTablet: isTablet,
//           ),
//           SizedBox(height: screenHeight * 0.04),
//           // Đặt Sân Cố Định (type: 2)
//           _buildServiceCard(
//             title: 'Đặt Sân Cố Định',
//             description:
//                 'Đặt lịch cố định theo tuần, tháng hoặc năm với giá ưu đãi.',
//             icon: Icons.calendar_today,
//             buttonText: 'Đặt Ngay',
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => FixedBookingScreen(courtId: 1),
//                 ),
//               );
//             },
//             screenWidth: screenWidth,
//             screenHeight: screenHeight,
//             isTablet: isTablet,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildServiceCard({
//     required String title,
//     required String description,
//     required IconData icon,
//     required String buttonText,
//     required VoidCallback onPressed,
//     required double screenWidth,
//     required double screenHeight,
//     required bool isTablet,
//   }) {
//     return Container(
//       width: double.infinity, // Đặt width full để tận dụng padding từ parent
//       padding: EdgeInsets.all(screenWidth * 0.05),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(25),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 15,
//             spreadRadius: 5,
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               CircleAvatar(
//                 radius: screenWidth * 0.07,
//                 backgroundColor: Colors.blue[100],
//                 child: Icon(
//                   icon,
//                   size: screenWidth * 0.08,
//                   color: Colors.blue[700],
//                 ),
//               ),
//               SizedBox(width: screenWidth * 0.04),
//               Expanded(
//                 child: Text(
//                   title,
//                   style: TextStyle(
//                     fontSize: isTablet ? 24 : 20,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.blueGrey[800],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: screenHeight * 0.02),
//           Text(
//             description,
//             style: TextStyle(
//               fontSize: isTablet ? 18 : 16,
//               color: Colors.grey[700],
//             ),
//           ),
//           SizedBox(height: screenHeight * 0.03),
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blue[700],
//                 padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(15),
//                 ),
//               ),
//               onPressed: onPressed,
//               child: Text(
//                 buttonText,
//                 style: TextStyle(
//                   fontSize: isTablet ? 18 : 16,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:focus_badminton/screens/fixed_booking_screen.dart';
import 'package:focus_badminton/screens/schedule_screen.dart';

class SelectBookingType extends StatelessWidget {
  const SelectBookingType({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;

    return SingleChildScrollView(
      // Thêm scroll để chống vỡ giao diện
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        // padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Tiêu đề
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
            // Bảng giá
            _buildPriceTable(screenWidth, screenHeight, isTablet),
            SizedBox(height: 16),
            // Đặt Sân Trong Ngày (type: 1)
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
                    builder: (context) => ScheduleScreen(courtId: 1),
                  ),
                );
              },
              screenWidth: screenWidth,
              screenHeight: screenHeight,
              isTablet: isTablet,
            ),
            SizedBox(height: 16),
            // SizedBox(height: screenHeight * 0.04),
            // Đặt Sân Cố Định (type: 2)
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
            SizedBox(height: screenHeight * 0.02), // Khoảng cách dưới cùng
          ],
        ),
      ),
    );
  }

  Widget _buildPriceTable(
      double screenWidth, double screenHeight, bool isTablet) {
    // Dữ liệu bảng giá (có thể thay đổi theo yêu cầu)
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

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.03),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bảng Giá Đặt Sân',
            style: TextStyle(
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          Table(
            border: TableBorder.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
            columnWidths: {
              0: FlexColumnWidth(2), // Thứ
              1: FlexColumnWidth(2), // Khung giờ
              2: FlexColumnWidth(1.5), // Cố định
              3: FlexColumnWidth(1.5), // Vãng lai
            },
            children: [
              // Tiêu đề bảng
              TableRow(
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                ),
                children: [
                  _buildTableCell('Thứ', isTablet, isHeader: true),
                  _buildTableCell('Khung giờ', isTablet, isHeader: true),
                  _buildTableCell('Cố định', isTablet, isHeader: true),
                  _buildTableCell('Vãng lai', isTablet, isHeader: true),
                ],
              ),
              // Dữ liệu bảng
              ...priceData.map((row) {
                return TableRow(
                  children: [
                    _buildTableCell(row['day']!, isTablet),
                    _buildTableCell(row['time']!, isTablet),
                    _buildTableCell(row['fixed']!, isTablet),
                    _buildTableCell(row['casual']!, isTablet),
                  ],
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text, bool isTablet, {bool isHeader = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: isTablet ? 16 : 14,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: isHeader ? Colors.blueGrey[800] : Colors.black87,
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
      // padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
                backgroundColor: const Color.fromARGB(255, 58, 143, 228),
                // padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
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
