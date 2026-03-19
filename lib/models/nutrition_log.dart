class NutritionLog {
  final String? id;
  final DateTime timestamp;
  final String mealType;
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final String? notes;

  const NutritionLog({
    this.id,
    required this.timestamp,
    required this.mealType,
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.notes,
  });

  // Convert to a Map for Firestore
  Map<String, dynamic> toMap() => {
    'timestamp':      timestamp.toIso8601String(),
    'meal_type':      mealType,
    'calories_kcal':  caloriesKcal,
    'protein_g':      proteinG,
    'carbs_g':        carbsG,
    'fat_g':          fatG,
    if (notes != null && notes!.isNotEmpty) 'notes': notes,
  };

  // Build a NutritionLog from a Firestore document
  factory NutritionLog.fromMap(String id, Map<String, dynamic> map) {
    return NutritionLog(
      id:            id,
      timestamp:     DateTime.parse(map['timestamp'] as String),
      mealType:      map['meal_type'] as String,
      caloriesKcal:  (map['calories_kcal'] as num).toDouble(),
      proteinG:      (map['protein_g'] as num).toDouble(),
      carbsG:        (map['carbs_g'] as num).toDouble(),
      fatG:          (map['fat_g'] as num).toDouble(),
      notes:         map['notes'] as String?,
    );
  }
}
