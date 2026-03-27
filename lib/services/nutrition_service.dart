import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/nutrition_log.dart';

class NutritionService {
  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('users').doc(_uid).collection('nutrition_logs');

  Future<void> addNutritionLog(MealLog log) async {
    await _col.add(log.toMap());
  }

  Future<List<MealLog>> getRecentNutritionLogs({int limit = 30}) async {
    final snap = await _col
        .orderBy('created_at', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => MealLog.fromMap(d.id, d.data()))
        .toList();
  }

  Future<List<MealLog>> getNutritionLogsForDay(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end   = start.add(const Duration(days: 1));
    final snap  = await _col
        .where('created_at',
        isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('created_at', isLessThan: Timestamp.fromDate(end))
        .orderBy('created_at')
        .get();
    return snap.docs
        .map((d) => MealLog.fromMap(d.id, d.data()))
        .toList();
  }

  Future<void> deleteNutritionLog(String id) async {
    await _col.doc(id).delete();
  }
}