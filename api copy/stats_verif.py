#!/usr/bin/env python3
import os
import sqlite3
import argparse

DEFAULT_DB = "/Users/lukeyp02/Desktop/scranly/api/data/scranly.db"

def get_conn(db_path: str):
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    return conn

def print_table_columns(conn, table_name: str):
    print(f"\n📋 Columns in '{table_name}':")
    print("-" * 60)
    cur = conn.execute(f"PRAGMA table_info({table_name})")
    rows = cur.fetchall()
    if not rows:
        print(f"(no columns found — table '{table_name}' may not exist)")
        return
    for r in rows:
        print(f"{r['cid']:2d}. {r['name']} ({r['type']})"
              f"{' [PK]' if r['pk'] else ''}")

def print_user_stats(conn, user_id: str):
    # Check if table exists
    cur = conn.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='user_stats'")
    if not cur.fetchone():
        print("❌ Table 'user_stats' not found. Have you run the creation script?")
        return

    # Print columns
    print_table_columns(conn, "user_stats")

    # Fetch data
    cur = conn.execute("SELECT * FROM user_stats WHERE user_id = ? LIMIT 1", (user_id,))
    row = cur.fetchone()
    if not row:
        print(f"\n⚠️ No row found for user_id='{user_id}' in 'user_stats'.")
        return

    print(f"\n✅ user_stats row for '{user_id}':")
    print("-" * 60)
    for key in row.keys():
        val = row[key]
        if key.lower().startswith("money") and isinstance(val, (int, float)):
            print(f"{key:<24}: £{float(val):.2f}")
        else:
            print(f"{key:<24}: {val}")

def main():
    ap = argparse.ArgumentParser(description="Print user_stats row + table columns.")
    ap.add_argument("--db", default=os.getenv("DB_PATH", DEFAULT_DB),
                    help=f"Path to SQLite DB (default: %(default)s)")
    ap.add_argument("--user", default="testing",
                    help="User ID to inspect (default: testing)")
    args = ap.parse_args()

    conn = get_conn(args.db)
    try:
        print_user_stats(conn, args.user)
    finally:
        conn.close()

if __name__ == "__main__":
    main()