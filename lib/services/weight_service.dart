import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/weight_log.dart';

class WeightService {
  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('users').doc(_uid).collection('weight_logs');

  // Save
  Future<void> addWeightLog(WeightLog log) async {
    await _col.add(log.toMap());
  }

  // Newest first
  Future<List<WeightLog>> getWeightLogs({int limit = 30}) async {
    final snap = await _col
        .orderBy('created_at', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => WeightLog.fromMap(d.id, d.data()))
        .toList();
  }

  // Delete
  Future<void> deleteWeightLog(String id) async {
    await _col.doc(id).delete();
  }
}