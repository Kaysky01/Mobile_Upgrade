import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/report_model.dart';

class ReportService {
  static const String baseUrl = 'http://192.168.100.24:8000/api/v1';

  List<ReportModel>? get allReports => null;

  // =========================
  // GET TOKEN
  // =========================
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // =========================
  // GET ALL REPORTS (USER)
  // =========================
  Future<List<ReportModel>> getAllReports() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/reports'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List jsonData =
          jsonDecode(response.body)['data'] as List;

      return jsonData
          .map((item) => ReportModel.fromApi(item))
          .toList();
    } else {
      throw Exception('Gagal mengambil laporan');
    }
  }

  // =========================
  // GET DETAIL REPORT
  // =========================
  Future<ReportModel> getReportById(int id) async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/reports/$id'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return ReportModel.fromApi(
        jsonDecode(response.body)['data'],
      );
    } else {
      throw Exception('Gagal mengambil detail laporan');
    }
  }

  // =========================
  // CREATE REPORT (UPDATED + MEDIA)
  // =========================
  Future<bool> createReport({
  required int categoryId,
  required String title,
  required String description,
  String? location,
  List<File>? mediaFiles,
}) async {
  try {
    final token = await _getToken();

    if (token == null || token.isEmpty) {
      print('❌ Token tidak ditemukan');
      return false;
    }

    final uri = Uri.parse('$baseUrl/reports');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    // TEXT FIELDS
    request.fields['category_id'] = categoryId.toString();
    request.fields['title'] = title;
    request.fields['description'] = description;
    if (location != null) {
      request.fields['location'] = location;
    }

    // FILES
    if (mediaFiles != null && mediaFiles.isNotEmpty) {
      for (var file in mediaFiles) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'media[]', // ⬅️ HARUS media[]
            file.path,
          ),
        );
      }
    }

    print('➡️ UPLOAD MEDIA COUNT: ${mediaFiles?.length ?? 0}');

    // 🔴 TAMBAH TIMEOUT 30 DETIK
    final response = await request.send().timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        print('⏱️ TIMEOUT: Request took too long (30s)');
        throw TimeoutException('Upload timeout');
      },
    );
    
    // 🔴 TAMBAH TIMEOUT UNTUK BACA RESPONSE
    final responseBody = await response.stream.bytesToString().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        print('⏱️ TIMEOUT: Reading response took too long (10s)');
        throw TimeoutException('Response timeout');
      },
    );

    print('⬅️ STATUS: ${response.statusCode}');
    print('⬅️ BODY: $responseBody');

    return response.statusCode == 201;
  } on TimeoutException catch (e) {
    print('❌ TIMEOUT ERROR: $e');
    return false;
  } catch (e) {
    print('❌ CREATE REPORT ERROR: $e');
    return false;
  }
}
}