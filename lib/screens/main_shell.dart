import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home/home_screen.dart';
import 'log/log_screen.dart';
import 'analytics/analytics_screen.dart';
import 'settings/settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _labels      = ['Home', 'Log', 'Analytics'];
  static const _icons       = [Icons.home_outlined,  Icons.edit_outlined,    Icons.bar_chart_outlined];
  static const _activeIcons = [Icons.home_rounded,   Icons.edit_rounded,     Icons.bar_chart_rounded];

  void _openSettings() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const SettingsScreen()),
  );

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text('Aya',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF39FF14),
                fontSize: 22)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined,
                color: Color(0xFF39FF14)),
            tooltip: 'Settings',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeScreen(),
          LogScreen(),
          AnalyticsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor:   const Color(0xFF39FF14),
        unselectedItemColor: Colors.grey.shade400,
        elevation: 8,
        selectedLabelStyle:   GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
        items: List.generate(3, (i) => BottomNavigationBarItem(
          icon:       Icon(_icons[i]),
          activeIcon: Icon(_activeIcons[i]),
          label:      _labels[i],
        )),
      ),
    );
  }
}
