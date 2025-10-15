#!/usr/bin/env python3
import os
import sqlite3
import datetime as dt

DB_PATH = os.getenv("DB_PATH", "/Users/lukeyp02/Desktop/scranly/api/data/scranly.db")

SCHEMA = {
    "user_id":              "TEXT PRIMARY KEY",
    "given_name":           "TEXT",
    "family_name":          "TEXT",
    "email":                "TEXT",
    "tz":                   "TEXT",     # IANA timezone like "Europe/London"
    "goal_daily_calories":  "INTEGER",  # nullable, kcal target
    "height_cm":            "REAL",     # optional profile
    "weight_kg":            "REAL",     # optional profile
    "gender":               "TEXT",     # optional free text
    "birthdate":            "TEXT",     # "YYYY-MM-DD" optional
    "marketing_opt_in":     "INTEGER",  # 0/1
    "created_at":           "TEXT",     # ISO8601
    "updated_at":           "TEXT",     # ISO8601
    "last_login_at":        "TEXT"      # ISO8601
}

def connect():
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def table_exists(cur, name: str) -> bool:
    cur.execute("SELECT name FROM sqlite_master WHERE type='table' AND name=?;", (name,))
    return cur.fetchone() is not None

def column_names(cur, table: str) -> set:
    cur.execute(f"PRAGMA table_info({table});")
    return {row["name"] for row in cur.fetchall()}

def ensure_users_table(conn: sqlite3.Connection):
    cur = conn.cursor()

    if not table_exists(cur, "users"):
        # fresh create
        cols = ", ".join([f"{k} {v}" for k, v in SCHEMA.items()])
        cur.execute(f"CREATE TABLE users ({cols});")
        # unique index for email (nullable unique)
        cur.execute("CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email_unique ON users(email);")
        conn.commit()
        print("✅ Created table 'users'")
    else:
        # add any missing columns
        existing = column_names(cur, "users")
        added_any = False
        for col, decl in SCHEMA.items():
            if col not in existing:
                cur.execute(f"ALTER TABLE users ADD COLUMN {col} {decl};")
                added_any = True
                print(f"➕ Added column users.{col} {decl}")
        # ensure email unique index exists
        cur.execute("""
            SELECT name FROM sqlite_master 
            WHERE type='index' AND name='idx_users_email_unique';
        """)
        if cur.fetchone() is None:
            cur.execute("CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email_unique ON users(email);")
            print("➕ Added unique index on users.email")
        if added_any:
            conn.commit()
            print("✅ Users table updated")
        else:
            print("ℹ️ Users table already up to date")

def upsert_testing_user(conn: sqlite3.Connection):
    cur = conn.cursor()
    now = dt.datetime.utcnow().replace(microsecond=0).isoformat() + "Z"

    payload = {
        "user_id": "testing",
        "given_name": "Luke",
        "family_name": "Tester",
        "email": "luke.tester@example.com",
        "tz": "Europe/London",
        "goal_daily_calories": 2100,
        "height_cm": None,
        "weight_kg": None,
        "gender": None,
        "birthdate": None,
        "marketing_opt_in": 0,
        "created_at": now,
        "updated_at": now,
        "last_login_at": now
    }

    # Try update first; if 0 rows affected, insert.
    cur.execute("""
        UPDATE users SET
            given_name = :given_name,
            family_name = :family_name,
            email = :email,
            tz = :tz,
            goal_daily_calories = :goal_daily_calories,
            height_cm = :height_cm,
            weight_kg = :weight_kg,
            gender = :gender,
            birthdate = :birthdate,
            marketing_opt_in = :marketing_opt_in,
            updated_at = :updated_at,
            last_login_at = :last_login_at
        WHERE user_id = :user_id
    """, payload)
    if cur.rowcount == 0:
        cur.execute("""
            INSERT INTO users (
                user_id, given_name, family_name, email, tz, goal_daily_calories,
                height_cm, weight_kg, gender, birthdate, marketing_opt_in,
                created_at, updated_at, last_login_at
            ) VALUES (
                :user_id, :given_name, :family_name, :email, :tz, :goal_daily_calories,
                :height_cm, :weight_kg, :gender, :birthdate, :marketing_opt_in,
                :created_at, :updated_at, :last_login_at
            )
        """, payload)
        print("✅ Seeded test user 'testing'")
    else:
        print("✅ Updated test user 'testing'")

    conn.commit()

def print_users(conn: sqlite3.Connection):
    cur = conn.cursor()
    cur.execute("SELECT * FROM users ORDER BY created_at LIMIT 10;")
    rows = cur.fetchall()
    print(f"👤 users (showing {len(rows)}):")
    for r in rows:
        print(dict(r))

def main():
    conn = connect()
    try:
        ensure_users_table(conn)
        upsert_testing_user(conn)
        print_users(conn)
    finally:
        conn.close()

if __name__ == "__main__":
    main()