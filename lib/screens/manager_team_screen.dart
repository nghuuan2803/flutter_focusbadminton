import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ManagerTeamScreen extends StatefulWidget {
  const ManagerTeamScreen({super.key});

  @override
  _ManagerTeamScreenState createState() => _ManagerTeamScreenState();
}

class _ManagerTeamScreenState extends State<ManagerTeamScreen> {
  // Danh sách thành viên mẫu
  final List<Map<String, dynamic>> members = [
    {
      "name": "Nguyễn Hữu An",
      "phone": "0987654321",
      "contribution": 800000,
      "role": "Trưởng nhóm",
      "avatarUrl": "assets/avatar1.jpg",
    },
    {
      "name": "Nguyễn Thành Trung",
      "phone": "0987654321",
      "contribution": 500000,
      "role": "Thành viên",
      "avatarUrl": "assets/avatar2.jpg",
    },
  ];

  // Danh sách thành viên đã lọc
  List<Map<String, dynamic>> filteredMembers = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredMembers = List.from(members);
    _searchController.addListener(_filterMembers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Hàm lọc thành viên dựa trên từ khóa tìm kiếm
  void _filterMembers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredMembers = List.from(members);
      } else {
        filteredMembers = members.where((member) {
          final name = member["name"].toString().toLowerCase();
          return name.contains(query);
        }).toList();
      }
    });
  }

  // Hàm hiển thị Dialog thêm thành viên
  void _showAddMemberDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController contributionController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.all(16),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Avatar
                  Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey.shade300,
                      child: const Icon(Icons.person,
                          size: 40, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Họ và tên
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "Họ và tên",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Số tiền góp
                  TextField(
                    controller: contributionController,
                    decoration: InputDecoration(
                      labelText: "Số tiền góp",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  // Số điện thoại
                  TextField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: "Số điện thoại",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          print("Hủy được nhấn");
                        },
                        icon: const Icon(Icons.cancel, color: Colors.white),
                        label: const Text(
                          "Hủy",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Thêm thành viên mới vào danh sách
                          if (nameController.text.isNotEmpty &&
                              phoneController.text.isNotEmpty &&
                              contributionController.text.isNotEmpty) {
                            setState(() {
                              members.add({
                                "name": nameController.text,
                                "phone": phoneController.text,
                                "contribution":
                                    int.parse(contributionController.text),
                                "role": "Thành viên", // Mặc định là Thành viên
                                "avatarUrl":
                                    "assets/avatar2.jpg", // Ảnh mặc định
                              });
                              _filterMembers(); // Cập nhật danh sách đã lọc
                            });
                            Navigator.pop(context);
                            print("Thêm thành viên: ${nameController.text}");
                          }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Quản lý thành viên",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // Thanh tìm kiếm
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Tìm kiếm thành viên...",
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[700]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                  ),
                ),
              ),
            ),

            // Danh sách thành viên
            Expanded(
              child: ListView.separated(
                itemCount: filteredMembers.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final member = filteredMembers[index];
                  return MemberItem(
                    name: member["name"],
                    phone: member["phone"],
                    contribution: member["contribution"],
                    role: member["role"],
                    avatarUrl: member["avatarUrl"],
                    onEdit: () {
                      _showEditMemberDialog(
                        context,
                        name: member["name"],
                        phone: member["phone"],
                        contribution: member["contribution"],
                        role: member["role"],
                        avatarUrl: member["avatarUrl"],
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                _showAddMemberDialog(context); // Gọi dialog thêm thành viên
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "Thêm thành viên",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Hàm hiển thị Dialog chỉnh sửa thành viên
  void _showEditMemberDialog(BuildContext context,
      {required String name,
      required String phone,
      required int contribution,
      required String role,
      required String avatarUrl}) {
    String selectedRole = role;
    final List<String> roles = ["Trưởng nhóm", "Thành viên"];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.all(16),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: AssetImage(avatarUrl),
                      onBackgroundImageError: (_, __) =>
                          const Icon(Icons.error),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                  ),
                  const SizedBox(height: 16),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
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
                          Navigator.pop(context);
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
}

class MemberItem extends StatelessWidget {
  final String name;
  final String phone;
  final int contribution;
  final String role;
  final String avatarUrl;
  final VoidCallback onEdit;

  const MemberItem({
    super.key,
    required this.name,
    required this.phone,
    required this.contribution,
    required this.role,
    required this.avatarUrl,
    required this.onEdit,
  });

  String formatCurrency(int amount) {
    final formatter = NumberFormat("#,###", "vi_VN");
    return "${formatter.format(amount)} VND";
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Nội dung chính của Card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage(avatarUrl),
                  onBackgroundImageError: (_, __) => const Icon(Icons.error),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Số điện thoại: $phone",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Số tiền góp: ${formatCurrency(contribution)}",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Vai trò ở góc phải trên
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: role == "Trưởng nhóm"
                    ? Colors.blue.shade100
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    role == "Trưởng nhóm" ? Icons.star : Icons.person,
                    size: 16,
                    color: role == "Trưởng nhóm" ? Colors.blue : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    role,
                    style: TextStyle(
                      fontSize: 12,
                      color: role == "Trưởng nhóm" ? Colors.blue : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Nút Edit ở góc phải dưới
          Positioned(
            bottom: 8,
            right: 8,
            child: IconButton(
              onPressed: onEdit,
              icon: const Icon(
                Icons.edit,
                color: Colors.black54,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
