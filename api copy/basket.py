#!/usr/bin/env python3
import os, sqlite3, sys

DB = os.getenv("DB_PATH", "/Users/lukeyp02/Desktop/scranly/api/data/scranly.db")

SCHEMA = r"""
CREATE TABLE IF NOT EXISTS catalog_items (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  name           TEXT NOT NULL UNIQUE,
  aisle          TEXT NOT NULL,
  emoji          TEXT NOT NULL,
  pack_amount    REAL NOT NULL,
  pack_unit      TEXT NOT NULL CHECK (pack_unit IN ('count','grams','milliliters')),
  price_per_pack REAL NOT NULL,
  size_label     TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS ingredient_catalog_map (
  ingredient     TEXT PRIMARY KEY,              -- normalized ingredient key (e.g. "banana")
  catalog_id     INTEGER NOT NULL REFERENCES catalog_items(id) ON DELETE CASCADE
);

-- Only created if you don't already have a similar table.
CREATE TABLE IF NOT EXISTS meal_ingredients (
  meal_id        TEXT NOT NULL,
  ingredient     TEXT NOT NULL,
  amount         REAL NOT NULL,
  unit           TEXT NOT NULL,
  PRIMARY KEY (meal_id, ingredient)
);

CREATE TABLE IF NOT EXISTS baskets (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id         TEXT NOT NULL,
  plan_id         INTEGER NOT NULL,
  week_start      TEXT NOT NULL,                -- Sunday (YYYY-MM-DD)
  week_end        TEXT NOT NULL,                -- Saturday (YYYY-MM-DD)
  items_json      TEXT NOT NULL,                -- JSON array of computed items
  estimated_total REAL NOT NULL,
  created_at      TEXT DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, week_start)
);

CREATE INDEX IF NOT EXISTS idx_baskets_user_week ON baskets(user_id, week_start);
"""

def main():
    db_path = DB if len(sys.argv) < 2 else sys.argv[1]
    os.makedirs(os.path.dirname(db_path), exist_ok=True)
    conn = sqlite3.connect(db_path)
    try:
        conn.executescript(SCHEMA)
        conn.commit()
        print(f"✅ Migrated schema into {db_path}")
    finally:
        conn.close()

if __name__ == "__main__":
    main()