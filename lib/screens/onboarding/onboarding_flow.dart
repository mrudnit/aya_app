import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/profile_service.dart';
import '/widgets/onboarding_widgets.dart';
import 'onboarding_step1.dart';
import 'onboarding_step2.dart';
import 'onboarding_step3.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int _step = 0;

  // Step 1 values
  String _gender = 'male';
  final _ageCtrl    = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _step1Key   = GlobalKey<FormState>();

  // Step 2 values
  String _goal          = 'maintain';
  String _activityLevel = 'medium';
  final _sleepCtrl = TextEditingController();

  // Save state (step 3)
  bool    _saving = false;
  String? _error;

  final _service = ProfileService();

  @override
  void dispose() {
    // Always clean up controllers when the widget is removed
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _sleepCtrl.dispose();
    super.dispose();
  }

  // Move to the next step
  void _next() {
    if (_step == 0 && !(_step1Key.currentState?.validate() ?? false)) return;
    setState(() => _step++);
  }

  // Move back one step
  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  // Save all data to Firestore
  Future<void> _save() async {
    setState(() { _saving = true; _error = null; });
    try {
      final sleepRaw = _sleepCtrl.text.trim();
      await _service.saveOnboarding(
        gender:             _gender,
        age:                int.parse(_ageCtrl.text.trim()),
        height_cm:          double.parse(_heightCtrl.text.trim()),
        weight_kg:          double.parse(_weightCtrl.text.trim()),
        goal:               _goal,
        activity_level:     _activityLevel,
        target_sleep_hours: sleepRaw.isNotEmpty ? double.tryParse(sleepRaw) : null,
      );
    } catch (e) {
      setState(() => _error = 'Save failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [

            // The three neon green bars progress
            _ProgressBar(step: _step),

            // The active step screen fills
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: switch (_step) {
                    0 => OnboardingStep1(
                      key:             const ValueKey(0),
                      formKey:         _step1Key,
                      gender:          _gender,
                      onGenderChanged: (v) => setState(() => _gender = v),
                      ageCtrl:         _ageCtrl,
                      heightCtrl:      _heightCtrl,
                      weightCtrl:      _weightCtrl,
                    ),
                    1 => OnboardingStep2(
                      key:               const ValueKey(1),
                      goal:              _goal,
                      activityLevel:     _activityLevel,
                      sleepCtrl:         _sleepCtrl,
                      onGoalChanged:     (v) => setState(() => _goal = v),
                      onActivityChanged: (v) => setState(() => _activityLevel = v),
                    ),
                    _ => OnboardingStep3(
                      key:        const ValueKey(2),
                      gender:     _gender,
                      age:        _ageCtrl.text,
                      heightCm:   _heightCtrl.text,
                      weightKg:   _weightCtrl.text,
                      goal:       _goal,
                      activity:   _activityLevel,
                      sleepHours: _sleepCtrl.text,
                      saving:     _saving,
                      error:      _error,
                      onSave:     _save,
                    ),
                  },
                ),
              ),
            ),

            // Back / Next buttons at the bottom
            _BottomBar(
              step:   _step,
              saving: _saving,
              onBack: _back,
              onNext: _next,
            ),

          ],
        ),
      ),
    );
  }
}


// ProgressBar
class _ProgressBar extends StatelessWidget {
  final int step;
  const _ProgressBar({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
      child: Row(
        children: List.generate(3, (i) {
          final isDoneOrActive = i <= step;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
              height: 5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: isDoneOrActive ? kNeon : Colors.grey.shade200,
              ),
            ),
          );
        }),
      ),
    );
  }
}


// BottomBar

class _BottomBar extends StatelessWidget {
  final int step;
  final bool saving;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _BottomBar({
    required this.step,
    required this.saving,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      child: Row(
        children: [

          // Back button
          if (step > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: saving ? null : onBack,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: kNeon, width: 1.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Back',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              ),
            ),

          if (step > 0) const SizedBox(width: 12),

          // Next button
          if (step < 2)
            Expanded(
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kNeon,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Next',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                ),
              ),
            ),

        ],
      ),
    );
  }
}
