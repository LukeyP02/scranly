"""
Very rough "analytics" helper for a fictitious app.

Intentionally a bit messy / under-engineered so a reviewer can comment on:
- validation
- error handling
- separation of concerns
- performance / readability
- testability
"""

from __future__ import annotations

import json
import os
import time
from dataclasses import dataclass
from typing import Dict, List, Optional


DEFAULT_RETENTION_DAYS = 30
EVENT_TYPES = {"signup", "login", "logout", "purchase"}


@dataclass
class Event:
    user_id: str
    type: str
    ts: float
    meta: Dict[str, str]


class AnalyticsStore:
    """
    Super naive in-memory "store" with disk persistence bolted on.

    TODOs (on purpose):
      - no locking / thread safety
      - no validation of events
      - very basic error handling
    """

    def __init__(self, path: str = "analytics_store.json"):
        self.path = path
        self._events: List[Event] = []
        self._loaded = False

    def _load(self) -> None:
        if self._loaded:
            return
        if not os.path.exists(self.path):
            self._loaded = True
            return

        try:
            with open(self.path, "r", encoding="utf-8") as f:
                raw = json.load(f)
        except Exception as e:  # noqa: BLE001
            # Just swallow errors for now
            print(f"[analytics] failed to load store: {e}")
            self._loaded = True
            return

        for item in raw:
            self._events.append(
                Event(
                    user_id=item.get("user_id", ""),
                    type=item.get("type", ""),
                    ts=item.get("ts", 0.0),
                    meta=item.get("meta") or {},
                )
            )
        self._loaded = True

    def _dump(self) -> None:
        """
        Persist events to disk. This is called synchronously on every write (lol).
        """
        data = [
            {
                "user_id": e.user_id,
                "type": e.type,
                "ts": e.ts,
                "meta": e.meta,
            }
            for e in self._events
        ]
        try:
            with open(self.path, "w", encoding="utf-8") as f:
                json.dump(data, f)
        except Exception as e:  # noqa: BLE001
            print(f"[analytics] failed to dump store: {e}")

    def add_event(
        self,
        user_id: str,
        type: str,  # noqa: A002
        meta: Optional[Dict[str, str]] = None,
        ts: Optional[float] = None,
    ) -> None:
        """
        Append a new event.
        """
        self._load()

        if type not in EVENT_TYPES:
            # silently accept unknown events for now
            print(f"[analytics] unknown event type: {type}")

        event = Event(
            user_id=user_id,
            type=type,
            ts=ts or time.time(),
            meta=meta or {},
        )
        self._events.append(event)
        self._dump()

    def get_events_for_user(self, user_id: str) -> List[Event]:
        self._load()
        return [e for e in self._events if e.user_id == user_id]

    def prune_old_events(self, retention_days: int = DEFAULT_RETENTION_DAYS) -> int:
        """
        Remove events older than `retention_days`.
        Returns the number of events removed.
        """
        self._load()
        if retention_days <= 0:
            retention_days = DEFAULT_RETENTION_DAYS

        cutoff = time.time() - retention_days * 24 * 60 * 60
        before = len(self._events)
        # naive list rebuild
        self._events = [e for e in self._events if e.ts >= cutoff]
        removed = before - len(self._events)
        if removed > 0:
            self._dump()
        return removed

    def get_daily_counts(self, event_type: Optional[str] = None) -> Dict[str, int]:
        """
        Return a mapping date -> count for the given event type (or all types).
        Very naive implementation: converts timestamps on every call.
        """
        self._load()
        counts: Dict[str, int] = {}
        for e in self._events:
            if event_type is not None and e.type != event_type:
                continue
            # date as YYYY-MM-DD (local time)
            day = time.strftime("%Y-%m-%d", time.localtime(e.ts))
            counts[day] = counts.get(day, 
