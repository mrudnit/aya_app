import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/activity_log.dart';

class ActivityService {
  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('users').doc(_uid).collection('activity_logs');

  // Save a new entry
  Future<String> addActivityLog(ActivityLog log) async {
    final ref = await _col.add(log.toMap());
    return ref.id;
  }

  // Newest first
  Future<List<ActivityLog>> getActivityLogs({int limit = 30}) async {
    final snap = await _col
        .orderBy('created_at', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => ActivityLog.fromMap(d.id, d.data()))
        .toList();
  }

  Future<void> deleteActivityLog(String id) async {
    await _col.doc(id).delete();
  }
}
