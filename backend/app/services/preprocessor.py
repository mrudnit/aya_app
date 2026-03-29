import pandas as pd
import numpy as np
from typing import Optional


# Individual DataFrames

def make_sleep_df(raw: list[dict]) -> pd.DataFrame:
    if not raw:
        return pd.DataFrame(columns=[
            "date_only", "bedtime", "wake_time",
            "duration_hours", "quality_score",
        ])

    df = pd.DataFrame(raw)
    df["bedtime"]   = pd.to_datetime(df["bedtime"])
    df["wake_time"] = pd.to_datetime(df["wake_time"])

    # Sort oldest - newest
    df = df.sort_values("bedtime").reset_index(drop=True)

    df["quality_score"] = pd.to_numeric(df["quality_score"], errors="coerce")

    return df[["date_only", "bedtime", "wake_time", "duration_hours", "quality_score"]]


def make_nutrition_df(raw: list[dict]) -> pd.DataFrame:
    if not raw:
        return pd.DataFrame(columns=[
            "date_only", "meal_type", "created_at", "created_hour",
            "total_kcal", "total_protein", "total_carbs", "total_fat",
            "is_late_meal",
        ])

    df = pd.DataFrame(raw)
    df["created_at"] = pd.to_datetime(df["created_at"])
    df = df.sort_values("created_at").reset_index(drop=True)
    # Late meal flag
    df["is_late_meal"] = df["created_hour"] >= 20
    for col in ["total_kcal", "total_protein", "total_carbs", "total_fat"]:
        df[col] = pd.to_numeric(df[col], errors="coerce")

    return df[[
        "date_only", "meal_type", "created_at", "created_hour",
        "total_kcal", "total_protein", "total_carbs", "total_fat",
        "is_late_meal",
    ]]


def make_activity_df(raw: list[dict]) -> pd.DataFrame:
    if not raw:
        return pd.DataFrame(columns=[
            "date_only", "created_at", "category", "duration_min"
        ])

    df = pd.DataFrame(raw)
    df["created_at"]  = pd.to_datetime(df["created_at"])
    df["duration_min"] = pd.to_numeric(df["duration_min"], errors="coerce")
    df = df.sort_values("created_at").reset_index(drop=True)

    return df[["date_only", "created_at", "category", "duration_min"]]


def make_weight_df(raw: list[dict]) -> pd.DataFrame:
    if not raw:
        return pd.DataFrame(columns=["date_only", "created_at", "weight_kg"])

    df = pd.DataFrame(raw)
    df["created_at"] = pd.to_datetime(df["created_at"])
    df["weight_kg"]  = pd.to_numeric(df["weight_kg"], errors="coerce")
    df = df.sort_values("created_at").reset_index(drop=True)

    return df[["date_only", "created_at", "weight_kg"]]


# Daily merged summary

def build_daily_df(
        sleep_df:     pd.DataFrame,
        nutrition_df: pd.DataFrame,
        activity_df:  pd.DataFrame,
        weight_df:    pd.DataFrame,
) -> pd.DataFrame:

    # Sleep one row per night
    if not sleep_df.empty:
        slp = (
            sleep_df
            .groupby("date_only")
            .agg(
                duration_hours=("duration_hours", "mean"),
                quality_score=("quality_score",   "mean"),
            )
            .reset_index()
        )
    else:
        slp = pd.DataFrame(columns=["date_only", "duration_hours", "quality_score"])

    # Nutrition: sum all meals for the day
    if not nutrition_df.empty:
        nut = (
            nutrition_df
            .groupby("date_only")
            .agg(
                total_kcal=   ("total_kcal",    "sum"),
                total_protein=("total_protein",  "sum"),
                total_carbs=  ("total_carbs",    "sum"),
                total_fat=    ("total_fat",       "sum"),
                has_late_meal=("is_late_meal",   "any"),
            )
            .reset_index()
        )
    else:
        nut = pd.DataFrame(columns=[
            "date_only", "total_kcal", "total_protein",
            "total_carbs", "total_fat", "has_late_meal",
        ])

    # Activity: total duration + session count per day
    if not activity_df.empty:
        act = (
            activity_df
            .groupby("date_only")
            .agg(
                duration_min=("duration_min", lambda x: x.sum(skipna=True) if x.notna().any() else np.nan),
                n_sessions=  ("category",     "count"),
            )
            .reset_index()
        )
    else:
        act = pd.DataFrame(columns=["date_only", "duration_min", "n_sessions"])

    # Weight: take the last measurement of the day
    if not weight_df.empty:
        wt = (
            weight_df
            .groupby("date_only")
            .agg(weight_kg=("weight_kg", "last"))
            .reset_index()
        )
    else:
        wt = pd.DataFrame(columns=["date_only", "weight_kg"])
    daily = (
        slp
        .merge(nut, on="date_only", how="outer")
        .merge(act, on="date_only", how="outer")
        .merge(wt,  on="date_only", how="outer")
        .sort_values("date_only")
        .reset_index(drop=True)
    )

    return daily


# Calorie target calculation

def calculate_calorie_target(profile: dict) -> dict:
    age       = profile.get("age")
    height_cm = profile.get("height_cm")
    weight_kg = profile.get("weight_kg")
    gender    = profile.get("gender", "").lower()
    activity  = profile.get("activity_level", "medium").lower()
    goal      = profile.get("goal", "maintain").lower()

    # Cannot calculate without these four fields
    if any(v is None for v in [age, height_cm, weight_kg]):
        return {
            "bmr":                None,
            "tdee":               None,
            "target_kcal":        None,
            "formula":            "mifflin_st_jeor",
            "error":              "Missing profile fields: age, height_cm, or weight_kg",
        }

    # Step 1
    base = 10 * float(weight_kg) + 6.25 * float(height_cm) - 5 * float(age)
    if gender == "male":
        bmr = base + 5
    elif gender == "female":
        bmr = base - 161
    else:
        bmr = base - 78   # (5 + (-161)) / 2 = -78

    # Step 2 - TDEE
    multipliers = {"low": 1.375, "medium": 1.55, "high": 1.725}
    multiplier  = multipliers.get(activity, 1.55)
    tdee        = bmr * multiplier

    # Step 3 - Goal adjustment
    adjustments = {
        "lose_weight":  -400,
        "maintain":       0,
        "gain_weight":  +300,
    }
    adjustment  = adjustments.get(goal, 0)
    target_raw  = tdee + adjustment

    # Step 4 - Safety clamp
    target_kcal = max(1200.0, min(4000.0, target_raw))

    return {
        "bmr":                round(bmr, 1),
        "tdee":               round(tdee, 1),
        "target_kcal":        round(target_kcal, 1),
        "formula":            "mifflin_st_jeor",
        "activity_multiplier": multiplier,
        "goal_adjustment":    adjustment,
    }


# Convenience wrapper

def preprocess_all(
        raw_sleep:     list[dict],
        raw_nutrition: list[dict],
        raw_activity:  list[dict],
        raw_weight:    list[dict],
        profile:       dict,
) -> dict:
    sleep_df     = make_sleep_df(raw_sleep)
    nutrition_df = make_nutrition_df(raw_nutrition)
    activity_df  = make_activity_df(raw_activity)
    weight_df    = make_weight_df(raw_weight)
    daily_df     = build_daily_df(sleep_df, nutrition_df, activity_df, weight_df)
    calorie_target = calculate_calorie_target(profile)

    return {
        "sleep_df":       sleep_df,
        "nutrition_df":   nutrition_df,
        "activity_df":    activity_df,
        "weight_df":      weight_df,
        "daily_df":       daily_df,
        "calorie_target": calorie_target,
    }
