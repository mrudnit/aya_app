import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/sleep_log.dart';

class SleepService {
  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('users').doc(_uid).collection('sleep_logs');

  // Saving
  Future<void> addSleepLog(SleepLog log) async {
    await _col.add(log.toMap());
  }

  // Newest first.
  Future<List<SleepLog>> getSleepLogs({int limit = 30}) async {
    final snap = await _col
        .orderBy('bedtime', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => SleepLog.fromMap(d.id, d.data()))
        .toList();
  }

  // Delete
  Future<void> deleteSleepLog(String id) async {
    await _col.doc(id).delete();
  }
}
