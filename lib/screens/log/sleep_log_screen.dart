import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/sleep_log.dart';
import '../../../services/sleep_service.dart';
import '../../../widgets/onboarding_widgets.dart';
import 'sleep_history.dart';
import 'sleep_form.dart';

class SleepLogScreen extends StatefulWidget {
  const SleepLogScreen({super.key});

  @override
  State<SleepLogScreen> createState() => _SleepLogScreenState();
}

class _SleepLogScreenState extends State<SleepLogScreen> {
  final _service = SleepService();

  List<SleepLog> _logs    = [];
  bool           _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final logs = await _service.getSleepLogs();
    if (mounted) setState(() { _logs = logs; _loading = false; });
  }

  // Open Form
  void _openForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SleepForm(
        onSaved: (log) async {
          await _service.addSleepLog(log);
          if (mounted) _load();
        },
      ),
    );
  }

  Future<void> _delete(String id) async {
    await _service.deleteSleepLog(id);
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
          '🌙\n\nNo sleep logged yet.\nTap + to add your first entry.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
              fontSize: 14, color: Colors.grey.shade500),
        ),
      );
    } else {
      body = RefreshIndicator(
        color: kNeon,
        onRefresh: _load,
        child: SleepHistoryList(logs: _logs, onDelete: _delete),
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
        label: Text('Log sleep',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
