import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AnalyticsSummarySection extends StatelessWidget {
  final Map<String, dynamic> sleep, nutrition, activity, weight;

  const AnalyticsSummarySection({
    super.key,
    required this.sleep,
    required this.nutrition,
    required this.activity,
    required this.weight,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: [
        _SummaryCard(
          label: 'Sleep',
          icon: Icons.bedtime_outlined,
          accent: const Color(0xFF4FC3F7),
          data: sleep,
          mainValue: sleep['status'] == 'ok' ? '${sleep['avg_hours']}h' : null,
        ),
        _SummaryCard(
          label: 'Nutrition',
          icon: Icons.restaurant_outlined,
          accent: const Color(0xFFFFA726),
          data: nutrition,
          mainValue: nutrition['status'] == 'ok' ? '${nutrition['avg_kcal']} kcal' : null,
        ),
        _SummaryCard(
          label: 'Activity',
          icon: Icons.directions_run_outlined,
          accent: const Color(0xFF66BB6A),
          data: activity,
          mainValue: activity['status'] == 'ok' ? '${activity['total_min']} min' : null,
        ),
        _SummaryCard(
          label: 'Weight',
          icon: Icons.monitor_weight_outlined,
          accent: const Color(0xFFAB47BC),
          data: weight,
          mainValue: weight['status'] == 'ok' ? '${weight['last_kg']} kg' : null,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final Map<String, dynamic> data;
  final String? mainValue;

  const _SummaryCard({
    required this.label,
    required this.icon,
    required this.accent,
    required this.data,
    this.mainValue,
  });

  @override
  Widget build(BuildContext context) {
    final dark       = Theme.of(context).brightness == Brightness.dark;
    final isOk       = data['status'] == 'ok';
    final confidence = data['confidence'] as String? ?? '';
    final message    = data['message']    as String?;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: dark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: accent),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
          if (isOk) ...[
            Text(mainValue ?? '—',
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w800, color: accent)),
            Row(children: [
              _ConfidenceDot(confidence),
              const SizedBox(width: 4),
              Text(confidence,
                  style: GoogleFonts.inter(
                      fontSize: 10, color: Colors.grey.shade500)),
            ]),
          ] else ...[
            Text(message ?? 'Not enough data',
                style: GoogleFonts.inter(
                    fontSize: 10, color: Colors.grey.shade500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
}

class _ConfidenceDot extends StatelessWidget {
  final String confidence;
  const _ConfidenceDot(this.confidence);

  @override
  Widget build(BuildContext context) {
    final color = confidence == 'high'
        ? const Color(0xFF66BB6A)
        : confidence == 'medium'
        ? const Color(0xFFFFA726)
        : Colors.grey.shade400;
    return Container(
      width: 7, height: 7,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
