import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  // If onboarding is done
  Future<bool> isOnboardingCompleted() async {
    final doc = await _db.collection('users').doc(_uid).get();
    if (!doc.exists) return false;
    return doc.data()?['onboarding_completed'] == true;
  }
  // Save onboarding data
  Future<void> saveOnboarding({
    required String gender,
    required int    age,
    required double height_cm,
    required double weight_kg,
    required String goal,
    required String activity_level,
    double? target_sleep_hours,
  }) async{
    final data = <String, dynamic>{
      'gender':               gender,
      'age':                  age,
      'height_cm':            height_cm,
      'weight_kg':            weight_kg,
      'goal':                 goal,
      'activity_level':       activity_level,
      'onboarding_completed': true,
      'updated_at':           FieldValue.serverTimestamp(),
    };
    
    if (target_sleep_hours != null) {
      data['target_sleep_hours'] = target_sleep_hours;
    }
    await _db.collection('users').doc(_uid).set(data, SetOptions(merge: true));
  }
  Future<Map<String, dynamic>?> getProfile() async{
    final doc = await _db.collection('users').doc(_uid).get();
    return doc.data();
  }
  Future<void> updateFields(Map<String, dynamic> fields) async {
    await _db.collection('users').doc(_uid).update({
      ...fields,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}
