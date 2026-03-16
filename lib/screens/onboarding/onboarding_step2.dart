import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/neon_widgets.dart';
import '/widgets/onboarding_widgets.dart';

class OnboardingStep2 extends StatelessWidget {
  final String goal;
  final String activityLevel;
  final TextEditingController sleepCtrl;
  final void Function(String) onGoalChanged;
  final void Function(String) onActivityChanged;

  const OnboardingStep2({
    super.key,
    required this.goal,
    required this.activityLevel,
    required this.sleepCtrl,
    required this.onGoalChanged,
    required this.onActivityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const StepTitle(
          step: '2 of 3',
          title: 'Your goal',
          subtitle: 'We will tailor recommendations to match your lifestyle.',
        ),
        const SizedBox(height: 28),

        // Primary goal
        Text('What is your primary goal?',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 10),
        OptionCard(
          value: 'lose_weight',
          selected: goal,
          label: 'Lose weight',
          icon: Icons.trending_down_rounded,
          onTap: onGoalChanged,
        ),
        const SizedBox(height: 8),
        OptionCard(
          value: 'maintain',
          selected: goal,
          label: 'Maintain weight',
          icon: Icons.balance_rounded,
          onTap: onGoalChanged,
        ),
        const SizedBox(height: 8),
        OptionCard(
          value: 'gain_weight',
          selected: goal,
          label: 'Gain weight / muscle',
          icon: Icons.trending_up_rounded,
          onTap: onGoalChanged,
        ),
        const SizedBox(height: 24),

        // Activity level
        Text('Activity level',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 6),
        Text('How active are you in a typical week?',
            style: GoogleFonts.inter(
                fontSize: 13, color: Colors.grey.shade500)),
        const SizedBox(height: 10),
        SegmentRow(
          options:  const ['low', 'medium', 'high'],
          labels:   const ['Low', 'Medium', 'High'],
          selected: activityLevel,
          onChanged: onActivityChanged,
        ),
        const SizedBox(height: 24),

        // Target sleep (optional)
        Text('Target sleep (optional)',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 6),
        Text('How many hours of sleep do you aim for per night?',
            style: GoogleFonts.inter(
                fontSize: 13, color: Colors.grey.shade500)),
        const SizedBox(height: 10),
        NeonField(
          controller: sleepCtrl,
          label: 'Target sleep (hours)',
          hint: 'e.g. 8  — leave blank to skip',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
          ],
          validator: (v) {
            if (v == null || v.trim().isEmpty) return null; // optional
            final n = double.tryParse(v);
            if (n == null || n < 1 || n > 24) return 'Enter a number 1–24';
            return null;
          },
        ),
        const SizedBox(height: 16),

      ],
    );
  }
}
