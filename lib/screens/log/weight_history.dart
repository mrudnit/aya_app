import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/weight_log.dart';
import '../../../widgets/onboarding_widgets.dart'; // kNeon

class WeightHistoryList extends StatelessWidget {
  final List<WeightLog>       logs;
  final void Function(String) onDelete;

  const WeightHistoryList({
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
      itemBuilder: (_, i) {
        // Newest to Last
        final prev = i + 1 < logs.length ? logs[i + 1] : null;
        return _WeightCard(
          log:      logs[i],
          prev:     prev,
          onDelete: onDelete,
        );
      },
    );
  }
}

class _WeightCard extends StatelessWidget {
  final WeightLog             log;
  final WeightLog?            prev;
  final void Function(String) onDelete;

  const _WeightCard({
    required this.log,
    required this.prev,
    required this.onDelete,
  });

  // Returns
  ({String symbol, Color color}) _trend() {
    if (prev == null) return (symbol: '—', color: Colors.grey.shade400);
    final diff = log.weightKg - prev!.weightKg;
    if (diff.abs() < 0.05) {
      return (symbol: '—', color: Colors.grey.shade400);
    }
    if (diff > 0) {
      return (symbol: '↑ +${diff.toStringAsFixed(1)} kg',
      color: Colors.orange);
    }
    return (symbol: '↓ ${diff.toStringAsFixed(1)} kg',
    color: kNeon);
  }

  @override
  Widget build(BuildContext context) {
    final dark   = Theme.of(context).brightness == Brightness.dark;
    final bg     = dark ? const Color(0xFF1E1E1E) : Colors.white;
    final border = dark ? Colors.grey.shade800 : Colors.grey.shade200;
    final t      = _trend();

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
              color: kNeon.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('⚖️', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          // Date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.date,
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(t.symbol,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: t.color)),
              ],
            ),
          ),
          // Weight value
          Text(
            '${log.weightKg.toStringAsFixed(1)} kg',
            style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: kNeon),
          ),
          const SizedBox(width: 12),
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
