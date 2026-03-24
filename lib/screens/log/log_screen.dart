import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'nutrition_log_screen.dart';
import 'activity_log_screen.dart';
import 'sleep_log_screen.dart';
import 'weight_log_screen.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabs,
            labelColor: const Color(0xFF39FF14),
            unselectedLabelColor: Colors.grey.shade400,
            indicatorColor: const Color(0xFF39FF14),
            indicatorWeight: 2.5,
            labelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w700, fontSize: 13),
            unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
            tabs: const [
              Tab(text: 'Nutrition'),
              Tab(text: 'Activity'),
              Tab(text: 'Sleep'),
              Tab(text: 'Weight'),
            ],
          ),
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: const [
              NutritionLogScreen(),
              ActivityLogScreen(),
              SleepLogScreen(),
              WeightLogScreen(),
            ],
          ),
        ),
      ],
    );
  }
}
