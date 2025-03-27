import 'package:flutter/material.dart';
import 'package:focus_badminton/api_services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  Map<String, dynamic>? _userInfo;
  File? _newAvatar;
  bool _isEditing = false;
  bool _isLoading = false;

  final _fullNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _genderController = TextEditingController();
  final _dobController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final userInfo = await AuthService.getUserInfo();
    setState(() {
      _userInfo = userInfo;
      _fullNameController.text = _userInfo?['name'] ?? '';
      _addressController.text = _userInfo?['address'] ?? '';
      _genderController.text = _userInfo?['gender'] ?? '';
      _dobController.text = _userInfo?['dob'] ?? '';
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _newAvatar = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateUserInfo() async {
    setState(() => _isLoading = true);
    final accessToken = await SharedPreferences.getInstance()
        .then((prefs) => prefs.getString('accessToken'));
    if (accessToken == null || accessToken.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Token không hợp lệ')));
      setState(() => _isLoading = false);
      return;
    }

    final url = Uri.parse('${Constants.baseUrl}api/user/info');
    final body = {
      'fullName': _fullNameController.text,
      'address': _addressController.text,
      'gender': _genderController.text,
      'dob': _dobController.text.isNotEmpty ? _dobController.text : null,
      if (_newAvatar != null)
        'avatar': base64Encode(_newAvatar!.readAsBytesSync()),
    };

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    setState(() => _isLoading = false);
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Cập nhật thành công')));
      await _loadUserInfo();
      setState(() => _isEditing = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cập nhật thất bại: ${response.body}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[900]!, Colors.blue[200]!, Colors.white],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              expandedHeight: screenHeight * 0.3,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Padding(
                  padding: EdgeInsets.only(
                      top: screenHeight * 0.05, bottom: screenHeight * 0.02),
                  child: _buildAvatar(screenWidth),
                ),
              ),
              actions: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton(
                    onPressed: _userInfo == null
                        ? null
                        : () {
                            if (_isEditing) {
                              _updateUserInfo();
                            } else {
                              setState(() => _isEditing = true);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [Colors.blue[700]!, Colors.blue[400]!]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _isEditing ? 'Lưu' : 'Chỉnh sửa',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12, blurRadius: 10, spreadRadius: 2)
                  ],
                ),
                child: _userInfo == null
                    ? Padding(
                        padding: EdgeInsets.all(screenWidth * 0.04),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : Padding(
                        padding: EdgeInsets.all(screenWidth * 0.04),
                        child: Column(
                          children: [
                            _buildInfoTile(Icons.person, 'Họ và Tên',
                                _fullNameController, _isEditing),
                            _buildInfoTile(
                                Icons.phone,
                                'Số Điện Thoại',
                                TextEditingController(
                                    text: _userInfo!['phoneNumber'] ?? ''),
                                false),
                            _buildInfoTile(
                                Icons.email,
                                'Email',
                                TextEditingController(
                                    text: _userInfo!['email'] ?? ''),
                                false),
                            _buildInfoTile(Icons.location_on, 'Địa Chỉ',
                                _addressController, _isEditing),
                            _buildInfoTile(Icons.wc, 'Giới Tính',
                                _genderController, _isEditing),
                            _buildInfoTile(Icons.cake, 'Ngày Sinh',
                                _dobController, _isEditing),
                            _buildInfoTile(
                                Icons.group,
                                'Đội Hiện Tại',
                                TextEditingController(
                                    text: _userInfo!['currentTeamName'] ??
                                        'Chưa có đội'),
                                false),
                            _buildInfoTile(
                                Icons.confirmation_number,
                                'ID Đội',
                                TextEditingController(
                                    text: _userInfo!['currentTeamId']
                                            ?.toString() ??
                                        'N/A'),
                                false),
                            _buildInfoTile(
                                Icons.star,
                                'Điểm Đóng Góp',
                                TextEditingController(
                                    text: _userInfo!['contributed'].toString()),
                                false),
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

  Widget _buildAvatar(double screenWidth) {
    return Center(
      child: GestureDetector(
        onTap: _isEditing && _userInfo != null ? _pickImage : null,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black26, blurRadius: 10, spreadRadius: 2)
                ],
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: CircleAvatar(
                radius: screenWidth * 0.18,
                backgroundColor: Colors.white,
                backgroundImage: _newAvatar != null
                    ? FileImage(_newAvatar!)
                    : (_userInfo != null &&
                            _userInfo!['avatar'] != null &&
                            _userInfo!['avatar'].isNotEmpty
                        ? NetworkImage(_userInfo!['avatar']) as ImageProvider
                        : null),
                child: _newAvatar == null &&
                        (_userInfo == null ||
                            _userInfo!['avatar'] == null ||
                            _userInfo!['avatar'].isEmpty)
                    ? Icon(Icons.person,
                        size: screenWidth * 0.25, color: Colors.blue[700])
                    : null,
              ),
            ),
            if (_isEditing && _userInfo != null)
              Container(
                padding: EdgeInsets.all(screenWidth * 0.02),
                decoration: BoxDecoration(
                  color: Colors.blue[700],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(Icons.camera_alt,
                    size: screenWidth * 0.06, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label,
      TextEditingController controller, bool editable) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: editable ? Colors.white : Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
        boxShadow: editable
            ? [BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 5)]
            : [],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Icon(icon, color: Colors.blue[700]),
        ),
        title: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.blueGrey[800])),
        subtitle: TextField(
          controller: controller,
          enabled: editable,
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          style: TextStyle(color: Colors.black87),
        ),
      ),
    );
  }
}
