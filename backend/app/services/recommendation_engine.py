def _rec(
        id: str,
        category: str,
        rec_type: str,
        severity: str,
        confidence: str,
        title: str,
        summary: str,
        detail: str,
        suggested_action: str,
        priority: int,
        data_level: str = "weekly_trend",
        suppresses: list = None,
) -> dict:
    return {
        "id":               id,
        "category":         category,
        "type":             rec_type,
        "severity":         severity,
        "confidence":       confidence,
        "title":            title,
        "summary":          summary,
        "detail":           detail,
        "suggested_action": suggested_action,
        "priority":         priority,
        "data_level":       data_level,
        "suppresses":       suppresses or [],
    }

# Individual check functions
def _check_sleep(sleep: dict, target_hours: float) -> dict | None:
    if sleep.get("status") != "ok":
        return None

    avg    = sleep.get("avg_hours", 0)
    diff   = avg - target_hours   # negative = below target
    trend  = sleep.get("trend", "stable")
    conf   = sleep.get("confidence", "low")
    nights = sleep.get("nights_logged", 0)

    # More than 1 hour below target
    if diff < -1.0:
        return _rec(
            id="sleep_below_target",
            category="sleep",
            rec_type="metric",
            severity="warning",
            confidence=conf,
            title="Sleep is below your target",
            summary=f"Your average is {round(avg, 1)}h but your target is {target_hours}h.",
            detail=(
                f"Over the last {nights} logged nights your average sleep is "
                f"{round(avg, 1)}h — {abs(round(diff, 1))}h below your {target_hours}h target. "
                f"Sleep trend is {trend}. "
                "Consistent sleep deficit is linked to reduced energy, "
                "higher appetite and slower recovery."
            ),
            suggested_action="Try going to bed 30 minutes earlier for the next 5 nights.",
            priority=45,
        )

    # Sleep is declining
    if trend == "declining" and conf in ("medium", "high"):
        return _rec(
            id="sleep_declining",
            category="sleep",
            rec_type="metric",
            severity="info",
            confidence=conf,
            title="Sleep duration is declining",
            summary=f"Your sleep has been getting shorter recently ({round(avg, 1)}h average).",
            detail=(
                f"Your average sleep this week is {round(avg, 1)}h. "
                "The trend across your logged data is declining. "
                "Catching this early is better than waiting until it affects performance."
            ),
            suggested_action="Keep a consistent bedtime even on weekends.",
            priority=30,
        )

    return None

def _check_nutrition(nutrition: dict, target_kcal: float | None) -> dict | None:
    if nutrition.get("status") != "ok":
        return None
    if target_kcal is None:
        return None

    avg_kcal = nutrition.get("avg_kcal", 0)
    diff     = avg_kcal - target_kcal
    conf     = nutrition.get("confidence", "low")
    days     = nutrition.get("days_logged", 0)

    # More than 200 kcal above target
    if diff > 200:
        return _rec(
            id="calories_above_target",
            category="nutrition",
            rec_type="metric",
            severity="warning" if diff > 400 else "info",
            confidence=conf,
            title="Calories above your personalised target",
            summary=f"Your average is {round(avg_kcal)} kcal vs your target of {round(target_kcal)} kcal.",
            detail=(
                f"Based on {days} logged days, your average is {round(avg_kcal)} kcal/day. "
                f"Your personalised target (Mifflin-St Jeor formula) is {round(target_kcal)} kcal. "
                f"You are averaging {round(diff)} kcal above that. "
                "A consistent surplus above your goal will slow weight loss progress."
            ),
            suggested_action="Try replacing one high-calorie snack with fruit or vegetables.",
            priority=35,
        )

    # More than 200 kcal below target
    if diff < -200:
        return _rec(
            id="calories_below_target",
            category="nutrition",
            rec_type="metric",
            severity="info",
            confidence=conf,
            title="Calories below your personalised target",
            summary=f"Your average is {round(avg_kcal)} kcal vs your target of {round(target_kcal)} kcal.",
            detail=(
                f"Based on {days} logged days, your average is {round(avg_kcal)} kcal/day — "
                f"{abs(round(diff))} kcal below your {round(target_kcal)} kcal target. "
                "Being consistently below target can reduce energy and recovery."
            ),
            suggested_action="Add a small protein-rich meal or snack between main meals.",
            priority=30,
        )

    return None

def _check_activity(activity: dict) -> dict | None:
    if activity.get("status") != "ok":
        return None

    total_min = activity.get("total_min", 0)
    sessions  = activity.get("sessions", 0)
    conf      = activity.get("confidence", "low")

    if total_min < 150:
        missing = 150 - total_min
        return _rec(
            id="activity_below_who",
            category="activity",
            rec_type="metric",
            severity="warning" if total_min < 90 else "info",
            confidence=conf,
            title="Weekly activity below WHO guideline",
            summary=f"{total_min} active minutes this week — {missing} min below the 150-min guideline.",
            detail=(
                f"You logged {sessions} session(s) totalling {total_min} minutes this week. "
                f"The WHO recommends at least 150 minutes of moderate-intensity activity per week. "
                f"You need {missing} more minutes to reach that target."
            ),
            suggested_action=f"Add one more {missing}-minute session this week.",
            priority=30,
        )

    return None

def _check_weight(weight: dict, user_goal: str) -> dict | None:
    if weight.get("status") != "ok":
        return None

    conf      = weight.get("confidence", "low")
    aligned   = weight.get("goal_aligned", True)
    trend     = weight.get("trend", "stable")
    delta     = weight.get("delta_kg", 0)
    first_kg  = weight.get("first_kg")
    last_kg   = weight.get("last_kg")
    day_range = weight.get("day_range", 0)

    if conf == "low":
        return None

    if not aligned:
        direction = "increasing" if delta > 0 else "decreasing"
        goal_label = user_goal.replace("_", " ")
        return _rec(
            id="weight_misaligned",
            category="weight",
            rec_type="metric",
            severity="warning",
            confidence=conf,
            title="Weight trend does not match your goal",
            summary=(
                f"Weight is {direction} ({first_kg} → {last_kg} kg over {day_range} days) "
                f"but your goal is {goal_label}."
            ),
            detail=(
                f"Your weight changed by {round(delta, 1)} kg over {day_range} days. "
                f"The trend ({direction}) is opposite to your '{goal_label}' goal. "
                "Check whether your calorie intake and activity levels are aligned with your goal."
            ),
            suggested_action="Review your weekly calorie average and compare it to your target.",
            priority=50,
        )

    # Positive: weight is going in the right direction
    if aligned and abs(delta) > 0.2 and conf in ("medium", "high"):
        direction = "decreasing" if delta < 0 else "increasing"
        return _rec(
            id="weight_on_track",
            category="weight",
            rec_type="metric",
            severity="good",
            confidence=conf,
            title="Weight is moving in the right direction",
            summary=f"{round(delta, 1)} kg change over {day_range} days — consistent with your goal.",
            detail=(
                f"Your weight went from {first_kg} kg to {last_kg} kg over {day_range} days. "
                "This is consistent with your goal. Keep up the current habits."
            ),
            suggested_action="Maintain your current diet and activity balance.",
            priority=15,
        )

    return None

# Relationship recommendation checks
def _check_sleep_vs_activity(sva: dict) -> dict | None:
    if sva.get("status") != "ok":
        return None

    corr   = sva.get("correlation") or {}
    ttest  = sva.get("t_test") or {}
    conf   = sva.get("confidence", "low")

    corr_sig  = corr.get("significant", False)
    ttest_sig = ttest.get("significant", False)

    if not corr_sig and not ttest_sig:
        return None

    low_avg    = sva.get("low_sleep_avg_activity_min")
    normal_avg = sva.get("normal_sleep_avg_activity_min")
    n          = corr.get("n") or sva.get("paired_days", 0)
    p          = corr.get("p_value") or ttest.get("p_value")
    r          = corr.get("r")

    # Build detail
    detail_parts = [
        f"Analysis of {n} paired days shows that on low-sleep days (<6h) "
        f"your average activity is {low_avg} min vs {normal_avg} min on normal-sleep days."
    ]
    if r is not None:
        detail_parts.append(f"Pearson r = {r}, p = {p}.")
    elif p is not None:
        detail_parts.append(f"T-test p = {p} (statistically significant).")
    detail_parts.append(
        "This suggests that improving sleep may directly support workout consistency."
    )

    return _rec(
        id="relationship_sleep_vs_activity",
        category="relationship",
        rec_type="relationship",
        severity="warning",
        confidence=conf,
        title="Your sleep is affecting your workouts",
        summary=(
            f"On low-sleep days you average {low_avg} min of activity "
            f"vs {normal_avg} min on normal-sleep days."
        ),
        detail=" ".join(detail_parts),
        suggested_action=(
            "Prioritise getting at least 6 hours of sleep before planned workout days."
        ),
        priority=90,
        data_level="relationship_analysis",
        suppresses=["sleep_below_target", "sleep_declining", "activity_below_who"],
    )

def _check_sleep_vs_calories(svc: dict) -> dict | None:
    if svc.get("status") != "ok":
        return None

    corr  = svc.get("correlation") or {}
    ttest = svc.get("t_test") or {}
    conf  = svc.get("confidence", "low")

    if not corr.get("significant", False) and not ttest.get("significant", False):
        return None

    low_kcal    = svc.get("low_sleep_avg_kcal")
    normal_kcal = svc.get("normal_sleep_avg_kcal")
    n           = corr.get("n") or svc.get("paired_days", 0)
    p           = corr.get("p_value") or ttest.get("p_value")
    r           = corr.get("r")

    detail_parts = [
        f"On {n} paired days, you averaged {low_kcal} kcal on low-sleep days "
        f"vs {normal_kcal} kcal on normal-sleep days."
    ]
    if r is not None:
        detail_parts.append(
            f"Pearson correlation r = {r} (p = {p}) — "
            "less sleep is associated with higher food intake."
        )

    return _rec(
        id="relationship_sleep_vs_calories",
        category="relationship",
        rec_type="relationship",
        severity="info",
        confidence=conf,
        title="Poor sleep is linked to higher calorie intake",
        summary=(
            f"You eat {low_kcal} kcal on low-sleep days vs "
            f"{normal_kcal} kcal on normal-sleep days."
        ),
        detail=" ".join(detail_parts),
        suggested_action=(
            "Improving sleep quality may reduce unnecessary snacking. "
            "Keep healthy snacks available for days after poor sleep."
        ),
        priority=85,
        data_level="relationship_analysis",
        suppresses=["calories_above_target"],
    )


def _check_late_meal(lma: dict) -> dict | None:
    if lma.get("status") != "ok":
        return None

    corr  = lma.get("correlation") or {}
    ttest = lma.get("t_test") or {}
    conf  = lma.get("confidence", "low")

    if not corr.get("significant", False) and not ttest.get("significant", False):
        return None

    avg_late   = lma.get("avg_quality_late_meal")
    avg_normal = lma.get("avg_quality_no_late_meal")
    n          = lma.get("paired_days", 0)
    p          = corr.get("p_value") or (ttest.get("p_value") if ttest else None)

    detail_parts = [
        f"Across {n} days, your sleep quality averages "
        f"{avg_late}/5 on evenings with a late meal (after 20:00) "
        f"vs {avg_normal}/5 on evenings without."
    ]
    if p is not None:
        detail_parts.append(f"This difference is statistically significant (p = {p}).")
    detail_parts.append(
        "Late eating raises core body temperature and insulin levels, "
        "which can disrupt sleep onset and quality."
    )

    return _rec(
        id="relationship_late_meal_sleep_quality",
        category="relationship",
        rec_type="relationship",
        severity="warning",
        confidence=conf,
        title="Late meals are reducing your sleep quality",
        summary=(
            f"Sleep quality: {avg_late}/5 on late-meal evenings "
            f"vs {avg_normal}/5 on normal evenings."
        ),
        detail=" ".join(detail_parts),
        suggested_action=(
            "Try finishing your last meal before 20:00 for the next 7 days "
            "and track whether your sleep quality improves."
        ),
        priority=92,
        data_level="relationship_analysis",
        suppresses=["sleep_below_target", "sleep_declining"],
    )


def _check_activity_vs_weight(avw: dict) -> dict | None:
    if avw.get("status") != "ok":
        return None

    corr = avw.get("correlation") or {}
    conf = avw.get("confidence", "low")

    if not corr.get("significant", False):
        return None

    r = corr.get("r")
    p = corr.get("p_value")
    n = corr.get("n") or avw.get("paired_days", 0)

    return _rec(
        id="relationship_activity_vs_weight",
        category="relationship",
        rec_type="relationship",
        severity="info",
        confidence=conf,
        title="Activity level is linked to your weight trend",
        summary=f"Spearman correlation between activity and weight: r = {r} (p = {p}, n = {n}).",
        detail=(
            f"Analysis of {n} days where both activity and weight were logged "
            f"shows a {'negative' if r < 0 else 'positive'} correlation (ρ = {r}, p = {p}). "
            "This suggests that on days with more activity your weight tends to be "
            f"{'lower' if r < 0 else 'higher'}, consistent with your fitness goal."
        ),
        suggested_action="Maintain consistent activity frequency to support your weight goal.",
        priority=80,
        data_level="relationship_analysis",
        suppresses=["weight_misaligned"],
    )


# Deduplication and suppression

def _apply_suppression(recs: list[dict]) -> list[dict]:
    # Collect all ids
    suppressed_ids = set()
    for r in recs:
        for s in r.get("suppresses", []):
            suppressed_ids.add(s)

    return [r for r in recs if r["id"] not in suppressed_ids]


def _deduplicate_by_category(recs: list[dict]) -> list[dict]:
    seen_categories = {}
    final = []

    for r in recs:
        cat = r["category"]
        if cat == "relationship":
            # Relationship recs always go through
            final.append(r)
            continue
        if cat not in seen_categories:
            seen_categories[cat] = r
        else:
            if r["priority"] > seen_categories[cat]["priority"]:
                seen_categories[cat] = r

    final.extend(seen_categories.values())
    return final

# Main entry point

def generate_recommendations(
        sleep: dict,
        nutrition: dict,
        activity: dict,
        weight: dict,
        target_sleep: float,
        target_kcal: float | None,
        user_goal: str,
        correlations: dict,
        late_meal_analysis: dict,
) -> list[dict]:

    all_recs = []
    # Step 1: metric recommendations
    metric_checks = [
        _check_sleep(sleep, target_sleep),
        _check_nutrition(nutrition, target_kcal),
        _check_activity(activity),
        _check_weight(weight, user_goal),
    ]
    all_recs += [r for r in metric_checks if r is not None]

    # Step 2: relationship recommendations
    sva = correlations.get("sleep_vs_activity", {})  if correlations else {}
    svc = correlations.get("sleep_vs_calories", {})  if correlations else {}
    avw = correlations.get("activity_vs_weight", {}) if correlations else {}
    lma = late_meal_analysis or {}

    relationship_checks = [
        _check_sleep_vs_activity(sva),
        _check_sleep_vs_calories(svc),
        _check_activity_vs_weight(avw),
        _check_late_meal(lma),
    ]
    all_recs += [r for r in relationship_checks if r is not None]

    # Step 3: apply suppression
    all_recs = _apply_suppression(all_recs)

    # Step 4: deduplicate by category
    all_recs = _deduplicate_by_category(all_recs)

    # Step 5: if nothing bad found - positive card
    if not all_recs:
        all_recs.append(_rec(
            id="all_on_track",
            category="general",
            rec_type="metric",
            severity="good",
            confidence="high",
            title="Everything looks good!",
            summary="All your tracked metrics are aligned with your goals.",
            detail=(
                "Your sleep, nutrition, activity and weight are all within expected ranges. "
                "Keep logging consistently to maintain data quality and unlock relationship insights."
            ),
            suggested_action="Keep up the current habits and log every day.",
            priority=10,
        ))

    # Step 6: sort by priority
    all_recs.sort(key=lambda r: r["priority"], reverse=True)
    return all_recs[:4]
