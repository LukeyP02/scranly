# print_nutrition.py
import argparse, json, sqlite3, sys

DB_PATH = "/Users/lukeyp02/Desktop/scranly/api/data/scranly.db"

def connect(db_path=DB_PATH):
    return sqlite3.connect(db_path)

def detect_nutrition_column(cur):
    cur.execute("PRAGMA table_info(meals)")
    cols = {r[1] for r in cur.fetchall()}
    if "nutrition_json" in cols:
        return "nutrition_json"
    if "nutrition" in cols:
        return "nutrition"
    return None

def pretty(obj):
    try:
        return json.dumps(obj, indent=2, ensure_ascii=False)
    except Exception:
        return str(obj)

def main():
    ap = argparse.ArgumentParser(description="Print meals.nutrition_json/nutrition entries")
    ap.add_argument("--db", default=DB_PATH, help="Path to SQLite DB")
    ap.add_argument("--id", nargs="*", help="Meal id(s) to print (match meals.id)")
    ap.add_argument("--limit", type=int, default=5, help="How many samples to show if not filtering by id")
    args = ap.parse_args()

    conn = connect(args.db)
    cur = conn.cursor()

    nutr_col = detect_nutrition_column(cur)
    if not nutr_col:
        print("❌ No 'nutrition_json' or 'nutrition' column found on meals table.")
        sys.exit(1)

    print(f"🧬 Using column: meals.{nutr_col}")

    if args.id:
        # Show exactly these ids
        placeholders = ",".join(["?"] * len(args.id))
        sql = f"SELECT id, title, {nutr_col} FROM meals WHERE CAST(id AS TEXT) IN ({placeholders})"
        cur.execute(sql, [str(x) for x in args.id])
    else:
        # Sample some non-null entries
        sql = f"""
            SELECT id, title, {nutr_col}
            FROM meals
            WHERE {nutr_col} IS NOT NULL AND TRIM({nutr_col}) <> ''
            ORDER BY id
            LIMIT ?
        """
        cur.execute(sql, (args.limit,))

    rows = cur.fetchall()
    if not rows:
        print("ℹ️ No rows found with non-empty nutrition.")
        sys.exit(0)

    for mid, title, blob in rows:
        print("\n" + "="*72)
        print(f"🆔 id: {mid}")
        print(f"📝 title: {title}")
        try:
            data = json.loads(blob)
        except Exception as e:
            print(f"⚠️ Could not parse {nutr_col} as JSON ({e}); raw value below:")
            print(blob)
            continue

        # Support either dict or list-of-dicts
        if isinstance(data, dict):
            print("📦 nutrition_json (dict):")
            print(pretty(data))
        elif isinstance(data, list):
            print(f"📦 nutrition_json (list, {len(data)} items) — first item:")
            print(pretty(data[0] if data else {}))
        else:
            print(f"⚠️ Unexpected JSON type: {type(data)}")
            print(pretty(data))

    # Quick counts
    cur.execute(f"SELECT COUNT(*) FROM meals WHERE {nutr_col} IS NOT NULL AND TRIM({nutr_col}) <> ''")
    cnt_nonnull = cur.fetchone()[0]
    cur.execute("SELECT COUNT(*) FROM meals")
    cnt_total = cur.fetchone()[0]
    print("\n" + "-"*72)
    print(f"Summary: {cnt_nonnull} / {cnt_total} meals have non-empty {nutr_col}")

    conn.close()

if __name__ == "__main__":
    main()