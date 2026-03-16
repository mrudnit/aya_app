import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/widgets/onboarding_widgets.dart';
import '/widgets/neon_widgets.dart';

class OnboardingStep1 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final String gender;
  final void Function(String) onGenderChanged;
  final TextEditingController ageCtrl;
  final TextEditingController heightCtrl;
  final TextEditingController weightCtrl;

  const OnboardingStep1({
    super.key,
    required this.formKey,
    required this.gender,
    required this.onGenderChanged,
    required this.ageCtrl,
    required this.heightCtrl,
    required this.weightCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepTitle(
            step: '1 of 3',
            title: 'About you',
            subtitle: 'We use this to personalise your health data.',
          ),
          const SizedBox(height: 28),

          Text(
            'Gender',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),

          SegmentRow(
            options: const ['male', 'female', 'other'],
            labels: const ['Male', 'Female', 'Other'],
            selected: gender,
            onChanged: onGenderChanged,
          ),
          const SizedBox(height: 20),

          NeonField(
            controller: ageCtrl,
            label: 'Age (years)',
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              final n = int.tryParse(v);
              if (n == null || n < 10 || n > 120) return 'Enter a valid age';
              return null;
            },
          ),
          const SizedBox(height: 14),

          NeonField(
            controller: heightCtrl,
            label: 'Height (cm)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              final n = double.tryParse(v);
              if (n == null || n < 50 || n > 280) return 'Enter a valid height';
              return null;
            },
          ),
          const SizedBox(height: 14),

          NeonField(
            controller: weightCtrl,
            label: 'Weight (kg)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              final n = double.tryParse(v);
              if (n == null || n < 20 || n > 500) return 'Enter a valid weight';
              return null;
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}