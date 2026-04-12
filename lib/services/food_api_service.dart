import 'dart:convert';
import 'package:http/http.dart' as http;

class FoodItem {
  final String name;
  final String category;
  final double kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;

  const FoodItem({
    required this.name,
    required this.category,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });
}

class FoodApiService {
  static const String _baseUrl =
      'https://imaginative-transformation-production-06e6.up.railway.app';

  static Future<List<FoodItem>> searchFoods(String query) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse('$_baseUrl/api/v1/foods/search')
        .replace(queryParameters: {'q': query, 'limit': '30'});

    try {
      final response =
      await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>;
        return results
            .map((e) => _fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  static FoodItem _fromJson(Map<String, dynamic> j) => FoodItem(
    name:     j['name']      as String,
    category: j['category']  as String,
    kcal:     (j['kcal']     as num).toDouble(),
    proteinG: (j['protein_g'] as num).toDouble(),
    carbsG:   (j['carbs_g']  as num).toDouble(),
    fatG:     (j['fat_g']    as num).toDouble(),
  );
}
