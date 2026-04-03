

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../widgets/neon_widgets.dart';
import '../../widgets/onboarding_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _profileService = ProfileService();
  final _sleepCtrl      = TextEditingController();

  bool    _loading    = true;
  bool    _saving     = false;
  bool    _hasChanges = false;

  String _firstName = '';
  String _email     = '';

  String _goal        = 'maintain';
  double _sleepHours  = 8.0;
  bool   _darkMode    = false;

  @override
  void initState() {
    super.initState();
    _darkMode = themeNotifier.value == ThemeMode.dark;
    _load();
  }

  @override
  void dispose() {
    _sleepCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final profile = await _profileService.getProfile();
    if (profile != null && mounted) {
      final sleep = (profile['target_sleep_hours'] as num?)?.toDouble() ?? 8.0;
      setState(() {
        _firstName        = profile['firstName'] ?? '';
        _email            = FirebaseAuth.instance.currentUser?.email ?? '';
        _goal             = profile['goal'] ?? 'maintain';
        _sleepHours       = sleep;
        _sleepCtrl.text   = sleep % 1 == 0
            ? sleep.toInt().toString()
            : sleep.toString();
        _loading          = false;
      });
    }
  }

  // Called whenever user changes anything
  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  // Save everything at once
  Future<void> _save() async {
    final sleepVal = double.tryParse(_sleepCtrl.text.trim());
    if (sleepVal == null || sleepVal < 1 || sleepVal > 24) {
      _showSnack('Sleep target must be a number between 1 and 24.');
      return;
    }

    setState(() => _saving = true);
    try {
      // Save profile fields to Firestore
      await _profileService.updateFields({
        'goal':                _goal,
        'target_sleep_hours':  sleepVal,
      });

      // Apply dark mode immediately
      themeNotifier.value = _darkMode ? ThemeMode.dark : ThemeMode.light;

      setState(() { _hasChanges = false; _sleepHours = sleepVal; });
      _showSnack('Settings saved.');
    } catch (e) {
      _showSnack('Save failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Log out?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('You will be returned to the login screen.',
            style: GoogleFonts.inter(
                fontSize: 14, color: Colors.grey.shade500)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: Colors.grey.shade500)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Log out',
                style: GoogleFonts.inter(
                    color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AuthService().logout();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(fontSize: 13)),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = dark ? const Color(0xFF1E1E1E) : Colors.white;
    final cardBorder = dark ? Colors.grey.shade800 : Colors.grey.shade200;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: kNeon, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Settings',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        // Saving spinner in top-right
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: kNeon),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(
          child: CircularProgressIndicator(color: kNeon))
          : SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 1. User info
            _SectionHeader('User info'),
            _Card(color: cardColor, border: cardBorder,
              child: Column(children: [
                _InfoRow(icon: Icons.person_outline_rounded,
                    label: 'Name', value: _firstName),
                _RowDivider(color: cardBorder),
                _InfoRow(icon: Icons.email_outlined,
                    label: 'Email', value: _email),
              ]),
            ),
            const SizedBox(height: 24),

            //  2. Goal
            _SectionHeader('Goal'),
            _Card(color: cardColor, border: cardBorder,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your primary goal',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey.shade500)),
                  const SizedBox(height: 12),
                  SegmentRow(
                    options: const ['lose_weight','maintain','gain_weight'],
                    labels:  const ['Lose','Maintain','Gain'],
                    selected: _goal,
                    onChanged: (v) {
                      setState(() => _goal = v);
                      _markChanged();
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(_goalHint(_goal),
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey.shade400)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Sleep target
            _SectionHeader('Sleep target'),
            _Card(color: cardColor, border: cardBorder,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hours of sleep you aim for per night',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey.shade500)),
                  const SizedBox(height: 12),
                  NeonField(
                    controller: _sleepCtrl,
                    label: 'Hours (e.g. 8)',
                    keyboardType: const TextInputType
                        .numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter
                          .allow(RegExp(r'[\d.]')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. Dark mode
            _SectionHeader('Appearance'),
            _Card(color: cardColor, border: cardBorder,
              child: Row(children: [
                const Icon(Icons.dark_mode_outlined,
                    color: kNeon, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Dark mode',
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ),
                Switch(
                  value: _darkMode,
                  activeColor: kNeon,
                  onChanged: (v) {
                    setState(() => _darkMode = v);
                    _markChanged();
                  },
                ),
              ]),
            ),
            const SizedBox(height: 32),

            //  Save button
            NeonButton(
              label: 'Save changes',
              loading: _saving,
              onPressed: _save,
            ),
            const SizedBox(height: 16),

            // Logout
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: Icon(Icons.logout_rounded,
                    color: Colors.red.shade400, size: 20),
                label: Text('Log out',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade400)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                      color: Colors.red.shade300, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _goalHint(String v) => switch (v) {
    'lose_weight' => 'Recommendations will focus on calorie control.',
    'gain_weight' => 'Recommendations will focus on calorie surplus.',
    _             => 'Recommendations will focus on balance.',
  };
}


//  Local widgets

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text,
        style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 0.4)),
  );
}

class _Card extends StatelessWidget {
  final Widget child;
  final Color color;
  final Color border;
  const _Card({required this.child, required this.color, required this.border});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color,
      border: Border.all(color: border, width: 1.5),
      borderRadius: BorderRadius.circular(16),
    ),
    child: child,
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Icon(icon, size: 20, color: kNeon),
      const SizedBox(width: 12),
      Text(label,
          style: GoogleFonts.inter(
              fontSize: 14, color: Colors.grey.shade500)),
      const Spacer(),
      Text(value,
          style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w600)),
    ]),
  );
}

class _RowDivider extends StatelessWidget {
  final Color color;
  const _RowDivider({required this.color});
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, color: color);
}
