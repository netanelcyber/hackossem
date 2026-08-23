"""
core.engagement — Orchestrator that wires the safety layer to the modules.

An `Engagement` is the only object a module talks to. Every network-touching
helper on it (``guarded_action``) first clears the ScopeGate and RateLimiter,
then writes an AuditLog record. Modules therefore *cannot* act out of scope or
without an audit trail — the enforcement lives here, not in the modules.
"""

from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable

from .module_base import Finding, Module
from .safety import (
    AuditLog,
    RateLimiter,
    RulesOfEngagement,
    ScopeGate,
    ScopeViolation,
)


class Engagement:
    def __init__(self, roe: RulesOfEngagement, workdir: str | Path = "reports") -> None:
        self.roe = roe
        self.scope = ScopeGate(roe)
        self.limiter = RateLimiter(
            rate_per_sec=roe.requests_per_second,
            burst=max(1, int(roe.requests_per_second)),
            ceiling=roe.max_requests_per_target,
        )
        self.workdir = Path(workdir)
        self.workdir.mkdir(parents=True, exist_ok=True)
        self.audit = AuditLog(self.workdir / f"audit-{roe.engagement_id}.jsonl")
        self._modules: dict[str, Module] = {}
        self._findings: list[Finding] = []
        self.audit.record("engagement.start", roe.engagement_id,
                          {"client": roe.client, "authorized_by": roe.authorized_by})

    # -- registration -------------------------------------------------------
    def register(self, module: Module) -> None:
        self._modules[module.name] = module

    # -- the single mediated entry point for anything touching a target -----
    def guarded_action(self, action: str, target: str,
                       fn: Callable[[], Any], **detail: Any) -> Any:
        """Run `fn` only after scope + rate checks; audit the outcome."""
        self.scope.check(target)          # raises ScopeViolation if out of scope
        self.limiter.acquire(target)      # blocks / raises at ceiling
        try:
            result = fn()
        except Exception as exc:          # noqa: BLE001 - audit then re-raise
            self.audit.record(f"{action}.error", target,
                             {**detail, "error": repr(exc)})
            raise
        self.audit.record(action, target, detail)
        return result

    # -- module execution ---------------------------------------------------
    def run_module(self, name: str, target: str, **opts: Any) -> list[Finding]:
        module = self._modules[name]
        self.audit.record("module.run", target,
                         {"module": name, "technique": module.technique_id})
        findings = module.run(self, target, **opts)
        self._findings.extend(findings)
        return findings

    def run_all(self, target: str, **opts: Any) -> list[Finding]:
        results: list[Finding] = []
        for name in self._modules:
            try:
                results.extend(self.run_module(name, target, **opts))
            except ScopeViolation:
                raise
            except Exception as exc:  # noqa: BLE001 - one module never kills the run
                self.audit.record("module.exception", target,
                                 {"module": name, "error": repr(exc)})
        return results

    # -- reporting ----------------------------------------------------------
    @property
    def findings(self) -> list[Finding]:
        return list(self._findings)

    def export_report(self, path: str | Path | None = None) -> Path:
        path = Path(path) if path else self.workdir / f"report-{self.roe.engagement_id}.json"
        sev_order = {"CRITICAL": 0, "HIGH": 1, "MEDIUM": 2, "LOW": 3, "INFO": 4}
        findings = sorted(self._findings, key=lambda f: sev_order.get(f.severity, 9))
        report = {
            "engagement_id": self.roe.engagement_id,
            "client": self.roe.client,
            "authorized_by": self.roe.authorized_by,
            "generated": datetime.now(timezone.utc).isoformat(),
            "scope": list(self.roe.scope),
            "audit_chain_valid": self.audit.verify(),
            "summary": {
                sev: sum(1 for f in findings if f.severity == sev)
                for sev in ("CRITICAL", "HIGH", "MEDIUM", "LOW", "INFO")
            },
            "findings": [f.as_dict() for f in findings],
        }
        path.write_text(json.dumps(report, indent=2), encoding="utf-8")
        self.audit.record("report.export", self.roe.engagement_id,
                         {"path": str(path), "findings": len(findings)})
        return path
