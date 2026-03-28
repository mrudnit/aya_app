import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/sleep_log.dart';
import '../../models/nutrition_log.dart';
import '../../models/activity_log.dart';
import '../../models/weight_log.dart';
import '../../services/sleep_service.dart';
import '../../services/nutrition_service.dart';
import '../../services/activity_service.dart';
import '../../services/weight_service.dart';
import '../../services/profile_service.dart';
import '../../widgets/onboarding_widgets.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/home_insight_card.dart';
import '../../widgets/home/home_today.dart';
import '../../widgets/home/home_week.dart';
import '../../widgets/home/home_quick_add.dart';
import '../shell_tab_notifier.dart';
import '../log/sleep_form.dart';
import '../log/nutrition_form.dart';
import '../log/activity_form.dart';
import '../log/weight_form.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _profileSvc   = ProfileService();
  final _sleepSvc     = SleepService();
  final _nutritionSvc = NutritionService();
  final _activitySvc  = ActivityService();
  final _weightSvc    = WeightService();

  bool                  _loading = true;
  Map<String, dynamic>? _profile;
  SleepLog?             _sleepToday;
  double                _caloriesToday    = 0;
  int                   _activityMinToday = 0;
  WeightLog?            _latestWeight;
  double                _weekAvgSleep     = 0;
  int                   _weekSessions     = 0;
  double                _weekAvgCalories  = 0;
  int                   _weekSleepDays    = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _profileSvc.getProfile(),
        _sleepSvc.getSleepLogs(limit: 14),
        _nutritionSvc.getRecentNutritionLogs(limit: 30),
        _activitySvc.getActivityLogs(limit: 14),
        _weightSvc.getWeightLogs(limit: 1),
      ]);

      final profile    = results[0] as Map<String, dynamic>?;
      final sleepLogs  = results[1] as List<SleepLog>;
      final mealLogs   = results[2] as List<MealLog>;
      final actLogs    = results[3] as List<ActivityLog>;
      final weightLogs = results[4] as List<WeightLog>;

      final now   = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final week  = today.subtract(const Duration(days: 7));

      // Sleep today
      SleepLog? sleepToday;
      for (final s in sleepLogs) {
        final d = DateTime(s.wakeTime.year, s.wakeTime.month, s.wakeTime.day);
        if (d == today) { sleepToday = s; break; }
      }

      // Calories today
      double calToday = 0;
      for (final m in mealLogs) {
        final d = DateTime(m.createdAt.year, m.createdAt.month, m.createdAt.day);
        if (d == today) calToday += m.totalKcal;
      }

      // Activity today
      int actMin = 0;
      for (final a in actLogs) {
        final d = DateTime(a.createdAt.year, a.createdAt.month, a.createdAt.day);
        if (d == today) actMin += a.durationMin ?? 0;
      }

      // Weekly sleep
      final weekSleep = sleepLogs.where((s) => s.bedtime.isAfter(week)).toList();
      final uniqueSleepDays = weekSleep
          .map((s) => DateTime(s.bedtime.year, s.bedtime.month, s.bedtime.day))
          .toSet().length;
      final weekAvgSleep = weekSleep.isEmpty ? 0.0
          : weekSleep.map((s) => s.durationHours).reduce((a, b) => a + b)
          / weekSleep.length;

      // Weekly activity
      final weekAct = actLogs.where((a) => a.createdAt.isAfter(week)).length;

      // Weekly calories
      final Map<String, double> kcalByDay = {};
      for (final m in mealLogs) {
        if (m.createdAt.isAfter(week)) {
          final d = '${m.createdAt.year}-${m.createdAt.month}-${m.createdAt.day}';
          kcalByDay[d] = (kcalByDay[d] ?? 0) + m.totalKcal;
        }
      }
      final weekAvgCal = kcalByDay.isEmpty ? 0.0
          : kcalByDay.values.reduce((a, b) => a + b) / kcalByDay.length;

      if (mounted) {
        setState(() {
          _profile           = profile;
          _sleepToday        = sleepToday;
          _caloriesToday     = calToday;
          _activityMinToday  = actMin;
          _latestWeight      = weightLogs.isNotEmpty ? weightLogs.first : null;
          _weekAvgSleep      = weekAvgSleep;
          _weekSessions      = weekAct;
          _weekAvgCalories   = weekAvgCal;
          _weekSleepDays     = uniqueSleepDays;
          _loading           = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Insight logic
  ({String emoji, String title, String body}) _insight() {
    if (_sleepToday == null) {
      return (
      emoji: '🌙',
      title: 'Log your sleep',
      body:  'You haven\'t logged last night\'s sleep yet. '
          'Tap "Sleep" below.',
      );
    }
    if (_caloriesToday == 0) {
      return (
      emoji: '🍽️',
      title: 'Log your first meal today',
      body:  'Start tracking what you eat to stay on top of your nutrition.',
      );
    }
    if (_activityMinToday == 0) {
      return (
      emoji: '🏃',
      title: 'No activity logged today',
      body:  'Even a short walk counts. Tap "Activity" to log it.',
      );
    }
    final daysSinceWeight = _latestWeight == null
        ? 999
        : DateTime.now().difference(_latestWeight!.createdAt).inDays;
    if (daysSinceWeight > 6) {
      return (
      emoji: '⚖️',
      title: 'Time to log your weight',
      body:  'You haven\'t logged your weight in $daysSinceWeight days. '
          'Weekly measurements give the best trend data.',
      );
    }
    final sleepH = _sleepToday!.durationHours.toStringAsFixed(1);
    return (
    emoji: '✅',
    title: 'All logged for today!',
    body:  'Sleep: ${sleepH}h  ·  '
        '${_caloriesToday.round()} kcal  ·  '
        '${_activityMinToday} min active. Keep it up!',
    );
  }

  // Bottom openers
  void _openSleepForm() => showModalBottomSheet(
    context: context, isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => SleepForm(
      onSaved: (log) async {
        await _sleepSvc.addSleepLog(log);
        if (mounted) _load();
      },
    ),
  );

  void _openNutritionForm() => showModalBottomSheet(
    context: context, isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => NutritionForm(
      onSaved: (log) async {
        await _nutritionSvc.addNutritionLog(log);
        if (mounted) _load();
      },
    ),
  );

  void _openActivityForm() => showModalBottomSheet(
    context: context, isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ActivityForm(
      onSaved: (log) async {
        await _activitySvc.addActivityLog(log);
        if (mounted) _load();
      },
    ),
  );

  void _openWeightForm() => showModalBottomSheet(
    context: context, isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => WeightForm(
      onSaved: (log) async {
        await _weightSvc.addWeightLog(log);
        if (mounted) _load();
      },
    ),
  );

  // Build
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: kNeon));
    }

    final firstName  = _profile?['firstName'] ?? '';
    final targetSleep= (_profile?['target_sleep_hours'] as num?)
        ?.toDouble() ?? 8.0;
    final goal       = _profile?['goal'] as String? ?? 'maintain';
    final targetKcal = goal == 'lose_weight' ? 1800.0
        : goal == 'gain_weight' ? 2800.0 : 2200.0;
    final insight    = _insight();

    return RefreshIndicator(
      color: kNeon,
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            HomeHeader(firstName: firstName),
            const SizedBox(height: 20),

            HomeInsightCard(
              emoji: insight.emoji,
              title: insight.title,
              body:  insight.body,
            ),
            const SizedBox(height: 24),

            Text('Today', style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            HomeTodaySection(
              sleepToday:    _sleepToday,
              caloriesToday: _caloriesToday,
              calorieTarget: targetKcal,
              activityMin:   _activityMinToday,
              sleepTarget:   targetSleep,
            ),
            const SizedBox(height: 24),

            Text('This week', style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            HomeWeekSection(
              avgSleep:    _weekAvgSleep,
              sleepDays:   _weekSleepDays,
              sessions:    _weekSessions,
              avgCalories: _weekAvgCalories,
              onTap: () =>
              shellTabNotifier.value = ShellTab.analytics,
            ),
            const SizedBox(height: 24),

            Text('Quick add', style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            HomeQuickAddSection(
              onAddSleep:     _openSleepForm,
              onAddMeal:      _openNutritionForm,
              onAddActivity:  _openActivityForm,
              onAddWeight:    _openWeightForm,
            ),
          ],
        ),
      ),
    );
  }
}
