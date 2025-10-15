# routes_baskets.py
from fastapi import APIRouter, HTTPException, Query
import datetime as dt
from basket_builder import connect, sunday_of_week, build_basket_for_week

router = APIRouter(prefix="/v1/baskets", tags=["baskets"])

@router.post("/rebuild")
def rebuild_basket(user_id: str = Query(...), week_start: str | None = None):
    try:
        ws = dt.datetime.strptime(week_start, "%Y-%m-%d").date() if week_start else sunday_of_week(dt.date.today())
    except ValueError:
        raise HTTPException(status_code=400, detail="week_start must be yyyy-MM-dd")
    conn = connect()
    try:
        return build_basket_for_week(conn, user_id, ws)
    except RuntimeError as e:
        raise HTTPException(status_code=404, detail=str(e))
    finally:
        conn.close()

@router.get("")
def get_basket(user_id: str = Query(...), week_start: str = Query(...)):
    conn = connect()
    try:
        cur = conn.cursor()
        row = cur.execute("""
            SELECT items_json FROM baskets WHERE user_id=? AND week_start=?
        """, (user_id, week_start)).fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="basket not found")
        items = json.loads(row["items_json"])
        return {"user_id": user_id, "week_start": week_start, "items": items}
    finally:
        conn.close()