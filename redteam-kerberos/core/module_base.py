"""
core.module_base — Base class for MITRE ATT&CK-mapped engagement modules.

Every offensive capability is a subclass of `Module`. A module declares the
ATT&CK technique(s) it exercises and implements `run()`. It never touches the
network directly: it goes through the `Engagement` it is handed, which enforces
scope, rate limiting and audit logging on its behalf.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import TYPE_CHECKING, Any

if TYPE_CHECKING:
    from .engagement import Engagement


@dataclass
class Finding:
    """A single reportable result produced by a module."""

    title: str
    severity: str  # INFO | LOW | MEDIUM | HIGH | CRITICAL
    target: str
    technique_id: str
    description: str
    evidence: dict[str, Any] = field(default_factory=dict)
    remediation: str = ""

    def as_dict(self) -> dict[str, Any]:
        return {
            "title": self.title,
            "severity": self.severity,
            "target": self.target,
            "technique_id": self.technique_id,
            "description": self.description,
            "evidence": self.evidence,
            "remediation": self.remediation,
        }


class Module:
    """Abstract engagement module.

    Subclasses set ``name``, ``technique_id`` (ATT&CK, e.g. ``T1558.003``) and
    ``tactic``, then implement ``run(engagement, target, **opts)`` returning a
    list of :class:`Finding`.
    """

    name: str = "abstract"
    tactic: str = ""
    technique_id: str = ""
    description: str = ""

    def run(self, engagement: "Engagement", target: str, **opts: Any) -> list[Finding]:
        raise NotImplementedError

    # Convenience so subclasses read cleanly.
    def finding(self, **kwargs: Any) -> Finding:
        kwargs.setdefault("technique_id", self.technique_id)
        return Finding(**kwargs)
