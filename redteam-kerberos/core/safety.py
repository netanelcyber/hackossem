"""
core.safety — Enforcement-in-code safety layer for authorized Kerberos
security engagements.

Every offensive action MUST pass through this layer. There are three gates:

  1. ScopeGate    — a target is refused unless it is explicitly in-scope per
                    the signed Rules of Engagement (ROE).
  2. RateLimiter  — a token-bucket that bounds request volume per target so an
                    assessment cannot turn into a denial-of-service.
  3. AuditLog     — an append-only, hash-chained record of every action, so the
                    engagement is fully reconstructable and tamper-evident.

The design principle: a module cannot *choose* to skip these. The engagement
context owns the gates and mediates all network-touching calls.
"""

from __future__ import annotations

import fnmatch
import hashlib
import ipaddress
import json
import threading
import time
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


# --------------------------------------------------------------------------- #
# Rules of Engagement
# --------------------------------------------------------------------------- #
@dataclass(frozen=True)
class RulesOfEngagement:
    """Immutable authorization boundary for an engagement.

    Loaded from a signed ROE file. `scope` entries may be hostnames, glob
    patterns (``*.corp.example``), single IPs, or CIDR ranges. `not_before` /
    `not_after` bound the authorized window (UTC ISO-8601).
    """

    engagement_id: str
    client: str
    authorized_by: str
    scope: tuple[str, ...]
    exclusions: tuple[str, ...] = ()
    not_before: str | None = None
    not_after: str | None = None
    max_requests_per_target: int = 600
    requests_per_second: float = 5.0

    @classmethod
    def from_file(cls, path: str | Path) -> "RulesOfEngagement":
        data = json.loads(Path(path).read_text(encoding="utf-8"))
        return cls(
            engagement_id=data["engagement_id"],
            client=data["client"],
            authorized_by=data["authorized_by"],
            scope=tuple(data["scope"]),
            exclusions=tuple(data.get("exclusions", ())),
            not_before=data.get("not_before"),
            not_after=data.get("not_after"),
            max_requests_per_target=int(data.get("max_requests_per_target", 600)),
            requests_per_second=float(data.get("requests_per_second", 5.0)),
        )


class ScopeViolation(RuntimeError):
    """Raised when an action is attempted against an out-of-scope target."""


class ScopeGate:
    """Decides whether a target host/IP is authorized under the ROE."""

    def __init__(self, roe: RulesOfEngagement) -> None:
        self._roe = roe

    def _matches(self, target: str, pattern: str) -> bool:
        # CIDR / IP match takes precedence when both sides parse as networks.
        try:
            net = ipaddress.ip_network(pattern, strict=False)
            try:
                return ipaddress.ip_address(target) in net
            except ValueError:
                return False
        except ValueError:
            pass
        return fnmatch.fnmatch(target.lower(), pattern.lower())

    def _window_ok(self) -> bool:
        now = datetime.now(timezone.utc)
        if self._roe.not_before and now < _parse_iso(self._roe.not_before):
            return False
        if self._roe.not_after and now > _parse_iso(self._roe.not_after):
            return False
        return True

    def check(self, target: str) -> None:
        """Raise ScopeViolation unless `target` is authorized right now."""
        if not self._window_ok():
            raise ScopeViolation(
                f"outside authorized time window for {self._roe.engagement_id}"
            )
        for excl in self._roe.exclusions:
            if self._matches(target, excl):
                raise ScopeViolation(f"{target!r} is explicitly excluded by ROE")
        for allowed in self._roe.scope:
            if self._matches(target, allowed):
                return
        raise ScopeViolation(
            f"{target!r} is not in scope for engagement {self._roe.engagement_id}"
        )

    def is_authorized(self, target: str) -> bool:
        try:
            self.check(target)
            return True
        except ScopeViolation:
            return False


# --------------------------------------------------------------------------- #
# Rate limiting
# --------------------------------------------------------------------------- #
class RateLimiter:
    """Per-target token bucket + hard request ceiling.

    Prevents an assessment from degrading service availability. Thread-safe.
    """

    def __init__(self, rate_per_sec: float, burst: int, ceiling: int) -> None:
        self._rate = float(rate_per_sec)
        self._burst = float(burst)
        self._ceiling = int(ceiling)
        self._state: dict[str, list[float]] = {}  # target -> [tokens, last_ts, count]
        self._lock = threading.Lock()

    def acquire(self, target: str) -> None:
        """Block until a token is available; raise if the ceiling is hit."""
        with self._lock:
            tokens, last, count = self._state.get(
                target, [self._burst, time.monotonic(), 0]
            )
            if count >= self._ceiling:
                raise ScopeViolation(
                    f"request ceiling ({self._ceiling}) reached for {target!r}"
                )
            now = time.monotonic()
            tokens = min(self._burst, tokens + (now - last) * self._rate)
            if tokens < 1.0:
                sleep_for = (1.0 - tokens) / self._rate
            else:
                sleep_for = 0.0
                tokens -= 1.0
            self._state[target] = [tokens, now, count + 1]
        if sleep_for > 0:
            time.sleep(sleep_for)
            self.acquire(target)


# --------------------------------------------------------------------------- #
# Tamper-evident audit log
# --------------------------------------------------------------------------- #
@dataclass
class AuditLog:
    """Append-only, hash-chained JSON-lines audit log.

    Each record embeds the SHA-256 of the previous record, so any deletion or
    edit of a past entry breaks the chain and is detectable via ``verify()``.
    """

    path: Path
    _prev_hash: str = field(default="0" * 64, init=False)
    _lock: threading.Lock = field(default_factory=threading.Lock, init=False)

    def __post_init__(self) -> None:
        self.path = Path(self.path)
        if self.path.exists():
            for line in self.path.read_text(encoding="utf-8").splitlines():
                if line.strip():
                    self._prev_hash = json.loads(line)["hash"]

    @staticmethod
    def _digest(record: dict[str, Any]) -> str:
        payload = json.dumps(record, sort_keys=True, separators=(",", ":"))
        return hashlib.sha256(payload.encode("utf-8")).hexdigest()

    def record(self, action: str, target: str, detail: dict[str, Any]) -> str:
        with self._lock:
            entry = {
                "ts": datetime.now(timezone.utc).isoformat(),
                "action": action,
                "target": target,
                "detail": detail,
                "prev": self._prev_hash,
            }
            entry["hash"] = self._digest(entry)
            with self.path.open("a", encoding="utf-8") as fh:
                fh.write(json.dumps(entry, separators=(",", ":")) + "\n")
            self._prev_hash = entry["hash"]
            return entry["hash"]

    def verify(self) -> bool:
        """Return True iff the hash chain is intact from genesis to head."""
        prev = "0" * 64
        for line in self.path.read_text(encoding="utf-8").splitlines():
            if not line.strip():
                continue
            entry = json.loads(line)
            claimed = entry.pop("hash")
            if entry["prev"] != prev or self._digest(entry) != claimed:
                return False
            prev = claimed
        return True


def _parse_iso(value: str) -> datetime:
    dt = datetime.fromisoformat(value.replace("Z", "+00:00"))
    return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)
