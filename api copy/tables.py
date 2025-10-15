#!/usr/bin/env python3
"""
print_table_counts.py

Prints:
- total number of (user) tables
- row count per table

Usage:
  python print_table_counts.py [optional_path_to_db]

Env:
  DB_PATH can be used instead of an argument.

By default internal sqlite_* tables are hidden. Use --include-internal to show them.
"""

import os
import sys
import sqlite3

DEFAULT_DB = "/Users/lukeyp02/Desktop/scranly/api/data/scranly.db"

def connect(db_path: str) -> sqlite3.Connection:
    if not os.path.exists(db_path):
        sys.exit(f"❌ DB not found: {db_path}")
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    return conn

def list_tables(conn: sqlite3.Connection, include_internal: bool = False) -> list[str]:
    cur = conn.cursor()
    if include_internal:
        sql = "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
        rows = cur.execute(sql).fetchall()
    else:
        sql = """
            SELECT name FROM sqlite_master
            WHERE type='table' AND name NOT LIKE 'sqlite_%'
            ORDER BY name
        """
        rows = cur.execute(sql).fetchall()
    return [r["name"] if isinstance(r, sqlite3.Row) else r[0] for r in rows]

def count_rows(conn: sqlite3.Connection, table: str) -> int:
    cur = conn.cursor()
    # Quote the table name defensively
    qname = '"' + table.replace('"', '""') + '"'
    return cur.execute(f"SELECT COUNT(*) AS c FROM {qname}").fetchone()[0]

def main():
    # Parse args
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    include_internal = any(a == "--include-internal" for a in sys.argv[1:])
    db_path = os.getenv("DB_PATH") or (args[0] if args else DEFAULT_DB)

    conn = connect(db_path)
    try:
        tables = list_tables(conn, include_internal=include_internal)

        if not tables:
            print(f"📦 {db_path}")
            print("No tables found.")
            return

        # Widths for nice columns
        name_w = max(5, *(len(t) for t in tables))
        print(f"📦 {db_path}\n")

        total_rows = 0
        print(f"{'TABLE'.ljust(name_w)} | ROWS")
        print(f"{'-'*name_w}-+------")
        for t in tables:
            try:
                n = count_rows(conn, t)
                total_rows += n
                print(f"{t.ljust(name_w)} | {n}")
            except sqlite3.Error as e:
                print(f"{t.ljust(name_w)} | (error: {e})")

        print("\nSummary:")
        print(f"• Tables: {len(tables)}")
        print(f"• Total rows across all tables: {total_rows}")
    finally:
        conn.close()

if __name__ == "__main__":
    main()