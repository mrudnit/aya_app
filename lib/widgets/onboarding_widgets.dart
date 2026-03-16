import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// The neon green colour used everywhere in onboarding.
const kNeon = Color(0xFF39FF14);


//  StepTitle
class StepTitle extends StatelessWidget {
  final String step;
  final String title;
  final String subtitle;

  const StepTitle({
    super.key,
    required this.step,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // Small neon step counter
        Text(
          step,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: kNeon,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        // Big heading
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        // Description
        Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}

// SegmentRow
class SegmentRow extends StatelessWidget {
  final List<String> options;
  final List<String> labels;
  final String selected;
  final void Function(String) onChanged;

  const SegmentRow({
    super.key,
    required this.options,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(options.length, (i) {
        final active = options[i] == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(options[i]),
            child: Container(
              // Gap between buttons
              margin: EdgeInsets.only(right: i < options.length - 1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: active ? kNeon : Colors.white,
                border: Border.all(
                  color: active ? kNeon : Colors.grey.shade300,
                  width: 1.8,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                labels[i],
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.black : Colors.grey.shade600,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

//  OptionCard
class OptionCard extends StatelessWidget {
  final String value;
  final String selected;
  final String label;
  final IconData icon;
  final void Function(String) onTap;

  const OptionCard({
    super.key,
    required this.value,
    required this.selected,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFF5FFF5) : Colors.white,
          border: Border.all(
            color: active ? kNeon : Colors.grey.shade200,
            width: active ? 2 : 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: active ? kNeon : Colors.grey.shade400,
              size: 22,
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            if (active) const Icon(Icons.check_circle, color: kNeon, size: 20),
          ],
        ),
      ),
    );
  }
}


// SummaryRow
class SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const SummaryRow(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// capitalize extension
extension CapitalizeString on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
