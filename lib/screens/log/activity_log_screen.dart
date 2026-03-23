import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/activity_log.dart';
import '../../../services/activity_service.dart';
import '../../../widgets/onboarding_widgets.dart';
import 'activity_form.dart';
import 'activity_history.dart';

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  final _service = ActivityService();

  List<ActivityLog> _logs    = [];
  bool              _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final logs = await _service.getActivityLogs();
    if (mounted) setState(() { _logs = logs; _loading = false; });
  }

  void _openForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ActivityForm(
        onSaved: (log) async {
          await _service.addActivityLog(log);
          if (mounted) {
            _load();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Workout saved!',
                    style: GoogleFonts.inter(fontSize: 13)),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _delete(String id) async {
    await _service.deleteActivityLog(id);
    _load();
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
          '🏋️\n\nNo workouts logged yet.\nTap + to add your first entry.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
              fontSize: 14, color: Colors.grey.shade500),
        ),
      );
    } else {
      body = RefreshIndicator(
        color: kNeon,
        onRefresh: _load,
        child: ActivityHistoryList(logs: _logs, onDelete: _delete),
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
        label: Text('Log workout',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
