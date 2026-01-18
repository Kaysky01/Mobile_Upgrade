import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // BASE URL API (SUDAH BENAR)
  static const String baseUrl = 'http://192.168.100.24:8000/api/v1';

  // KEY STORAGE (BIAR KONSISTEN)
  static const String _tokenKey = 'auth_token';
  static const String _loginMethodKey = 'login_method';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';

  // ================= LOGIN EMAIL =================
  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode != 200) {
        print('LOGIN FAILED: ${response.body}');
        return false;
      }

      final Map<String, dynamic> json = jsonDecode(response.body);
      final String? token = json['data']?['token'];
      final Map<String, dynamic>? user = json['data']?['user'];

      if (token == null) {
        print('TOKEN NULL DARI API');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();

      // 🔑 SIMPAN TOKEN (INI YANG PALING PENTING)
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_loginMethodKey, 'email');

      if (user != null) {
        await prefs.setString(_userNameKey, user['name'] ?? '');
        await prefs.setString(_userEmailKey, user['email'] ?? '');
      }

      return true;
    } catch (e) {
      print('LOGIN ERROR: $e');
      return false;
    }
  }

  // ================= LOGIN GOOGLE =================
  Future<bool> loginWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/google'),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': googleUser.displayName,
          'email': googleUser.email,
          'google_id': googleUser.id,
          'avatar': googleUser.photoUrl,
        }),
      );

      if (response.statusCode != 200) {
        print('GOOGLE LOGIN FAILED: ${response.body}');
        return false;
      }

      final Map<String, dynamic> json = jsonDecode(response.body);
      final String? token = json['data']?['token'];

      if (token == null) {
        print('TOKEN GOOGLE NULL');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_tokenKey, token);
      await prefs.setString(_loginMethodKey, 'google');
      await prefs.setString(_userNameKey, googleUser.displayName ?? '');
      await prefs.setString(_userEmailKey, googleUser.email);

      return true;
    } catch (e) {
      print('GOOGLE AUTH ERROR: $e');
      return false;
    }
  }

  // ================= HELPER =================
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<String?> getLoginMethod() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_loginMethodKey);
  }

  // ================= LOGOUT =================
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_loginMethodKey);
      await prefs.remove(_userNameKey);
      await prefs.remove(_userEmailKey);

      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      print('LOGOUT ERROR: $e');
    }
  }
}
