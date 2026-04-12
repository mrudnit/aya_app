import pandas as pd
import numpy as np
from datetime import datetime, timedelta

from app.core.sufficiency import (
    Confidence,
    sleep_confidence,
    calorie_confidence,
    activity_confidence,
    weight_confidence,
    insufficient,
)

# Helper: filter to last
def _last_n_days(df: pd.DataFrame, n: int = 7) -> pd.DataFrame:
    if df.empty:
        return df
    cutoff = (datetime.now() - timedelta(days=n)).date()
    return df[df["date_only"] >= cutoff].copy()


def _unique_days(df: pd.DataFrame) -> int:
    if df.empty:
        return 0
    return int(df["date_only"].nunique())

def _safe(val) -> float | None:
    if val is None:
        return None
    try:
        if np.isnan(val):
            return None
    except (TypeError, ValueError):
        pass
    return round(float(val), 2)

# 1. Sleep analysis
def analyse_sleep(sleep_df: pd.DataFrame, target_hours: float) -> dict:
    last7  = _last_n_days(sleep_df, 7)
    last14 = _last_n_days(sleep_df, 14)

    n_days = _unique_days(last7)
    conf   = sleep_confidence(n_days)

    if conf == Confidence.NONE:
        return insufficient(
            "Log sleep for at least 3 nights to see your weekly summary.",
            current=n_days,
            needed=3,
        )

    avg  = float(last7["duration_hours"].mean())
    minn = float(last7["duration_hours"].min())
    maxx = float(last7["duration_hours"].max())

    # Trend direction
    trend = "stable"
    if len(sleep_df) >= 6:
        mid        = len(sleep_df) // 2
        first_avg  = sleep_df.head(mid)["duration_hours"].mean()
        second_avg = sleep_df.tail(mid)["duration_hours"].mean()
        diff       = second_avg - first_avg
        if diff >  0.3:
            trend = "improving"
        elif diff < -0.3:
            trend = "declining"

    quality_trend = "stable"
    quality_scores = sleep_df["quality_score"].dropna()
    if len(quality_scores) >= 6:
        mid        = len(quality_scores) // 2
        first_q    = quality_scores.iloc[:mid].mean()
        second_q   = quality_scores.iloc[mid:].mean()
        q_diff     = second_q - first_q
        if q_diff > 0.3:
            quality_trend = "improving"
        elif q_diff < -0.3:
            quality_trend = "declining"

    avg_quality = None
    last7_quality = last7["quality_score"].dropna()
    if not last7_quality.empty:
        avg_quality = round(float(last7_quality.mean()), 2)

    # Chart data
    chart_data = []
    for _, row in last14.sort_values("bedtime").iterrows():
        chart_data.append({
            "date":          str(row["date_only"]),
            "hours":         round(float(row["duration_hours"]), 2),
            "quality_score": _safe(row.get("quality_score")),
        })

    return {
        "status":        "ok",
        "confidence":    conf.value,
        "data_level":    "weekly_trend",
        "nights_logged": n_days,
        "avg_hours":     round(avg, 2),
        "min_hours":     round(minn, 2),
        "max_hours":     round(maxx, 2),
        "target_hours":  target_hours,
        "vs_target":     round(avg - target_hours, 2),
        "trend":         trend,
        "avg_quality":    avg_quality,
        "quality_trend":  quality_trend,
        "chart_data":    chart_data,
    }

# 2. Nutrition analysis
def analyse_nutrition(
        nutrition_df: pd.DataFrame,
        target_kcal: float | None,
) -> dict:
    last7  = _last_n_days(nutrition_df, 7)
    n_days = _unique_days(last7)
    conf   = calorie_confidence(n_days)

    if conf == Confidence.NONE:
        return insufficient(
            "Log meals for at least 3 days to see your nutrition summary.",
            current=n_days,
            needed=3,
        )

    # Aggregate to daily totals
    daily = (
        last7
        .groupby("date_only")
        .agg(
            kcal=    ("total_kcal",    "sum"),
            protein= ("total_protein", "sum"),
            carbs=   ("total_carbs",   "sum"),
            fat=     ("total_fat",     "sum"),
        )
        .reset_index()
    )

    avg_kcal    = float(daily["kcal"].mean())
    avg_protein = float(daily["protein"].mean())
    avg_carbs   = float(daily["carbs"].mean())
    avg_fat     = float(daily["fat"].mean())

    # Comparison with personalised target
    vs_target = None
    if target_kcal is not None:
        vs_target = round(avg_kcal - target_kcal, 1)

    # Macro balance
    macro_kcal_total = (avg_protein * 4) + (avg_carbs * 4) + (avg_fat * 9)
    macro_balance = None
    if macro_kcal_total > 0:
        macro_balance = {
            "protein_pct": round((avg_protein * 4) / macro_kcal_total * 100, 1),
            "carbs_pct":   round((avg_carbs   * 4) / macro_kcal_total * 100, 1),
            "fat_pct":     round((avg_fat      * 9) / macro_kcal_total * 100, 1),
        }

    # Breakfast
    breakfast_days = 0
    if not last7.empty and "meal_type" in last7.columns:
        days_with_breakfast = (
            last7[last7["meal_type"] == "breakfast"]["date_only"]
            .nunique()
        )
        breakfast_days = int(days_with_breakfast)

    # VS Average kcal on breakfast
    avg_kcal_with_breakfast    = None
    avg_kcal_without_breakfast = None
    if not last7.empty and "meal_type" in last7.columns and n_days >= 3:
        dates_with_breakfast = set(
            last7[last7["meal_type"] == "breakfast"]["date_only"].unique()
        )
        daily_with    = daily[daily["date_only"].isin(dates_with_breakfast)]
        daily_without = daily[~daily["date_only"].isin(dates_with_breakfast)]
        if not daily_with.empty:
            avg_kcal_with_breakfast    = round(float(daily_with["kcal"].mean()), 1)
        if not daily_without.empty:
            avg_kcal_without_breakfast = round(float(daily_without["kcal"].mean()), 1)

    # Chart data
    chart_data = []
    for _, row in daily.sort_values("date_only").iterrows():
        chart_data.append({
            "date": str(row["date_only"]),
            "kcal": round(float(row["kcal"]), 1),
        })

    return {
        "status":       "ok",
        "confidence":   conf.value,
        "data_level":   "weekly_trend",
        "days_logged":  n_days,
        "avg_kcal":     round(avg_kcal, 1),
        "avg_protein_g":round(avg_protein, 1),
        "avg_carbs_g":  round(avg_carbs, 1),
        "avg_fat_g":    round(avg_fat, 1),
        "min_kcal":     round(float(daily["kcal"].min()), 1),
        "max_kcal":     round(float(daily["kcal"].max()), 1),
        "target_kcal":  target_kcal,
        "vs_target":    vs_target,
        "macro_balance":               macro_balance,
        "breakfast_days":              breakfast_days,
        "avg_kcal_with_breakfast":     avg_kcal_with_breakfast,
        "avg_kcal_without_breakfast":  avg_kcal_without_breakfast,
        "chart_data":   chart_data,
    }

# 3. Activity analysis
def analyse_activity(activity_df: pd.DataFrame) -> dict:
    last7      = _last_n_days(activity_df, 7)
    n_sessions = len(last7)
    conf       = activity_confidence(n_sessions)

    if conf == Confidence.NONE:
        return insufficient(
            "Log at least 2 workouts this week to see your activity summary.",
            current=n_sessions,
            needed=2,
        )

    # Total minutes
    total_min = int(last7["duration_min"].sum(skipna=True))

    # Category breakdown
    strength_count = int((last7["category"] == "strength").sum())
    cardio_count   = int((last7["category"] == "cardio").sum())
    other_count    = int(
        ((last7["category"] != "strength") & (last7["category"] != "cardio")).sum()
    )

    # Chart data
    chart_data = []
    for _, row in last7.sort_values("created_at").iterrows():
        chart_data.append({
            "date":         str(row["date_only"]),
            "duration_min": int(row["duration_min"]) if pd.notna(row["duration_min"]) else 0,
            "category":     row["category"],
        })

    return {
        "status":          "ok",
        "confidence":      conf.value,
        "data_level":      "weekly_trend",
        "sessions":        n_sessions,
        "total_min":       total_min,
        "strength_count":  strength_count,
        "cardio_count":    cardio_count,
        "other_count":     other_count,
        "who_target_min":  150,
        "vs_who_target":   total_min - 150,
        "chart_data":      chart_data,
    }

# 4. Weight analysis
def analyse_weight(weight_df: pd.DataFrame, user_goal: str) -> dict:
    df = weight_df.dropna(subset=["weight_kg"]).copy()
    n  = len(df)

    day_range = 0
    if n >= 2:
        day_range = (df["created_at"].max() - df["created_at"].min()).days

    conf = weight_confidence(n, day_range)

    if conf == Confidence.NONE:
        return insufficient(
            "Log your weight on at least 2 separate days to see progress.",
            current=n,
            needed=2,
        )

    first_kg = float(df["weight_kg"].iloc[0])
    last_kg  = float(df["weight_kg"].iloc[-1])
    delta_kg = round(last_kg - first_kg, 2)

    # Simple trend direction from delta
    if abs(delta_kg) < 0.3:
        trend = "stable"
    elif delta_kg > 0:
        trend = "increasing"
    else:
        trend = "decreasing"

    # Goal alignment
    aligned = (
            (user_goal == "lose_weight" and delta_kg <= 0.3) or
            (user_goal == "gain_weight" and delta_kg >= -0.3) or
            (user_goal == "maintain"    and abs(delta_kg) < 1.0)
    )

    regression_available = conf in (Confidence.MEDIUM, Confidence.HIGH)

    # Chart data
    chart_data = []
    for _, row in df.sort_values("created_at").iterrows():
        chart_data.append({
            "date":      str(row["date_only"]),
            "weight_kg": round(float(row["weight_kg"]), 2),
        })

    return {
        "status":               "ok",
        "confidence":           conf.value,
        "data_level":           "weekly_trend",
        "entries":              n,
        "day_range":            day_range,
        "first_kg":             round(first_kg, 2),
        "last_kg":              round(last_kg, 2),
        "delta_kg":             delta_kg,
        "trend":                trend,
        "user_goal":            user_goal,
        "goal_aligned":         aligned,
        "regression_available": regression_available,
        "chart_data":           chart_data,
    }
