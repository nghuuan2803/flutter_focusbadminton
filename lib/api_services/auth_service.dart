import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/constants.dart';
import 'package:http/http.dart' as http;

class GoogleSignInService {
  static final _googleSignIn = GoogleSignIn(
      clientId:
          // '568380109802-5jch3b2fep6kjkse5aj554m4gkloh647.apps.googleusercontent.com',
          '463299174196-umpv1mo3frgasib9li1g2i15190qd5t7.apps.googleusercontent.com',
      serverClientId:
          //  '568380109802-dtu6hse617l9bs7dg0tn9me2fl3tvau4.apps.googleusercontent.com',
          '463299174196-388krapsu38nbmg6r846rl4opg1f12ua.apps.googleusercontent.com',
      // scopes: ['email', 'profile']);
      scopes: ['email', 'profile', 'openid']);
  static Future<GoogleSignInAccount?> login() => _googleSignIn.signIn();
  static Future logout() => _googleSignIn.signOut();
}

class AuthService {
  Future<bool> googleSignIn() async {
    try {
      final user = await GoogleSignInService.login();
      final auth = await user?.authentication;
      if (auth?.idToken != null) {
        bool rs = await sendIdTokenToBackend(
            auth!.idToken!); // Gửi lên backend để lấy accessToken
        print(user!.displayName.toString());
        print(user.email);
        print(user.id);
        print(user.photoUrl.toString());
        return rs;
      }
      return false;
    } catch (e) {
      print(e.toString());
      return false;
    }
  }

  Future<bool> passwordSignIn(String email, String password) async {
    const String backendUrl = "${Constants.baseUrl}api/auth/login";
    try {
      final credential = "$email|$password";
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "loginType": "password",
          "credential": credential,
        }),
      );

      print(
          "Password SignIn Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String accessToken = data["accessToken"];
        String refreshToken = data["refreshToken"];
        await _saveTokens(accessToken, refreshToken);
        await _fetchAndSaveUserInfo(accessToken);
        return true;
      } else {
        print("❌ Password SignIn failed: ${response.body}");
        return false;
      }
    } catch (e) {
      print("⚠ Error during password sign in: $e");
      return false;
    }
  }

  Future<bool> sendIdTokenToBackend(String idToken) async {
    const String backendUrl =
        "${Constants.baseUrl}api/auth/login"; // Thay bằng API của bạn

    try {
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body:
            jsonEncode({"loginType": "google-flutter", "credential": idToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String accessToken = data["accessToken"];
        String refreshToken = data["refreshToken"];
        // Lưu token vào SharedPreferences
        await _saveTokens(accessToken, refreshToken);

        // Gọi API để lấy User Info và lưu
        await _fetchAndSaveUserInfo(accessToken);

        print("✅ Access Token: $accessToken");
        print("🔄 Refresh Token: $refreshToken");
        return true;
        // Lưu lại accessToken & refreshToken nếu cần
      } else {
        print("❌ Đăng nhập thất bại: ${response.body}");
        return false;
      }
    } catch (e) {
      print("⚠ Lỗi khi gửi idToken: $e");
      return false;
    }
  }

// Lưu token vào SharedPreferences
  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', accessToken);
    await prefs.setString('refreshToken', refreshToken);
  }

// Gọi API để lấy User Info và lưu vào SharedPreferences
  Future<void> _fetchAndSaveUserInfo(String accessToken) async {
    const String userInfoUrl =
        "${Constants.baseUrl}api/user/info"; // Thay bằng API của bạn
    try {
      final response = await http.get(
        Uri.parse(userInfoUrl),
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userInfo', jsonEncode(userData));
        print("✅ User Info: $userData");
      } else {
        print("❌ Lỗi khi lấy User Info: ${response.body}");
      }
    } catch (e) {
      print("⚠ Lỗi khi gọi API User Info: $e");
    }
  }

  // Kiểm tra trạng thái đăng nhập
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken') != null;
  }

  // Lấy User Info từ SharedPreferences
  static Future<Map<String, dynamic>?> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userInfoString = prefs.getString('userInfo');
    if (userInfoString != null) {
      return jsonDecode(userInfoString) as Map<String, dynamic>;
    }
    return null;
  }

  Future<bool> LogOut() async {
    try {
      await GoogleSignInService.logout();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('accessToken');
      await prefs.remove('refreshToken');
      await prefs.remove('userInfo'); // Xóa userInfo

      print("Sign Out Success");
      return true;
    } catch (exception) {
      print("Error during sign out: $exception");
      return false;
    }
  }
}
