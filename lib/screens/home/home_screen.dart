import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/profile_service.dart';
import '../../widgets/onboarding_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _profileService = ProfileService();

  bool _loading = true;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final profile = await _profileService.getProfile();
    if (mounted) setState(() { _profile = profile; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: kNeon));
    }
    if (_profile == null) {
      return const Center(child: Text('Could not load profile.'));
    }

    final firstName = _profile!['firstName'] ?? '';
    final goal      = _profile!['goal']      ?? '';
    final heightCm  = _profile!['height_cm'];
    final weightKg  = _profile!['weight_kg'];
    final cardBg    = dark ? const Color(0xFF1E1E1E) : const Color(0xFFF5FFF5);
    final cardBorder = dark ? Colors.grey.shade700 : Colors.grey.shade200;

    return RefreshIndicator(
      color: kNeon,
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Greeting
            Text('Hello, $firstName 👋',
                style: GoogleFonts.inter(
                    fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text("Here's your daily overview.",
                style: GoogleFonts.inter(
                    fontSize: 14, color: Colors.grey.shade500)),
            const SizedBox(height: 20),

            //  Insight placeholder
            Container(
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
                  const Text('📋', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Start logging today',
                            style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(
                            'Log your meals, activity and sleep to get '
                                'personalised insights here. Available in Phase 4.',
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Today summary (placeholders)
            _SectionLabel('Today'),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _SummaryTile(
                  emoji: '🌙', label: 'Sleep',
                  value: 'No data', dim: true)),
              const SizedBox(width: 10),
              Expanded(child: _SummaryTile(
                  emoji: '🍽️', label: 'Calories',
                  value: 'No data', dim: true)),
              const SizedBox(width: 10),
              Expanded(child: _SummaryTile(
                  emoji: '🏃', label: 'Activity',
                  value: 'No data', dim: true)),
            ]),
            const SizedBox(height: 24),

            // Week summary (placeholders)
            _SectionLabel('This week'),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                border: Border.all(color: kNeon, width: 1.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                Expanded(child: _WeekStat(
                    emoji: '🌙', label: 'Avg sleep',   value: '—')),
                _VDivider(),
                Expanded(child: _WeekStat(
                    emoji: '🏃', label: 'Activity',    value: '—')),
                _VDivider(),
                Expanded(child: _WeekStat(
                    emoji: '🍽️', label: 'Avg calories', value: '—')),
              ]),
            ),
            const SizedBox(height: 24),

            // Quick actions
            _SectionLabel('Quick add'),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _QuickTile(emoji: '🌙', label: 'Sleep')),
              const SizedBox(width: 10),
              Expanded(child: _QuickTile(emoji: '🏃', label: 'Activity')),
              const SizedBox(width: 10),
              Expanded(child: _QuickTile(emoji: '🍽️', label: 'Nutrition')),
            ]),
            const SizedBox(height: 24),

            // Profile card
            _SectionLabel('Your profile'),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                border: Border.all(color: kNeon, width: 1.8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(children: [
                _InfoRow('Height',   '${heightCm ?? '-'} cm'),
                _InfoRow('Weight',   '${weightKg ?? '-'} kg'),
                _InfoRow('Goal',     _goalLabel(goal)),
                _InfoRow('Activity', _cap(_profile!['activity_level'] ?? '')),
                if (_profile!['target_sleep_hours'] != null)
                  _InfoRow('Sleep target',
                      '${_profile!['target_sleep_hours']} h / night'),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  String _goalLabel(String v) => switch (v) {
    'lose_weight' => 'Lose weight',
    'gain_weight' => 'Gain weight / muscle',
    _             => 'Maintain weight',
  };
  String _cap(String v) =>
      v.isEmpty ? v : '${v[0].toUpperCase()}${v.substring(1)}';
}


// Local widgets

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w700));
}

class _SummaryTile extends StatelessWidget {
  final String emoji, label, value;
  final bool dim;
  const _SummaryTile({
    required this.emoji, required this.label,
    required this.value, this.dim = false,
  });
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border.all(
            color: dark ? Colors.grey.shade700 : Colors.grey.shade200,
            width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: dim ? 12 : 14,
                  fontWeight:
                  dim ? FontWeight.w400 : FontWeight.w700,
                  color: dim ? Colors.grey.shade400 : null)),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

class _WeekStat extends StatelessWidget {
  final String emoji, label, value;
  const _WeekStat(
      {required this.emoji, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(emoji, style: const TextStyle(fontSize: 22)),
    const SizedBox(height: 6),
    Text(value,
        style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade400)),
    const SizedBox(height: 2),
    Text(label,
        style: GoogleFonts.inter(
            fontSize: 11, color: Colors.grey.shade500)),
  ]);
}

class _VDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1, height: 48, color: Colors.grey.shade200,
    margin: const EdgeInsets.symmetric(horizontal: 8),
  );
}

class _QuickTile extends StatelessWidget {
  final String emoji, label;
  const _QuickTile({required this.emoji, required this.label});
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1A2E1A) : const Color(0xFFF5FFF5),
        border: Border.all(color: kNeon, width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 5),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 14, color: Colors.grey.shade500)),
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}
