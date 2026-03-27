import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/nutrition_log.dart';
import '../../../services/nutrition_service.dart';
import '../../../widgets/onboarding_widgets.dart';
import 'nutrition_form.dart';
import 'nutrition_history.dart';

class NutritionLogScreen extends StatefulWidget {
  const NutritionLogScreen({super.key});

  @override
  State<NutritionLogScreen> createState() => _NutritionLogScreenState();
}

class _NutritionLogScreenState extends State<NutritionLogScreen> {
  final _service = NutritionService();
  List<MealLog> _logs    = [];
  bool          _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final logs = await _service.getRecentNutritionLogs();
    if (mounted) setState(() { _logs = logs; _loading = false; });
  }

  void _openForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NutritionForm(
        onSaved: (log) async {
          await _service.addNutritionLog(log);
          if (mounted) {
            _load();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Meal saved!',
                  style: GoogleFonts.inter(fontSize: 13)),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ));
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const Center(
          child: CircularProgressIndicator(color: kNeon));
    } else if (_logs.isEmpty) {
      body = Center(
        child: Text(
          '🍽️\n\nNo meals logged yet.\nTap + to add your first meal.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
              fontSize: 14, color: Colors.grey.shade500),
        ),
      );
    } else {
      body = RefreshIndicator(
        color: kNeon,
        onRefresh: _load,
        child: NutritionHistoryList(
          logs:     _logs,
          onDelete: (id) async {
            await _service.deleteNutritionLog(id);
            _load();
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        backgroundColor: kNeon,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: Text('Add meal',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
