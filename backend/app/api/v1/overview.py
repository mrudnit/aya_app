from datetime import datetime
from fastapi import APIRouter, Depends

from app.core.auth import verify_token
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
    analyse_weight_regression,
)

from app.services.recommendation_engine import generate_recommendations
router = APIRouter()

@router.get("/overview/{uid}")
async def overview(
        uid: str,
):
    # 1. Load raw data from Firestore
    profile       = await read_profile(uid)
    raw_sleep     = await read_sleep_logs(uid)
    raw_nutrition = await read_nutrition_logs(uid)
    raw_activity  = await read_activity_logs(uid)
    raw_weight    = await read_weight_logs(uid)

    # 2. Build dataframes
    sleep_df     = make_sleep_df(raw_sleep)
    nutrition_df = make_nutrition_df(raw_nutrition)
    activity_df  = make_activity_df(raw_activity)
    weight_df    = make_weight_df(raw_weight)
    daily_df = build_daily_df(sleep_df, nutrition_df, activity_df, weight_df)

    # 3. Personalised calorie target
    cal_target = calculate_calorie_target(profile)
    target_kcal = cal_target.get("target_kcal")

    # 4. Run all
    target_sleep = float(profile.get("target_sleep_hours") or 8.0)
    user_goal    = profile.get("goal") or "maintain"

    user_weight_kg = profile.get("weight_kg")
    if user_weight_kg is not None:
        user_weight_kg = float(user_weight_kg)

    sleep_result     = analyse_sleep(sleep_df, target_sleep)
    nutrition_result = analyse_nutrition(nutrition_df, target_kcal)
    activity_result  = analyse_activity(activity_df)
    weight_result    = analyse_weight(weight_df, user_goal)

    # Weight regression
    if weight_result.get("status") == "ok" and weight_result.get("regression_available"):
        regression = analyse_weight_regression(weight_df)
        weight_result["regression"] = regression
    else:
        weight_result["regression"] = None

    # Relationship analyses
    sleep_vs_activity  = analyse_sleep_vs_activity(daily_df)
    sleep_vs_calories  = analyse_sleep_vs_calories(daily_df)
    activity_vs_weight = analyse_activity_vs_weight(daily_df)
    late_meal_quality  = analyse_late_meal_vs_sleep_quality(daily_df)

    # Correlations
    correlations = {
        "sleep_vs_activity":  sleep_vs_activity,
        "sleep_vs_calories":  sleep_vs_calories,
        "activity_vs_weight": activity_vs_weight,
    }

    # Recommendations
    recommendations = generate_recommendations(
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

    # 5. Assemble response
    return {
        "generated_at":    datetime.utcnow().isoformat() + "Z",
        "uid":             uid,
        "profile": {
            "first_name":         profile.get("first_name", ""),
            "goal":               user_goal,
            "target_sleep_hours": target_sleep,
        },
        "calorie_target":  cal_target,
        "sleep":           sleep_result,
        "nutrition":       nutrition_result,
        "activity":        activity_result,
        "weight":          weight_result,
        "correlations":    correlations,
        "late_meal_analysis": late_meal_quality,
        "recommendations":    recommendations,
    }
