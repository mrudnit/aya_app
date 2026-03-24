import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/nutrition_log.dart';
import '../models/activity_log.dart';
import '../models/sleep_log.dart';
import '../models/weight_log.dart';

import 'sleep_service.dart';
import 'activity_service.dart';
import 'weight_service.dart';
import 'nutrition_service.dart';

class LogService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _nutrition = NutritionService();
  final _sleep = SleepService();
  final _activity = ActivityService();
  final _weight   = WeightService();

  String get _uid => _auth.currentUser!.uid;

  DocumentReference get _userDoc =>
      _db.collection('users').doc(_uid);

  // NUTRITION

  Future<void> addNutritionLog(NutritionLog log) =>
      _nutrition.addNutritionLog(log);

  Future<List<NutritionLog>> getRecentNutritionLogs({int limit = 7}) =>
      _nutrition.getRecentNutritionLogs(limit: limit);

  Future<List<NutritionLog>> getNutritionLogsForDay(DateTime day) =>
      _nutrition.getNutritionLogsForDay(day);

  Future<void> deleteNutritionLog(String id) =>
      _nutrition.deleteNutritionLog(id);

  // ACTIVITY

  Future<void> addActivityLog(ActivityLog log) =>
      _activity.addActivityLog(log);

  Future<List<ActivityLog>> getRecentActivityLogs({int limit = 7}) =>
      _activity.getActivityLogs(limit: limit);

  Future<void> deleteActivityLog(String logId) =>
      _activity.deleteActivityLog(logId);


  // SLEEP

  Future<void> addSleepLog(SleepLog log) =>
      _sleep.addSleepLog(log);

  Future<List<SleepLog>> getRecentSleepLogs({int limit = 7}) =>
      _sleep.getSleepLogs(limit: limit);

  Future<void> deleteSleepLog(String logId) =>
      _sleep.deleteSleepLog(logId);

  // WEIGHT

  Future<void> addWeightLog(WeightLog log) =>
      _weight.addWeightLog(log);

  Future<List<WeightLog>> getRecentWeightLogs({int limit = 30}) =>
      _weight.getWeightLogs(limit: limit);

  Future<void> deleteWeightLog(String logId) =>
      _weight.deleteWeightLog(logId);
}