import argparse
import random
import math
from datetime import datetime, timedelta, timezone

import firebase_admin
from firebase_admin import credentials, firestore
import os
from dotenv import load_dotenv

load_dotenv()

DAYS       = 21
START_DATE = datetime.now() - timedelta(days=DAYS)
random.seed(42)   # reproducible


# Realistic value generators

def _sleep_hours(day: int, has_late_meal: bool) -> float:
    base  = 7.5
    dip   = 1.5 * math.exp(-0.5 * ((day - 10) / 3) ** 2)
    late  = 0.5 if has_late_meal else 0
    noise = random.gauss(0, 0.25)
    return round(max(4.0, min(10.0, base - dip - late + noise)), 2)


def _sleep_quality(duration_h: float, has_late_meal: bool) -> int:
    base  = duration_h / 2          # 8h sleep → base quality ~4
    late  = -1 if has_late_meal else 0
    noise = random.gauss(0, 0.4)
    return max(1, min(5, round(base + late + noise)))


def _activity_min(sleep_h: float, skip: bool) -> int | None:
    if skip:
        return None
    base   = 45
    effect = (sleep_h - 6.5) * 7
    noise  = random.gauss(0, 10)
    return max(10, int(base + effect + noise))


def _calories(activity_min: int | None) -> float:
    base  = 2100
    rest  = 200 if (activity_min is None or activity_min < 20) else 0
    noise = random.gauss(0, 150)
    return round(max(1200, base + rest + noise), 1)


def _weight(day: int, start: float = 84.0) -> float:
    trend = start - day * 0.05
    noise = random.gauss(0, 0.2)
    return round(trend + noise, 1)


def _ts(dt: datetime):
    return dt.replace(tzinfo=timezone.utc)


# Seeder

def seed(uid: str, db):
    user_ref = db.collection("users").document(uid)
    user_ref.set({
        "firstName":           "Demo",
        "gender":              "male",
        "age":                 22,
        "height_cm":           178,
        "weight_kg":           84.0,
        "activity_level":      "medium",
        "goal":                "lose_weight",
        "target_sleep_hours":  8.0,
        "onboarding_completed": True,
    }, merge=True)
    print(f"  ✓ Profile set for uid={uid}")

    sleep_col = user_ref.collection("sleep_logs")
    nut_col   = user_ref.collection("nutrition_logs")
    act_col   = user_ref.collection("activity_logs")
    wt_col    = user_ref.collection("weight_logs")

    for i in range(DAYS):
        day = START_DATE + timedelta(days=i)
        has_late_meal = random.random() < 0.30

        sleep_h = _sleep_hours(i, has_late_meal)
        quality = _sleep_quality(sleep_h, has_late_meal)

        # Skip activity ~2 days per week
        skip_activity = (i % 3 == 2) or (random.random() < 0.1)
        act_min = _activity_min(sleep_h, skip_activity)
        kcal    = _calories(act_min)

        # Sleep log
        bedtime   = day.replace(hour=23, minute=random.randint(0, 59))
        wake_time = bedtime + timedelta(hours=sleep_h)
        sleep_col.add({
            "bedtime":        _ts(bedtime),
            "wake_time":      _ts(wake_time),
            "duration_hours": sleep_h,
            "quality_score":  quality,
        })

        # Nutrition log
        meal_hour = 20 + random.randint(0, 59) // 60 if has_late_meal else random.randint(12, 19)
        protein   = round(kcal * 0.30 / 4, 1)
        carbs     = round(kcal * 0.40 / 4, 1)
        fat       = round(kcal * 0.30 / 9, 1)
        meal_time = day.replace(hour=meal_hour, minute=random.randint(0, 59))
        nut_col.add({
            "meal_type":     "dinner" if has_late_meal else "lunch",
            "date":          day.strftime("%Y-%m-%d"),
            "created_at":    _ts(meal_time),
            "items":         [],
            "total_kcal":    kcal,
            "total_protein": protein,
            "total_carbs":   carbs,
            "total_fat":     fat,
        })

        # Activity log
        if act_min is not None:
            category = "cardio" if i % 2 == 0 else "strength"
            act_doc  = {
                "date":       day.strftime("%Y-%m-%d"),
                "category":   category,
                "created_at": _ts(day.replace(hour=18, minute=0)),
                "updated_at": _ts(day.replace(hour=18, minute=0)),
            }
            if category == "cardio":
                act_doc["cardio_type"]  = "running"
                act_doc["duration_min"] = act_min
            else:
                act_doc["muscle_group"]  = "chest"
                act_doc["exercise_name"] = "Bench Press"
                act_doc["sets"]          = 4
                act_doc["reps"]          = 8
                act_doc["weight_kg"]     = 80.0
                act_doc["duration_min"]  = act_min
            act_col.add(act_doc)

        #  Weight log (every 3 days)
        if i % 3 == 0:
            wt_col.add({
                "weight_kg":  _weight(i),
                "date":       day.strftime("%Y-%m-%d"),
                "created_at": _ts(day.replace(hour=8, minute=0)),
            })

    print(f"  ✓ {DAYS} days of data written")


# Entry point

def main():
    parser = argparse.ArgumentParser(description="Seed 21 days of demo data")
    parser.add_argument("--uid", required=True, help="Firebase UID of the test user")
    args = parser.parse_args()

    key_path = os.getenv("FIREBASE_KEY_PATH", "serviceAccountKey.json")
    if not firebase_admin._apps:
        cred = credentials.Certificate(key_path)
        firebase_admin.initialize_app(cred)
    db = firestore.client()

    print(f"\nSeeding {DAYS} days for uid={args.uid}...")
    seed(args.uid, db)
    print("\nDone! Open http://localhost:8000/api/v1/analytics/debug/<uid> to verify.\n")


if __name__ == "__main__":
    main()
