import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/activity_log.dart';
import '../../../widgets/neon_widgets.dart';
import '../../../widgets/onboarding_widgets.dart'; // kNeon
import 'activity_constants.dart';

class ActivityForm extends StatefulWidget {
  final Future<void> Function(ActivityLog) onSaved;
  const ActivityForm({super.key, required this.onSaved});

  @override
  State<ActivityForm> createState() => _ActivityFormState();
}

class _ActivityFormState extends State<ActivityForm> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  // Category selection
  String _category = 'strength'; // default

  // Strength fields
  String? _muscleGroup;
  String? _exerciseName;
  final _customExerciseCtrl = TextEditingController();
  final _setsCtrl           = TextEditingController();
  final _repsCtrl           = TextEditingController();
  final _weightCtrl         = TextEditingController();

  // Cardio fields
  String? _cardioType;
  final _durationCtrl  = TextEditingController();
  final _caloriesCtrl  = TextEditingController();

  // Other fields
  final _titleCtrl    = TextEditingController();
  final _durationOtherCtrl = TextEditingController();

  // Shared
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _customExerciseCtrl.dispose();
    _setsCtrl.dispose();
    _repsCtrl.dispose();
    _weightCtrl.dispose();
    _durationCtrl.dispose();
    _caloriesCtrl.dispose();
    _titleCtrl.dispose();
    _durationOtherCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  List<String> get _exercises =>
      kExercisesByGroup[_muscleGroup] ?? ['Other'];

  bool get _showCustomExercise =>
      _muscleGroup != null && _exerciseName == 'Other';

  // Date
  String _todayDate() {
    final n = DateTime.now();
    return '${n.year}-'
        '${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

  // Save
  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final now  = DateTime.now();
      final date = _todayDate();
      final int? durationMin = switch (_category) {
        'cardio' => _durationCtrl.text.isNotEmpty
            ? int.tryParse(_durationCtrl.text)
            : null,
        'other'  => _durationOtherCtrl.text.isNotEmpty
            ? int.tryParse(_durationOtherCtrl.text)
            : null,
        _        => null,
      };

      final log = ActivityLog(
        date:      date,
        category:  _category,
        createdAt: now,
        updatedAt: now,
        // Strength
        muscleGroup:    _category == 'strength' ? _muscleGroup  : null,
        exerciseName:   _category == 'strength' ? _exerciseName : null,
        customExercise: _showCustomExercise
            ? _customExerciseCtrl.text.trim()
            : null,
        sets:     _category == 'strength' && _setsCtrl.text.isNotEmpty
            ? int.tryParse(_setsCtrl.text)      : null,
        reps:     _category == 'strength' && _repsCtrl.text.isNotEmpty
            ? int.tryParse(_repsCtrl.text)      : null,
        weightKg: _category == 'strength' && _weightCtrl.text.isNotEmpty
            ? double.tryParse(_weightCtrl.text) : null,
        // Cardio
        cardioType:     _category == 'cardio' ? _cardioType : null,
        caloriesBurned: _category == 'cardio' && _caloriesCtrl.text.isNotEmpty
            ? double.tryParse(_caloriesCtrl.text) : null,
        // Other
        title: _category == 'other' ? _titleCtrl.text.trim() : null,
        durationMin: durationMin,
        notes: _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
      );

      await widget.onSaved(log);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // Build
  @override
  Widget build(BuildContext context) {
    final dark   = Theme.of(context).brightness == Brightness.dark;
    final bg     = dark ? const Color(0xFF1E1E1E) : Colors.white;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [

              // Drag handle
              Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              )),
              const SizedBox(height: 16),

              Text('Log workout',
                  style: GoogleFonts.inter(
                      fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('Date set to today automatically.',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 20),

              // Category selector
              _Label('Category'),
              const SizedBox(height: 8),
              SegmentRow(
                options:  const ['strength', 'cardio', 'other'],
                labels:   const ['Strength', 'Cardio', 'Other'],
                selected: _category,
                onChanged: (v) => setState(() {
                  _category = v;
                  // Reset category-specific selections on switch
                  _muscleGroup  = null;
                  _exerciseName = null;
                  _cardioType   = null;
                }),
              ),
              const SizedBox(height: 20),

              // Strength fields
              if (_category == 'strength') ...[
                _Label('Muscle group'),
                const SizedBox(height: 8),
                _Dropdown(
                  value:    _muscleGroup,
                  hint:     'Select muscle group',
                  items:    kMuscleGroups,
                  labels:   kMuscleGroupLabels,
                  onChanged: (v) => setState(() {
                    _muscleGroup  = v;
                    _exerciseName = null;
                  }),
                  validator: (v) => v == null ? 'Select a muscle group' : null,
                ),
                const SizedBox(height: 14),

                if (_muscleGroup != null) ...[
                  _Label('Exercise'),
                  const SizedBox(height: 8),
                  _Dropdown(
                    value:    _exerciseName,
                    hint:     'Select exercise',
                    items:    _exercises,
                    onChanged: (v) => setState(() => _exerciseName = v),
                    validator: (v) => v == null ? 'Select an exercise' : null,
                  ),
                  const SizedBox(height: 14),
                ],

                if (_showCustomExercise) ...[
                  NeonField(
                    controller: _customExerciseCtrl,
                    label: 'Custom exercise name',
                    validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter exercise name' : null,
                  ),
                  const SizedBox(height: 14),
                ],

                Row(children: [
                  Expanded(child: NeonField(
                    controller: _setsCtrl,
                    label: 'Sets',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) =>
                    (v == null || v.isEmpty) ? 'Required' : null,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: NeonField(
                    controller: _repsCtrl,
                    label: 'Reps',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) =>
                    (v == null || v.isEmpty) ? 'Required' : null,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: NeonField(
                    controller: _weightCtrl,
                    label: 'Weight (kg)',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                    validator: (v) =>
                    (v == null || v.isEmpty) ? 'Required' : null,
                  )),
                ]),
                const SizedBox(height: 14),
              ],

              // Cardio fields
              if (_category == 'cardio') ...[
                _Label('Cardio type'),
                const SizedBox(height: 8),
                _Dropdown(
                  value:    _cardioType,
                  hint:     'Select type',
                  items:    kCardioTypes,
                  labels:   kCardioTypeLabels,
                  onChanged: (v) => setState(() => _cardioType = v),
                  validator: (v) => v == null ? 'Select a cardio type' : null,
                ),
                const SizedBox(height: 14),

                Row(children: [
                  Expanded(child: NeonField(
                    controller: _durationCtrl,
                    label: 'Duration (min)',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) =>
                    (v == null || v.isEmpty) ? 'Required' : null,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: NeonField(
                    controller: _caloriesCtrl,
                    label: 'Calories (optional)',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  )),
                ]),
                const SizedBox(height: 14),
              ],

              // Other fields
              if (_category == 'other') ...[
                NeonField(
                  controller: _titleCtrl,
                  label: 'Activity name',
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                NeonField(
                  controller: _durationOtherCtrl,
                  label: 'Duration (min, optional)',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 14),
              ],

              // Notes
              NeonField(
                controller: _notesCtrl,
                label: 'Notes (optional)',
              ),
              const SizedBox(height: 24),

              NeonButton(
                label:     'Save',
                loading:   _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


//  Small local widgets ─

// Section label inside the form
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
  );
}

class _Dropdown extends StatelessWidget {
  final String?              value;
  final String               hint;
  final List<String>         items;
  final Map<String, String>? labels;
  final void Function(String?) onChanged;
  final String? Function(String?)? validator;

  const _Dropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    this.labels,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final dark       = Theme.of(context).brightness == Brightness.dark;
    final fillColor  = dark ? const Color(0xFF2A2A2A) : const Color(0xFFF5FFF5);
    final borderIdle = dark ? Colors.grey.shade700 : Colors.grey.shade300;

    return DropdownButtonFormField<String>(
      value:     value,
      hint:      Text(hint, style: GoogleFonts.inter(fontSize: 14,
          color: Colors.grey.shade400)),
      validator: validator,
      isExpanded: true,
      decoration: InputDecoration(
        filled:    true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderIdle, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kNeon, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
      ),
      items: items.map((v) => DropdownMenuItem(
        value: v,
        child: Text(
          labels?[v] ?? v,
          style: GoogleFonts.inter(fontSize: 14),
        ),
      )).toList(),
      onChanged: onChanged,
    );
  }
}
