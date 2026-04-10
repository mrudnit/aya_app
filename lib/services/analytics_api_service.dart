import 'dart:convert';
import 'package:http/http.dart' as http;

class AnalyticsApiService {
  static const String _baseUrl = 'https://imaginative-transformation-production-06e6.up.railway.app';

  Future<Map<String, dynamic>> fetchHome(String uid) async {
    final uri      = Uri.parse('$_baseUrl/api/v1/home/$uid');
    final response = await http.get(uri).timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Backend error ${response.statusCode}: ${response.body}');
  }
  Future<Map<String, dynamic>> fetchOverview(String uid) async {
    final uri = Uri.parse('$_baseUrl/api/v1/analytics/overview/$uid');
    final response = await http.get(uri).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Backend error ${response.statusCode}: ${response.body}');
    }
  }
}
