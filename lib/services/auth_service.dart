import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  static const String baseUrl = 'http://192.168.100.24:8000/api/v1';

  // --- LOGIN EMAIL ---
  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final String? token = responseData['data']['token'];
        final Map<String, dynamic>? user = responseData['data']['user'];

        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
          // TAMBAHKAN INI agar Dashboard tahu ini login manual
          await prefs.setString('login_method', 'email'); 
          
          if (user != null) {
            await prefs.setString('user_name', user['name'] ?? '');
            await prefs.setString('user_email', user['email'] ?? '');
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      print('LOGIN ERROR: $e'); 
      return false;
    }
  }

  // --- LOGIN GOOGLE ---
  Future<bool> loginWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/google'),
        headers: {
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

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final String? token = responseData['data'] != null 
            ? responseData['data']['token'] 
            : responseData['token'];

        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
          // TAMBAHKAN INI agar Dashboard tahu ini login Google
          await prefs.setString('login_method', 'google'); 
          
          // Simpan info dasar google untuk profil
          await prefs.setString('user_name', googleUser.displayName ?? '');
          await prefs.setString('user_email', googleUser.email);
          return true;
        }
      }
      return false;
    } catch (e) {
      print('GOOGLE AUTH ERROR: $e');
      return false;
    }
  }

  // --- HELPER FUNCTIONS ---
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_name');
      await prefs.remove('user_email');
      await prefs.remove('login_method'); // Hapus juga metodenya
      
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      print('LOGOUT ERROR: $e');
    }
  }
}