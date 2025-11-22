# create_user_stats.py
import os
import sqlite3
from datetime import datetime

DB_PATH = os.getenv("DB_PATH", "/Users/lukeyp02/Desktop/scranly/api/data/scranly.db")

DDL = """
CREATE TABLE IF NOT EXISTS user_stats (
    user_id               TEXT PRIMARY KEY,
    saved_gbp             REAL    NOT NULL DEFAULT 0,     -- total £ saved
    time_saved_minutes    INTEGER NOT NULL DEFAULT 0,     -- e.g. vs baseline
    meals_planned         INTEGER NOT NULL DEFAULT 0,     -- lifetime/planned count
    personalisation_score INTEGER NOT NULL DEFAULT 65,    -- 0–100
    updated_at            TEXT    NOT NULL                -- ISO8601
);
"""

SEED_ROWS = [
    # seed your demo user “testing” with the same numbers you show in Home
    # (saved_gbp, time_saved_minutes, meals_planned, personalisation_score, updated_at)
    ("testing", 184.0, 46, 73, 65, datetime.utcnow().isoformat(timespec="seconds") + "Z"),
]

UPSERT = """
INSERT INTO user_stats (
    user_id, saved_gbp, time_saved_minutes, meals_planned, personalisation_score, updated_at
) VALUES (?, ?, ?, ?, ?, ?)
ON CONFLICT(user_id) DO UPDATE SET
    saved_gbp = excluded.saved_gbp,
    time_saved_minutes = excluded.time_saved_minutes,
    meals_planned = excluded.meals_planned,
    personalisation_score = excluded.personalisation_score,
    updated_at = excluded.updated_at;
"""

def has_column(cur: sqlite3.Cursor, table: str, column: str) -> bool:
    cur.execute(f"PRAGMA table_info({table})")
    return any(row[1] == column for row in cur.fetchall())

def ensure_table_and_column(cur: sqlite3.Cursor):
    # Create table if missing (with the new column present in the schema)
    cur.execute(DDL)

    # If the table existed previously without personalisation_score, add it.
    if not has_column(cur, "user_stats", "personalisation_score"):
        print("🧭 migrating: adding personalisation_score to user_stats …")
        cur.execute("""
            ALTER TABLE user_stats
            ADD COLUMN personalisation_score INTEGER NOT NULL DEFAULT 65
        """)

    # Ensure every existing row has a value (safety if legacy nulls exist)
    cur.execute("""
        UPDATE user_stats
        SET personalisation_score = 65
        WHERE personalisation_score IS NULL
    """)

def main():
    print(f"🔌 connecting → {DB_PATH}")
    conn = sqlite3.connect(DB_PATH)
    try:
        cur = conn.cursor()

        print("🧱 ensuring table & column")
        ensure_table_and_column(cur)

        print("🌱 seeding/upsserting initial rows")
        cur.executemany(UPSERT, SEED_ROWS)

        # final sanity info
        cur.execute("SELECT COUNT(*) FROM user_stats")
        total = cur.fetchone()[0]
        cur.execute("SELECT COUNT(*) FROM user_stats WHERE personalisation_score = 65")
        set65 = cur.fetchone()[0]

        conn.commit()
        print(f"✅ done — rows: {total} (with personalisation_score=65: {set65})")
    finally:
        conn.close()

if __name__ == "__main__":
    main()