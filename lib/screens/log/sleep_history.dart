import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/sleep_log.dart';
import '../../../widgets/onboarding_widgets.dart';

//  History list
class SleepHistoryList extends StatelessWidget {
  final List<SleepLog> logs;
  final void Function(String id) onDelete;

  const SleepHistoryList({
    super.key,
    required this.logs,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: logs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _SleepCard(
        log:      logs[i],
        onDelete: onDelete,
      ),
    );
  }
}

// Single card
class _SleepCard extends StatelessWidget {
  final SleepLog log;
  final void Function(String id) onDelete;

  const _SleepCard({required this.log, required this.onDelete});

  // Distribution
  Color _color(double h) {
    if (h >= 7.0) return kNeon;
    if (h >= 5.5) return Colors.orange;
    return Colors.red.shade400;
  }

  // Quality label
  String _qualityText(int? q) {
    const map = {1: '😞 Poor', 2: '😕 Fair', 3: '😐 OK',
      4: '😊 Good', 5: '😄 Great'};
    return q != null ? (map[q] ?? '') : '';
  }

  @override
  Widget build(BuildContext context) {
    final dark   = Theme.of(context).brightness == Brightness.dark;
    final bg     = dark ? const Color(0xFF1E1E1E) : Colors.white;
    final border = dark ? Colors.grey.shade800 : Colors.grey.shade200;
    final h      = log.durationHours;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        bg,
        border:       Border.all(color: border, width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color:        kNeon.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('🌙', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),

          // Date + time range + quality
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.formattedDate,
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${log.formattedBedtime}  →  ${log.formattedWakeTime}',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: Colors.grey.shade500),
                ),
                if (log.qualityScore != null)
                  Text(
                    _qualityText(log.qualityScore),
                    style: GoogleFonts.inter(
                        fontSize: 11, color: Colors.grey.shade400),
                  ),
              ],
            ),
          ),

          // Duration + delete
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${h.toStringAsFixed(1)} h',
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _color(h)),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => onDelete(log.id!),
                child: Icon(Icons.delete_outline,
                    size: 18, color: Colors.red.shade300),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
