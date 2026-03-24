import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/weight_log.dart';
import '../../../widgets/neon_widgets.dart';
import '../../../widgets/onboarding_widgets.dart';

class WeightForm extends StatefulWidget {
  final Future<void> Function(WeightLog) onSaved;
  const WeightForm({super.key, required this.onSaved});

  @override
  State<WeightForm> createState() => _WeightFormState();
}

class _WeightFormState extends State<WeightForm> {
  final _formKey    = GlobalKey<FormState>();
  final _weightCtrl = TextEditingController();
  bool  _saving     = false;

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final kg  = double.parse(_weightCtrl.text.trim());
      final log = WeightLog.create(kg);
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

            Text('Log weight',
                style: GoogleFonts.inter(
                    fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text('Date and time set automatically.',
                style: GoogleFonts.inter(
                    fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(height: 24),

            NeonField(
              controller: _weightCtrl,
              label: 'Weight (kg)',
              hint: 'e.g. 82.5',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter your weight';
                final n = double.tryParse(v);
                if (n == null || n < 20 || n > 500) {
                  return 'Enter a valid weight (20–500 kg)';
                }
                return null;
              },
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
    );
  }
}
