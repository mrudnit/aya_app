// recommendation_service.dart
//
// Generates simple text recommendations based on the user's
// recent logs and their onboarding profile.
//
// This is deliberately simple — no ML, no backend, no complex
// algorithms. Just plain Dart if/else rules that read the data
// and produce readable advice. Perfect for an MVP thesis project.
//
// Later (Phase 5) this logic moves to a FastAPI backend where
// you can run real statistical analysis with Python/Pandas.

import '../models/nutrition_log.dart';
import '../models/activity_log.dart';
import '../models/sleep_log.dart';

// A single recommendation card shown on the Home screen
class Recommendation {
  final String title;
  final String body;
  final String emoji;

  const Recommendation({
    required this.title,
    required this.body,
    required this.emoji,
  });
}

class RecommendationService {

  // Main entry point.
  // Pass in the user's profile and recent logs — returns a list
  // of recommendations to display on the Home screen.
  List<Recommendation> generate({
    required Map<String, dynamic> profile,
    required List<NutritionLog> recentNutrition,  // last 7 days
    required List<ActivityLog> recentActivity,     // last 7 entries
    required List<SleepLog> recentSleep,           // last 7 nights
  }) {
    final results = <Recommendation>[];

    results.addAll(_sleepRecommendations(profile, recentSleep));
    results.addAll(_nutritionRecommendations(profile, recentNutrition));
    results.addAll(_activityRecommendations(profile, recentActivity));
    results.addAll(_loggingReminders(recentNutrition, recentActivity, recentSleep));

    // If we have nothing to say, show a friendly default
    if (results.isEmpty) {
      results.add(const Recommendation(
        emoji: '✅',
        title: 'You\'re on track!',
        body: 'Keep logging your meals, activity, and sleep to get personalised insights.',
      ));
    }

    return results;
  }


  // ── Sleep rules ────────────────────────────────────────────

  List<Recommendation> _sleepRecommendations(
      Map<String, dynamic> profile,
      List<SleepLog> logs,
      ) {
    if (logs.isEmpty) return [];

    final target = (profile['target_sleep_hours'] as num?)?.toDouble() ?? 8.0;
    final avg    = logs.map((l) => l.durationH).reduce((a, b) => a + b) / logs.length;
    final avgRounded = double.parse(avg.toStringAsFixed(1));

    // More than 1 hour below target
    if (avg < target - 1) {
      return [Recommendation(
        emoji: '😴',
        title: 'You\'re sleeping less than your target',
        body:  'Your average is ${avgRounded}h but your target is ${target}h. '
            'Try going to bed 30 minutes earlier this week.',
      )];
    }

    // Consistently sleeping well
    if (avg >= target - 0.25) {
      return [Recommendation(
        emoji: '🌙',
        title: 'Great sleep this week!',
        body:  'Your average of ${avgRounded}h matches your ${target}h target. Keep it up.',
      )];
    }

    return [];
  }


  // ── Nutrition rules ────────────────────────────────────────

  List<Recommendation> _nutritionRecommendations(
      Map<String, dynamic> profile,
      List<NutritionLog> logs,
      ) {
    if (logs.isEmpty) return [];

    final goal = profile['goal'] as String? ?? 'maintain';

    // Average daily calories over the logged days
    // Group by day first, then average
    final Map<String, double> byDay = {};
    for (final log in logs) {
      final day = log.timestamp.toIso8601String().substring(0, 10);
      byDay[day] = (byDay[day] ?? 0) + log.caloriesKcal;
    }
    final avgCalories = byDay.values.reduce((a, b) => a + b) / byDay.length;

    // Average daily protein
    final Map<String, double> proteinByDay = {};
    for (final log in logs) {
      final day = log.timestamp.toIso8601String().substring(0, 10);
      proteinByDay[day] = (proteinByDay[day] ?? 0) + log.proteinG;
    }
    final avgProtein = proteinByDay.values.reduce((a, b) => a + b) / proteinByDay.length;
    final weightKg   = (profile['weight_kg'] as num?)?.toDouble() ?? 70.0;

    final results = <Recommendation>[];

    // Calorie check based on goal
    if (goal == 'lose_weight' && avgCalories > 2200) {
      results.add(Recommendation(
        emoji: '🥗',
        title: 'Calorie intake above your goal',
        body: 'You\'re averaging ${avgCalories.round()} kcal/day. '
            'For weight loss, aim for 300–500 kcal below your maintenance.',
      ));
    } else if (goal == 'gain_weight' && avgCalories < 2200) {
      results.add(Recommendation(
        emoji: '🍽️',
        title: 'Eat a bit more to support your goal',
        body: 'You\'re averaging ${avgCalories.round()} kcal/day. '
            'For muscle gain, try adding a small extra meal or snack.',
      ));
    }

    // Protein check — simple rule: 1.6 g per kg body weight
    final proteinTarget = weightKg * 1.6;
    if (avgProtein < proteinTarget * 0.8) {
      results.add(Recommendation(
        emoji: '🥩',
        title: 'Protein intake is low',
        body: 'Your average is ${avgProtein.round()} g/day. '
            'Aim for at least ${proteinTarget.round()} g to support your goal.',
      ));
    }

    return results;
  }


  // ── Activity rules ─────────────────────────────────────────

  List<Recommendation> _activityRecommendations(
      Map<String, dynamic> profile,
      List<ActivityLog> logs,
      ) {
    if (logs.isEmpty) return [];

    final activityLevel = profile['activity_level'] as String? ?? 'medium';

    // Total active minutes logged in the last 7 entries
    final totalMin = logs.map((l) => l.durationMin).reduce((a, b) => a + b);

    // WHO recommends 150 min / week of moderate activity
    if (totalMin < 90 && activityLevel != 'low') {
      return [Recommendation(
        emoji: '🏃',
        title: 'Stay active this week',
        body: 'You\'ve logged ${totalMin} minutes of activity recently. '
            'Try to reach at least 150 minutes per week.',
      )];
    }

    if (totalMin >= 150) {
      return [Recommendation(
        emoji: '💪',
        title: 'Active week!',
        body: 'You\'ve logged ${totalMin} minutes of activity. Great consistency!',
      )];
    }

    return [];
  }


  // ── Logging reminder rules ─────────────────────────────────
  // If the user hasn't logged anything in the last 2 days,
  // remind them to keep logging so insights stay accurate.

  List<Recommendation> _loggingReminders(
      List<NutritionLog> nutrition,
      List<ActivityLog> activity,
      List<SleepLog> sleep,
      ) {
    final results = <Recommendation>[];
    final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));

    final hasRecentNutrition = nutrition.any((l) => l.timestamp.isAfter(twoDaysAgo));
    final hasRecentSleep     = sleep.any((l) => l.bedtime.isAfter(twoDaysAgo));

    if (!hasRecentNutrition) {
      results.add(const Recommendation(
        emoji: '📝',
        title: 'Log your meals',
        body: 'You haven\'t logged any meals recently. '
            'Consistent tracking gives you much better insights.',
      ));
    }

    if (!hasRecentSleep) {
      results.add(const Recommendation(
        emoji: '🌙',
        title: 'Log your sleep',
        body: 'Sleep data helps us give you better recommendations. '
            'Try to log each morning.',
      ));
    }

    return results;
  }
}
