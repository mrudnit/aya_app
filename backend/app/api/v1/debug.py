from datetime import datetime, timedelta
from fastapi import APIRouter, Depends
import pandas as pd

from app.core.auth import verify_token
from app.core.sufficiency import (
    sleep_confidence, calorie_confidence, activity_confidence,
    weight_confidence, relationship_confidence,
)
from app.services.firestore_reader import (
    read_profile, read_sleep_logs, read_nutrition_logs,
    read_activity_logs, read_weight_logs,
)
from app.services.preprocessor import preprocess_all

router = APIRouter()

@router.get("/debug/{uid}")
def debug_user_data(
        uid: str,
):

    # Load raw data from Firestore
    profile       = read_profile(uid)
    raw_sleep     = read_sleep_logs(uid)
    raw_nutrition = read_nutrition_logs(uid)
    raw_activity  = read_activity_logs(uid)
    raw_weight    = read_weight_logs(uid)

    # Preprocess into DataFrames
    processed = preprocess_all(
        raw_sleep, raw_nutrition, raw_activity, raw_weight, profile
    )

    sleep_df     = processed["sleep_df"]
    nutrition_df = processed["nutrition_df"]
    activity_df  = processed["activity_df"]
    weight_df    = processed["weight_df"]
    daily_df     = processed["daily_df"]

    # Raw document counts
    raw_counts = {
        "sleep_logs":     len(raw_sleep),
        "nutrition_logs": len(raw_nutrition),
        "activity_logs":  len(raw_activity),
        "weight_logs":    len(raw_weight),
    }

    # Detected fields
    detected_fields = {}

    # quality_score
    if not sleep_df.empty:
        detected_fields["sleep_quality_score_present"] = bool(
            sleep_df["quality_score"].notna().any()
        )

    # duration_min
    if not activity_df.empty:
        detected_fields["activity_duration_min_present"] = bool(
            activity_df["duration_min"].notna().any()
        )
        detected_fields["activity_categories_found"] = (
            activity_df["category"].unique().tolist()
        )

    # has_late_meal
    if not nutrition_df.empty:
        detected_fields["any_late_meals_found"] = bool(
            nutrition_df["is_late_meal"].any()
        )
        detected_fields["meal_types_found"] = (
            nutrition_df["meal_type"].unique().tolist()
        )

    # Last 7 days
    today  = datetime.now().date()
    cutoff = today - timedelta(days=7)

    def _unique_days_last7(df: pd.DataFrame) -> int:
        if df.empty:
            return 0
        return int(df[df["date_only"] >= cutoff]["date_only"].nunique())

    last7 = {
        "sleep_nights":    _unique_days_last7(sleep_df),
        "nutrition_days":  _unique_days_last7(nutrition_df),
        "activity_sessions": (
            int(activity_df[activity_df["date_only"] >= cutoff].shape[0])
            if not activity_df.empty else 0
        ),
    }

    # Weight needs day_range
    n_weight = len(weight_df)
    weight_day_range = 0
    if n_weight >= 2:
        weight_day_range = (
                weight_df["created_at"].max() - weight_df["created_at"].min()
        ).days

    # Sufficiency checks
    sufficiency = {
        "sleep":    sleep_confidence(last7["sleep_nights"]).value,
        "calories": calorie_confidence(last7["nutrition_days"]).value,
        "activity": activity_confidence(last7["activity_sessions"]).value,
        "weight":   weight_confidence(n_weight, weight_day_range).value,
    }

    # Paired days
    def _paired(df_a: pd.DataFrame, df_b: pd.DataFrame) -> int:
        if df_a.empty or df_b.empty:
            return 0
        set_a = set(df_a["date_only"].tolist())
        set_b = set(df_b["date_only"].tolist())
        return len(set_a & set_b)

    # Build day-level sets
    sleep_days_set = (
        set(daily_df[daily_df["duration_hours"].notna()]["date_only"].tolist())
        if not daily_df.empty else set()
    )
    kcal_days_set = (
        set(daily_df[daily_df["total_kcal"].notna()]["date_only"].tolist())
        if not daily_df.empty else set()
    )
    act_days_set = (
        set(daily_df[daily_df["n_sessions"].notna()]["date_only"].tolist())
        if not daily_df.empty else set()
    )
    wt_days_set = (
        set(daily_df[daily_df["weight_kg"].notna()]["date_only"].tolist())
        if not daily_df.empty else set()
    )
    quality_days_set = (
        set(daily_df[daily_df["quality_score"].notna()]["date_only"].tolist())
        if not daily_df.empty else set()
    )
    late_meal_days_set = (
        set(daily_df[daily_df["has_late_meal"] == True]["date_only"].tolist())
        if not daily_df.empty else set()
    )

    p_sleep_activity = len(sleep_days_set & act_days_set)
    p_sleep_calories = len(sleep_days_set & kcal_days_set)
    p_late_quality   = len(late_meal_days_set & quality_days_set)
    p_activity_weight= len(act_days_set & wt_days_set)

    paired_days = {
        "sleep_and_activity":         p_sleep_activity,
        "sleep_and_calories":         p_sleep_calories,
        "late_meal_and_sleep_quality": p_late_quality,
        "activity_and_weight":        p_activity_weight,
    }

    relationship_sufficiency = {
        "sleep_vs_activity":          relationship_confidence(p_sleep_activity).value,
        "sleep_vs_calories":          relationship_confidence(p_sleep_calories).value,
        "late_meal_vs_sleep_quality": relationship_confidence(p_late_quality).value,
        "activity_vs_weight":         relationship_confidence(p_activity_weight).value,
    }

    # Daily summary
    daily_records = []
    if not daily_df.empty:
        for _, row in daily_df.iterrows():
            daily_records.append({
                "date":           str(row["date_only"]),
                "duration_hours": None if pd.isna(row.get("duration_hours", float("nan"))) else round(float(row["duration_hours"]), 2),
                "quality_score":  None if pd.isna(row.get("quality_score",  float("nan"))) else float(row["quality_score"]),
                "total_kcal":     None if pd.isna(row.get("total_kcal",     float("nan"))) else round(float(row["total_kcal"]), 1),
                "total_protein":  None if pd.isna(row.get("total_protein",  float("nan"))) else round(float(row["total_protein"]), 1),
                "has_late_meal":  bool(row["has_late_meal"]) if pd.notna(row.get("has_late_meal")) else None,
                "duration_min":   None if pd.isna(row.get("duration_min",   float("nan"))) else float(row["duration_min"]),
                "n_sessions":     None if pd.isna(row.get("n_sessions",     float("nan"))) else int(row["n_sessions"]),
                "weight_kg":      None if pd.isna(row.get("weight_kg",      float("nan"))) else round(float(row["weight_kg"]), 2),
            })

    # Assemble final response
    return {
        "uid":                    uid,
        "generated_at":           datetime.utcnow().isoformat() + "Z",
        "profile":                profile,
        "calorie_target":         processed["calorie_target"],
        "raw_counts":             raw_counts,
        "detected_fields":        detected_fields,
        "last_7_days":            last7,
        "sufficiency":            sufficiency,
        "paired_days":            paired_days,
        "relationship_sufficiency": relationship_sufficiency,
        "daily_summary":          daily_records,
        "total_unique_days_all":  (
            len(
                set(str(d) for d in sleep_df["date_only"].tolist()) |
                set(str(d) for d in nutrition_df["date_only"].tolist()) |
                set(str(d) for d in activity_df["date_only"].tolist())
            ) if any([not sleep_df.empty, not nutrition_df.empty, not activity_df.empty])
            else 0
        ),
    }
