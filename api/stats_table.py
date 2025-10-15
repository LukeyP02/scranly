# create_user_stats.py
import os
import sqlite3
from datetime import datetime

DB_PATH = os.getenv("DB_PATH", "/Users/lukeyp02/Desktop/scranly/api/data/scranly.db")

DDL = """
CREATE TABLE IF NOT EXISTS user_stats (
    user_id             TEXT PRIMARY KEY,
    saved_gbp           REAL    NOT NULL DEFAULT 0,     -- total £ saved
    time_saved_minutes  INTEGER NOT NULL DEFAULT 0,     -- e.g. vs baseline
    meals_planned       INTEGER NOT NULL DEFAULT 0,     -- lifetime/planned count
    updated_at          TEXT    NOT NULL                -- ISO8601
);
"""

UPSERT = """
INSERT INTO user_stats (user_id, saved_gbp, time_saved_minutes, meals_planned, updated_at)
VALUES (?, ?, ?, ?, ?)
ON CONFLICT(user_id) DO UPDATE SET
    saved_gbp = excluded.saved_gbp,
    time_saved_minutes = excluded.time_saved_minutes,
    meals_planned = excluded.meals_planned,
    updated_at = excluded.updated_at;
"""

SEED_ROWS = [
    # seed your demo user “testing” with the same numbers you show in Home
    ("testing", 184.0, 46, 73, datetime.utcnow().isoformat(timespec="seconds") + "Z"),
]

def main():
    print(f"🔌 connecting → {DB_PATH}")
    conn = sqlite3.connect(DB_PATH)
    try:
        cur = conn.cursor()
        print("🧱 creating table user_stats (if missing)")
        cur.execute(DDL)

        print("🌱 seeding initial rows")
        cur.executemany(UPSERT, SEED_ROWS)

        conn.commit()
        print("✅ done")
    finally:
        conn.close()

if __name__ == "__main__":
    main()