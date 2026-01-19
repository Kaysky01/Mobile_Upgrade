import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CategoryService {
  static const baseUrl = 'http://192.168.100.24:8000/api/v1';

  static Future<List<dynamic>> getCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.get(
      Uri.parse('$baseUrl/categories'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token', // 🔥 TOKEN DI SINI
      },
    );

    return jsonDecode(response.body);
  }
}
