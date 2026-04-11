import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/sleep_log.dart';
import '../../../widgets/neon_widgets.dart';
import '../../../widgets/onboarding_widgets.dart'; // kNeon

class SleepForm extends StatefulWidget {
  final Future<void> Function(SleepLog) onSaved;

  const SleepForm({super.key, required this.onSaved});

  @override
  State<SleepForm> createState() => _SleepFormState();
}

class _SleepFormState extends State<SleepForm> {
  TimeOfDay _bedtime  = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7,  minute: 0);
  int?      _quality; // null = not rated
  bool      _saving = false;

  // Date inference
  DateTime _toBedtime() {
    final today = _today();
    return DateTime(
      today.year,
      today.month,
      today.day,
      _bedtime.hour,
      _bedtime.minute,
    );
  }

  DateTime _toWakeTime() {
    final today = _today();

    final bedtime = _toBedtime();
    DateTime wakeTime = DateTime(
      today.year,
      today.month,
      today.day,
      _wakeTime.hour,
      _wakeTime.minute,
    );

    if (!wakeTime.isAfter(bedtime)) {
      wakeTime = wakeTime.add(const Duration(days: 1));
    }

    return wakeTime;
  }

  DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  double get _previewHours =>
      _toWakeTime().difference(_toBedtime()).inMinutes / 60.0;

  // Time picker
  Future<void> _pickTime(bool isBedtime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isBedtime ? _bedtime : _wakeTime,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx)
            .copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() => isBedtime ? _bedtime = picked : _wakeTime = picked);
  }

  // Save
  Future<void> _save() async {
    if (_previewHours <= 0 || _previewHours > 20) {
      _snack('Check your times — duration looks incorrect.');
      return;
    }
    setState(() => _saving = true);
    try {
      final log = SleepLog.create(
        bedtime:      _toBedtime(),
        wakeTime:     _toWakeTime(),
        qualityScore: _quality,
      );
      await widget.onSaved(log);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _snack('Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg, style: GoogleFonts.inter(fontSize: 13))),
  );

  // Build
  @override
  Widget build(BuildContext context) {
    final dark   = Theme.of(context).brightness == Brightness.dark;
    final bg     = dark ? const Color(0xFF1E1E1E) : Colors.white;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final h      = _previewHours;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius:
        const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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

          Text('Log sleep',
              style: GoogleFonts.inter(
                  fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text('Date is set automatically.',
              style: GoogleFonts.inter(
                  fontSize: 12, color: Colors.grey.shade500)),
          const SizedBox(height: 20),

          // Time pickers
          Row(children: [
            Expanded(child: _TimeTile(
              label: 'Bedtime',
              time:  _fmt(_bedtime),
              onTap: () => _pickTime(true),
            )),
            const SizedBox(width: 12),
            Expanded(child: _TimeTile(
              label: 'Wake time',
              time:  _fmt(_wakeTime),
              onTap: () => _pickTime(false),
            )),
          ]),
          const SizedBox(height: 14),

          // Duration preview
          Center(child: Text(
            'Duration: ${h.toStringAsFixed(1)} h',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: h >= 7.0
                  ? kNeon
                  : h >= 5.5
                  ? Colors.orange
                  : Colors.red.shade400,
            ),
          )),
          const SizedBox(height: 20),

          // Quality
          Text('Sleep quality (optional)',
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _StarPicker(
            value:     _quality,
            onChanged: (v) => setState(() => _quality = v),
          ),
          const SizedBox(height: 24),

          NeonButton(label: 'Save', loading: _saving, onPressed: _save),
        ],
      ),
    );
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
          '${t.minute.toString().padLeft(2, '0')}';
}


// Time tile
class _TimeTile extends StatelessWidget {
  final String       label;
  final String       time;
  final VoidCallback onTap;

  const _TimeTile({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg   = dark ? const Color(0xFF2A2A2A) : const Color(0xFFF5FFF5);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color:        bg,
          border:       Border.all(color: kNeon, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11, color: Colors.grey.shade500)),
            const SizedBox(height: 4),
            Text(time,
                style: GoogleFonts.inter(
                    fontSize: 22, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}


// Stars
class _StarPicker extends StatelessWidget {
  final int?            value;
  final void Function(int?) onChanged;

  const _StarPicker({required this.value, required this.onChanged});

  static const _labels = {
    1: 'Poor', 2: 'Fair', 3: 'OK', 4: 'Good', 5: 'Great'
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...List.generate(5, (i) {
          final star   = i + 1;
          final active = star <= (value ?? 0);
          return GestureDetector(
            // Tap again to deselect (quality is optional).
            onTap: () => onChanged(active ? null : star),
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(
                active
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: kNeon,
                size: 30,
              ),
            ),
          );
        }),
        if (value != null)
          Text(
            _labels[value!] ?? '',
            style: GoogleFonts.inter(
                fontSize: 12, color: Colors.grey.shade500),
          ),
      ],
    );
  }
}
