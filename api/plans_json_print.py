import sqlite3
import json
import os

DB_PATH = os.getenv("DB_PATH", "/Users/lukeyp02/Desktop/scranly/api/data/scranly.db")
USER_ID = "testing"  # change if needed

conn = sqlite3.connect(DB_PATH)
cur = conn.cursor()

cur.execute("""
    SELECT id, plan_json
    FROM plans
    WHERE user_id = ?
    ORDER BY start_date;
""", (USER_ID,))

rows = cur.fetchall()

print(f"📋 Found {len(rows)} plans for user '{USER_ID}'\n")

for plan_id, raw_json in rows:
    print(f"--- PLAN {plan_id} ---")
    if not raw_json:
        print("(no plan_json)\n")
        continue

    try:
        obj = json.loads(raw_json)
        print(json.dumps(obj, indent=2))  # pretty print JSON
    except json.JSONDecodeError:
        print("⚠️ Invalid JSON:", raw_json)
    print("\n")

conn.close()