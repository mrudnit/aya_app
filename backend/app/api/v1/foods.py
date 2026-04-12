import csv
import os
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
    csv_path = Path(__file__).parent.parent.parent / "data" / "food_database.csv"
    if not csv_path.exists():
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
        limit: int = Query(20, ge=1, le=50),
        category: Optional[str] = Query(None),
):

    query = q.strip().lower()
    results = []

    for food in _FOODS:
        if query in food["name"].lower():
            if category and food["category"].lower() != category.lower():
                continue
            results.append(food)
        if len(results) >= limit:
            break

    return {
        "query":   q,
        "count":   len(results),
        "results": results,
    }

@router.get("/foods/categories")
def get_categories():
    cats = sorted(set(f["category"] for f in _FOODS))
    return {"categories": cats}