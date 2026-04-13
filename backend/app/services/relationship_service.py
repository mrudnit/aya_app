import pandas as pd
import numpy as np
from scipy import stats

from app.core.sufficiency import (
    Confidence,
    relationship_confidence,
    correlation_confidence,
    ttest_confidence,
    insufficient,
)

LOW_SLEEP_THRESHOLD_H = 6.0

MIN_PAIRED_DISPLAY = 7

MIN_PAIRED_CORRELATION = 10

MIN_TTEST_PER_GROUP = 3

# Shared helpers
def _paired(daily_df: pd.DataFrame, col_a: str, col_b: str) -> pd.DataFrame:
    return daily_df[[col_a, col_b]].dropna().copy()


import math

def _sanitize(obj):
    if isinstance(obj, dict):
        return {k: _sanitize(v) for k, v in obj.items()}
    if isinstance(obj, list):
        return [_sanitize(v) for v in obj]
    if isinstance(obj, float):
        if math.isnan(obj) or math.isinf(obj):
            return None
    return obj


def _safe_round(val, n: int = 3) -> float | None:
    try:
        if val is None or np.isnan(float(val)):
            return None
        return round(float(val), n)
    except (TypeError, ValueError):
        return None

def _pearson(x: pd.Series, y: pd.Series) -> dict:
    if x.nunique() < 2 or y.nunique() < 2:
        return {
            "method": "pearson", "r": None, "p_value": None,
            "n": len(x), "significant": False, "strength": "none",
            "direction": "none",
            "interpretation": "Correlation not computable (insufficient variation in data).",
        }
    r, p = stats.pearsonr(x, y)
    r = float(r) if not (np.isnan(float(r)) or np.isinf(float(r))) else None
    p = float(p) if not (np.isnan(float(p)) or np.isinf(float(p))) else None
    if r is None or p is None:
        return {
            "method": "pearson", "r": None, "p_value": None,
            "n": len(x), "significant": False, "strength": "none",
            "direction": "none",
            "interpretation": "Correlation not computable (constant input).",
        }

    strength  = "strong" if abs(r) >= 0.5 else "moderate" if abs(r) >= 0.3 else "weak"
    direction = "positive" if r > 0 else "negative"
    sig       = p < 0.05

    interp = (
        f"{'Statistically significant' if sig else 'No significant'} "
        f"{strength} {direction} correlation "
        f"(r = {round(r, 3)}, p = {round(p, 4)}, n = {len(x)})."
    )

    return {
        "method":          "pearson",
        "r":               round(r, 4),
        "p_value":         round(p, 4),
        "n":               int(len(x)),
        "significant":     sig,
        "strength":        strength,
        "direction":       direction,
        "interpretation":  interp,
    }

def _spearman(x: pd.Series, y: pd.Series) -> dict:
    r, p = stats.spearmanr(x, y)
    r, p = float(r), float(p)

    strength  = "strong" if abs(r) >= 0.5 else "moderate" if abs(r) >= 0.3 else "weak"
    direction = "positive" if r > 0 else "negative"
    sig       = p < 0.05

    interp = (
        f"{'Statistically significant' if sig else 'No significant'} "
        f"{strength} {direction} Spearman correlation "
        f"(ρ = {round(r, 3)}, p = {round(p, 4)}, n = {len(x)})."
    )

    return {
        "method":         "spearman",
        "r":              round(r, 4),
        "p_value":        round(p, 4),
        "n":              int(len(x)),
        "significant":    sig,
        "strength":       strength,
        "direction":      direction,
        "interpretation": interp,
    }

def _welch_ttest(
        group_low: pd.Series,
        group_normal: pd.Series,
        metric_label: str,
) -> dict | None:
    g_low    = group_low.dropna()
    g_normal = group_normal.dropna()

    if len(g_low) < MIN_TTEST_PER_GROUP or len(g_normal) < MIN_TTEST_PER_GROUP:
        return None

    t, p = stats.ttest_ind(g_low, g_normal, equal_var=False)

    return {
        "metric":              metric_label,
        "mean_low_sleep":      round(float(g_low.mean()), 2),
        "mean_normal_sleep":   round(float(g_normal.mean()), 2),
        "t_statistic":         round(float(t), 4),
        "p_value":             round(float(p), 4),
        "significant":         bool(p < 0.05),
        "n_low_sleep":         int(len(g_low)),
        "n_normal_sleep":      int(len(g_normal)),
    }

# 1. Sleep vs Activity
def analyse_sleep_vs_activity(daily_df: pd.DataFrame) -> dict:
    paired = _paired(daily_df, "duration_hours", "duration_min")
    n      = len(paired)

    # Gate 1: need at least 7 paired days to show anything
    if n < MIN_PAIRED_DISPLAY:
        return insufficient(
            f"Need {MIN_PAIRED_DISPLAY} days where both sleep and activity are logged. "
            f"Currently {n}.",
            current=n,
            needed=MIN_PAIRED_DISPLAY,
        )

    conf = relationship_confidence(n)

    low_sleep    = paired[paired["duration_hours"] <  LOW_SLEEP_THRESHOLD_H]
    normal_sleep = paired[paired["duration_hours"] >= LOW_SLEEP_THRESHOLD_H]

    low_avg    = _safe_round(low_sleep["duration_min"].mean(),    1)
    normal_avg = _safe_round(normal_sleep["duration_min"].mean(), 1)

    group_summary = None
    if low_avg is not None and normal_avg is not None:
        diff = normal_avg - low_avg
        if diff > 5:
            group_summary = (
                f"On days after sleeping less than {LOW_SLEEP_THRESHOLD_H}h, "
                f"average activity is {low_avg} min vs {normal_avg} min on "
                f"normal-sleep days — {round(diff, 1)} min less."
            )
        else:
            group_summary = (
                f"Activity levels are similar on low-sleep ({low_avg} min) "
                f"and normal-sleep ({normal_avg} min) days."
            )

    # Pearson correlation
    correlation = None
    if n >= MIN_PAIRED_CORRELATION:
        correlation = _pearson(
            paired["duration_hours"],
            paired["duration_min"],
        )

    # Welch t-test
    t_test = None
    ttest_conf = ttest_confidence(n)
    if ttest_conf != Confidence.NONE:
        t_test = _welch_ttest(
            low_sleep["duration_min"],
            normal_sleep["duration_min"],
            metric_label="activity_duration_min",
        )

    return {
        "status":              "ok",
        "confidence":          conf.value,
        "data_level":          "relationship_analysis",
        "paired_days":         n,
        "low_sleep_threshold": LOW_SLEEP_THRESHOLD_H,
        "n_low_sleep_days":    int(len(low_sleep)),
        "n_normal_sleep_days": int(len(normal_sleep)),
        "low_sleep_avg_activity_min":    low_avg,
        "normal_sleep_avg_activity_min": normal_avg,
        "group_summary":       group_summary,
        "correlation":         correlation,
        "t_test":              t_test,
    }

# 2. Sleep vs Calories
def analyse_sleep_vs_calories(daily_df: pd.DataFrame) -> dict:
    paired = _paired(daily_df, "duration_hours", "total_kcal")
    n      = len(paired)

    if n < MIN_PAIRED_DISPLAY:
        return insufficient(
            f"Need {MIN_PAIRED_DISPLAY} days where both sleep and meals are logged. "
            f"Currently {n}.",
            current=n,
            needed=MIN_PAIRED_DISPLAY,
        )

    conf = relationship_confidence(n)

    low_sleep    = paired[paired["duration_hours"] <  LOW_SLEEP_THRESHOLD_H]
    normal_sleep = paired[paired["duration_hours"] >= LOW_SLEEP_THRESHOLD_H]

    low_avg_kcal    = _safe_round(low_sleep["total_kcal"].mean(),    1)
    normal_avg_kcal = _safe_round(normal_sleep["total_kcal"].mean(), 1)

    group_summary = None
    if low_avg_kcal is not None and normal_avg_kcal is not None:
        diff = low_avg_kcal - normal_avg_kcal
        if diff > 50:
            group_summary = (
                f"On low-sleep days (<{LOW_SLEEP_THRESHOLD_H}h), average intake is "
                f"{low_avg_kcal} kcal vs {normal_avg_kcal} kcal on normal days — "
                f"{round(diff, 0)} kcal more."
            )
        else:
            group_summary = (
                f"Calorie intake is similar on low-sleep ({low_avg_kcal} kcal) "
                f"and normal-sleep ({normal_avg_kcal} kcal) days."
            )

    correlation = None
    if n >= MIN_PAIRED_CORRELATION:
        correlation = _pearson(
            paired["duration_hours"],
            paired["total_kcal"],
        )

    t_test = None
    if ttest_confidence(n) != Confidence.NONE:
        t_test = _welch_ttest(
            low_sleep["total_kcal"],
            normal_sleep["total_kcal"],
            metric_label="total_kcal",
        )

    return {
        "status":              "ok",
        "confidence":          conf.value,
        "data_level":          "relationship_analysis",
        "paired_days":         n,
        "low_sleep_threshold": LOW_SLEEP_THRESHOLD_H,
        "n_low_sleep_days":    int(len(low_sleep)),
        "n_normal_sleep_days": int(len(normal_sleep)),
        "low_sleep_avg_kcal":    low_avg_kcal,
        "normal_sleep_avg_kcal": normal_avg_kcal,
        "group_summary":         group_summary,
        "correlation":           correlation,
        "t_test":                t_test,
    }

# 3. Activity vs Weight
def analyse_activity_vs_weight(daily_df: pd.DataFrame) -> dict:
    paired = _paired(daily_df, "duration_min", "weight_kg")
    n      = len(paired)

    if n < MIN_PAIRED_DISPLAY:
        return insufficient(
            f"Need {MIN_PAIRED_DISPLAY} days where both activity and weight are logged. "
            f"Currently {n}. Log your weight more regularly.",
            current=n,
            needed=MIN_PAIRED_DISPLAY,
        )

    conf = relationship_confidence(n)

    correlation = None
    if n >= MIN_PAIRED_CORRELATION:
        # Spearman
        correlation = _spearman(
            paired["duration_min"],
            paired["weight_kg"],
        )

    return {
        "status":       "ok",
        "confidence":   conf.value,
        "data_level":   "relationship_analysis",
        "paired_days":  n,
        "correlation":  correlation,
        "note": (
            "Spearman correlation used because weight data is non-normally "
            "distributed and changes slowly over time."
        ),
    }

# 4. Late Meal vs Sleep Quality
def analyse_late_meal_vs_sleep_quality(daily_df: pd.DataFrame) -> dict:
    # Paired days
    paired = daily_df[["has_late_meal", "quality_score"]].dropna().copy()
    n      = len(paired)

    if n < MIN_PAIRED_DISPLAY:
        return insufficient(
            f"Need {MIN_PAIRED_DISPLAY} days with both a meal timestamp and a sleep "
            f"quality score. Currently {n}. Make sure to rate your sleep quality when logging.",
            current=n,
            needed=MIN_PAIRED_DISPLAY,
        )

    conf = relationship_confidence(n)

    late_meal_days    = paired[paired["has_late_meal"] == True]
    no_late_meal_days = paired[paired["has_late_meal"] == False]

    avg_quality_late   = _safe_round(late_meal_days["quality_score"].mean(),    2)
    avg_quality_normal = _safe_round(no_late_meal_days["quality_score"].mean(), 2)

    # Proportion of "poor sleep"
    prop_poor_late   = None
    prop_poor_normal = None
    if len(late_meal_days) > 0:
        prop_poor_late   = round(
            float((late_meal_days["quality_score"] < 3).mean()) * 100, 1
        )
    if len(no_late_meal_days) > 0:
        prop_poor_normal = round(
            float((no_late_meal_days["quality_score"] < 3).mean()) * 100, 1
        )

    group_summary = None
    if avg_quality_late is not None and avg_quality_normal is not None:
        diff = avg_quality_normal - avg_quality_late
        if diff > 0.3:
            group_summary = (
                f"Sleep quality averages {avg_quality_late}/5 on evenings with a late meal "
                f"vs {avg_quality_normal}/5 on evenings without — "
                f"{round(diff, 2)} points lower."
            )
        else:
            group_summary = (
                f"Sleep quality is similar on late-meal evenings ({avg_quality_late}/5) "
                f"and normal evenings ({avg_quality_normal}/5)."
            )
    correlation = None
    if n >= MIN_PAIRED_CORRELATION:
        x = paired["has_late_meal"].astype(int)
        y = paired["quality_score"]
        correlation = None
        if x.nunique() >= 2 and y.nunique() >= 2:
            r_raw, p_raw = stats.pearsonr(x, y)
            r = float(r_raw) if not (np.isnan(float(r_raw)) or np.isinf(float(r_raw))) else None
            p = float(p_raw) if not (np.isnan(float(p_raw)) or np.isinf(float(p_raw))) else None
            if r is not None and p is not None:
                correlation = {
                    "method":         "point_biserial",
                    "r":              round(r, 4),
                    "p_value":        round(p, 4),
                    "n":              n,
                    "significant":    bool(p < 0.05),
                    "direction":      "negative" if r < 0 else "positive",
                    "interpretation": (
                        f"{'Significant' if p < 0.05 else 'No significant'} "
                        f"{'negative' if r < 0 else 'positive'} association between "
                        f"late meals and sleep quality "
                        f"(r = {round(r, 3)}, p = {round(p, 4)}, n = {n})."
                    ),
                }

    # Welch t-test
    t_test = None
    if ttest_confidence(n) != Confidence.NONE:
        t_test = _welch_ttest(
            late_meal_days["quality_score"],
            no_late_meal_days["quality_score"],
            metric_label="sleep_quality_score",
        )
        if t_test is not None:
            t_test["mean_late_meal"]    = t_test.pop("mean_low_sleep")
            t_test["mean_no_late_meal"] = t_test.pop("mean_normal_sleep")
            t_test["n_late_meal"]       = t_test.pop("n_low_sleep")
            t_test["n_no_late_meal"]    = t_test.pop("n_normal_sleep")

    return {
        "status":                    "ok",
        "confidence":                conf.value,
        "data_level":                "relationship_analysis",
        "paired_days":               n,
        "late_meal_hour_threshold":  20,
        "n_late_meal_days":          int(len(late_meal_days)),
        "n_no_late_meal_days":       int(len(no_late_meal_days)),
        "avg_quality_late_meal":     avg_quality_late,
        "avg_quality_no_late_meal":  avg_quality_normal,
        "prop_poor_sleep_late_meal_pct":   prop_poor_late,
        "prop_poor_sleep_no_late_meal_pct":prop_poor_normal,
        "group_summary":             group_summary,
        "correlation":               correlation,
        "t_test":                    t_test,
    }

# Weight regression
def analyse_weight_regression(weight_df: pd.DataFrame) -> dict | None:
    df = weight_df.dropna(subset=["weight_kg"]).copy()
    if len(df) < 4:
        return None

    df = df.sort_values("created_at").reset_index(drop=True)

    first = df["created_at"].iloc[0]
    df["days"] = (df["created_at"] - first).dt.total_seconds() / 86400

    slope, intercept, r, p, se = stats.linregress(df["days"], df["weight_kg"])

    return {
        "slope_kg_per_day":  round(float(slope), 5),
        "slope_kg_per_week": round(float(slope) * 7, 3),
        "r_squared":         round(float(r ** 2), 4),
        "p_value":           round(float(p), 4),
        "significant":       bool(p < 0.05),
        "n_entries":         int(len(df)),
    }
