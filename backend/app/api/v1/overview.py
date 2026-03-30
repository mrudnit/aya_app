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
    calculate_calorie_target,
)
from app.services.analytics_service import (
    analyse_sleep,
    analyse_nutrition,
    analyse_activity,
    analyse_weight,
)

router = APIRouter()


@router.get("/overview/{uid}")
def overview(
        uid: str,
):
    # 1. Load raw data from Firestore
    profile       = read_profile(uid)
    raw_sleep     = read_sleep_logs(uid)
    raw_nutrition = read_nutrition_logs(uid)
    raw_activity  = read_activity_logs(uid)
    raw_weight    = read_weight_logs(uid)

    # 2. Build dataframes
    sleep_df     = make_sleep_df(raw_sleep)
    nutrition_df = make_nutrition_df(raw_nutrition)
    activity_df  = make_activity_df(raw_activity)
    weight_df    = make_weight_df(raw_weight)

    # 3. Personalised calorie target
    cal_target = calculate_calorie_target(profile)
    target_kcal = cal_target.get("target_kcal")   # None if profile incomplete

    # 4. Run all
    target_sleep = float(profile.get("target_sleep_hours") or 8.0)
    user_goal    = profile.get("goal") or "maintain"

    sleep_result     = analyse_sleep(sleep_df, target_sleep)
    nutrition_result = analyse_nutrition(nutrition_df, target_kcal)
    activity_result  = analyse_activity(activity_df)
    weight_result    = analyse_weight(weight_df, user_goal)

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
        "correlations":    None,
        "t_tests":         None,
        "late_meal_analysis": None,
    }
