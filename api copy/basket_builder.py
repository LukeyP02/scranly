# basket_builder.py

import sqlite3, datetime as dt, json

def connect(db_path="/Users/lukeyp02/Desktop/scranly/api/data/scranly.db"):
    return sqlite3.connect(db_path)
PANTRY = {"salt","pepper","olive oil","oil","water","chili flakes","sugar","flour"}

def normalise_name(name: str) -> str:
    n = name.lower().strip()
    # strip numbers/units like "1x ", "200 g ", "3 tbsp "
    n = re.sub(r"^\d+[xX]?\s*", "", n)
    n = re.sub(r"\b\d+\s*(g|kg|ml|l|tbsp|tsp|cups?)\b", "", n)
    # common synonyms
    synonyms = {
        "bell pepper":"pepper",
        "red pepper":"pepper",
        "green pepper":"pepper",
        "scallion":"spring onion",
        "coriander":"cilantro",
    }
    if n in synonyms: 
        n = synonyms[n]
    return n.strip()

def normalise_unit(qty: str):
    """Turn messy qty strings into (amount, unit)"""
    qty = qty.strip().lower().replace("x", "").strip()
    if not qty:
        return 1.0, "count"

    # Match e.g. "200 g", "1kg", "2 tbsp", "3"
    m = re.match(r"([0-9]+(?:\.[0-9]+)?)\s*([a-zA-Z]+)?", qty)
    if m:
        amount = float(m.group(1))
        unit = m.group(2) or "count"
        # Normalise weight/volume units
        if unit in ["kg"]:
            return amount * 1000, "g"
        if unit in ["g"]:
            return amount, "g"
        if unit in ["l"]:
            return amount * 1000, "ml"
        if unit in ["ml"]:
            return amount, "ml"
        if unit in ["tbsp","tablespoon"]:
            return amount, "tbsp"
        if unit in ["tsp","teaspoon"]:
            return amount, "tsp"
        if unit in ["count"]:
            return amount, "count"
        return amount, unit
    return 1.0, "count"

def clean_name(name: str):
    """Simplify ingredient names for deduping"""
    name = name.lower().strip()
    # singularise a bit
    if name.endswith("es"): 
        name = name[:-2]
    elif name.endswith("s"):
        name = name[:-1]
    return name
def sunday_of_week(d: dt.date) -> dt.date:
    return d - dt.timedelta(days=d.weekday() + 1) if d.weekday() != 6 else d
def build_basket_for_week(conn, user_id: str, week_start: dt.date) -> dict:
    """
    Build a basket for a user in a given week.
    Counts each ingredient mention as one portion (ignores grams/ml).
    Dedupes by normalised name.
    Skips pantry staples.
    Returns dict with items, estimated_total, and source_plan_id.
    """
    print(f"🔨 build_basket_for_week(user_id={user_id}, week_start={week_start})")

    cur = conn.cursor()
    cur.execute("""
        SELECT id, plan_json
        FROM plans
        WHERE user_id = ? AND start_date <= ? AND end_date >= ?
        LIMIT 1
    """, (user_id, week_start.isoformat(), week_start.isoformat()))
    row = cur.fetchone()
    if not row:
        print("❌ No plan found")
        return {"items": [], "estimated_total": 0.0, "source_plan_id": None}

    plan_id, plan_json = row
    print(f"📅 Found plan {plan_id}")

    try:
        plan = json.loads(plan_json)
    except Exception as e:
        print(f"⚠️ Error parsing plan_json: {e}")
        return {"items": [], "estimated_total": 0.0, "source_plan_id": plan_id}

    # collect meal_ids
    meal_ids = []
    for day in plan.get("days", []):
        for slot in ("breakfast", "lunch", "dinner"):
            for it in day.get(slot, []):
                if "meal_id" in it:
                    meal_ids.append(it["meal_id"])

    if not meal_ids:
        print("❌ No meals found in plan")
        return {"items": [], "estimated_total": 0.0, "source_plan_id": plan_id}

    placeholders = ",".join(["?"] * len(meal_ids))
    cur.execute(f"SELECT id, ingredients_json FROM meals WHERE id IN ({placeholders})", meal_ids)
    rows = cur.fetchall()

    PANTRY = {"salt", "pepper", "olive oil", "oil", "water", "chili flakes"}

    basket = {}
    for meal_id, ing_json in rows:
        try:
            ings = json.loads(ing_json) if ing_json else []
            for ing in ings:
                raw_name = (ing.get("ingredient") or ing.get("name") or "").strip()
                if not raw_name:
                    continue
                norm = raw_name.lower()
                print(f"   raw='{raw_name}' → norm='{norm}'")

                # skip pantry items
                if norm in PANTRY:
                    print(f"     ↳ skipped pantry: {norm}")
                    continue

                if norm not in basket:
                    basket[norm] = {
                        "name": norm,
                        "need_amount": 0.0,
                        "need_unit": "portion",
                        "aisle": ing.get("aisle") or "Other",
                        "emoji": ing.get("emoji") or "🛒",
                        "estimate": {
                            "price_per_pack": float(ing.get("price_per_pack") or 1.0),
                            "pack_amount": 1.0,
                            "pack_unit": "portion",
                            "size_label": "1 portion"
                        }
                    }
                basket[norm]["need_amount"] += 1.0
        except Exception as e:
            print(f"⚠️ Error parsing ingredients for meal {meal_id}: {e}")

    items = list(basket.values())
    est_total = sum(it["need_amount"] * it["estimate"]["price_per_pack"] for it in items)

    print(f"🧺 Built basket with {len(items)} items, est_total=£{est_total:.2f}")
    return {
        "items": items,
        "estimated_total": est_total,
        "source_plan_id": plan_id,
    }