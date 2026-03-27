import 'package:cloud_firestore/cloud_firestore.dart';

// One food inside a meal
class MealItem {
  final String foodName;
  final double portionG;
  final double kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;

  const MealItem({
    required this.foodName,
    required this.portionG,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  Map<String, dynamic> toMap() => {
    'food_name': foodName,
    'portion_g': portionG,
    'kcal':      kcal,
    'protein_g': proteinG,
    'carbs_g':   carbsG,
    'fat_g':     fatG,
  };

  factory MealItem.fromMap(Map<String, dynamic> m) => MealItem(
    foodName: m['food_name'] as String,
    portionG: (m['portion_g'] as num).toDouble(),
    kcal:     (m['kcal']      as num).toDouble(),
    proteinG: (m['protein_g'] as num).toDouble(),
    carbsG:   (m['carbs_g']   as num).toDouble(),
    fatG:     (m['fat_g']     as num).toDouble(),
  );
}

// One complete meal
class MealLog {
  final String?        id;
  final String         mealType;  // breakfast / lunch / dinner / snack
  final String         date;      // "YYYY-MM-DD" — display label
  final List<MealItem> items;
  final String?        notes;
  final DateTime       createdAt;

  const MealLog({
    this.id,
    required this.mealType,
    required this.date,
    required this.items,
    this.notes,
    required this.createdAt,
  });

  // Totals
  double get totalKcal    => items.fold(0, (s, i) => s + i.kcal);
  double get totalProtein => items.fold(0, (s, i) => s + i.proteinG);
  double get totalCarbs   => items.fold(0, (s, i) => s + i.carbsG);
  double get totalFat     => items.fold(0, (s, i) => s + i.fatG);

  Map<String, dynamic> toMap() {
    final m = <String, dynamic>{
      'meal_type':     mealType,
      'date':          date,
      'items':         items.map((i) => i.toMap()).toList(),
      // Store totals
      'total_kcal':    totalKcal,
      'total_protein': totalProtein,
      'total_carbs':   totalCarbs,
      'total_fat':     totalFat,
      'created_at':    Timestamp.fromDate(createdAt),
    };
    if (notes != null && notes!.isNotEmpty) m['notes'] = notes;
    return m;
  }

  factory MealLog.fromMap(String id, Map<String, dynamic> m) {
    final raw = m['items'] as List<dynamic>? ?? [];
    return MealLog(
      id:        id,
      mealType:  m['meal_type'] as String,
      date:      m['date']      as String,
      items:     raw.map((i) =>
          MealItem.fromMap(i as Map<String, dynamic>)).toList(),
      notes:     m['notes']     as String?,
      createdAt: (m['created_at'] as Timestamp).toDate(),
    );
  }
}
typedef NutritionLog = MealLog;
