import argparse
import math
import os
import random
from datetime import datetime, timedelta, timezone

import firebase_admin
from firebase_admin import credentials, firestore
from dotenv import load_dotenv

load_dotenv()

DAYS = 21
random.seed(42)


def utc_ts(dt: datetime):
    return dt.replace(tzinfo=timezone.utc)


def clamp(value, min_v, max_v):
    return max(min_v, min(max_v, value))


def daterange(start_date, days):
    for i in range(days):
        yield start_date + timedelta(days=i), i


def init_firebase():
    key_path = os.getenv("FIREBASE_KEY_PATH", "serviceAccountKey.json")
    if not firebase_admin._apps:
        cred = credentials.Certificate(key_path)
        firebase_admin.initialize_app(cred)
    return firestore.client()


def clear_subcollection(doc_ref, sub_name: str):
    docs = list(doc_ref.collection(sub_name).stream())
    for d in docs:
        d.reference.delete()


def clear_user_logs(user_ref):
    for sub in ["sleep_logs", "nutrition_logs", "activity_logs", "weight_logs"]:
        clear_subcollection(user_ref, sub)


def make_profile(scenario: str):
    if scenario == "lose_good":
        return {
            "firstName": "Demo Lose",
            "gender": "male",
            "age": 24,
            "height_cm": 180,
            "weight_kg": 92.0,
            "activity_level": "medium",
            "goal": "lose_weight",
            "target_sleep_hours": 8.0,
            "onboarding_completed": True,
        }
    if scenario == "gain_bad":
        return {
            "firstName": "Demo Gain",
            "gender": "male",
            "age": 22,
            "height_cm": 178,
            "weight_kg": 74.0,
            "activity_level": "medium",
            "goal": "gain_weight",
            "target_sleep_hours": 8.0,
            "onboarding_completed": True,
        }
    if scenario == "late_meal_problem":
        return {
            "firstName": "Demo Sleep",
            "gender": "male",
            "age": 23,
            "height_cm": 176,
            "weight_kg": 84.0,
            "activity_level": "medium",
            "goal": "maintain",
            "target_sleep_hours": 8.0,
            "onboarding_completed": True,
        }
    raise ValueError(f"Unknown scenario: {scenario}")


def scenario_logic(scenario: str, day_index: int):
    if scenario == "lose_good":
        late_meal = random.random() < 0.10
        sleep_h = clamp(7.5 + random.gauss(0, 0.35), 6.8, 8.4)
        quality = int(clamp(round((sleep_h / 2) + random.gauss(0, 0.3)), 3, 5))

        has_activity = day_index % 2 == 0 or day_index % 5 == 0
        category = "cardio" if day_index % 3 != 0 else "strength"
        duration_min = random.randint(35, 65) if has_activity else None

        kcal = round(clamp(2200 + random.gauss(0, 120), 1950, 2450), 1)
        weight = round(92.0 - day_index * 0.10 + random.gauss(0, 0.12), 1)
        return late_meal, sleep_h, quality, has_activity, category, duration_min, kcal, weight

    if scenario == "gain_bad":
        late_meal = random.random() < 0.35
        sleep_h = clamp(6.1 + random.gauss(0, 0.45), 5.0, 7.0)
        quality_penalty = 1 if late_meal else 0
        quality = int(clamp(round((sleep_h / 2) - quality_penalty + random.gauss(0, 0.3)), 1, 4))

        has_activity = random.random() < 0.45
        category = "strength" if random.random() < 0.7 else "cardio"
        duration_min = random.randint(20, 45) if has_activity else None

        # Слишком мало калорий для набора
        kcal = round(clamp(2100 + random.gauss(0, 180), 1800, 2400), 1)
        # Вес почти не растёт, местами падает
        weight = round(74.0 - day_index * 0.02 + random.gauss(0, 0.20), 1)
        return late_meal, sleep_h, quality, has_activity, category, duration_min, kcal, weight

    if scenario == "late_meal_problem":
        late_meal = random.random() < 0.55
        base_sleep = 7.2 + random.gauss(0, 0.3)
        if late_meal:
            sleep_h = clamp(base_sleep - 1.0 + random.gauss(0, 0.15), 5.2, 7.0)
            quality = int(clamp(round(2.2 + random.gauss(0, 0.35)), 1, 3))
        else:
            sleep_h = clamp(base_sleep + random.gauss(0, 0.15), 6.8, 8.0)
            quality = int(clamp(round(3.8 + random.gauss(0, 0.35)), 3, 5))

        has_activity = random.random() < 0.55
        category = "cardio" if random.random() < 0.5 else "strength"
        duration_min = random.randint(25, 55) if has_activity else None

        kcal = round(clamp(2350 + (120 if late_meal else 0) + random.gauss(0, 140), 2000, 2800), 1)
        weight = round(84.0 + random.gauss(0, 0.20), 1)
        return late_meal, sleep_h, quality, has_activity, category, duration_min, kcal, weight

    raise ValueError(f"Unknown scenario: {scenario}")


def meal_items_from_totals(kcal: float, scenario: str):
    # Просто реалистичные items, totals backend всё равно читает из total_*
    if scenario == "lose_good":
        return [
            {
                "food_name": "Chicken Breast",
                "portion_g": 200.0,
                "kcal": 330.0,
                "protein_g": 62.0,
                "carbs_g": 0.0,
                "fat_g": 7.2,
            },
            {
                "food_name": "Brown Rice",
                "portion_g": 220.0,
                "kcal": 246.4,
                "protein_g": 5.7,
                "carbs_g": 52.8,
                "fat_g": 2.0,
            },
            {
                "food_name": "Broccoli",
                "portion_g": 180.0,
                "kcal": 61.2,
                "protein_g": 5.0,
                "carbs_g": 12.6,
                "fat_g": 0.7,
            },
        ]

    if scenario == "gain_bad":
        return [
            {
                "food_name": "White Bread",
                "portion_g": 120.0,
                "kcal": 318.0,
                "protein_g": 10.8,
                "carbs_g": 61.2,
                "fat_g": 3.8,
            },
            {
                "food_name": "Cheddar Cheese",
                "portion_g": 60.0,
                "kcal": 241.2,
                "protein_g": 15.0,
                "carbs_g": 0.8,
                "fat_g": 19.8,
            },
            {
                "food_name": "Banana",
                "portion_g": 150.0,
                "kcal": 133.5,
                "protein_g": 1.7,
                "carbs_g": 34.5,
                "fat_g": 0.5,
            },
        ]

    if scenario == "late_meal_problem":
        return [
            {
                "food_name": "Pasta",
                "portion_g": 250.0,
                "kcal": 327.5,
                "protein_g": 12.5,
                "carbs_g": 62.5,
                "fat_g": 2.8,
            },
            {
                "food_name": "Ground Beef (lean)",
                "portion_g": 180.0,
                "kcal": 387.0,
                "protein_g": 46.8,
                "carbs_g": 0.0,
                "fat_g": 21.6,
            },
            {
                "food_name": "Dark Chocolate",
                "portion_g": 40.0,
                "kcal": 218.4,
                "protein_g": 2.0,
                "carbs_g": 24.0,
                "fat_g": 12.4,
            },
        ]

    return []


def macro_split(kcal: float, scenario: str):
    if scenario == "lose_good":
        protein_pct, carbs_pct, fat_pct = 0.32, 0.38, 0.30
    elif scenario == "gain_bad":
        protein_pct, carbs_pct, fat_pct = 0.22, 0.43, 0.35
    else:
        protein_pct, carbs_pct, fat_pct = 0.26, 0.44, 0.30

    protein = round((kcal * protein_pct) / 4, 1)
    carbs = round((kcal * carbs_pct) / 4, 1)
    fat = round((kcal * fat_pct) / 9, 1)
    return protein, carbs, fat


def build_activity_doc(day: datetime, category: str, duration_min: int):
    common = {
        "date": day.strftime("%Y-%m-%d"),
        "category": category,
        "created_at": utc_ts(day.replace(hour=18, minute=0)),
        "updated_at": utc_ts(day.replace(hour=18, minute=0)),
        "duration_min": duration_min,
    }

    if category == "cardio":
        cardio_type = random.choice(["walking", "running", "cycling"])
        common.update({
            "cardio_type": cardio_type,
            "calories_burned": round(duration_min * random.uniform(5.5, 8.5), 1),
            "title": cardio_type.capitalize(),
        })
    else:
        muscle = random.choice(["chest", "back", "legs", "shoulders", "arms", "full_body"])
        exercise_map = {
            "chest": "Bench Press",
            "back": "Barbell Row",
            "legs": "Squat",
            "shoulders": "Overhead Press",
            "arms": "Barbell Curl",
            "full_body": "Deadlift",
        }
        common.update({
            "muscle_group": muscle,
            "exercise_name": exercise_map[muscle],
            "sets": random.choice([3, 4]),
            "reps": random.choice([6, 8, 10]),
            "weight_kg": round(random.choice([40, 50, 60, 70, 80]), 1),
            "title": exercise_map[muscle],
        })
    return common


def seed(uid: str, scenario: str, clear_existing: bool = True):
    db = init_firebase()

    user_ref = db.collection("users").document(uid)
    if clear_existing:
        clear_user_logs(user_ref)

    profile = make_profile(scenario)
    user_ref.set(profile, merge=True)

    sleep_col = user_ref.collection("sleep_logs")
    nut_col = user_ref.collection("nutrition_logs")
    act_col = user_ref.collection("activity_logs")
    wt_col = user_ref.collection("weight_logs")

    start_date = datetime.now() - timedelta(days=DAYS)

    print(f"\nSeeding scenario='{scenario}' for uid={uid}...")

    for day, i in daterange(start_date, DAYS):
        late_meal, sleep_h, quality, has_activity, category, duration_min, kcal, weight = scenario_logic(scenario, i)

        bedtime = day.replace(hour=23, minute=random.randint(0, 40), second=0, microsecond=0)
        wake_time = bedtime + timedelta(hours=sleep_h)

        sleep_col.add({
            "bedtime": utc_ts(bedtime),
            "wake_time": utc_ts(wake_time),
            "duration_hours": round(sleep_h, 2),
            "quality_score": quality,
        })

        protein, carbs, fat = macro_split(kcal, scenario)
        items = meal_items_from_totals(kcal, scenario)

        if late_meal:
            meal_hour = random.randint(20, 22)
            meal_type = "dinner"
        else:
            meal_hour = random.randint(12, 18)
            meal_type = random.choice(["lunch", "dinner", "snack"])

        meal_time = day.replace(hour=meal_hour, minute=random.randint(0, 59), second=0, microsecond=0)

        nut_col.add({
            "meal_type": meal_type,
            "date": day.strftime("%Y-%m-%d"),
            "items": items,
            "notes": None,
            "created_at": utc_ts(meal_time),
            "total_kcal": round(kcal, 1),
            "total_protein": protein,
            "total_carbs": carbs,
            "total_fat": fat,
        })

        if has_activity and duration_min is not None:
            act_col.add(build_activity_doc(day, category, duration_min))

        # Вес каждые 3 дня
        if i % 3 == 0:
            wt_col.add({
                "weight_kg": weight,
                "date": day.strftime("%Y-%m-%d"),
                "created_at": utc_ts(day.replace(hour=8, minute=0, second=0, microsecond=0)),
            })

    print("✓ Profile written")
    print("✓ Sleep logs written")
    print("✓ Nutrition logs written")
    print("✓ Activity logs written")
    print("✓ Weight logs written")
    print("✓ Done\n")


def main():
    parser = argparse.ArgumentParser(description="Seed realistic demo data for analytics scenarios")
    parser.add_argument("--uid", required=True, help="Firebase UID")
    parser.add_argument(
        "--scenario",
        required=True,
        choices=["lose_good", "gain_bad", "late_meal_problem"],
        help="Which demo scenario to generate",
    )
    parser.add_argument(
        "--keep-existing",
        action="store_true",
        help="Do not clear existing logs before seeding",
    )
    args = parser.parse_args()

    seed(
        uid=args.uid,
        scenario=args.scenario,
        clear_existing=not args.keep_existing,
    )

if __name__ == "__main__":
    main()