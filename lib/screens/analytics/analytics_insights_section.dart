import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AnalyticsInsightsSection extends StatelessWidget {
  final Map<String, dynamic> correlations;
  final Map<String, dynamic> lateMeal;
  final List<Map<String, dynamic>> recommendations;

  const AnalyticsInsightsSection({
    super.key,
    required this.correlations,
    required this.lateMeal,
    required this.recommendations,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Insights
        _SectionHeader(
          label: 'Insights',
          subtitle: 'Patterns found in your logged data',
        ),
        const SizedBox(height: 10),
        _RelationshipCard(
          title: 'Sleep & Activity',
          icon: Icons.swap_horiz_outlined,
          data: correlations['sleep_vs_activity'] as Map<String, dynamic>?,
        ),
        const SizedBox(height: 10),
        _RelationshipCard(
          title: 'Sleep & Nutrition',
          icon: Icons.swap_horiz_outlined,
          data: correlations['sleep_vs_calories'] as Map<String, dynamic>?,
        ),
        const SizedBox(height: 10),
        _RelationshipCard(
          title: 'Activity & Weight',
          icon: Icons.swap_horiz_outlined,
          data: correlations['activity_vs_weight'] as Map<String, dynamic>?,
        ),
        const SizedBox(height: 10),
        _RelationshipCard(
          title: 'Evening meals & Sleep quality',
          icon: Icons.nights_stay_outlined,
          data: lateMeal,
        ),

        // Recommendations
        if (recommendations.isNotEmpty) ...[
          const SizedBox(height: 24),
          _SectionHeader(
            label: 'Recommendations',
            subtitle: 'Actions you can take based on your data',
          ),
          const SizedBox(height: 10),
          ...recommendations.map(
                (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RecommendationCard(data: r),
            ),
          ),
        ],
      ],
    );
  }
}

// Section header
class _SectionHeader extends StatelessWidget {
  final String label;
  final String subtitle;
  const _SectionHeader({required this.label, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(subtitle,
            style: GoogleFonts.inter(
                fontSize: 12, color: Colors.grey.shade500)),
      ],
    );
  }
}

//Relationship / pattern card
class _RelationshipCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Map<String, dynamic>? data;

  const _RelationshipCard({
    required this.title,
    required this.icon,
    this.data,
  });

  @override
  State<_RelationshipCard> createState() => _RelationshipCardState();
}

class _RelationshipCardState extends State<_RelationshipCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final dark  = Theme.of(context).brightness == Brightness.dark;
    final d     = widget.data ?? {};
    final isOk  = d['status'] == 'ok';
    final bg    = dark ? const Color(0xFF1E1E1E) : Colors.grey.shade50;
    final bord  = dark ? Colors.grey.shade800    : Colors.grey.shade200;

    // Plain-language summary
    final summary    = d['group_summary'] as String?
        ?? d['summary'] as String?
        ?? '';
    final pairedDays = d['paired_days'] as int?;
    final correlation = d['correlation'] as Map<String, dynamic>?;
    final ttest       = d['t_test']      as Map<String, dynamic>?;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bord),
      ),
      child: Column(children: [
        InkWell(
          onTap: isOk ? () => setState(() => _expanded = !_expanded) : null,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Icon(widget.icon, size: 16, color: Colors.grey.shade400),
              const SizedBox(width: 8),
              Expanded(
                child: Text(widget.title,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700, fontSize: 14)),
              ),
              if (isOk)
                Icon(
                  _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 18, color: Colors.grey.shade400,
                ),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: isOk
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Plain-language summary always visible
            if (summary.isNotEmpty)
              Text(summary,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      height: 1.4)),
            if (pairedDays != null) ...[
              const SizedBox(height: 6),
              Text(
                'Based on $pairedDays days of your logged data.',
                style: GoogleFonts.inter(
                    fontSize: 11, color: Colors.grey.shade500),
              ),
            ],

            // Expanded: technical footnote, very small and muted
            if (_expanded && (correlation != null || ttest != null)) ...[
              const SizedBox(height: 10),
              _TechFootnote(correlation: correlation, ttest: ttest),
            ],
          ])
              : _InsufficientBanner(
              message: d['message'] as String?),
        ),
      ]),
    );
  }
}

// Research note
class _TechFootnote extends StatelessWidget {
  final Map<String, dynamic>? correlation;
  final Map<String, dynamic>? ttest;
  const _TechFootnote({this.correlation, this.ttest});

  @override
  Widget build(BuildContext context) {
    final corrSig = correlation?['significant'] as bool? ?? false;
    final ttestSig = ttest?['significant']      as bool? ?? false;
    final hasAny  = correlation != null || ttest != null;

    if (!hasAny) return const SizedBox();

    final isConfirmed = corrSig || ttestSig;
    final message = isConfirmed
        ? 'This pattern appears consistently in your data and is likely affecting your results.'
        : 'This is an early observation. Log more days to see if the pattern continues.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isConfirmed ? Icons.check_circle_outline : Icons.info_outline,
            size: 13,
            color: isConfirmed ? Colors.green.shade400 : Colors.grey.shade400,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// Recommendation card
class _RecommendationCard extends StatefulWidget {
  final Map<String, dynamic> data;
  const _RecommendationCard({required this.data});

  @override
  State<_RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<_RecommendationCard> {
  bool _expanded = false;

  static const _severityColors = {
    'critical': Color(0xFFEF5350),
    'warning':  Color(0xFFFFA726),
    'info':     Color(0xFF4FC3F7),
    'good':     Color(0xFF66BB6A),
  };

  static const _severityIcons = {
    'critical': Icons.error_outline,
    'warning':  Icons.warning_amber_outlined,
    'info':     Icons.info_outline,
    'good':     Icons.check_circle_outline,
  };

  // Human-readable
  static const _severityLabel = {
    'critical': 'Needs attention',
    'warning':  'Worth improving',
    'info':     'Good to know',
    'good':     'On track',
  };

  @override
  Widget build(BuildContext context) {
    final dark     = Theme.of(context).brightness == Brightness.dark;
    final severity = widget.data['severity']         as String? ?? 'info';
    final accent   = _severityColors[severity]       ?? const Color(0xFF4FC3F7);
    final iconData = _severityIcons[severity]        ?? Icons.info_outline;
    final title    = widget.data['title']            as String? ?? '';
    final summary  = widget.data['summary']          as String? ?? '';
    final detail   = widget.data['detail']           as String?;
    final action   = widget.data['suggested_action'] as String?;
    final sevLabel = _severityLabel[severity]        ?? '';

    return Container(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: dark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Severity icon
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(iconData, size: 16, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 4),
                    // Summary
                    Text(summary,
                        style: GoogleFonts.inter(
                            fontSize: 13, color: Colors.grey.shade600)),
                    const SizedBox(height: 6),
                    _Badge(label: sevLabel, color: accent),
                  ],
                )),
                Icon(
                  _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 18, color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),

        if (_expanded && (detail != null || action != null))
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(
                  color: dark ? Colors.grey.shade800 : Colors.grey.shade200,
                  height: 1,
                ),
                const SizedBox(height: 12),

                // Plain language
                if (detail != null) ...[
                  Text(detail,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.5)),
                  const SizedBox(height: 12),
                ],

                // Suggested action
                if (action != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: accent.withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline, size: 15, color: accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(action,
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: accent)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ]),
    );
  }
}

// Shared tiny widgets
class _InsufficientBanner extends StatelessWidget {
  final String? message;
  const _InsufficientBanner({this.message});

  @override
  Widget build(BuildContext context) => Row(children: [
    const Icon(Icons.lock_clock_outlined, size: 14, color: Colors.grey),
    const SizedBox(width: 6),
    Expanded(
      child: Text(
        // Friendly message
        'Log more days to unlock this analysis.',
        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
      ),
    ),
  ]);
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label,
        style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color)),
  );
}
