#!/usr/bin/env python3
import os, json, sqlite3, argparse
from datetime import date

DB_PATH_DEFAULT = "/Users/lukeyp02/Desktop/scranly/api/data/scranly.db"

def get_conn(db_path: str):
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    return conn

def table_has_column(conn, table: str, col: str) -> bool:
    cur = conn.execute(f"PRAGMA table_info({table})")
    return any(row["name"] == col for row in cur.fetchall())

def ensure_columns(conn):
    # Add columns to plans if they don't exist
    alters = []
    if not table_has_column(conn, "plans", "meals_count"):
        alters.append("ALTER TABLE plans ADD COLUMN meals_count INTEGER DEFAULT 0")
    if not table_has_column(conn, "plans", "money_saved"):
        alters.append("ALTER TABLE plans ADD COLUMN money_saved REAL DEFAULT 0.0")
    if not table_has_column(conn, "plans", "time_saved_min"):
        alters.append("ALTER TABLE plans ADD COLUMN time_saved_min INTEGER DEFAULT 0")

    for ddl in alters:
        conn.execute(ddl)
    if alters:
        conn.commit()

def find_current_plan(conn, user_id: str):
    today = date.today().isoformat()
    cur = conn.execute("""
        SELECT id, user_id, start_date, end_date, length_days, plan_json
        FROM plans
        WHERE user_id = ?
          AND start_date <= ?
          AND end_date   >= ?
        ORDER BY start_date DESC
        LIMIT 1
    """, (user_id, today, today))
    return cur.fetchone()

def count_meals_in_plan_json(raw_json: str | None) -> int:
    if not raw_json:
        return 0
    try:
        obj = json.loads(raw_json)
    except Exception:
        return 0

    days = obj.get("days", [])
    total = 0
    for d in days:
        for slot in ("breakfast", "lunch", "dinner"):
            items = d.get(slot) or []
            # Count each entry in the slot as a planned meal
            total += sum(1 for _ in items)
    return total

def annotate_plan(conn, plan_id: int, meals_count: int, money_saved: float, time_saved_min: int):
    conn.execute("""
        UPDATE plans
        SET meals_count = ?, money_saved = ?, time_saved_min = ?
        WHERE id = ?
    """, (meals_count, money_saved, time_saved_min, plan_id))
    conn.commit()

def verify_print(conn, plan_id: int):
    cur = conn.execute("""
        SELECT id, user_id, start_date, end_date, length_days,
               COALESCE(meals_count,0) AS meals_count,
               COALESCE(money_saved,0.0) AS money_saved,
               COALESCE(time_saved_min,0) AS time_saved_min
        FROM plans
        WHERE id = ?
    """, (plan_id,))
    row = cur.fetchone()
    if not row:
        print("❌ Verification failed: plan not found after update.")
        return
    print("\n✅ Verification")
    print("---------------")
    print(f"plan_id        : {row['id']}")
    print(f"user_id        : {row['user_id']}")
    print(f"start_date     : {row['start_date']}")
    print(f"end_date       : {row['end_date']}")
    print(f"length_days    : {row['length_days']}")
    print(f"meals_count    : {row['meals_count']}")
    print(f"money_saved    : £{row['money_saved']:.2f}")
    print(f"time_saved_min : {row['time_saved_min']} min")

def main():
    parser = argparse.ArgumentParser(description="Annotate CURRENT plan with meals_count, money_saved, time_saved_min.")
    parser.add_argument("--db", default=os.getenv("DB_PATH", DB_PATH_DEFAULT), help="Path to SQLite DB")
    parser.add_argument("--user", default="testing", help="User ID to target")
    parser.add_argument("--money", type=float, default=11.89, help="Money saved to write (e.g., 11.89)")
    parser.add_argument("--time", type=int, default=67, help="Time saved (minutes) to write (e.g., 67)")
    args = parser.parse_args()

    conn = get_conn(args.db)
    try:
        ensure_columns(conn)

        plan = find_current_plan(conn, args.user)
        if not plan:
            print(f"⚠️ No current plan for user '{args.user}'. Nothing to annotate.")
            return

        meals_count = count_meals_in_plan_json(plan["plan_json"])

        # Write values
        annotate_plan(conn, plan_id=plan["id"],
                      meals_count=meals_count,
                      money_saved=args.money,
                      time_saved_min=args.time)

        # Print verification
        print(f"📝 Annotated plan {plan['id']} for user '{args.user}'")
        print(f"   • meals_count   = {meals_count}")
        print(f"   • money_saved   = £{args.money:.2f}")
        print(f"   • time_saved_min= {args.time} min")

        verify_print(conn, plan_id=plan["id"])
    finally:
        conn.close()

if __name__ == "__main__":
    main()