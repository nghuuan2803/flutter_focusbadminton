import 'package:flutter/material.dart';
import '../screens/manager_team_screen.dart';
import 'package:intl/intl.dart';

class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TeamHeader(),
            const SizedBox(height: 16),
            const MembersSection(),
            const SizedBox(height: 20),
            const OverviewSection(),
            const SizedBox(height: 30),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class TeamHeader extends StatelessWidget {
  const TeamHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: const AssetImage("assets/team_logo.png"),
            onBackgroundImageError: (_, __) => const Icon(Icons.error),
          ),
          const SizedBox(height: 8),
          const Text(
            "Cơn Lốc Xanh",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text("Ngày lập nhóm: 08/03/2025"),
        ],
      ),
    );
  }
}

class MembersSection extends StatelessWidget {
  const MembersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Thành viên",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ManagerTeamScreen()),
                );
              },
              icon: const Icon(
                Icons.manage_accounts,
                color: Colors.blue,
              ),
              label: const Text(
                "Quản lý",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 292,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 2,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, index) => MemberCard(
              name: index == 0 ? "Nguyễn Hữu An" : "Nguyễn Thành",
              phone: "0987654321",
              contribution: index == 0 ? 800000 : 500000,
              avatarUrl:
                  index == 0 ? "assets/avatar1.jpg" : "assets/avatar2.jpg",
            ),
          ),
        ),
      ],
    );
  }
}

class OverviewSection extends StatelessWidget {
  const OverviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.pie_chart, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              "Tổng quan",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: const [
            OverviewItem(icon: Icons.group, label: "Thành viên", value: "3"),
            OverviewItem(
                icon: Icons.sports_soccer,
                label: "Số trận đấu",
                value: "15 trận"),
            OverviewItem(
                icon: Icons.timer, label: "Số giờ chơi", value: "54 tiếng"),
            OverviewItem(
                icon: Icons.attach_money,
                label: "Tổng tiền góp",
                value: "1.800.000 VND"),
          ],
        ),
      ],
    );
  }
}

class MemberCard extends StatelessWidget {
  final String name;
  final String phone;
  final int contribution;
  final String avatarUrl;

  const MemberCard({
    super.key,
    required this.name,
    required this.phone,
    required this.contribution,
    required this.avatarUrl,
  });

  String formatCurrency(int amount) {
    final formatter = NumberFormat("#,###", "vi_VN");
    return "${formatter.format(amount)} VND";
  }

  // Dữ liệu mẫu cho lịch sử góp tiền
  final List<Map<String, dynamic>> contributionHistory = const [
    {"date": "01/04/2025", "amount": 500000},
    {"date": "15/03/2025", "amount": 300000},
    {"date": "15/03/2025", "amount": 300000},
    {"date": "15/03/2025", "amount": 300000},
    {"date": "15/03/2025", "amount": 300000},
    {"date": "15/03/2025", "amount": 300000},
    {"date": "15/03/2025", "amount": 300000},
    {"date": "15/03/2025", "amount": 300000},
    {"date": "15/03/2025", "amount": 300000},
    {"date": "15/03/2025", "amount": 300000},
    {"date": "15/03/2025", "amount": 300000},
    {"date": "15/03/2025", "amount": 300000},
    {"date": "15/03/2025", "amount": 300000},
    {"date": "15/03/2025", "amount": 300000},
    {"date": "15/03/2025", "amount": 300000},
    {"date": "15/03/2025", "amount": 300000},
    {"date": "15/03/2025", "amount": 300000},
    {"date": "15/03/2025", "amount": 300000},
    {"date": "15/03/2025", "amount": 300000},
    {"date": "15/03/2025", "amount": 300000},
  ];

  // Hàm hiển thị BottomSheet cho lịch sử góp tiền
  void _showContributionHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Lịch sử góp tiền - $name",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: contributionHistory.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final history = contributionHistory[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Ngày: ${history['date']}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Số tiền: ${formatCurrency(history['amount'])}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.teal,
                                ),
                              ),
                            ],
                          ),
                          const Icon(
                            Icons.access_time,
                            color: Colors.blue,
                            size: 20,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Hàm hiển thị Dialog khi nhấn "Edit"
  void _showEditMemberDialog(BuildContext context) {
    String selectedRole = "Trưởng nhóm"; // Giá trị mặc định cho Dropdown
    final List<String> roles = ["Trưởng nhóm", "Thành viên"];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.all(16), // Điều chỉnh padding
          content: SizedBox(
            width: MediaQuery.of(context).size.width *
                1, // Chiếm 90% chiều rộng màn hình
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Avatar
                  Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: AssetImage(avatarUrl),
                      onBackgroundImageError: (_, __) =>
                          const Icon(Icons.error),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Họ và tên
                  TextField(
                    decoration: InputDecoration(
                      labelText: "Họ và tên",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.person),
                    ),
                    controller: TextEditingController(text: name),
                  ),
                  const SizedBox(height: 16),
                  // Số tiền góp
                  TextField(
                    decoration: InputDecoration(
                      labelText: "Số tiền góp",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                    controller:
                        TextEditingController(text: contribution.toString()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  // Số điện thoại
                  TextField(
                    decoration: InputDecoration(
                      labelText: "Số điện thoại",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.phone),
                    ),
                    controller: TextEditingController(text: phone),
                    keyboardType: TextInputType.phone,
                    readOnly: true,
                    enableInteractiveSelection: false,
                  ),
                  const SizedBox(height: 16),
                  // Vai trò
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: InputDecoration(
                      labelText: "Vai trò",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.person_pin),
                    ),
                    items: roles.map((String role) {
                      return DropdownMenuItem<String>(
                        value: role,
                        child: Text(role),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      selectedRole = newValue!;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context); // Đóng Dialog
                          print("Xóa thành viên được nhấn");
                        },
                        icon: const Icon(Icons.delete, color: Colors.white),
                        label: const Text(
                          "Xóa thành viên",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context); // Đóng Dialog
                          print("Lưu được nhấn");
                        },
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: const Text(
                          "Lưu",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage(avatarUrl),
                    onBackgroundImageError: (_, __) => const Icon(Icons.error),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Liên hệ :",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          phone,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Số tiền góp :",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatCurrency(contribution),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                _showContributionHistory(context);
                              },
                              child: const Row(
                                children: [
                                  Text(
                                    "Xem lịch sử góp tiền",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color: Colors.blue,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () {
                  _showEditMemberDialog(context); // Gọi Dialog khi nhấn "Edit"
                },
                icon: const Icon(
                  Icons.edit,
                  color: Colors.black54,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OverviewItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const OverviewItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 48) / 2,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 14)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
