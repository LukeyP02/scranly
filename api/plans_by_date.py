#!/usr/bin/env python3
"""
Rebuilds the `plans_by_date` table from the `plans` table.

- Creates `plans_by_date` if missing
- For each plan, clears existing rows in `plans_by_date` for that plan_id
- Inserts one row per (date, slot, idx, meal_id)
- Idempotent & safe to run repeatedly

Usage:
  python materialize_plans_by_date.py
  python materialize_plans_by_date.py --db /path/to/scranly.db
  python materialize_plans_by_date.py --plan-ids 3 5 9
  python materialize_plans_by_date.py --dry-run
"""

import argparse, json, sqlite3, sys, os
from typing import Iterable, Dict, Any, List


DEFAULT_DB = "/Users/lukeyp02/Desktop/scranly/api/data/scranly.db"


def connect(db_path: str) -> sqlite3.Connection:
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    return conn


def ensure_table(conn: sqlite3.Connection) -> None:
    conn.execute("""
    CREATE TABLE IF NOT EXISTS plans_by_date (
        plan_id INTEGER NOT NULL,
        user_id TEXT    NOT NULL,
        date    TEXT    NOT NULL,   -- YYYY-MM-DD
        slot    TEXT    NOT NULL,   -- breakfast|lunch|dinner
        idx     INTEGER NOT NULL,   -- order within slot
        meal_id TEXT    NOT NULL,
        PRIMARY KEY (user_id, date, slot, idx)
    );
    """)
    conn.execute("CREATE INDEX IF NOT EXISTS idx_pbd_user_date ON plans_by_date(user_id, date);")
    conn.execute("CREATE INDEX IF NOT EXISTS idx_pbd_plan ON plans_by_date(plan_id);")


def iter_plans(conn: sqlite3.Connection, plan_ids: Iterable[int] | None) -> Iterable[sqlite3.Row]:
    if plan_ids:
        qmarks = ",".join("?" * len(plan_ids))
        sql = f"SELECT id, user_id, plan_json FROM plans WHERE id IN ({qmarks}) ORDER BY id"
        return conn.execute(sql, list(plan_ids))
    else:
        return conn.execute("SELECT id, user_id, plan_json FROM plans ORDER BY id")


def parse_plan_json(raw: Any) -> List[Dict[str, Any]]:
    """Returns normalized days list: [{date, breakfast:[], lunch:[], dinner:[]}, ...]"""
    if not raw:
        return []
    try:
        obj = json.loads(raw) if isinstance(raw, (str, bytes, bytearray)) else raw
    except Exception:
        return []
    days = obj.get("days", [])
    out = []
    for d in days:
        date_str = str(d.get("date") or "").strip()
        if not date_str:
            continue
        out.append({
            "date": date_str,
            "breakfast": d.get("breakfast") or [],
            "lunch":     d.get("lunch") or [],
            "dinner":    d.get("dinner") or [],
        })
    return out


def materialize_one(conn: sqlite3.Connection, plan_row: sqlite3.Row, dry_run: bool = False) -> int:
    """
    Deletes old rows for this plan and inserts fresh rows.
    Returns number of rows inserted.
    """
    plan_id = int(plan_row["id"])
    user_id = str(plan_row["user_id"])
    days = parse_plan_json(plan_row["plan_json"])

    # delete existing for this plan
    if not dry_run:
        conn.execute("DELETE FROM plans_by_date WHERE plan_id = ?", (plan_id,))

    to_insert = []
    for d in days:
        date_str = d["date"]
        for slot in ("breakfast", "lunch", "dinner"):
            items = d.get(slot, []) or []
            for idx, it in enumerate(items):
                mid = str(it.get("meal_id") or "").strip()
                if not mid:
                    continue
                to_insert.append((plan_id, user_id, date_str, slot, idx, mid))

    if not to_insert:
        return 0

    if not dry_run:
        conn.executemany(
            "INSERT OR REPLACE INTO plans_by_date (plan_id, user_id, date, slot, idx, meal_id) VALUES (?,?,?,?,?,?)",
            to_insert
        )
    return len(to_insert)


def main():
    ap = argparse.ArgumentParser(description="Materialize plans_by_date from plans.")
    ap.add_argument("--db", default=DEFAULT_DB, help=f"Path to SQLite DB (default: {DEFAULT_DB})")
    ap.add_argument("--plan-ids", nargs="*", type=int, help="Limit to these plan IDs")
    ap.add_argument("--dry-run", action="store_true", help="Parse & count only; no DB writes")
    args = ap.parse_args()

    if not os.path.exists(args.db):
        print(f"❌ DB not found: {args.db}", file=sys.stderr)
        sys.exit(1)

    conn = connect(args.db)
    try:
        if not args.dry_run:
            ensure_table(conn)

        total_plans = 0
        total_rows = 0

        print(f"🧩 Materializing plans_by_date (db={args.db})")
        if args.plan_ids:
            print(f"   → limiting to plan_ids={args.plan_ids}")

        with (conn if not args.dry_run else _NullCtx()):
            for row in iter_plans(conn, args.plan_ids):
                total_plans += 1
                inserted = materialize_one(conn, row, dry_run=args.dry_run)
                total_rows += inserted
                print(f"   • plan_id={row['id']} user={row['user_id']} → rows={inserted}")

        print(f"✅ Done. plans processed={total_plans}, rows inserted/replaced={total_rows}")
        if args.dry_run:
            print("ℹ️  Dry run: no changes committed.")
    finally:
        conn.commit()
        conn.close()


class _NullCtx:
    """Context manager that does nothing (used for dry-run to keep same 'with' shape)."""
    def __enter__(self): return None
    def __exit__(self, exc_type, exc, tb): return False


if __name__ == "__main__":
    main()