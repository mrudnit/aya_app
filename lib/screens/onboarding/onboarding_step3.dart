import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/widgets/onboarding_widgets.dart';

class OnboardingStep3 extends StatelessWidget {
  // All values to display
  final String gender;
  final String age;
  final String heightCm;
  final String weightKg;
  final String goal;
  final String activity;
  final String sleepHours;

  final bool saving;
  final String? error;
  // Called "Save & continue"
  final VoidCallback onSave;

  const OnboardingStep3({
    super.key,
    required this.gender,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.goal,
    required this.activity,
    required this.sleepHours,
    required this.saving,
    required this.error,
    required this.onSave,
  });

  String _goalLabel(String v) => switch (v) {
    'lose_weight' => 'Lose weight',
    'gain_weight' => 'Gain weight / muscle',
    _             => 'Maintain weight',
  };

  String _activityLabel(String v) => switch (v) {
    'low'  => 'Low',
    'high' => 'High',
    _      => 'Medium',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const StepTitle(
          step: '3 of 3',
          title: 'Confirm your profile',
          subtitle: 'Everything looks right? Tap Save to continue.',
        ),
        const SizedBox(height: 24),

        // Summary card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF5FFF5),
            border: Border.all(color: kNeon, width: 1.8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              SummaryRow('Gender', gender.capitalize()),
              SummaryRow('Age',    '$age years'),
              SummaryRow('Height', '$heightCm cm'),
              SummaryRow('Weight', '$weightKg kg'),
              const Divider(height: 24),
              SummaryRow('Goal',           _goalLabel(goal)),
              SummaryRow('Activity level', _activityLabel(activity)),
              // Sleep row only appears if the user filled it in
              if (sleepHours.trim().isNotEmpty)
                SummaryRow('Target sleep', '$sleepHours h / night'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Error banner
        if (error != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              border: Border.all(color: Colors.red.shade300),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              error!,
              style: GoogleFonts.inter(
                  color: Colors.red.shade700, fontSize: 13),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Save button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: saving ? null : onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: kNeon,
              foregroundColor: Colors.black,
              elevation: 0,
              disabledBackgroundColor: const Color(0xFFB0FFB0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            // Show a spinner while saving
            child: saving
                ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: Colors.black54),
            )
                : Text(
              'Save & continue',
              style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 16),

      ],
    );
  }
}
