import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/nutrition_log.dart';
import '../models/activity_log.dart';
import '../models/sleep_log.dart';

class LogService {
  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Current user's UID — shortcut used by every method below
  String get _uid => _auth.currentUser!.uid;

  // Shortcut to the user's document in Firestore
  DocumentReference get _userDoc => _db.collection('users').doc(_uid);

  // NUTRITION
  // Save a new nutrition entry
  Future<void> addNutritionLog(NutritionLog log) async {
    await _userDoc.collection('nutrition_logs').add(log.toMap());
  }

  // Load all nutrition entries for a specific calendar day
  Future<List<NutritionLog>> getNutritionLogsForDay(DateTime day) async {
    // Build start and end of the day as ISO strings for comparison
    final start = DateTime(day.year, day.month, day.day);
    final end   = start.add(const Duration(days: 1));

    final snap = await _userDoc
        .collection('nutrition_logs')
        .where('timestamp', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('timestamp', isLessThan: end.toIso8601String())
        .orderBy('timestamp')
        .get();

    return snap.docs
        .map((d) => NutritionLog.fromMap(d.id, d.data()))
        .toList();
  }

  // Load the last N nutrition entries (used on Home for quick summary)
  Future<List<NutritionLog>> getRecentNutritionLogs({int limit = 7}) async {
    final snap = await _userDoc
        .collection('nutrition_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snap.docs
        .map((d) => NutritionLog.fromMap(d.id, d.data()))
        .toList();
  }

  // Delete a nutrition entry
  Future<void> deleteNutritionLog(String logId) async {
    await _userDoc.collection('nutrition_logs').doc(logId).delete();
  }


  // ACTIVITY
  Future<void> addActivityLog(ActivityLog log) async {
    await _userDoc.collection('activity_logs').add(log.toMap());
  }

  Future<List<ActivityLog>> getRecentActivityLogs({int limit = 7}) async {
    final snap = await _userDoc
        .collection('activity_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snap.docs
        .map((d) => ActivityLog.fromMap(d.id, d.data()))
        .toList();
  }

  Future<void> deleteActivityLog(String logId) async {
    await _userDoc.collection('activity_logs').doc(logId).delete();
  }


  // SLEEP
  Future<void> addSleepLog(SleepLog log) async {
    await _userDoc.collection('sleep_logs').add(log.toMap());
  }

  // Load the last N sleep entries (used on Home and Analytics)
  Future<List<SleepLog>> getRecentSleepLogs({int limit = 7}) async {
    final snap = await _userDoc
        .collection('sleep_logs')
        .orderBy('bedtime', descending: true)
        .limit(limit)
        .get();

    return snap.docs
        .map((d) => SleepLog.fromMap(d.id, d.data()))
        .toList();
  }

  Future<void> deleteSleepLog(String logId) async {
    await _userDoc.collection('sleep_logs').doc(logId).delete();
  }
}
