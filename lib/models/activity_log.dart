class ActivityLog {
  final String? id;
  final DateTime timestamp;
  final String activityType;
  final int durationMin;
  final double? caloriesBurnedKcal;

  const ActivityLog({
    this.id,
    required this.timestamp,
    required this.activityType,
    required this.durationMin,
    this.caloriesBurnedKcal,
  });

  Map<String, dynamic> toMap() => {
    'timestamp':     timestamp.toIso8601String(),
    'activity_type': activityType,
    'duration_min':  durationMin,
    if (caloriesBurnedKcal != null)
      'calories_burned_kcal': caloriesBurnedKcal,
  };

  factory ActivityLog.fromMap(String id, Map<String, dynamic> map) {
    return ActivityLog(
      id:                   id,
      timestamp:            DateTime.parse(map['timestamp'] as String),
      activityType:         map['activity_type'] as String,
      durationMin:          (map['duration_min'] as num).toInt(),
      caloriesBurnedKcal:   (map['calories_burned_kcal'] as num?)?.toDouble(),
    );
  }
}
