import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/onboarding_widgets.dart';

class SleepLogScreen extends StatelessWidget {
  const SleepLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌙', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 16),
              Text('Sleep',
                  style: GoogleFonts.inter(
                      fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              _PlannedFeature('🕐  Log bedtime and wake time'),
              _PlannedFeature('⭐  Optional 1–5 quality rating'),
              _PlannedFeature('📱  Auto-import from Apple Health / Google Fit (Phase 5)'),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: null,
        backgroundColor: kNeon.withOpacity(0.4),
        foregroundColor: Colors.black54,
        icon: const Icon(Icons.add),
        label: Text('Sleep',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _PlannedFeature extends StatelessWidget {
  final String text;
  const _PlannedFeature(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      Expanded(child: Text(text,
          style: GoogleFonts.inter(
              fontSize: 13, color: Colors.grey.shade500))),
    ]),
  );
}
