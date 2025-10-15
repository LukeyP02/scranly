# main.py
from __future__ import annotations

import os, math, json
import datetime as dt
from datetime import date as _date
from typing import List, Optional, Dict, Any

import sqlalchemy as sa
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# basket builder (kept as-is, now expected to use plans_by_date internally)
from basket_builder import connect, sunday_of_week, build_basket_for_week

# -----------------------
# DB setup (SQLite)
# -----------------------
DB_PATH = os.getenv("DB_PATH", "/Users/lukeyp02/Desktop/scranly/api/data/scranly.db")
engine = sa.create_engine(
    f"sqlite:///{DB_PATH}",
    connect_args={"check_same_thread": False},
    future=True,
)
metadata = sa.MetaData()
with engine.begin() as conn:
    metadata.reflect(conn)

meals = metadata.tables.get("meals")
plans = metadata.tables.get("plans")
plans_by_date = metadata.tables.get("plans_by_date")

if meals is None:
    raise RuntimeError("Table 'meals' not found.")
if plans is None:
    raise RuntimeError("Table 'plans' not found.")
if plans_by_date is None:
    raise RuntimeError("Table 'plans_by_date' not found. Run your backfill first.")

# -----------------------
# Helpers
# -----------------------
def colname(table, *cands):
    return next((n for n in cands if n in table.c), None)

ID           = colname(meals, "id") or "id"
TITLE        = colname(meals, "title")
DESC         = colname(meals, "app_description", "description", "desc")
IMAGE_PATH   = colname(meals, "image_path")
TIME_TOTAL   = colname(meals, "time_total_minutes")
TIME_ACTIVE  = colname(meals, "time_active_minutes")
CAL          = colname(meals, "cals", "calories")
PROT         = colname(meals, "proteins", "protein_g", "protein")
CARB         = colname(meals, "carbs", "carbs_g")
FAT          = colname(meals, "fats", "fat_g")
TAGS         = colname(meals, "tags")
ALLERGENS    = colname(meals, "allergens")
CUISINE      = colname(meals, "cuisine")
SUB_CUISINE  = colname(meals, "sub_cuisine")
DIET         = colname(meals, "diet")
MEAL_TYPE    = colname(meals, "meal_type")
DIFFICULTY   = colname(meals, "difficulty")

def val(row: sa.engine.RowMapping, *names: Optional[str]):
    for n in names:
        if not n:
            continue
        try:
            v = row[n]
            if v is not None:
                return v
        except KeyError:
            continue
    return None

BASE_IMAGE_URL = os.getenv("BASE_IMAGE_URL", "").rstrip("/")

def build_image_url(path) -> Optional[str]:
    if not path: return None
    s = str(path)
    if s.startswith("http://") or s.startswith("https://"): return s
    if BASE_IMAGE_URL: return f"{BASE_IMAGE_URL}/{s.lstrip('/')}"
    return None

def parse_listish(raw) -> List[str]:
    if raw is None: return []
    if isinstance(raw, list): return [str(t).strip() for t in raw if str(t).strip()]
    s = str(raw).strip()
    if not s: return []
    if s.startswith("["):
        try:
            arr = json.loads(s)
            if isinstance(arr, list):
                return [str(t).strip() for t in arr if str(t).strip()]
        except Exception:
            pass
    return [t.strip() for t in s.split(",") if t.strip()]

# -----------------------
# API & CORS
# -----------------------
app = FastAPI(title="Meals API", version="1.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"],
)

# -----------------------
# Models
# -----------------------
class RecipeOut(BaseModel):
    id: str
    title: str
    desc: str
    image_url: Optional[str] = None
    time_minutes: int
    calories: int
    protein_g: int
    carbs_g: int
    fat_g: int
    tags: List[str] = []
    cuisine: Optional[str] = None
    sub_cuisine: Optional[str] = None
    diet: Optional[str] = None
    meal_type: Optional[str] = None
    difficulty: Optional[str] = None
    allergens: List[str] = []

class PageOut(BaseModel):
    data: List[RecipeOut]
    page: int
    total_pages: int
    
# --- Add near your other models ---
class ImageOnlyOut(BaseModel):
    image_url: Optional[str] = None

class ImagesOut(BaseModel):
    images: Dict[str, Optional[str]]

def row_to_recipe(row) -> RecipeOut:
    return RecipeOut(
        id=str(val(row, ID)),
        title=str(val(row, TITLE) or ""),
        desc=str(val(row, DESC) or ""),
        image_url=build_image_url(val(row, IMAGE_PATH)),
        time_minutes=int(val(row, TIME_TOTAL) or val(row, TIME_ACTIVE) or 0),
        calories=int(val(row, CAL) or 0),
        protein_g=int(val(row, PROT) or 0),
        carbs_g=int(val(row, CARB) or 0),
        fat_g=int(val(row, FAT) or 0),
        tags=parse_listish(val(row, TAGS)),
        cuisine=(str(val(row, CUISINE)) if val(row, CUISINE) else None),
        sub_cuisine=(str(val(row, SUB_CUISINE)) if val(row, SUB_CUISINE) else None),
        diet=(str(val(row, DIET)) if val(row, DIET) else None),
        meal_type=(str(val(row, MEAL_TYPE)) if val(row, MEAL_TYPE) else None),
        difficulty=(str(val(row, DIFFICULTY)) if val(row, DIFFICULTY) else None),
        allergens=parse_listish(val(row, ALLERGENS)),
    )

# ---------- Plans DTOs ----------
class PlanEventOut(BaseModel):
    id: str                    # "{plan_id}|{date}|{slot}|{idx}"
    meal_id: str               # id from meals table (string)
    time: Optional[str] = None
    recipe: Optional[RecipeOut] = None  # ONLY present when expand=true

class PlanDayOut(BaseModel):
    date: str
    breakfast: List[PlanEventOut] = []
    lunch: List[PlanEventOut] = []
    dinner: List[PlanEventOut] = []

class PlanOut(BaseModel):
    id: int
    user_id: str
    start_date: str
    end_date: str
    length_days: int
    days: List[PlanDayOut]

class PlanSummaryOut(BaseModel):
    id: int
    user_id: str
    start_date: str
    end_date: str
    length_days: int
    created_at: Optional[str] = None

_DEFAULT_TIMES = {"breakfast": "08:00", "lunch": "12:30", "dinner": "19:00"}

# ---------- plans_by_date helpers ----------
SLOT_ORDER = {"breakfast": 0, "lunch": 1, "dinner": 2}

def _recipes_by_ids(conn, ids: List[str]) -> Dict[str, RecipeOut]:
    if not ids:
        return {}
    placeholders = ",".join([f":id{i}" for i in range(len(ids))])
    params = {f"id{i}": ids[i] for i in range(len(ids))}
    sql = sa.text(f"SELECT * FROM {meals.name} WHERE CAST({ID} AS TEXT) IN ({placeholders})")
    rows = conn.execute(sql, params).mappings().all()
    out: Dict[str, RecipeOut] = {}
    for r in rows:
        rec = row_to_recipe(r)
        out[str(rec.id)] = rec
    return out

def pbd_meal_ids_for_range(conn, user_id: str, start_iso: str, end_iso: str) -> Dict[str, Dict[str, List[str]]]:
    rows = conn.execute(sa.text("""
        SELECT date, slot, idx, meal_id
        FROM plans_by_date
        WHERE user_id = :u AND date BETWEEN :a AND :b
        ORDER BY date ASC,
                 CASE slot
                   WHEN 'breakfast' THEN 0
                   WHEN 'lunch' THEN 1
                   WHEN 'dinner' THEN 2
                   ELSE 99 END,
                 idx ASC
    """), {"u": user_id, "a": start_iso, "b": end_iso}).mappings().all()

    out: Dict[str, Dict[str, List[str]]] = {}
    for r in rows:
        d = r["date"]
        out.setdefault(d, {"breakfast": [], "lunch": [], "dinner": []})
        out[d][r["slot"]].append(str(r["meal_id"]))
    return out

def pbd_meal_ids_for_day(conn, user_id: str, day_iso: str) -> Dict[str, List[str]]:
    m = pbd_meal_ids_for_range(conn, user_id, day_iso, day_iso)
    return m.get(day_iso, {"breakfast": [], "lunch": [], "dinner": []})

# -----------------------
# Plans endpoints (now reading from plans_by_date)
# -----------------------
@app.get("/v1/plans", response_model=List[PlanSummaryOut])
def list_plans(user_id: Optional[str] = None, limit: int = Query(20, ge=1, le=100)):
    with engine.begin() as conn:
        stmt = sa.select(plans)
        if user_id:
            stmt = stmt.where(plans.c.user_id == user_id)
        stmt = stmt.order_by(plans.c.start_date.desc()).limit(limit)
        rows = conn.execute(stmt).mappings().all()
        return [
            PlanSummaryOut(
                id=int(r["id"]),
                user_id=str(r["user_id"]),
                start_date=str(r["start_date"]),
                end_date=str(r["end_date"]),
                length_days=int(r["length_days"]),
                created_at=str(r.get("created_at")) if r.get("created_at") is not None else None,
            )
            for r in rows
        ]


@app.get("/v1/plans/current", response_model=PlanOut)
def get_current_plan(user_id: str, as_of: Optional[str] = None, expand: bool = False):
    if as_of is None:
        as_of = _date.today().isoformat()
    with engine.begin() as conn:
        row = conn.execute(
            sa.select(plans)
            .where(
                plans.c.user_id == user_id,
                plans.c.start_date <= as_of,
                plans.c.end_date >= as_of
            )
            .order_by(plans.c.start_date.desc())
            .limit(1)
        ).mappings().first()

        if not row:
            # ✅ return empty valid object (instead of 404)
            return {
                "id": -1,
                "user_id": user_id,
                "start_date": as_of,
                "end_date": as_of,
                "length_days": 0,
                "days": []
            }

        # reuse existing behavior if plan exists
        return get_plan(plan_id=int(row["id"]), expand=expand)

@app.get("/v1/plans/{plan_id}", response_model=PlanOut)
def get_plan(plan_id: int, expand: bool = False):
    """
    Fetch a specific plan by its ID.
    Returns an empty PlanOut instead of raising 404 when not found.
    """
    with engine.begin() as conn:
        row = conn.execute(sa.select(plans).where(plans.c.id == plan_id)).mappings().first()

        if not row:
            print(f"⚠️ Plan id={plan_id} not found — returning empty PlanOut instead of 404")
            today = _date.today().isoformat()
            return PlanOut(
                id=plan_id,
                user_id="unknown",
                start_date=today,
                end_date=today,
                length_days=0,
                days=[],
            )

        # --- Extract basic fields ---
        user_id   = str(row["user_id"])
        start_iso = str(row["start_date"])
        end_iso   = str(row["end_date"])

        # --- Load meal IDs for each date/slot from plans_by_date ---
        date_map = pbd_meal_ids_for_range(conn, user_id, start_iso, end_iso)

        # --- If expand=true, fetch recipes for all unique meal_ids ---
        uniq_ids: list[str] = []
        for slots in date_map.values():
            for s in ("breakfast", "lunch", "dinner"):
                uniq_ids.extend(slots.get(s, []))
        seen = set()
        uniq_ids = [x for x in uniq_ids if not (x in seen or seen.add(x))]

        rec_map = _recipes_by_ids(conn, uniq_ids) if expand and uniq_ids else {}

        # --- Build PlanDayOut list ---
        days_out: list[PlanDayOut] = []
        for d in sorted(date_map.keys()):
            slots = date_map[d]

            def to_events(slot_name: str) -> list[PlanEventOut]:
                arr: list[PlanEventOut] = []
                for idx, mid in enumerate(slots.get(slot_name, [])):
                    arr.append(PlanEventOut(
                        id=f"{plan_id}|{d}|{slot_name}|{idx}",
                        meal_id=str(mid),
                        time=_DEFAULT_TIMES[slot_name],
                        recipe=rec_map.get(str(mid)) if expand else None
                    ))
                return arr

            days_out.append(PlanDayOut(
                date=d,
                breakfast=to_events("breakfast"),
                lunch=to_events("lunch"),
                dinner=to_events("dinner"),
            ))

        # --- Return final structured plan ---
        plan_out = PlanOut(
            id=int(row["id"]),
            user_id=user_id,
            start_date=start_iso,
            end_date=end_iso,
            length_days=int(row["length_days"]),
            days=days_out
        )

        print(f"✅ /v1/plans/{plan_id} OK → days={len(days_out)} expand={expand}")
        return plan_out
    
# --- Single image by recipe/meal id ---
@app.get("/v1/recipes/{recipe_id}/image", response_model=ImageOnlyOut)
def recipe_image(recipe_id: str):
    """
    Returns the image URL for a given recipe.
    Always returns 200 OK — even if recipe not found or image missing.
    """
    try:
        with engine.begin() as conn:
            row = conn.execute(
                sa.select(meals).where(meals.c[ID] == recipe_id)
            ).mappings().first()

            if not row:
                print(f"⚠️ Recipe {recipe_id} not found → returning null image_url")
                return ImageOnlyOut(image_url=None)

            image_url = build_image_url(val(row, IMAGE_PATH))
            if not image_url:
                print(f"⚠️ Recipe {recipe_id} found but no image path → returning null")
                return ImageOnlyOut(image_url=None)

            print(f"✅ Recipe {recipe_id} image: {image_url}")
            return ImageOnlyOut(image_url=image_url)

    except Exception as e:
        import traceback; traceback.print_exc()
        print(f"❌ Error in /v1/recipes/{recipe_id}/image: {repr(e)}")
        # Return graceful fallback instead of HTTP 500
        return ImageOnlyOut(image_url=None)
    
# --- Batch: /v1/recipes/images?ids=12&ids=34&ids=99 ---
@app.get("/v1/recipes/images", response_model=ImagesOut)
def recipe_images(ids: List[str] = Query(..., description="Repeat ?ids= for each id")):
    if not ids:
        return ImagesOut(images={})

    placeholders = ",".join(f":id{i}" for i in range(len(ids)))
    params = {f"id{i}": ids[i] for i in range(len(ids))}

    with engine.begin() as conn:
        sql = sa.text(f"""
            SELECT CAST({ID} AS TEXT) AS rid, {IMAGE_PATH} AS img
            FROM {meals.name}
            WHERE CAST({ID} AS TEXT) IN ({placeholders})
        """)
        rows = conn.execute(sql, params).mappings().all()

    out: Dict[str, Optional[str]] = {str(i): None for i in ids}
    for r in rows:
        out[str(r["rid"])] = build_image_url(r["img"])
    return ImagesOut(images=out)

# -----------------------
# Health
# -----------------------
@app.get("/v1/health")
def health():
    return {"ok": True}

# -----------------------
# Recipes
# -----------------------
@app.get("/v1/recipes", response_model=PageOut)
def list_recipes(
    page: int = Query(1, ge=1),
    limit: int = Query(50, ge=1, le=200),
    q: Optional[str] = None,
    tag: Optional[str] = None,
    sort: Optional[str] = "title_asc",
):
    try:
        with engine.begin() as conn:
            stmt = sa.select(meals)
            where = []
            params: Dict[str, Any] = {}

            if q and (TITLE or DESC):
                like = f"%{q.lower()}%"
                or_conds = []
                if TITLE:
                    or_conds.append(sa.func.lower(meals.c[TITLE]).like(like))
                if DESC:
                    or_conds.append(sa.func.lower(meals.c[DESC]).like(like))
                if or_conds:
                    where.append(sa.or_(*or_conds))

            if tag and TAGS:
                where.append(meals.c[TAGS].like(sa.bindparam("t")))
                params["t"] = f"%{tag}%"

            if where:
                stmt = stmt.where(sa.and_(*where))

            if sort == "title_asc" and TITLE:
                stmt = stmt.order_by(meals.c[TITLE].asc())
            elif sort == "protein_desc" and PROT:
                stmt = stmt.order_by(meals.c[PROT].desc())
            elif sort == "time_asc" and (TIME_TOTAL or TIME_ACTIVE):
                time_expr = sa.func.coalesce(
                    meals.c.get(TIME_TOTAL) if TIME_TOTAL else None,
                    meals.c.get(TIME_ACTIVE) if TIME_ACTIVE else None,
                )
                if time_expr is not None:
                    stmt = stmt.order_by(time_expr.asc())

            stmt_count = sa.select(sa.func.count()).select_from(meals)
            if where:
                stmt_count = stmt_count.where(sa.and_(*where))

            total = conn.execute(stmt_count, params).scalar_one()
            total_pages = max(1, math.ceil(total / limit))

            rows = conn.execute(
                stmt.limit(limit).offset((page - 1) * limit),
                params
            ).mappings().all()

            return PageOut(
                data=[row_to_recipe(r) for r in rows],
                page=page,
                total_pages=total_pages
            )
    except Exception as e:
        print("ERROR /v1/recipes:", repr(e))
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/v1/recipes/deck", response_model=List[RecipeOut])
def random_deck(limit: int = Query(40, ge=1, le=200)):
    try:
        with engine.begin() as conn:
            rows = conn.execute(
                sa.text(f"SELECT * FROM {meals.name} ORDER BY RANDOM() LIMIT :lim"),
                {"lim": limit}
            ).mappings().all()
            return [row_to_recipe(r) for r in rows]
    except Exception as e:
        print("ERROR /v1/recipes/deck:", repr(e))
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/v1/recipes/{recipe_id}", response_model=RecipeOut)
def get_recipe(recipe_id: str):
    """
    Returns a single recipe by ID.
    Always returns 200 OK — even if not found (returns empty/default RecipeOut).
    """
    try:
        with engine.begin() as conn:
            row = conn.execute(
                sa.select(meals).where(meals.c[ID] == recipe_id)
            ).mappings().first()

            if not row:
                print(f"⚠️ Recipe {recipe_id} not found → returning empty RecipeOut")
                return RecipeOut(
                    id=str(recipe_id),
                    title="Recipe not found",
                    desc="This recipe is unavailable or has been removed.",
                    image_url=None,
                    time_minutes=0,
                    calories=0,
                    protein_g=0,
                    carbs_g=0,
                    fat_g=0,
                    tags=[],
                    cuisine=None,
                    sub_cuisine=None,
                    diet=None,
                    meal_type=None,
                    difficulty=None,
                    allergens=[],
                )

            recipe = row_to_recipe(row)
            print(f"✅ /v1/recipes/{recipe_id} OK → {recipe.title}")
            return recipe

    except Exception as e:
        import traceback; traceback.print_exc()
        print(f"❌ Error in /v1/recipes/{recipe_id}: {repr(e)}")
        # Return safe empty fallback
        return RecipeOut(
            id=str(recipe_id),
            title="Error loading recipe",
            desc="Something went wrong retrieving this recipe.",
            image_url=None,
            time_minutes=0,
            calories=0,
            protein_g=0,
            carbs_g=0,
            fat_g=0,
            tags=[],
            cuisine=None,
            sub_cuisine=None,
            diet=None,
            meal_type=None,
            difficulty=None,
            allergens=[],
        )

# -----------------------
# Basket (unchanged surface; builder should now use plans_by_date)
# -----------------------
@app.get("/v1/basket")
def get_basket(user_id: str = Query(...), week_start: Optional[str] = None):
    """
    Returns a shopping basket for the given user/week.
    Gracefully handles missing or empty plans by returning an empty basket instead of 404/500.
    """
    try:
        ws = (
            dt.datetime.strptime(week_start, "%Y-%m-%d").date()
            if week_start else sunday_of_week(dt.date.today())
        )
        print(f"🧺 GET /v1/basket user_id={user_id} week_start={ws}")
        conn = connect()
    except Exception as e:
        print(f"❌ Error before DB connect: {repr(e)}")
        return {
            "user_id": user_id,
            "week_start": week_start or dt.date.today().isoformat(),
            "items": [],
            "estimated_total": 0.0,
            "message": f"Error preparing basket: {e}"
        }

    try:
        out = build_basket_for_week(conn, user_id, ws)
        print(f"✅ build_basket_for_week output: {out}")

        # --- Handle missing meals safely ---
        if not out or not out.get("items"):
            print(f"⚠️ No meals/items found for user={user_id}, week={ws} → returning empty basket")
            return {
                "user_id": user_id,
                "week_start": ws.isoformat(),
                "items": [],
                "estimated_total": 0.0,
                "message": "No meals found for this week — plan meals to generate a basket."
            }

        # --- Normal response ---
        resp = {"user_id": user_id, "week_start": ws.isoformat(), **out}
        print(f"📦 Final basket response: {resp}")
        return resp

    except Exception as e:
        import traceback; traceback.print_exc()
        print(f"❌ Exception building basket: {repr(e)}")
        # Return empty fallback instead of 500
        return {
            "user_id": user_id,
            "week_start": ws.isoformat(),
            "items": [],
            "estimated_total": 0.0,
            "message": f"Basket error: {e}"
        }

    finally:
        conn.close()

@app.post("/v1/basket/rebuild")
def rebuild_basket(user_id: str = Query(...), week_start: Optional[str] = None):
    """
    Rebuilds and stores a basket for the given user/week.
    Always returns 200 OK — returns an empty basket if no meals are found.
    """
    ws = (
        dt.datetime.strptime(week_start, "%Y-%m-%d").date()
        if week_start else _date.today()
    )
    print(f"🧺 POST /v1/basket/rebuild user_id={user_id} week_start={ws}")

    conn = connect()
    try:
        out = build_basket_for_week(conn, user_id, ws)
        print(f"✅ build_basket_for_week output: {out}")

        # --- Handle missing meals/items safely ---
        if not out or not out.get("items"):
            print(f"⚠️ No meals found for user={user_id}, week={ws} → returning empty basket")
            return {
                "user_id": user_id,
                "week_start": ws.isoformat(),
                "items": [],
                "estimated_total": 0.0,
                "message": "No meals found for this week — plan meals to generate your basket."
            }

        # --- Persist rebuilt basket ---
        try:
            with engine.begin() as econn:
                econn.execute(sa.text("""
                    INSERT INTO baskets (user_id, week_start, basket_json, estimated_total)
                    VALUES (:u, :w, :j, :t)
                """), {
                    "u": user_id,
                    "w": ws.isoformat(),
                    "j": json.dumps(out, separators=(",", ":")),
                    "t": out.get("estimated_total", 0.0),
                })
            print(f"💾 Saved basket for {user_id} @ {ws.isoformat()}")
        except Exception as e:
            import traceback; traceback.print_exc()
            print(f"⚠️ Could not save basket to DB: {repr(e)} (continuing anyway)")

        # --- Return normal basket result ---
        return {
            "user_id": user_id,
            "week_start": ws.isoformat(),
            **out
        }

    except Exception as e:
        import traceback; traceback.print_exc()
        print(f"❌ Error rebuilding basket: {repr(e)}")
        # Return a graceful fallback instead of 500
        return {
            "user_id": user_id,
            "week_start": ws.isoformat(),
            "items": [],
            "estimated_total": 0.0,
            "message": f"Error rebuilding basket: {e}"
        }

    finally:
        conn.close()

# -----------------------
# Track (now sums from plans_by_date -> meals.nutrition_json)
# -----------------------
class TrackEntryOut(BaseModel):
    user_id: str
    date: str          # YYYY-MM-DD
    calories: float
    protein: float     # grams
    carbs: float       # grams
    fats: float        # grams

def _sum_nutrition_blob(blob) -> tuple[float, float, float, float]:
    """
    Accepts any of:
      1) {"totals": {kcal, protein_g, carbs_g, fat_g}, "by_ingredient": [...]}
      2) dict with kcal/protein_g/carbs_g/fat_g at top-level
      3) list[dict] of the same (sum them)

    Returns: (calories, protein_g, carbs_g, fat_g)
    """
    def extract_one(d: dict) -> tuple[float, float, float, float]:
        kcal   = float(d.get("kcal") or 0.0)
        prot_g = float(d.get("protein_g") or 0.0)
        carb_g = float(d.get("carbs_g") or 0.0)
        fat_g  = float(d.get("fat_g") or 0.0)
        return kcal, prot_g, carb_g, fat_g

    # case 1: dict with "totals"
    if isinstance(blob, dict):
        if "totals" in blob and isinstance(blob["totals"], dict):
            return extract_one(blob["totals"])

        # no "totals": maybe values are at the top-level
        c, p, cb, f = extract_one(blob)
        # if that was all zeros, try summing by_ingredient if present
        if (c, p, cb, f) == (0.0, 0.0, 0.0, 0.0) and isinstance(blob.get("by_ingredient"), list):
            tc = tp = tcb = tf = 0.0
            for ing in blob["by_ingredient"]:
                if isinstance(ing, dict):
                    ic, ip, icb, iff = extract_one(ing)
                    tc += ic; tp += ip; tcb += icb; tf += iff
            return tc, tp, tcb, tf
        return c, p, cb, f

    # case 2: list of dicts → sum each
    if isinstance(blob, list):
        tc = tp = tcb = tf = 0.0
        for it in blob:
            if isinstance(it, dict):
                c, p, cb, f = extract_one(it)
                tc += c; tp += p; tcb += cb; tf += f
        return tc, tp, tcb, tf

    # unknown shape
    return 5.0, 0.0, 0.0, 0.0

# --- minimal, strict "totals"-only tracker ---

class TrackEntryOut(BaseModel):
    user_id: str
    date: str          # YYYY-MM-DD
    calories: float
    protein: float     # grams
    carbs: float       # grams
    fats: float        # grams


def _meal_ids_for_date(plan_json: str | dict | None, day_iso: str) -> list[str]:
    if not plan_json:
        return []
    try:
        plan = json.loads(plan_json) if isinstance(plan_json, str) else plan_json
    except Exception:
        return []
    mids: list[str] = []
    for d in plan.get("days", []):
        if str(d.get("date")) != day_iso:
            continue
        for slot in ("breakfast", "lunch", "dinner"):
            for it in d.get(slot, []) or []:
                mid = it.get("meal_id")
                if mid is not None:
                    mids.append(str(mid))
    # de-dupe, keep order
    seen = set()
    out = []
    for m in mids:
        if m in seen: 
            continue
        seen.add(m)
        out.append(m)
    return out


@app.get("/v1/track", response_model=List[TrackEntryOut])
def get_track(user_id: str, days: int = 7):
    """
    For each day in [today-(days-1) ... today]:
      - find that day's plan (if any)
      - collect the day's meal_ids
      - sum meals.nutrition_json["totals"] (kcal, protein_g, carbs_g, fat_g)
      - if no meals, return zeros for that day
    """
    days = max(1, int(days))
    today = dt.date.today()
    start_date = today - dt.timedelta(days=days - 1)

    conn = connect()
    cur = conn.cursor()

    out: list[dict] = []
    for i in range(days):
        d = start_date + dt.timedelta(days=i)
        ds = d.isoformat()

        # 1) plan covering that day (if any)
        cur.execute("""
            SELECT plan_json
            FROM plans
            WHERE user_id = ?
              AND start_date <= ?
              AND end_date   >= ?
            ORDER BY start_date DESC
            LIMIT 1
        """, (user_id, ds, ds))
        row = cur.fetchone()
        plan_json = row[0] if row else None

        # 2) meal ids for that date
        meal_ids = _meal_ids_for_date(plan_json, ds)

        # 3) sum totals from nutrition_json
        kcal = prot = carbs = fats = 0.0
        if meal_ids:
            placeholders = ",".join(["?"] * len(meal_ids))
            cur.execute(f"""
                SELECT nutrition_json
                FROM meals
                WHERE CAST(id AS TEXT) IN ({placeholders})
            """, meal_ids)
            for (nj,) in cur.fetchall():
                if not nj:
                    continue
                try:
                    blob = json.loads(nj)
                    t = blob.get("totals") or {}
                    kcal  += float(t.get("kcal", 0.0))
                    prot  += float(t.get("protein_g", 0.0))
                    carbs += float(t.get("carbs_g", 0.0))
                    fats  += float(t.get("fat_g", 0.0))
                except Exception:
                    # bad/missing json: skip
                    pass
        # 4) always emit a row (even if zeros)
        out.append({
            "user_id": user_id,
            "date": ds,
            "calories": kcal,
            "protein": prot,
            "carbs": carbs,
            "fats": fats,
        })

    conn.close()
    return out

# ==== Home stats: /v1/stats/summary ==========================================

class StatsSummaryOut(BaseModel):
    user_id: str
    meals_cooked: int
    money_saved: float
    time_saved_min: int
    calories_avg_7d: float | None = None
    protein_avg_7d: float | None = None

def _totals_from_nutrition_json(nj: str | None) -> tuple[float, float, float, float]:
    """
    nutrition_json shape (what you showed):

    {
      "totals": { "kcal": 772.8, "protein_g": 21.0, "carbs_g": 86.48, "fat_g": 42.1 },
      "by_ingredient": [...]
    }
    """
    if not nj:
        return (0.0, 0.0, 0.0, 0.0)
    try:
        blob = json.loads(nj)
        if isinstance(blob, dict) and isinstance(blob.get("totals"), dict):
            t = blob["totals"]
            kcal = float(t.get("kcal") or t.get("calories") or 0.0)
            p    = float(t.get("protein_g") or t.get("protein") or 0.0)
            c    = float(t.get("carbs_g")   or t.get("carbs")   or 0.0)
            f    = float(t.get("fat_g")     or t.get("fats")    or t.get("fat") or 0.0)
            return (kcal, p, c, f)
    except Exception:
        pass
    return (0.0, 0.0, 0.0, 0.0)

def _has_table(conn, name: str) -> bool:
    insp = sa.inspect(conn)
    try:
        return insp.has_table(name)
    except Exception:
        return False

import traceback
from decimal import Decimal

def _has_table(conn, name: str) -> bool:
    try:
        insp = sa.inspect(conn)
        return insp.has_table(name)
    except Exception as e:
        print(f"⚠️ _has_table({name}) failed: {repr(e)}")
        return False

@app.get("/v1/stats/summary", response_model=StatsSummaryOut)
def stats_summary(user_id: str):
    """
    Lifetime-ish stats + quick weekly averages for the Home screen.
    - meals_cooked: COUNT of rows in plans_by_date up to today
    - money_saved / time_saved_min: optional, if you created a 'user_stats' table
    - calories_avg_7d / protein_avg_7d: average from last 7 days of planned meals
    """
    print(f"🟠 /v1/stats/summary user_id={user_id}")
    today = dt.date.today().isoformat()
    start_7d = (dt.date.today() - dt.timedelta(days=6)).isoformat()
    print(f"  → today={today}  start_7d={start_7d}")

    try:
        with engine.begin() as conn:
            # ---------- meals_cooked ----------
            meals_cooked = 0
            if _has_table(conn, "plans_by_date"):
                sql = sa.text("""
                    SELECT COUNT(*) AS cnt
                    FROM plans_by_date
                    WHERE user_id = :u AND date <= :t
                """)
                print("  SQL meals_cooked:", sql.text, {"u": user_id, "t": today})
                meals_cooked = conn.execute(sql, {"u": user_id, "t": today}).scalar_one() or 0
                try:
                    meals_cooked = int(meals_cooked)
                except Exception:
                    # handle Decimal or weird types
                    meals_cooked = int(float(meals_cooked))
            print(f"  ✓ meals_cooked={meals_cooked}")

            # ---------- money/time saved (user_stats) ----------
            money_saved = 0.0
            time_saved_min = 0
            if _has_table(conn, "user_stats"):
                sql = sa.text("""
                    SELECT COALESCE(SUM(saved_gbp),0) AS money_sum,
                           COALESCE(SUM(time_saved_minutes),0) AS time_sum
                    FROM user_stats
                    WHERE user_id = :u
                """)
                print("  SQL user_stats:", sql.text, {"u": user_id})
                row = conn.execute(sql, {"u": user_id}).first()
                if row:
                    m, t = row[0], row[1]
                    # Convert Decimal/None safely
                    if isinstance(m, Decimal): m = float(m)
                    if isinstance(t, Decimal): t = float(t)
                    money_saved = float(m or 0.0)
                    time_saved_min = int(float(t or 0))
            print(f"  ✓ money_saved={money_saved}  time_saved_min={time_saved_min}")

            # ---------- last 7 days averages from plans_by_date → meals.nutrition_json.totals ----------
            cals_total = 0.0
            prot_total = 0.0
            days_count = 0

            if _has_table(conn, "plans_by_date"):
                sql_pairs = sa.text("""
                    SELECT date, meal_id
                    FROM plans_by_date
                    WHERE user_id = :u AND date BETWEEN :s AND :t
                    ORDER BY date ASC
                """)
                print("  SQL 7d pairs:", sql_pairs.text, {"u": user_id, "s": start_7d, "t": today})
                pairs = conn.execute(sql_pairs, {"u": user_id, "s": start_7d, "t": today}).all()
                print(f"  ✓ pairs rows={len(pairs)}")

                # group meal_ids by date
                by_day: dict[str, list[str]] = {}
                for r in pairs:
                    # support Row/Mapping/tuple
                    d = str(r[0]) if len(r) > 0 else str(getattr(r, "date", ""))
                    mid_val = r[1] if len(r) > 1 else getattr(r, "meal_id", None)
                    if mid_val is None:
                        continue
                    ds = str(d)
                    by_day.setdefault(ds, []).append(str(mid_val))
                print(f"  ✓ grouped days={len(by_day)}  example={next(iter(by_day.items()), None)}")

                # prefetch meals for all involved ids
                all_ids = sorted({mid for mids in by_day.values() for mid in mids})
                print(f"  ✓ unique meal_ids={len(all_ids)}  example={all_ids[:5]}")
                nj_by_id: dict[str, str] = {}
                if all_ids:
                    placeholders = ",".join(f":m{i}" for i in range(len(all_ids)))
                    params = {f"m{i}": all_ids[i] for i in range(len(all_ids))}
                    sql_meals = sa.text(
                        f"SELECT CAST(id AS TEXT) AS id, nutrition_json FROM {meals.name} "
                        f"WHERE CAST(id AS TEXT) IN ({placeholders})"
                    )
                    print("  SQL meals(fanout):", sql_meals.text, params)
                    for rr in conn.execute(sql_meals, params).mappings():
                        nj_by_id[str(rr["id"])] = rr.get("nutrition_json")
                print(f"  ✓ prefetched nutrition_json count={len(nj_by_id)}")

                # sum per day; count only days with at least one planned meal
                for ds, mids in by_day.items():
                    day_cals = 0.0
                    day_p = 0.0
                    for mid in mids:
                        c, p, _, _ = _totals_from_nutrition_json(nj_by_id.get(mid))
                        day_cals += c
                        day_p    += p
                    if mids:
                        cals_total += day_cals
                        prot_total += day_p
                        days_count += 1
                    print(f"    • {ds}: meals={len(mids)} kcal={day_cals:.1f} P={day_p:.1f}")

            calories_avg_7d = (cals_total / days_count) if days_count else None
            protein_avg_7d  = (prot_total / days_count) if days_count else None
            print(f"  ✓ 7d avgs: days_count={days_count}  cal_avg={calories_avg_7d}  prot_avg={protein_avg_7d}")

            resp = StatsSummaryOut(
                user_id=user_id,
                meals_cooked=int(meals_cooked),
                money_saved=money_saved,
                time_saved_min=int(time_saved_min),
                calories_avg_7d=calories_avg_7d,
                protein_avg_7d=protein_avg_7d,
            )
            print("✅ /v1/stats/summary OK →", resp.model_dump())
            return resp

    except Exception as e:
        print("❌ /v1/stats/summary ERROR:", repr(e))
        traceback.print_exc()
        # surface error to client with 500 but keep logs detailed
        raise HTTPException(status_code=500, detail=str(e))
    
