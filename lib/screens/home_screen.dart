import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Aya',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF39FF14),
                fontSize: 22)),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.logout, color: Color(0xFF39FF14), size: 18),
            label: Text('Logout',
                style: GoogleFonts.inter(
                    color: const Color(0xFF39FF14),
                    fontWeight: FontWeight.w600)),
            onPressed: () => AuthService().logout(),
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
        FirebaseFirestore.instance.collection('users').doc(uid).get(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF39FF14)));
          }

          final data = snap.data?.data() as Map<String, dynamic>?;
          if (data == null) {
            return const Center(child: Text('No profile found.'));
          }

          final firstName = data['firstName'] ?? '';
          final goal      = data['goal'] ?? '';
          final heightCm  = data['height_cm'];
          final weightKg  = data['weight_kg'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hello, $firstName 👋',
                    style: GoogleFonts.inter(
                        fontSize: 24, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Here\'s your profile summary.',
                    style: GoogleFonts.inter(
                        fontSize: 14, color: Colors.grey.shade500)),
                const SizedBox(height: 24),

                // Profile card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5FFF5),
                    border: Border.all(
                        color: const Color(0xFF39FF14), width: 1.8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _Row('Height', '${heightCm ?? '-'} cm'),
                      _Row('Weight', '${weightKg ?? '-'} kg'),
                      _Row('Goal', _goalLabel(goal)),
                      _Row('Activity',
                          _cap(data['activity_level'] ?? '')),
                      if (data['target_sleep_hours'] != null)
                        _Row('Target sleep',
                            '${data['target_sleep_hours']} h / night'),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                Text('Phase 3: Logging screens coming here...',
                    style: GoogleFonts.inter(
                        color: Colors.grey.shade400, fontSize: 13)),
              ],
            ),
          );
        },
      ),
    );
  }

  String _goalLabel(String v) => switch (v) {
    'lose_weight'  => 'Lose weight',
    'gain_weight'  => 'Gain weight / muscle',
    _              => 'Maintain weight',
  };

  String _cap(String v) =>
      v.isEmpty ? v : '${v[0].toUpperCase()}${v.substring(1)}';
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 14, color: Colors.grey.shade600)),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)),
        ],
      ),
    );
  }
}
