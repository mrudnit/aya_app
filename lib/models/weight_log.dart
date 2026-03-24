import 'package:cloud_firestore/cloud_firestore.dart';

class WeightLog {
  final String?  id;
  final double   weightKg;
  final String   date;
  final DateTime createdAt;

  const WeightLog({
    this.id,
    required this.weightKg,
    required this.date,
    required this.createdAt,
  });

  factory WeightLog.create(double weightKg) {
    final now = DateTime.now();
    final date = '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    return WeightLog(
      weightKg:  weightKg,
      date:      date,
      createdAt: now,
    );
  }

  // Serialize
  Map<String, dynamic> toMap() => {
    'weight_kg':  weightKg,
    'date':       date,
    'created_at': Timestamp.fromDate(createdAt),
  };

  // Deserialize
  factory WeightLog.fromMap(String id, Map<String, dynamic> m) {
    return WeightLog(
      id:        id,
      weightKg:  (m['weight_kg'] as num).toDouble(),
      date:      m['date'] as String,
      createdAt: (m['created_at'] as Timestamp).toDate(),
    );
  }
}