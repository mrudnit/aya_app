import argparse
import os
import random
from datetime import datetime, timedelta, timezone

import firebase_admin
from firebase_admin import credentials, firestore
from dotenv import load_dotenv

load_dotenv()

DAYS_PAST   = 15
DAYS_FUTURE = 30
TOTAL_DAYS  = DAYS_PAST + DAYS_FUTURE
random.seed(42)


def utc_ts(dt):
    return dt.replace(tzinfo=timezone.utc)

def clamp(v, lo, hi):
    return max(lo, min(hi, v))

def init_firebase():
    key_path = os.getenv("FIREBASE_KEY_PATH", "serviceAccountKey.json")
    if not firebase_admin._apps:
        cred = credentials.Certificate(key_path)
        firebase_admin.initialize_app(cred)
    return firestore.client()

def clear_subcollection(doc_ref, name):
    for d in list(doc_ref.collection(name).stream()):
        d.reference.delete()

def clear_user_logs(user_ref):
    for sub in ["sleep_logs", "nutrition_logs", "activity_logs", "weight_logs"]:
        clear_subcollection(user_ref, sub)
        print(f"  cleared {sub}")


FOODS = {
    "protein": [
        ("Chicken Breast",  165, 31.0,  0.0,  3.6),
        ("Salmon",          208, 20.0,  0.0, 13.4),
        ("Cod",              61, 14.2,  0.5,  0.2),
        ("Beef lean",       203, 28.7,  0.0,  9.2),
        ("Eggs",            147, 12.6,  0.8,  9.9),
        ("Tuna in water",   116, 25.5,  0.0,  0.8),
        ("Turkey breast",   135, 30.1,  0.0,  1.0),
    ],
    "carbs": [
        ("Brown Rice",       112,  2.6, 23.5,  0.9),
        ("Pasta",            131,  5.0, 25.0,  1.1),
        ("Oatmeal",           68,  2.4, 12.0,  1.4),
        ("Sweet Potato",     103,  2.3, 24.0,  0.1),
        ("Whole Wheat Bread",247, 13.0, 41.0,  3.4),
        ("Quinoa",           120,  4.4, 21.3,  1.9),
    ],
    "vegetables": [
        ("Broccoli",    35, 2.4,  7.2, 0.4),
        ("Spinach",     23, 2.9,  3.6, 0.4),
        ("Cucumber",    16, 0.7,  3.6, 0.1),
        ("Tomato",      18, 0.9,  3.9, 0.2),
        ("Bell Pepper", 31, 1.0,  6.0, 0.3),
        ("Carrot",      41, 0.9,  9.6, 0.2),
    ],
    "dairy": [
        ("Greek Yogurt",   97,  9.0,  3.6, 5.0),
        ("Cottage Cheese", 98, 11.1,  3.4, 4.3),
        ("Milk",           61,  3.2,  4.8, 3.3),
    ],
    "fruits": [
        ("Banana",      89, 1.1, 22.8, 0.3),
        ("Apple",       52, 0.3, 13.8, 0.2),
        ("Orange",      47, 0.9, 11.8, 0.1),
        ("Blueberries", 57, 0.7, 14.5, 0.3),
    ],
}


def make_items(meal_type, target_kcal):
    if meal_type == "breakfast":
        combos = [
            (random.choice(FOODS["carbs"]),      80),
            (random.choice(FOODS["fruits"]),    120),
            (random.choice(FOODS["dairy"]),     150),
        ]
    elif meal_type == "lunch":
        combos = [
            (random.choice(FOODS["protein"]),   150),
            (random.choice(FOODS["carbs"]),     180),
            (random.choice(FOODS["vegetables"]),200),
        ]
    else:  # dinner
        combos = [
            (random.choice(FOODS["protein"]),   180),
            (random.choice(FOODS["carbs"]),     200),
            (random.choice(FOODS["vegetables"]),150),
        ]

    items = []
    total = 0
    for food, grams in combos:
        name, k100, p100, c100, f100 = food
        r = grams / 100.0
        items.append({
            "food_name": name,
            "portion_g": float(grams),
            "kcal":      round(k100 * r, 1),
            "protein_g": round(p100 * r, 1),
            "carbs_g":   round(c100 * r, 1),
            "fat_g":     round(f100 * r, 1),
        })
        total += k100 * r

    scale = target_kcal / max(total, 1)
    for item in items:
        for key in ["portion_g", "kcal", "protein_g", "carbs_g", "fat_g"]:
            item[key] = round(item[key] * scale, 1)
    return items

PROFILES = {
    "lose_good": {
        "firstName": "Demo", "lastName": "User",
        "gender": "male", "age": 24,
        "height_cm": 180, "weight_kg": 80.0,
        "activity_level": "medium",
        "goal": "lose_weight",
        "target_sleep_hours": 8.0,
        "onboarding_completed": True,
        "email": "demo@aya-app.com",
        "phone": "",
    },
    "gain_bad": {
        "firstName": "Demo", "lastName": "User",
        "gender": "male", "age": 22,
        "height_cm": 178, "weight_kg": 74.0,
        "activity_level": "medium",
        "goal": "gain_weight",
        "target_sleep_hours": 8.0,
        "onboarding_completed": True,
        "email": "demo@aya-app.com",
        "phone": "",
    },
    "late_meal_problem": {
        "firstName": "Demo", "lastName": "User",
        "gender": "male", "age": 23,
        "height_cm": 176, "weight_kg": 84.0,
        "activity_level": "medium",
        "goal": "maintain",
        "target_sleep_hours": 8.0,
        "onboarding_completed": True,
        "email": "demo@aya-app.com",
        "phone": "",
    },
}


def day_logic(scenario, i):
    if scenario == "lose_good":
        late_meal = random.random() < 0.10
        sleep_h   = clamp(7.5 + random.gauss(0, 0.35), 6.8, 8.4)
        quality   = int(clamp(round(sleep_h / 2 + random.gauss(0, 0.3)), 3, 5))
        has_act   = (i % 2 == 0) or (i % 5 == 0)
        category  = "cardio" if i % 3 != 0 else "strength"
        dur       = random.randint(35, 65) if has_act else None
        kcal      = round(clamp(2150 + random.gauss(0, 100), 1950, 2350), 1)
        weight    = round(80.0 - i * 0.06 + random.gauss(0, 0.10), 1)

    elif scenario == "gain_bad":
        late_meal = random.random() < 0.35
        sleep_h   = clamp(6.1 + random.gauss(0, 0.45), 5.0, 7.0)
        quality   = int(clamp(round(sleep_h / 2 - (1 if late_meal else 0) + random.gauss(0, 0.3)), 1, 4))
        has_act   = random.random() < 0.45
        category  = "strength" if random.random() < 0.7 else "cardio"
        dur       = random.randint(20, 45) if has_act else None
        kcal      = round(clamp(2100 + random.gauss(0, 180), 1800, 2400), 1)
        weight    = round(74.0 - i * 0.02 + random.gauss(0, 0.20), 1)

    else:  # late_meal_problem
        late_meal = random.random() < 0.55
        base      = 7.2 + random.gauss(0, 0.3)
        if late_meal:
            sleep_h = clamp(base - 1.0 + random.gauss(0, 0.15), 5.2, 7.0)
            quality = int(clamp(round(2.2 + random.gauss(0, 0.35)), 1, 3))
        else:
            sleep_h = clamp(base + random.gauss(0, 0.15), 6.8, 8.0)
            quality = int(clamp(round(3.8 + random.gauss(0, 0.35)), 3, 5))
        has_act   = random.random() < 0.55
        category  = "cardio" if random.random() < 0.5 else "strength"
        dur       = random.randint(25, 55) if has_act else None
        kcal      = round(clamp(2350 + (120 if late_meal else 0) + random.gauss(0, 140), 2000, 2800), 1)
        weight    = round(84.0 + random.gauss(0, 0.20), 1)

    return late_meal, sleep_h, quality, has_act, category, dur, kcal, weight


def macro_split(kcal, scenario):
    splits = {
        "lose_good":         (0.32, 0.38, 0.30),
        "gain_bad":          (0.22, 0.43, 0.35),
        "late_meal_problem": (0.26, 0.44, 0.30),
    }
    p, c, f = splits[scenario]
    return round(kcal * p / 4, 1), round(kcal * c / 4, 1), round(kcal * f / 9, 1)


def build_activity_doc(day, category, dur):
    doc = {
        "date":        day.strftime("%Y-%m-%d"),
        "category":    category,
        "created_at":  utc_ts(day.replace(hour=18, minute=0, second=0, microsecond=0)),
        "updated_at":  utc_ts(day.replace(hour=18, minute=0, second=0, microsecond=0)),
        "duration_min": dur,
    }
    if category == "cardio":
        ct = random.choice(["running", "cycling", "walking"])
        doc.update({
            "cardio_type":    ct,
            "calories_burned": round(dur * random.uniform(5.5, 8.5), 1),
            "title":          ct.capitalize(),
        })
    else:
        mm = {
            "chest":     "Bench Press",
            "back":      "Barbell Row",
            "legs":      "Squat",
            "shoulders": "Overhead Press",
            "arms":      "Barbell Curl",
            "full_body": "Deadlift",
        }
        m = random.choice(list(mm.keys()))
        doc.update({
            "muscle_group":  m,
            "exercise_name": mm[m],
            "sets":          random.choice([3, 4]),
            "reps":          random.choice([6, 8, 10]),
            "weight_kg":     float(random.choice([40, 50, 60, 70, 80])),
            "title":         mm[m],
        })
    return doc


def seed(uid, scenario, clear_existing=True):
    db       = init_firebase()
    user_ref = db.collection("users").document(uid)

    if clear_existing:
        print("Clearing existing logs...")
        clear_user_logs(user_ref)

    user_ref.set(PROFILES[scenario], merge=True)
    print(f"✓ Profile written ({scenario})")

    sleep_col = user_ref.collection("sleep_logs")
    nut_col   = user_ref.collection("nutrition_logs")
    act_col   = user_ref.collection("activity_logs")
    wt_col    = user_ref.collection("weight_logs")

    today = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
    start = today - timedelta(days=DAYS_PAST)

    print(f"Seeding {DAYS_PAST} past + {DAYS_FUTURE} future = {TOTAL_DAYS} days total...")
    print(f"From {start.strftime('%Y-%m-%d')} to {(today + timedelta(days=DAYS_FUTURE)).strftime('%Y-%m-%d')}")

    for i in range(TOTAL_DAYS):
        day       = start + timedelta(days=i)
        is_future = day.date() > today.date()

        late_meal, sleep_h, quality, has_act, category, dur, kcal, weight = day_logic(scenario, i)

        bedtime   = day.replace(hour=23, minute=random.randint(0, 40), second=0, microsecond=0)
        wake_time = bedtime + timedelta(hours=sleep_h)
        sleep_col.add({
            "bedtime":        utc_ts(bedtime),
            "wake_time":      utc_ts(wake_time),
            "duration_hours": round(sleep_h, 2),
            "quality_score":  quality,
        })

        protein, carbs, fat = macro_split(kcal, scenario)

        bk = round(kcal * 0.25, 1)
        bt = day.replace(hour=random.randint(7, 9), minute=random.randint(0, 30), second=0, microsecond=0)
        nut_col.add({
            "meal_type": "breakfast", "date": day.strftime("%Y-%m-%d"),
            "items": make_items("breakfast", bk), "notes": None,
            "created_at": utc_ts(bt), "total_kcal": bk,
            "total_protein": round(protein * 0.25, 1),
            "total_carbs":   round(carbs   * 0.25, 1),
            "total_fat":     round(fat     * 0.25, 1),
        })

        lk = round(kcal * 0.40, 1)
        lt = day.replace(hour=random.randint(12, 14), minute=random.randint(0, 30), second=0, microsecond=0)
        nut_col.add({
            "meal_type": "lunch", "date": day.strftime("%Y-%m-%d"),
            "items": make_items("lunch", lk), "notes": None,
            "created_at": utc_ts(lt), "total_kcal": lk,
            "total_protein": round(protein * 0.40, 1),
            "total_carbs":   round(carbs   * 0.40, 1),
            "total_fat":     round(fat     * 0.40, 1),
        })

        dh  = random.randint(20, 22) if late_meal else random.randint(17, 19)
        dt_ = day.replace(hour=dh, minute=random.randint(0, 30), second=0, microsecond=0)
        dk  = round(kcal * 0.35, 1)
        nut_col.add({
            "meal_type": "dinner", "date": day.strftime("%Y-%m-%d"),
            "items": make_items("dinner", dk), "notes": None,
            "created_at": utc_ts(dt_), "total_kcal": dk,
            "total_protein": round(protein * 0.35, 1),
            "total_carbs":   round(carbs   * 0.35, 1),
            "total_fat":     round(fat     * 0.35, 1),
        })

        if has_act and dur is not None:
            act_col.add(build_activity_doc(day, category, dur))

        wt_col.add({
            "weight_kg":  weight,
            "date":       day.strftime("%Y-%m-%d"),
            "created_at": utc_ts(day.replace(hour=8, minute=0, second=0, microsecond=0)),
        })

        label = "future" if is_future else "past"
        if (i + 1) % 10 == 0:
            print(f"  {i + 1}/{TOTAL_DAYS} days written ({label})...")

    print(f"\n✓ Done! {TOTAL_DAYS} days seeded.")
    print(f"  Past:   {DAYS_PAST} days  → analytics works RIGHT NOW")
    print(f"  Future: {DAYS_FUTURE} days → analytics works for 30 more days")
    print()
    print("Expected analytics output:")
    previews = {
        "lose_good": [
            "Sleep 7–8h, quality 3–5",
            "Activity every 2 days (cardio + strength)",
            "Calories ~2150 kcal/day — within target",
            "Weight slowly dropping from 80 kg",
            "Sleep vs Activity: positive correlation",
            "Activity vs Weight: significant",
            "Recommendation: On track — maintain current habits",
        ],
        "gain_bad": [
            "Sleep 5–7h, poor quality",
            "Calories too low for gain goal",
            "Weight stagnating",
            "Recommendation: Eat more + improve sleep",
        ],
        "late_meal_problem": [
            "55% of days: dinner after 20:00",
            "Late meal nights: worse sleep quality",
            "t-test: significant difference",
            "Recommendation: Avoid eating after 20:00",
        ],
    }
    for line in previews[scenario]:
        print(f"  → {line}")


def main():
    parser = argparse.ArgumentParser(description="Seed 45-day demo data for Aya")
    parser.add_argument("--uid",           required=True, help="Firebase UID of demo account")
    parser.add_argument("--scenario",      required=True,
                        choices=["lose_good", "gain_bad", "late_meal_problem"])
    parser.add_argument("--keep-existing", action="store_true",
                        help="Do not clear existing logs before seeding")
    args = parser.parse_args()
    seed(uid=args.uid, scenario=args.scenario, clear_existing=not args.keep_existing)


if __name__ == "__main__":
    main()