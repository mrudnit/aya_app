import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/sleep_log.dart';
import '../onboarding_widgets.dart';

class HomeTodaySection extends StatelessWidget {
  final SleepLog? sleepToday;
  final double    caloriesToday;
  final double    calorieTarget;
  final int       activityMin;
  final double    sleepTarget;

  const HomeTodaySection({
    super.key,
    required this.sleepToday,
    required this.caloriesToday,
    required this.calorieTarget,
    required this.activityMin,
    required this.sleepTarget,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Row(children: [
      Expanded(child: _SleepCard(
          log: sleepToday, target: sleepTarget, dark: dark)),
      const SizedBox(width: 10),
      Expanded(child: _CalorieCard(
          current: caloriesToday, target: calorieTarget, dark: dark)),
      const SizedBox(width: 10),
      Expanded(child: _ActivityCard(
          minutes: activityMin, dark: dark)),
    ]);
  }
}

// Shared card shell
class _Card extends StatelessWidget {
  final Widget child;
  final bool   dark;
  const _Card({required this.child, required this.dark});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: dark ? const Color(0xFF1E1E1E) : Colors.white,
      border: Border.all(
        color: dark ? Colors.grey.shade800 : Colors.grey.shade200,
        width: 1.5,
      ),
      borderRadius: BorderRadius.circular(14),
    ),
    child: child,
  );
}

// Sleep card
class _SleepCard extends StatelessWidget {
  final SleepLog? log;
  final double    target;
  final bool      dark;
  const _SleepCard({required this.log, required this.target, required this.dark});

  @override
  Widget build(BuildContext context) {
    final h     = log?.durationHours ?? 0;
    final color = log == null
        ? Colors.grey.shade400
        : h >= target - 0.5 ? kNeon
        : h >= target - 1.0 ? Colors.orange
        : Colors.red.shade400;

    return _Card(
      dark: dark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🌙', style: TextStyle(fontSize: 22)),
          const SizedBox(height: 8),
          Text(
            log != null ? '${h.toStringAsFixed(1)}h' : 'No data',
            style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text('Sleep',
              style: GoogleFonts.inter(
                  fontSize: 11, color: Colors.grey.shade500)),
          if (log != null) ...[
            const SizedBox(height: 4),
            Text('Target ${target.toStringAsFixed(0)}h',
                style: GoogleFonts.inter(
                    fontSize: 10, color: Colors.grey.shade400)),
          ],
        ],
      ),
    );
  }
}

// Calorie card
class _CalorieCard extends StatelessWidget {
  final double current, target;
  final bool   dark;
  const _CalorieCard({
    required this.current,
    required this.target,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    final hasData  = current > 0;
    final progress = hasData ? (current / target).clamp(0.0, 1.0) : 0.0;
    final color    = progress >= 1.0
        ? Colors.orange
        : progress >= 0.5
        ? kNeon
        : Colors.grey.shade400;

    return _Card(
      dark: dark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🍽️', style: TextStyle(fontSize: 22)),
          const SizedBox(height: 8),
          Text(
            hasData ? '${current.round()}' : 'No data',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: hasData ? null : Colors.grey.shade400,
            ),
          ),
          if (hasData)
            Text('kcal',
                style: GoogleFonts.inter(
                    fontSize: 10, color: Colors.grey.shade500)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value:           progress,
              minHeight:       5,
              backgroundColor: dark
                  ? Colors.grey.shade800
                  : Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 4),
          Text('/ ${target.round()} kcal',
              style: GoogleFonts.inter(
                  fontSize: 10, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}

// Activity card
class _ActivityCard extends StatelessWidget {
  final int  minutes;
  final bool dark;
  const _ActivityCard({required this.minutes, required this.dark});

  @override
  Widget build(BuildContext context) {
    final hasData = minutes > 0;
    final color   = !hasData
        ? Colors.grey.shade400
        : minutes >= 30 ? kNeon : Colors.orange;

    return _Card(
      dark: dark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🏃', style: TextStyle(fontSize: 22)),
          const SizedBox(height: 8),
          Text(
            hasData ? '${minutes}m' : 'No data',
            style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text('Activity',
              style: GoogleFonts.inter(
                  fontSize: 11, color: Colors.grey.shade500)),
          if (hasData) ...[
            const SizedBox(height: 4),
            Text('active today',
                style: GoogleFonts.inter(
                    fontSize: 10, color: Colors.grey.shade400)),
          ],
        ],
      ),
    );
  }
}
