# inspect_user_stats.py
import os
import sqlite3
from textwrap import indent

DB_PATH = os.getenv("DB_PATH", "/Users/lukeyp02/Desktop/scranly/api/data/scranly.db")

def main():
    print(f"🔎 Opening DB: {DB_PATH}")
    conn = sqlite3.connect(DB_PATH)
    try:
        cur = conn.cursor()

        # Does the table exist?
        cur.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='user_stats'")
        row = cur.fetchone()
        if not row:
            print("❌ Table 'user_stats' does NOT exist.")
            return
        print("✅ Table 'user_stats' exists.")

        # Show CREATE statement
        cur.execute("SELECT sql FROM sqlite_master WHERE type='table' AND name='user_stats'")
        create_sql = cur.fetchone()[0]
        print("\n📐 CREATE TABLE sql:")
        print(indent(create_sql, "  "))

        # Show column info
        cur.execute("PRAGMA table_info(user_stats)")
        cols = cur.fetchall()
        # PRAGMA table_info columns: cid, name, type, notnull, dflt_value, pk
        print("\n📊 Columns (cid | name | type | notnull | default | pk):")
        for c in cols:
            print("  ", c)

        # Show first few rows (optional)
        cur.execute("SELECT * FROM user_stats LIMIT 5")
        rows = cur.fetchall()
        print("\n🧾 Sample rows (up to 5):")
        if rows:
            for r in rows:
                print("  ", r)
        else:
            print("  (no rows)")

        # Show entry for your user specifically
        cur.execute("SELECT * FROM user_stats WHERE user_id = ?", ("testing",))
        rows = cur.fetchall()
        print("\n👤 Rows for user_id='testing':")
        if rows:
            for r in rows:
                print("  ", r)
        else:
            print("  (none)")

    finally:
        conn.close()

if __name__ == "__main__":
    main()