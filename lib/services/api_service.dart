import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ================= BASE URL =================
  static const String baseUrl = 'https://pelaporanakademik.com/api/v1';

  // ================= SHARED PREF =================
  Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', user['id']);
    await prefs.setString('user_name', user['name']);
    await prefs.setString('user_email', user['email']);
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ================= AUTH (LOGIN / REGISTER) =================
  /// BACKEND: POST /api/v1/user/auth
  Future<Map<String, dynamic>> authUser({
    required String name,
    required String email,
    String? googleId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/auth'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        if (googleId != null) 'google_id': googleId,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      await saveUser(data['data']);
      return data['data'];
    } else {
      throw Exception(data['message'] ?? 'Auth gagal');
    }
  }

  // ================= CATEGORIES =================
  /// GET /api/v1/categories
  Future<List<dynamic>> getCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories'),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'];
    } else {
      throw Exception('Gagal mengambil kategori');
    }
  }

  // ================= CREATE REPORT =================
  /// POST /api/v1/reports
  Future<void> createReport({
    required int categoryId,
    required String title,
    required String description,
    String? location,
    List<File>? mediaFiles,
  }) async {
    final userId = await getUserId();

    if (userId == null) {
      throw Exception('User belum login');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/reports'),
    );

    request.fields['user_id'] = userId.toString();
    request.fields['category_id'] = categoryId.toString();
    request.fields['title'] = title;
    request.fields['description'] = description;
    if (location != null) {
      request.fields['location'] = location;
    }

    if (mediaFiles != null) {
      for (final file in mediaFiles) {
        request.files.add(
          await http.MultipartFile.fromPath('media[]', file.path),
        );
      }
    }

    final response = await request.send();

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Gagal mengirim laporan');
    }
  }

  // ================= USER REPORTS =================
  /// GET /api/v1/reports/user/{userId}
  Future<List<dynamic>> getUserReports() async {
    final userId = await getUserId();

    if (userId == null) {
      return [];
    }

    final response = await http.get(
      Uri.parse('$baseUrl/reports/user/$userId'),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'];
    } else {
      throw Exception('Gagal mengambil laporan');
    }
  }

  // ================= REPORT DETAIL =================
  /// GET /api/v1/reports/{id}
  Future<Map<String, dynamic>> getReportDetail(int reportId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/reports/$reportId'),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'];
    } else {
      throw Exception('Gagal mengambil detail laporan');
    }
  }

  // ================= STATISTICS =================
  /// GET /api/v1/statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final response = await http.get(
      Uri.parse('$baseUrl/statistics'),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'];
    } else {
      throw Exception('Gagal mengambil statistik');
    }
  }
}
