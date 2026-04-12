import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home/home_screen.dart';
import 'log/log_screen.dart';
import 'settings/settings_screen.dart';
import 'analytics/analytics_screen.dart';
import 'shell_tab_notifier.dart';


const _kNeon = Color(0xFF39FF14);

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

  @override
  void initState() {
    super.initState();
    shellTabNotifier.addListener(_onTabSwitch);
  }

  @override
  void dispose() {
    shellTabNotifier.removeListener(_onTabSwitch);
    super.dispose();
  }

  void _onTabSwitch() {
    final i = shellTabNotifier.value.index;
    if (_currentIndex != i) setState(() => _currentIndex = i);
  }

  void _openSettings() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const SettingsScreen()),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Aya',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                color: _kNeon,
                fontSize: 22)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined,
                color: _kNeon),
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
        selectedItemColor:   _kNeon,
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
