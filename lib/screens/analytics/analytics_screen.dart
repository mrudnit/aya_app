import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/analytics_api_service.dart';
import 'analytics_summary_section.dart';
import 'analytics_chart_section.dart';
import 'analytics_insights_section.dart';

const _kNeon = Color(0xFF39FF14);

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _api = AnalyticsApiService();

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Not logged in');
      final data = await _api.fetchOverview(uid);
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _kNeon),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text('Could not load analytics',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 8),
              Text(_error!,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: Colors.grey.shade600),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kNeon,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final d               = _data!;
    final sleep           = d['sleep']              as Map<String, dynamic>? ?? {};
    final nutrition       = d['nutrition']          as Map<String, dynamic>? ?? {};
    final activity        = d['activity']           as Map<String, dynamic>? ?? {};
    final weight          = d['weight']             as Map<String, dynamic>? ?? {};
    final correlations    = d['correlations']       as Map<String, dynamic>? ?? {};
    final lateMeal        = d['late_meal_analysis'] as Map<String, dynamic>? ?? {};
    final recommendations = (d['recommendations']   as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    return RefreshIndicator(
      color: _kNeon,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // Header
          Text('Analytics',
              style: GoogleFonts.inter(
                  fontSize: 26, fontWeight: FontWeight.w800, color: _kNeon)),
          const SizedBox(height: 4),
          Text('Understand your recent patterns and what to do next',
              style: GoogleFonts.inter(
                  fontSize: 13, color: Colors.grey.shade500)),
          const SizedBox(height: 20),

          // Weekly summary cards
          _SectionLabel('Weekly Summary'),
          const SizedBox(height: 10),
          AnalyticsSummarySection(
            sleep: sleep,
            nutrition: nutrition,
            activity: activity,
            weight: weight,
          ),
          const SizedBox(height: 24),

          // Charts
          _SectionLabel('Trends'),
          const SizedBox(height: 10),
          AnalyticsChartsSection(
            sleep: sleep,
            nutrition: nutrition,
            activity: activity,
            weight: weight,
          ),
          const SizedBox(height: 24),

          _SectionLabel('Insights'),
          const SizedBox(height: 10),
          AnalyticsInsightsSection(
            correlations: correlations,
            lateMeal: lateMeal,
            recommendations: recommendations,
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade500,
        letterSpacing: 0.8,
      ),
    );
  }
}
