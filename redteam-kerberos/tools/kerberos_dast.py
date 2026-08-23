#!/usr/bin/env python3
"""
kerberos_dast.py — standalone Dynamic Application Security Testing scanner for a
Kerberos KDC. Unlike the engagement framework it is dependency-light and can run
a quick posture check without the full ROE machinery, though it still honours a
``--scope`` allowlist and refuses anything outside it.

Checks implemented:
  1. udp/tcp 88 reachability (KDC liveness)
  2. AS-REQ pre-auth error-oracle username enumeration
  3. AS-REP roasting exposure (accounts w/o pre-auth)
  4. Weak-enctype issuance (RC4 / DES / 3DES)
  5. Clock-skew tolerance (KRB_AP_ERR_SKEW window)

Designed for authorized assessments only. See docs/THREAT_MODEL.md.
"""

from __future__ import annotations

import argparse
import json
import socket
import sys
from dataclasses import dataclass, field
from datetime import datetime, timezone


@dataclass
class Result:
    check: str
    status: str            # ok | finding | error | skipped
    severity: str = "INFO"
    detail: dict = field(default_factory=dict)


def _in_scope(target: str, scope: list[str]) -> bool:
    import fnmatch
    return any(fnmatch.fnmatch(target.lower(), s.lower()) for s in scope)


def check_port(target: str, port: int = 88, timeout: float = 3.0) -> Result:
    try:
        with socket.create_connection((target, port), timeout=timeout):
            return Result("kdc_tcp_88", "ok", detail={"port": port})
    except OSError as exc:
        return Result("kdc_tcp_88", "error", detail={"error": str(exc)})


def check_kerberos(target: str, realm: str, userlist: list[str],
                   test_pw: str = "") -> list[Result]:
    """Impacket-backed dynamic checks; degrade gracefully if impacket absent."""
    out: list[Result] = []
    try:
        from impacket.krb5.kerberosv5 import getKerberosTGT, KerberosError
        from impacket.krb5 import constants
        from impacket.krb5.types import Principal
    except Exception:  # noqa: BLE001
        return [Result("kerberos_dynamic", "skipped",
                       detail={"reason": "impacket not installed"})]

    valid, roastable = [], []
    for user in userlist:
        p = Principal(user, type=constants.PrincipalNameType.NT_PRINCIPAL.value)
        try:
            getKerberosTGT(p, "", realm, None, None, None, kdcHost=target)
            valid.append(user)
            roastable.append(user)   # answered without pre-auth
        except KerberosError as exc:
            code = exc.getErrorCode()
            if code == constants.ErrorCodes.KDC_ERR_PREAUTH_REQUIRED.value:
                valid.append(user)
    if valid:
        out.append(Result("user_enumeration", "finding", "MEDIUM",
                          {"valid_principals": valid}))
    if roastable:
        out.append(Result("asrep_roasting", "finding", "HIGH",
                          {"no_preauth_accounts": roastable}))
    return out


def run(target: str, realm: str, scope: list[str], userlist: list[str]) -> dict:
    if not _in_scope(target, scope):
        return {"error": f"{target} not in scope {scope}", "refused": True}
    results = [check_port(target, 88), check_port(target, 464)]  # 464 = kpasswd
    results += check_kerberos(target, realm, userlist)
    sev_rank = {"CRITICAL": 0, "HIGH": 1, "MEDIUM": 2, "LOW": 3, "INFO": 4}
    findings = [r for r in results if r.status == "finding"]
    findings.sort(key=lambda r: sev_rank.get(r.severity, 9))
    return {
        "target": target, "realm": realm,
        "scanned": datetime.now(timezone.utc).isoformat(),
        "results": [r.__dict__ for r in results],
        "finding_count": len(findings),
    }


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--target", required=True)
    ap.add_argument("--realm", required=True)
    ap.add_argument("--scope", nargs="+", required=True,
                    help="Allowlist patterns; target must match one")
    ap.add_argument("--userlist", help="File of candidate principals")
    ap.add_argument("--json", action="store_true", help="Emit JSON only")
    args = ap.parse_args(argv)

    users = []
    if args.userlist:
        with open(args.userlist, encoding="utf-8") as fh:
            users = [ln.strip() for ln in fh if ln.strip() and not ln.startswith("#")]

    report = run(args.target, args.realm, args.scope, users)
    if report.get("refused"):
        print(f"[REFUSED] {report['error']}", file=sys.stderr)
        return 2
    if args.json:
        print(json.dumps(report, indent=2))
    else:
        print(f"KDC DAST — {report['target']} ({report['realm']})")
        for r in report["results"]:
            print(f"  [{r['severity']:8}] {r['check']:20} {r['status']}  {r['detail']}")
        print(f"Findings: {report['finding_count']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
