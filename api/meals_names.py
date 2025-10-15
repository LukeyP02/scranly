import sqlite3

DB_PATH = "/Users/lukeyp02/Desktop/scranly/api/data/scranly.db"

def inspect_meals():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()

    # Show all column names
    cur.execute("PRAGMA table_info(meals);")
    cols = [row["name"] for row in cur.fetchall()]
    print("📋 Columns in meals table:", cols)

    # Show first 10 meal titles (or whatever column exists)
    try:
        cur.execute("SELECT id, title FROM meals LIMIT 10;")
        for row in cur.fetchall():
            print(f"🍽️ {row['id']} → {row['title']}")
    except Exception as e:
        print("⚠️ Could not fetch id/title:", e)

    conn.close()

if __name__ == "__main__":
    inspect_meals()