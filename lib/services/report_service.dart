import 'dart:convert';
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
  // CREATE REPORT
  // =========================
Future<bool> createReport({
  required int categoryId,
  required String title,
  required String description,
  String? location,
}) async {
  final token = await _getToken();

  final response = await http.post(
    Uri.parse('$baseUrl/reports'),
    headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: {
      'category_id': categoryId.toString(),
      'title': title,
      'description': description,
      if (location != null) 'location': location,
    },
  );
print('➡️ FLUTTER HIT API: $baseUrl/reports');
print('➡️ TOKEN: $token');
print('⬅️ STATUS: ${response.statusCode}');
print('⬅️ BODY: ${response.body}');

  return response.statusCode == 201;
}

}
