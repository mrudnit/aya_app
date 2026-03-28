import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../onboarding_widgets.dart';

class HomeInsightCard extends StatelessWidget {
  final String emoji, title, body;

  const HomeInsightCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: dark
            ? const Color(0xFF1A2E1A)
            : const Color(0xFFF0FFF0),
        border: Border.all(color: kNeon, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(body,
                    style: GoogleFonts.inter(
                        fontSize: 13, color: Colors.grey.shade500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
