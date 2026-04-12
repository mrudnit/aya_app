import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/activity_log.dart';
import '../../../widgets/neon_widgets.dart';
import '../../../widgets/onboarding_widgets.dart';
import 'activity_constants.dart';

class ActivityForm extends StatefulWidget {
  final Future<void> Function(ActivityLog) onSaved;
  const ActivityForm({super.key, required this.onSaved});

  @override
  State<ActivityForm> createState() => _ActivityFormState();
}

class _ActivityFormState extends State<ActivityForm> {
  bool _saving = false;
  // Category selection
  String _category = 'strength';
  final List<Map<String, dynamic>> _exercises = [];

  // Strength fields
  String? _muscleGroup;
  String? _exerciseName;
  final _customCtrl = TextEditingController();
  final _setsCtrl           = TextEditingController();
  final _repsCtrl           = TextEditingController();
  final _weightCtrl         = TextEditingController();
  bool   _addingExercise = true;

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
    _customCtrl.dispose();
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

  List<String> get _exercises_for_group =>
      kExercisesByGroup[_muscleGroup] ?? ['Other'];

  bool get _showCustom =>
      _muscleGroup != null && _exerciseName == 'Other';

  // Date
  String _todayDate() {
    final n = DateTime.now();
    return '${n.year}-'
        '${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

  // Add exercise to the session list
  void _addExercise() {
    final name = _showCustom
        ? _customCtrl.text.trim()
        : _exerciseName ?? '';
    if (name.isEmpty) { _snack('Select or enter an exercise name.'); return; }
    final sets = int.tryParse(_setsCtrl.text);
    final reps = int.tryParse(_repsCtrl.text);
    if (sets == null || reps == null) {
      _snack('Enter sets and reps.');
      return;
    }
    final weight = double.tryParse(_weightCtrl.text);
    if (weight == null) {
      _snack('Enter exercise weight (kg). Use 0 if bodyweight.');
      return;
    }
    setState(() {
      _exercises.add({
        'name':   name,
        'sets':   sets,
        'reps':   reps,
        'weight': weight,
      });
      // Reset exercise input area
      _exerciseName = null;
      _customCtrl.clear();
      _setsCtrl.clear();
      _repsCtrl.clear();
      _weightCtrl.clear();
      _addingExercise = false;
    });
  }

  void _removeExercise(int i) => setState(() => _exercises.removeAt(i));

  // Save
  Future<void> _save() async {
    if (_category == 'strength' && _exercises.isEmpty) {
      _snack('Add at least one exercise to this session.');
      return;
    }
    if (_category == 'cardio' && _cardioType == null) {
      _snack('Select a cardio type.');
      return;
    }
    if (_category == 'other' && _titleCtrl.text.trim().isEmpty) {
      _snack('Enter an activity name.');
      return;
    }

    setState(() => _saving = true);
    try {
      final now  = DateTime.now();
      String? exerciseName;
      String? muscleGroup;
      String? customExercise;
      int?    sets;
      int?    reps;
      double? weightKg;
      String? notes;

      if (_category == 'strength' && _exercises.isNotEmpty) {
        final first   = _exercises.first;
        exerciseName  = first['name'] as String?;
        muscleGroup   = _muscleGroup;
        sets          = first['sets']   as int?;
        reps          = first['reps']   as int?;
        weightKg      = first['weight'] as double?;

        // Additional exercises
        if (_exercises.length > 1) {
          final extras = _exercises.skip(1).map((e) {
            final w = e['weight'] != null ? ' ${e['weight']}kg' : '';
            return '${e['name']} ${e['sets']}×${e['reps']}$w';
          }).join(' | ');
          final userNotes = _notesCtrl.text.trim();
          notes = userNotes.isEmpty ? extras : '$extras\n$userNotes';
        } else {
          notes = _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();
        }
      } else {
        notes = _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();
      }

      final int? durationMin = switch (_category) {
        'cardio' => int.tryParse(_durationCtrl.text),
        'other'  => int.tryParse(_durationOtherCtrl.text),
        _        => null,
      };

    final log = ActivityLog(
      date:      _todayDate(),
      category:  _category,
      createdAt: now,
      updatedAt: now,
      muscleGroup:    muscleGroup,
      exerciseName:   _showCustom ? null   : exerciseName,
      customExercise: _showCustom ? exerciseName : null,
      sets:           sets,
      reps:           reps,
      weightKg:       weightKg,
      cardioType:     _category == 'cardio' ? _cardioType : null,
      durationMin:    durationMin,
      caloriesBurned: _category == 'cardio' && _caloriesCtrl.text.isNotEmpty
          ? double.tryParse(_caloriesCtrl.text) : null,
      title:          _category == 'other' ? _titleCtrl.text.trim() : null,
      notes:          notes,
    );

      await widget.onSaved(log);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _snack('Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

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
                labels:   const ['Strength 🏋️', 'Cardio 🏃', 'Other ⚡'],
                selected: _category,
                onChanged: (v) => setState(() {
                  _category = v;
                  // Reset category-specific selections on switch
                  _muscleGroup  = null;
                  _exerciseName = null;
                  _cardioType   = null;
                  _exercises.clear();
                  _addingExercise = true;
                }),
              ),
              const SizedBox(height: 20),

              // Strength fields
              if (_category == 'strength') ...[
                _Label('Muscle group for this session'),
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
                ),
                const SizedBox(height: 14),

                // Already-added exercises
                if (_exercises.isNotEmpty) ...[
                  _Label('Exercises in this session'),
                  const SizedBox(height: 8),
                  ..._exercises.asMap().entries.map((e) =>
                      _ExerciseTile(
                        item:     e.value,
                        onRemove: () => _removeExercise(e.key),
                      )),
                  const SizedBox(height: 8),
                ],

                // Add exercise input area
                if (_addingExercise && _muscleGroup != null) ...[
                  _Label(_exercises.isEmpty ? 'Exercise' : 'Add another exercise'),
                  const SizedBox(height: 8),
                  _Dropdown(
                    value:    _exerciseName,
                    hint:     'Select exercise',
                    items:    _exercises_for_group,
                    onChanged: (v) => setState(() => _exerciseName = v),
                  ),
                  const SizedBox(height: 12),
                  if (_showCustom) ...[
                    NeonField(
                      controller: _customCtrl,
                      label: 'Custom exercise name',
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(children: [
                    Expanded(child: NeonField(
                      controller: _setsCtrl, label: 'Sets',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: NeonField(
                      controller: _repsCtrl, label: 'Reps',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: NeonField(
                      controller: _weightCtrl, label: 'Weight (kg) *',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                      ],
                    )),
                  ]),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _addExercise,
                    icon: const Icon(Icons.add),
                    label: Text('Add exercise',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kNeon,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 46),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],

                // "+" button after first exercise added
                if (!_addingExercise && _exercises.isNotEmpty) ...[
                  TextButton.icon(
                    onPressed: () => setState(() => _addingExercise = true),
                    icon: const Icon(Icons.add, color: kNeon, size: 18),
                    label: Text('Add another exercise',
                        style: GoogleFonts.inter(
                            color: kNeon, fontWeight: FontWeight.w600)),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
                ],
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
                ),
                const SizedBox(height: 14),

                Row(children: [
                  Expanded(child: NeonField(
                    controller: _durationCtrl,
                    label: 'Duration (min)',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                label:     _category == 'strength'
                    ? 'Save session${_exercises.isNotEmpty ? ' (${_exercises.length} exercise${_exercises.length == 1 ? '' : 's'})' : ''}'
                    : 'Save',
                loading:   _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
    );
  }
}

// Exercise tile
class _ExerciseTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onRemove;
  const _ExerciseTile({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final dark   = Theme.of(context).brightness == Brightness.dark;
    final name   = item['name']   as String? ?? '';
    final sets   = item['sets']   as int?    ?? 0;
    final reps   = item['reps']   as int?    ?? 0;
    final weight = item['weight'] as double?;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF2A2A2A) : const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: dark ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
      ),
      child: Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            Text(
              '${sets}×${reps}${weight != null ? '  ·  ${weight}kg' : ''}',
              style: GoogleFonts.inter(
                  fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        )),
        GestureDetector(
          onTap: onRemove,
          child: Text('Remove',
              style: GoogleFonts.inter(
                  fontSize: 11, color: Colors.red.shade400)),
        ),
      ]),
    );
  }
}

//  Small local widgets
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

  const _Dropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    this.labels,
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
