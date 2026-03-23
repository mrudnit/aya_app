import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityLog {
  final String?  id;
  final String   date;
  final String   category;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Strength fields
  final String?  muscleGroup;
  final String?  exerciseName;
  final String?  customExercise;
  final int?     sets;
  final int?     reps;
  final double?  weightKg;

  // Cardio fields
  final String?  cardioType;
  final int?     durationMin;
  final double?  caloriesBurned;

  // Other fields
  final String?  title;

  // Shared optional
  final String?  notes;

  const ActivityLog({
    this.id,
    required this.date,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    this.muscleGroup,
    this.exerciseName,
    this.customExercise,
    this.sets,
    this.reps,
    this.weightKg,
    this.cardioType,
    this.durationMin,
    this.caloriesBurned,
    this.title,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    final m = <String, dynamic>{
      'date':       date,
      'category':   category,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
    if (muscleGroup    != null) m['muscle_group']    = muscleGroup;
    if (exerciseName   != null) m['exercise_name']   = exerciseName;
    if (customExercise != null) m['custom_exercise'] = customExercise;
    if (sets           != null) m['sets']            = sets;
    if (reps           != null) m['reps']            = reps;
    if (weightKg       != null) m['weight_kg']       = weightKg;
    if (cardioType     != null) m['cardio_type']     = cardioType;
    if (durationMin    != null) m['duration_min']    = durationMin;
    if (caloriesBurned != null) m['calories_burned'] = caloriesBurned;
    if (title          != null) m['title']           = title;
    if (notes          != null) m['notes']           = notes;
    return m;
  }

  factory ActivityLog.fromMap(String id, Map<String, dynamic> m) {
    return ActivityLog(
      id:             id,
      date:           m['date']     as String,
      category:       m['category'] as String,
      createdAt:      (m['created_at'] as Timestamp).toDate(),
      updatedAt:      (m['updated_at'] as Timestamp).toDate(),
      muscleGroup:    m['muscle_group']    as String?,
      exerciseName:   m['exercise_name']   as String?,
      customExercise: m['custom_exercise'] as String?,
      sets:           (m['sets']           as num?)?.toInt(),
      reps:           (m['reps']           as num?)?.toInt(),
      weightKg:       (m['weight_kg']      as num?)?.toDouble(),
      cardioType:     m['cardio_type']     as String?,
      durationMin:    (m['duration_min']   as num?)?.toInt(),
      caloriesBurned: (m['calories_burned'] as num?)?.toDouble(),
      title:          m['title']           as String?,
      notes:          m['notes']           as String?,
    );
  }

  // One-line summary for history list
  String get displayTitle {
    switch (category) {
      case 'strength':
        return customExercise ?? exerciseName ?? 'Strength';
      case 'cardio':
        final t = cardioType ?? 'Cardio';
        return t[0].toUpperCase() + t.substring(1);
      default:
        return title ?? 'Activity';
    }
  }

  String get displaySubtitle {
    switch (category) {
      case 'strength':
        final parts = <String>[];
        if (muscleGroup != null) parts.add(muscleGroup!);
        if (sets != null && reps != null) parts.add('${sets}x${reps}');
        if (weightKg != null) parts.add('${weightKg} kg');
        return parts.join(' · ');
      case 'cardio':
        final parts = <String>[];
        if (durationMin != null) parts.add('${durationMin} min');
        if (caloriesBurned != null) parts.add('${caloriesBurned!.round()} kcal');
        return parts.join(' · ');
      default:
        return durationMin != null ? '${durationMin} min' : '';
    }
  }

  String get categoryEmoji {
    switch (category) {
      case 'strength': return '🏋️';
      case 'cardio':   return '🏃';
      default:         return '⚡';
    }
  }
}
