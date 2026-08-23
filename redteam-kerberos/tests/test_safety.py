"""
Offline self-tests for the safety layer. No KDC or network required — these
prove the enforcement gates behave, which is the security-critical part of the
framework. Run:  python -m pytest tests/ -q   (or: python tests/test_safety.py)
"""
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from core.safety import (  # noqa: E402
    AuditLog, RateLimiter, RulesOfEngagement, ScopeGate, ScopeViolation,
)


def _roe(**kw):
    base = dict(engagement_id="ENG-TEST", client="Acme", authorized_by="ciso@acme",
                scope=("*.corp.lab", "10.0.0.0/24"), exclusions=("dc-prod.corp.lab",))
    base.update(kw)
    return RulesOfEngagement(**base)


def test_scope_allows_in_scope_host():
    assert ScopeGate(_roe()).is_authorized("dc01.corp.lab")


def test_scope_allows_cidr():
    assert ScopeGate(_roe()).is_authorized("10.0.0.55")


def test_scope_refuses_out_of_scope():
    assert not ScopeGate(_roe()).is_authorized("evil.example.com")


def test_scope_exclusion_beats_scope():
    # In the *.corp.lab scope but explicitly excluded -> must refuse.
    assert not ScopeGate(_roe()).is_authorized("dc-prod.corp.lab")


def test_rate_limiter_ceiling_raises():
    rl = RateLimiter(rate_per_sec=1000, burst=1000, ceiling=3)
    for _ in range(3):
        rl.acquire("t")
    try:
        rl.acquire("t")
    except ScopeViolation:
        return
    raise AssertionError("ceiling not enforced")


def test_audit_chain_detects_tampering():
    with tempfile.TemporaryDirectory() as d:
        log = AuditLog(Path(d) / "a.jsonl")
        log.record("a", "t", {"x": 1})
        log.record("b", "t", {"x": 2})
        assert log.verify()
        p = Path(d) / "a.jsonl"
        lines = p.read_text().splitlines()
        lines[0] = lines[0].replace('"x":1', '"x":9')
        p.write_text("\n".join(lines) + "\n")
        assert not AuditLog(p).verify()


if __name__ == "__main__":
    fns = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    passed = 0
    for fn in fns:
        fn(); passed += 1
        print(f"  ok  {fn.__name__}")
    print(f"\n{passed}/{len(fns)} passed")
