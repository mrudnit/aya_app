import csv
from pathlib import Path
from fastapi import APIRouter, Query
from typing import Optional

router = APIRouter()

# Load CSV
_FOODS: list[dict] = []

def _load_foods():
    global _FOODS
    if _FOODS:
        return
    here = Path(__file__).resolve()
    for parent in here.parents:
        candidate = parent / "data" / "food_database.csv"
        if candidate.exists():
            csv_path = candidate
            break
    else:
        return
    with open(csv_path, newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            _FOODS.append({
                "name":          row["name"],
                "category":      row["category"],
                "kcal":          float(row["kcal_per_100g"]),
                "protein_g":     float(row["protein_g"]),
                "carbs_g":       float(row["carbs_g"]),
                "fat_g":         float(row["fat_g"]),
            })

_load_foods()

@router.get("/foods/search")
def search_foods(
        q: str = Query(..., min_length=1, description="Search query"),
        limit: int = Query(30, ge=1, le=100),
        category: Optional[str] = Query(None),
):

    query = q.strip().lower()
    words = query.split()

    results = []
    for food in _FOODS:
        name_lower = food["name"].lower()

        if not all(w in name_lower for w in words):
            continue

        if category and food["category"].lower() != category.lower():
            continue

        results.append(food)

    def sort_key(f):
        n = f["name"].lower()
        if n.startswith(query):
            return (0, n)
        if query in n.split(",")[0]:
            return (1, n)
        return (2, n)

    results.sort(key=sort_key)

    return {
        "query":   q,
        "count":   len(results),
        "results": results[:limit],
    }

@router.get("/foods/categories")
def get_categories():
    cats = sorted(set(f["category"] for f in _FOODS))
    return {"categories": cats}