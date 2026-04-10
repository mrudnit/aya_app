from datetime import datetime, date
from fastapi import APIRouter

import pandas as pd

from app.services.firestore_reader import (
    read_profile,
    read_sleep_logs,
    read_nutrition_logs,
    read_activity_logs,
    read_weight_logs,
)
from app.services.preprocessor import (
    make_sleep_df,
    make_nutrition_df,
    make_activity_df,
    make_weight_df,
    build_daily_df,
    calculate_calorie_target,
)
from app.services.analytics_service import (
    analyse_sleep,
    analyse_nutrition,
    analyse_activity,
    analyse_weight,
)
from app.services.relationship_service import (
    analyse_sleep_vs_activity,
    analyse_sleep_vs_calories,
    analyse_activity_vs_weight,
    analyse_late_meal_vs_sleep_quality,
)
from app.services.recommendation_engine import generate_recommendations

router = APIRouter()

# Today helpers
def _today_sleep(sleep_df: pd.DataFrame) -> dict:
    today = date.today()

    if sleep_df.empty:
        return {"status": "not_logged"}

    # Find entries
    mask = sleep_df["date_only"] == today
    if not mask.any():
        return {"status": "not_logged"}

    # Take the most recent entry for today
    row = sleep_df[mask].iloc[-1]

    return {
        "status":         "ok",
        "duration_hours": round(float(row["duration_hours"]), 2),
        "quality_score":  int(row["quality_score"]) if pd.notna(row.get("quality_score")) else None,
    }

def _today_nutrition(nutrition_df: pd.DataFrame, target_kcal: float | None) -> dict:
    today = date.today()

    if nutrition_df.empty:
        return {
            "status":       "not_logged",
            "total_kcal":   0,
            "target_kcal":  target_kcal,
            "progress":     0.0,
            "meals_logged": 0,
            "has_late_meal": False,
        }

    today_meals = nutrition_df[nutrition_df["date_only"] == today]

    if today_meals.empty:
        return {
            "status":       "not_logged",
            "total_kcal":   0,
            "target_kcal":  target_kcal,
            "progress":     0.0,
            "meals_logged": 0,
            "has_late_meal": False,
        }

    total_kcal   = float(today_meals["total_kcal"].sum())
    meals_logged = len(today_meals)
    has_late_meal = bool(today_meals["is_late_meal"].any())

    progress = 0.0
    if target_kcal and target_kcal > 0:
        progress = round(min(total_kcal / target_kcal, 1.0), 3)

    return {
        "status":       "ok",
        "total_kcal":   round(total_kcal, 1),
        "target_kcal":  target_kcal,
        "progress":     progress,
        "meals_logged": meals_logged,
        "has_late_meal": has_late_meal,
    }

def _today_activity(activity_df: pd.DataFrame) -> dict:
    today = date.today()

    if activity_df.empty:
        return {"status": "not_logged", "sessions": 0, "total_min": 0}

    today_act = activity_df[activity_df["date_only"] == today]

    if today_act.empty:
        return {"status": "not_logged", "sessions": 0, "total_min": 0}

    sessions  = len(today_act)
    total_min = int(today_act["duration_min"].sum(skipna=True))

    if total_min >= 30:
        signal = "good"
    elif total_min > 0:
        signal = "ok"
    else:
        signal = "none"

    return {
        "status":    "ok",
        "sessions":  sessions,
        "total_min": total_min,
        "signal":    signal,
    }

# Week helper
def _week_preview(
        sleep_result:     dict,
        nutrition_result: dict,
        activity_result:  dict,
        weight_df:        pd.DataFrame,
) -> dict:

    # Sleep preview
    avg_sleep    = None
    sleep_nights = 0
    if sleep_result.get("status") == "ok":
        avg_sleep    = sleep_result.get("avg_hours")
        sleep_nights = sleep_result.get("nights_logged", 0)

    # Nutrition preview
    avg_kcal       = None
    calorie_days   = 0
    if nutrition_result.get("status") == "ok":
        avg_kcal     = nutrition_result.get("avg_kcal")
        calorie_days = nutrition_result.get("days_logged", 0)

    # Activity preview
    activity_sessions = 0
    activity_min      = 0
    if activity_result.get("status") == "ok":
        activity_sessions = activity_result.get("sessions", 0)
        activity_min      = activity_result.get("total_min", 0)

    # Weight preview
    latest_weight_kg = None
    weight_delta_kg  = None
    if not weight_df.empty:
        df_sorted = weight_df.sort_values("created_at")
        latest_weight_kg = round(float(df_sorted["weight_kg"].iloc[-1]), 2)
        if len(df_sorted) >= 2:
            first = float(df_sorted["weight_kg"].iloc[0])
            last  = float(df_sorted["weight_kg"].iloc[-1])
            weight_delta_kg = round(last - first, 2)

    return {
        "avg_sleep_hours":    avg_sleep,
        "sleep_nights_logged": sleep_nights,
        "avg_kcal":           avg_kcal,
        "calorie_days_logged": calorie_days,
        "activity_sessions":  activity_sessions,
        "activity_min_total": activity_min,
        "latest_weight_kg":   latest_weight_kg,
        "weight_delta_kg":    weight_delta_kg,
    }

# Endpoint
@router.get("/home/{uid}")
async def home(uid: str):
    # Load raw data
    profile       = await read_profile(uid)
    raw_sleep     = await read_sleep_logs(uid, limit=30)
    raw_nutrition = await read_nutrition_logs(uid, limit=30)
    raw_activity  = await read_activity_logs(uid, limit=30)
    raw_weight    = await read_weight_logs(uid, limit=30)

    # Build DataFrames
    sleep_df     = make_sleep_df(raw_sleep)
    nutrition_df = make_nutrition_df(raw_nutrition)
    activity_df  = make_activity_df(raw_activity)
    weight_df    = make_weight_df(raw_weight)
    daily_df     = build_daily_df(sleep_df, nutrition_df, activity_df, weight_df)

    # Profile + calorie target
    cal_target   = calculate_calorie_target(profile)
    target_kcal  = cal_target.get("target_kcal")
    target_sleep = float(profile.get("target_sleep_hours") or 8.0)
    user_goal    = profile.get("goal") or "maintain"
    user_weight_kg = profile.get("weight_kg")
    if user_weight_kg is not None:
        user_weight_kg = float(user_weight_kg)

    # Analytics (recommendations)
    sleep_result     = analyse_sleep(sleep_df, target_sleep)
    nutrition_result = analyse_nutrition(nutrition_df, target_kcal)
    activity_result  = analyse_activity(activity_df)
    weight_result    = analyse_weight(weight_df, user_goal)

    # Relationship analyses
    sleep_vs_activity  = analyse_sleep_vs_activity(daily_df)
    sleep_vs_calories  = analyse_sleep_vs_calories(daily_df)
    activity_vs_weight = analyse_activity_vs_weight(daily_df)
    late_meal_quality  = analyse_late_meal_vs_sleep_quality(daily_df)

    correlations = {
        "sleep_vs_activity":  sleep_vs_activity,
        "sleep_vs_calories":  sleep_vs_calories,
        "activity_vs_weight": activity_vs_weight,
    }

    # Recommendations - take only the top 1
    all_recommendations = generate_recommendations(
        sleep=sleep_result,
        nutrition=nutrition_result,
        activity=activity_result,
        weight=weight_result,
        target_sleep=target_sleep,
        target_kcal=target_kcal,
        user_goal=user_goal,
        correlations=correlations,
        late_meal_analysis=late_meal_quality,
        user_weight_kg=user_weight_kg,
    )
    # Home screen shows exactly one
    main_recommendation = all_recommendations[0] if all_recommendations else None

    # Today's data
    today_sleep    = _today_sleep(sleep_df)
    today_nutrition = _today_nutrition(nutrition_df, target_kcal)
    today_activity = _today_activity(activity_df)

    # Week preview
    week = _week_preview(
        sleep_result=sleep_result,
        nutrition_result=nutrition_result,
        activity_result=activity_result,
        weight_df=weight_df,
    )

    # Assemble response
    return {
        "generated_at": datetime.utcnow().isoformat() + "Z",
        "uid":          uid,

        "profile_summary": {
            "first_name":         profile.get("first_name", ""),
            "goal":               user_goal,
            "target_kcal":        target_kcal,
            "target_sleep_hours": target_sleep,
        },

        "today": {
            "date":      str(date.today()),
            "sleep":     today_sleep,
            "nutrition": today_nutrition,
            "activity":  today_activity,
        },

        "week_preview":       week,

        "main_recommendation": main_recommendation,
    }
