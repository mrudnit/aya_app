import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/activity_log.dart';
import '../../../widgets/onboarding_widgets.dart';

class ActivityHistoryList extends StatelessWidget {
  final List<ActivityLog>      logs;
  final void Function(String)  onDelete;

  const ActivityHistoryList({
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
      itemBuilder: (_, i) => _ActivityCard(
        log:      logs[i],
        onDelete: onDelete,
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final ActivityLog            log;
  final void Function(String)  onDelete;

  const _ActivityCard({required this.log, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final dark   = Theme.of(context).brightness == Brightness.dark;
    final bg     = dark ? const Color(0xFF1E1E1E) : Colors.white;
    final border = dark ? Colors.grey.shade800 : Colors.grey.shade200;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        bg,
        border:       Border.all(color: border, width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Category icon
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: kNeon.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(log.categoryEmoji,
                  style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),

          // Title + subtitle + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.displayTitle,
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                if (log.displaySubtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(log.displaySubtitle,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.grey.shade500)),
                ],
                const SizedBox(height: 2),
                Text(log.date,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: Colors.grey.shade400)),
              ],
            ),
          ),

          // Delete
          GestureDetector(
            onTap: () => onDelete(log.id!),
            child: Icon(Icons.delete_outline,
                size: 18, color: Colors.red.shade300),
          ),
        ],
      ),
    );
  }
}