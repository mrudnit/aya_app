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
                f"Over the last {nights} nights you logged, your average sleep was "
                f"{round(avg, 1)}h - that's {abs(round(diff, 1))}h less than your {target_hours}h target. "
                "Getting less sleep than your body needs can drain your energy, increase cravings, "
                "and slow down recovery after workouts."
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
                f"Your average sleep this week is {round(avg, 1)}h, and it's been gradually getting shorter. "
                "It's worth addressing this now - small sleep losses add up quickly and can affect your mood, "
                "focus, and workout performance before you even notice."
            ),
            suggested_action="Keep a consistent bedtime even on weekends.",
            priority=30,
        )

    # Sleep quality
    quality_trend = sleep.get("quality_trend", "stable")
    avg_quality   = sleep.get("avg_quality")

    if quality_trend == "declining" and avg_quality is not None and conf in ("medium", "high"):
        return _rec(
            id="sleep_quality_declining",
            category="sleep",
            rec_type="metric",
            severity="info",
            confidence=conf,
            title="Sleep quality is getting worse",
            summary=f"Your average sleep quality this week is {avg_quality}/5 and declining.",
            detail=(
                f"Even though your sleep duration may be okay, your sleep quality score has been "
                f"dropping recently (currently {avg_quality}/5). Poor quality sleep - even if long - "
                "leaves you feeling unrefreshed and can hurt your focus and recovery just as much as "
                "not getting enough hours."
            ),
            suggested_action=(
                "Try avoiding screens 30 minutes before bed and keep your room cool and dark."
            ),
            priority=28,
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
                f"Over the past {days} days you've been logging, your daily average is {round(avg_kcal)} kcal. "
                f"Your personalised target is {round(target_kcal)} kcal, so you're eating around {round(diff)} kcal "
                "more per day than planned. Over time, a consistent surplus like this can slow your progress toward your goal."
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
                f"Over the past {days} days you've been logging, your daily average is {round(avg_kcal)} kcal — "
                f"about {abs(round(diff))} kcal below your {round(target_kcal)} kcal target. "
                "Eating too little consistently can leave you low on energy and make it harder to recover from activity."
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
            summary=f"{total_min} active minutes this week - {missing} min below the 150-min guideline.",
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
                f"Your weight has changed by {round(delta, 1)} kg over the past {day_range} days, "
                f"but it's moving in the wrong direction for your '{goal_label}' goal. "
                "It might be worth taking a closer look at your calorie intake and activity levels to see where things can be adjusted."
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
            summary=f"{round(delta, 1)} kg change over {day_range} days - consistent with your goal.",
            detail=(
                f"Your weight went from {first_kg} kg to {last_kg} kg over {day_range} days. "
                "This is consistent with your goal. Keep up the current habits."
            ),
            suggested_action="Maintain your current diet and activity balance.",
            priority=15,
        )

    return None

# Protein check
def _check_protein(
        nutrition: dict,
        activity: dict,
        user_weight_kg: float | None,
) -> dict | None:
    if nutrition.get("status") != "ok":
        return None
    if user_weight_kg is None or user_weight_kg <= 0:
        return None

    avg_protein = nutrition.get("avg_protein_g", 0)
    strength_sessions = activity.get("strength_count", 0) if activity.get("status") == "ok" else 0
    conf = nutrition.get("confidence", "low")

    if strength_sessions >= 2:
        threshold = 1.2 * user_weight_kg
        threshold_label = "1.2 g/kg (recommended for strength training)"
    else:
        threshold = 0.8 * user_weight_kg
        threshold_label = "0.8 g/kg (general recommendation)"

    if avg_protein >= threshold:
        return None

    deficit = round(threshold - avg_protein, 1)

    return _rec(
        id="protein_below_target",
        category="nutrition",
        rec_type="metric",
        severity="info",
        confidence=conf,
        title="Daily protein intake may be too low",
        summary=(
            f"You averaged {round(avg_protein, 1)} g of protein per day "
            f"vs the {round(threshold, 1)} g recommended for your weight."
        ),
        detail=(
            f"Based on your body weight ({round(user_weight_kg, 1)} kg), "
            f"the recommended daily protein intake is {threshold_label} "
            f"— that's about {round(threshold, 1)} g per day. "
            f"Your average over the logged days was {round(avg_protein, 1)} g, "
            f"which is {deficit} g short. "
            "Protein is essential for muscle repair and keeping you feeling full. "
            "Low intake can slow recovery, especially after strength sessions."
        ),
        suggested_action=(
            "Add a protein source to each main meal — eggs, chicken, legumes, "
            "cottage cheese, or Greek yogurt all work well."
        ),
        priority=32,
    )

# Macro balance check
def _check_macro_balance(nutrition: dict) -> dict | None:
    if nutrition.get("status") != "ok":
        return None

    macro = nutrition.get("macro_balance")
    if macro is None:
        return None

    conf = nutrition.get("confidence", "low")

    protein_pct = macro.get("protein_pct", 0)
    carbs_pct   = macro.get("carbs_pct",   0)
    fat_pct     = macro.get("fat_pct",     0)

    # Check fat first
    if fat_pct > 40:
        return _rec(
            id="macro_fat_high",
            category="nutrition",
            rec_type="metric",
            severity="info",
            confidence=conf,
            title="Fat is a high share of your daily calories",
            summary=f"Fat accounts for {fat_pct}% of your calories — the guideline range is 20–35%.",
            detail=(
                f"Looking at your recent logs, fat makes up about {fat_pct}% of your daily calorie intake. "
                "The general dietary guideline places fat in the 20–35% range. "
                "A very high fat percentage usually means fewer calories are coming from protein and carbs, "
                "which can affect energy levels and muscle recovery."
            ),
            suggested_action="Try reducing cooking oils, fried foods, or fatty snacks at one meal per day.",
            priority=22,
        )

    if carbs_pct > 70:
        return _rec(
            id="macro_carbs_high",
            category="nutrition",
            rec_type="metric",
            severity="info",
            confidence=conf,
            title="Carbohydrates are a very high share of your calories",
            summary=f"Carbs account for {carbs_pct}% of your calories — the guideline range is 45–65%.",
            detail=(
                f"Carbohydrates make up about {carbs_pct}% of your daily calorie intake. "
                "While carbs are your body's primary fuel source, a very high proportion "
                "often means protein and fat intake is relatively low, which can impact "
                "satiety and muscle maintenance."
            ),
            suggested_action="Try adding a protein or fat source alongside your carb-heavy meals.",
            priority=20,
        )

    if protein_pct < 10:
        return _rec(
            id="macro_protein_low",
            category="nutrition",
            rec_type="metric",
            severity="info",
            confidence=conf,
            title="Protein is a low share of your daily calories",
            summary=f"Protein accounts for only {protein_pct}% of your calories — the guideline range is 20–35%.",
            detail=(
                f"Protein makes up only {protein_pct}% of your daily calorie intake. "
                "Dietary guidelines recommend protein covers at least 20% of total calories "
                "to support muscle maintenance, satiety, and metabolic health."
            ),
            suggested_action="Include a protein source in every main meal — meat, fish, eggs, or legumes.",
            priority=20,
        )

    return None

# Breakfast check
def _check_breakfast(nutrition: dict) -> dict | None:
    if nutrition.get("status") != "ok":
        return None

    days_logged      = nutrition.get("days_logged", 0)
    breakfast_days   = nutrition.get("breakfast_days", 0)
    kcal_with        = nutrition.get("avg_kcal_with_breakfast")
    kcal_without     = nutrition.get("avg_kcal_without_breakfast")
    conf             = nutrition.get("confidence", "low")

    if days_logged < 4:
        return None

    skip_days = days_logged - breakfast_days

    if skip_days < 3:
        return None

    if kcal_with is None or kcal_without is None:
        return None

    diff = kcal_without - kcal_with

    if diff <= 150:
        return None

    return _rec(
        id="breakfast_skip_overeat",
        category="nutrition",
        rec_type="metric",
        severity="info",
        confidence=conf,
        title="Skipping breakfast may lead to eating more later",
        summary=(
            f"On days without breakfast you averaged {round(kcal_without)} kcal "
            f"vs {round(kcal_with)} kcal on days with breakfast."
        ),
        detail=(
            f"You skipped breakfast on {skip_days} of the last {days_logged} logged days. "
            f"On those days your total calorie intake averaged {round(kcal_without)} kcal, "
            f"compared to {round(kcal_with)} kcal on days when you ate breakfast — "
            f"a difference of {round(diff)} kcal. "
            "Skipping breakfast often leads to higher hunger levels mid-morning, "
            "which can result in larger portions and more impulsive food choices at "
            "later meals. This pattern shows up clearly in your own data."
        ),
        suggested_action=(
            "Try a small, protein-rich breakfast (eggs, yogurt, or oats with nuts) "
            "for the next 5 days and see if your total intake feels easier to manage."
        ),
        priority=25,
        suppresses=["calories_above_target"],
    )

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
        f"Looking at {n} days where you logged both sleep and activity, "
        f"you averaged {low_avg} active minutes on days when you slept less than 6 hours, "
        f"compared to {normal_avg} minutes on days with more sleep."
    ]
    if r is not None:
        detail_parts.append(
            "This pattern is consistent enough across your data to be meaningful."
        )
    elif p is not None:
        detail_parts.append(
            "This difference is consistent enough across your data to be meaningful."
        )
    detail_parts.append(
        "Better sleep seems to directly support your ability to stay active - it's worth prioritising."
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
        f"Looking at {n} days where you logged both sleep and meals, "
        f"you averaged {low_kcal} kcal on days when you slept less than 6 hours, "
        f"compared to {normal_kcal} kcal on days with more sleep."
    ]
    if r is not None:
        detail_parts.append(
            "This pattern shows up consistently in your data - when you sleep less, you tend to eat more."
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
        f"Looking at {n} days in your logs, your sleep quality averaged "
        f"{avg_late}/5 on evenings when you ate after 20:00, "
        f"compared to {avg_normal}/5 on evenings when you didn't."
    ]
    if p is not None:
        detail_parts.append("This difference shows up consistently enough in your data to be worth paying attention to.")
    detail_parts.append(
        "Eating late can raise your body temperature and affect how quickly you fall asleep and how deeply you rest."
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
        summary=f"Your data shows a clear link between your activity level and how your weight is moving.",
        detail=(
            f"Looking at {n} days where you logged both activity and weight, "
            f"the pattern is clear: on days with more activity, your weight tends to be "
            f"{'lower' if r < 0 else 'higher'}, which lines up with your goal. "
            "Keep that consistency going — it's working."
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
        user_weight_kg: float | None = None,
) -> list[dict]:

    all_recs = []
    # Step 1: metric recommendations
    metric_checks = [
        _check_sleep(sleep, target_sleep),
        _check_nutrition(nutrition, target_kcal),
        _check_activity(activity),
        _check_weight(weight, user_goal),
        _check_protein(nutrition, activity, user_weight_kg),
        _check_macro_balance(nutrition),
        _check_breakfast(nutrition),
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
                "Your sleep, nutrition, activity and weight are all looking good this week. "
                "The more consistently you log, the better your insights will get — keep it up!"
            ),
            suggested_action="Keep up the current habits and log every day.",
            priority=10,
        ))

    # Step 6: sort by priority
    all_recs.sort(key=lambda r: r["priority"], reverse=True)
    return all_recs[:4]
