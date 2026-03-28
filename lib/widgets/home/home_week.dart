import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../onboarding_widgets.dart';

class HomeWeekSection extends StatelessWidget {
  final double       avgSleep;
  final int          sleepDays;
  final int          sessions;
  final double       avgCalories;
  final VoidCallback onTap;

  const HomeWeekSection({
    super.key,
    required this.avgSleep,
    required this.sleepDays,
    required this.sessions,
    required this.avgCalories,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark   = Theme.of(context).brightness == Brightness.dark;
    final bg     = dark ? const Color(0xFF1E1E1E) : Colors.white;
    final border = dark ? Colors.grey.shade800 : Colors.grey.shade200;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        bg,
          border:       Border.all(color: border, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text('Last 7 days',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500))),
              Row(children: [
                Text('View analytics',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: kNeon,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: kNeon, size: 11),
              ]),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _WeekStat(
                emoji: '🌙',
                value: sleepDays == 0
                    ? '—' : '${avgSleep.toStringAsFixed(1)}h',
                label: sleepDays == 0
                    ? 'No sleep data' : 'avg · $sleepDays nights',
              )),
              _Divider(dark: dark),
              Expanded(child: _WeekStat(
                emoji: '🏃',
                value: sessions == 0 ? '—' : '$sessions',
                label: sessions == 0
                    ? 'No workouts'
                    : 'workout${sessions == 1 ? '' : 's'}',
              )),
              _Divider(dark: dark),
              Expanded(child: _WeekStat(
                emoji: '🍽️',
                value: avgCalories == 0
                    ? '—' : '${avgCalories.round()}',
                label: avgCalories == 0
                    ? 'No meal data' : 'avg kcal/day',
              )),
            ]),
          ],
        ),
      ),
    );
  }
}

class _WeekStat extends StatelessWidget {
  final String emoji, value, label;
  const _WeekStat({
    required this.emoji,
    required this.value,
    required this.label,
  });
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(emoji, style: const TextStyle(fontSize: 20)),
    const SizedBox(height: 6),
    Text(value,
        style: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w800)),
    const SizedBox(height: 2),
    Text(label,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
            fontSize: 10, color: Colors.grey.shade500)),
  ]);
}

class _Divider extends StatelessWidget {
  final bool dark;
  const _Divider({required this.dark});
  @override
  Widget build(BuildContext context) => Container(
    width: 1, height: 52,
    color: dark ? Colors.grey.shade800 : Colors.grey.shade200,
    margin: const EdgeInsets.symmetric(horizontal: 8),
  );
}
