# =============================================================================
# app/services/firestore_reader.py  —  Firestore → raw Python dicts
# =============================================================================
# Reads raw documents from Firestore and converts them to Python dicts.
# Field names match the Flutter models EXACTLY as defined in the
# analytics design document.
#
# Firestore field names used here:
#
#   users/{uid}:
#     firstName, gender, age, height_cm, weight_kg,
#     activity_level, goal, target_sleep_hours
#
#   sleep_logs:
#     bedtime (Timestamp), wake_time (Timestamp),
#     duration_hours (float), quality_score (int, optional)
#
#   nutrition_logs (MealLog):
#     meal_type (str), date (str), created_at (Timestamp),
#     total_kcal (float), total_protein (float),
#     total_carbs (float), total_fat (float),
#     items (list — not used in analytics, only totals matter)
#
from app.core.firebase import get_db


def _user_collection(uid: str, name: str):
    return get_db().collection("users").document(uid).collection(name)


# User profile

def read_profile(uid: str) -> dict:
    doc = get_db().collection("users").document(uid).get()
    if not doc.exists:
        return {}
    data = doc.to_dict()

    # Return only needed fields
    return {
        "first_name":          data.get("firstName", ""),
        "gender":              data.get("gender", ""),
        "age":                 data.get("age"),
        "height_cm":           data.get("height_cm"),
        "weight_kg":           data.get("weight_kg"),
        "activity_level":      data.get("activity_level", "medium"),
        "goal":                data.get("goal", "maintain"),
        "target_sleep_hours":  data.get("target_sleep_hours", 8.0),
    }


# Sleep logs

def read_sleep_logs(uid: str, limit: int = 90) -> list[dict]:
    docs = (
        _user_collection(uid, "sleep_logs")
        .order_by("bedtime", direction="DESCENDING")
        .limit(limit)
        .stream()
    )

    result = []
    for doc in docs:
        m = doc.to_dict()
        # Firestore Timestamps
        bedtime  = m["bedtime"].replace(tzinfo=None)
        wake     = m["wake_time"].replace(tzinfo=None)

        result.append({
            "doc_id":         doc.id,
            "bedtime":        bedtime,
            "wake_time":      wake,
            "date_only":      bedtime.date(),
            "duration_hours": float(m.get("duration_hours", 0)),
            "quality_score":  m.get("quality_score"),
        })

    return result


# Nutrition logs

def read_nutrition_logs(uid: str, limit: int = 90) -> list[dict]:
    docs = (
        _user_collection(uid, "nutrition_logs")
        .order_by("created_at", direction="DESCENDING")
        .limit(limit)
        .stream()
    )

    result = []
    for doc in docs:
        m = doc.to_dict()
        created = m["created_at"].replace(tzinfo=None)

        result.append({
            "doc_id":        doc.id,
            "meal_type":     m.get("meal_type", ""),
            "date_only":     created.date(),
            "created_at":    created,
            "created_hour":  created.hour,
            "total_kcal":    float(m.get("total_kcal", 0)),
            "total_protein": float(m.get("total_protein", 0)),
            "total_carbs":   float(m.get("total_carbs", 0)),
            "total_fat":     float(m.get("total_fat", 0)),
        })

    return result


# Activity logs

def read_activity_logs(uid: str, limit: int = 90) -> list[dict]:
    docs = (
        _user_collection(uid, "activity_logs")
        .order_by("created_at", direction="DESCENDING")
        .limit(limit)
        .stream()
    )

    result = []
    for doc in docs:
        m = doc.to_dict()
        created = m["created_at"].replace(tzinfo=None)

        result.append({
            "doc_id":      doc.id,
            "date_only":   created.date(),
            "created_at":  created,
            "category":    m.get("category", "other"),
            "duration_min": m.get("duration_min"),
        })

    return result


# Weight logs

def read_weight_logs(uid: str, limit: int = 90) -> list[dict]:
    docs = (
        _user_collection(uid, "weight_logs")
        .order_by("created_at", direction="ASCENDING")
        .limit(limit)
        .stream()
    )

    result = []
    for doc in docs:
        m = doc.to_dict()
        created = m["created_at"].replace(tzinfo=None)

        result.append({
            "doc_id":     doc.id,
            "date_only":  created.date(),
            "created_at": created,
            "weight_kg":  float(m.get("weight_kg", 0)),
        })

    return result
