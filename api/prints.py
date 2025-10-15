import sqlite3
import os

DB_PATH = os.getenv("DB_PATH", "/Users/lukeyp02/Desktop/scranly/api/data/scranly.db")

conn = sqlite3.connect(DB_PATH)
cur = conn.cursor()

cur.execute("PRAGMA table_info(plans);")
columns = [row[1] for row in cur.fetchall()]

print("📋 Columns in 'plans':")
for c in columns:
    print(" -", c)

conn.close()