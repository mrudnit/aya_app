import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../onboarding_widgets.dart';

class HomeQuickAddSection extends StatelessWidget {
  final VoidCallback onAddSleep;
  final VoidCallback onAddMeal;
  final VoidCallback onAddActivity;
  final VoidCallback onAddWeight;

  const HomeQuickAddSection({
    super.key,
    required this.onAddSleep,
    required this.onAddMeal,
    required this.onAddActivity,
    required this.onAddWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _Btn(emoji: '🌙',  label: 'Sleep',    onTap: onAddSleep)),
      const SizedBox(width: 8),
      Expanded(child: _Btn(emoji: '🍽️', label: 'Meal',     onTap: onAddMeal)),
      const SizedBox(width: 8),
      Expanded(child: _Btn(emoji: '🏃',  label: 'Activity', onTap: onAddActivity)),
      const SizedBox(width: 8),
      Expanded(child: _Btn(emoji: '⚖️', label: 'Weight',   onTap: onAddWeight)),
    ]);
  }
}

class _Btn extends StatelessWidget {
  final String       emoji, label;
  final VoidCallback onTap;
  const _Btn({required this.emoji, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: dark
              ? const Color(0xFF1A2E1A)
              : const Color(0xFFF5FFF5),
          border: Border.all(color: kNeon, width: 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
