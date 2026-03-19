import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/onboarding_widgets.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Analytics',
              style: GoogleFonts.inter(
                  fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Insights about your habits over time.',
              style: GoogleFonts.inter(
                  fontSize: 13, color: Colors.grey.shade500)),
          const SizedBox(height: 28),

          _StubCard(
            emoji: '🌙',
            title: 'Sleep trends',
            description:
            'Average sleep per night vs your target.\n'
                'Line chart — available in Phase 4.',
          ),
          const SizedBox(height: 16),
          _StubCard(
            emoji: '🍽️',
            title: 'Nutrition overview',
            description:
            'Daily calorie and macro averages.\n'
                'Bar chart — available in Phase 4.',
          ),
          const SizedBox(height: 16),
          _StubCard(
            emoji: '🏃',
            title: 'Activity summary',
            description:
            'Active minutes per week vs WHO recommendation (150 min).\n'
                'Available in Phase 4.',
          ),
          const SizedBox(height: 16),
          _StubCard(
            emoji: '📊',
            title: 'Correlation analysis',
            description:
            'Sleep vs energy, activity vs mood, and more.\n'
                'Requires FastAPI + Python backend — Phase 5.',
          ),
        ],
      ),
    );
  }
}

class _StubCard extends StatelessWidget {
  final String emoji, title, description;
  const _StubCard({
    required this.emoji,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border.all(
            color: dark ? Colors.grey.shade700 : Colors.grey.shade200,
            width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(description,
                    style: GoogleFonts.inter(
                        fontSize: 13, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: kNeon.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Planned',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: kNeon)),
          ),
        ],
      ),
    );
  }
}
