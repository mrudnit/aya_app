import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/onboarding_widgets.dart'; // kNeon

class NutritionLogScreen extends StatelessWidget {
  const NutritionLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🍽️', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 16),
              Text('Nutrition',
                  style: GoogleFonts.inter(
                      fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              _PlannedFeature('🔍  Search food database (Open Food Facts)'),
              _PlannedFeature('✏️  Manual entry — calories, protein, carbs, fat'),
              _PlannedFeature('📷  Photo scan for automatic recognition (Phase 5)'),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: null, // disabled — not implemented yet
        backgroundColor: kNeon.withOpacity(0.4),
        foregroundColor: Colors.black54,
        icon: const Icon(Icons.add),
        label: Text('Add meal',
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
