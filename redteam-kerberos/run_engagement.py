#!/usr/bin/env python3
"""
run_engagement.py — CLI entrypoint for an authorized Kerberos engagement.

    python run_engagement.py --roe roe.example.json --target dc01.corp.lab \
        --realm CORP.LAB --username svc_scan --password '...' \
        --userlist users.txt --spns 'MSSQLSvc/db01.corp.lab:1433'

The engagement refuses any target not covered by the signed ROE file, rate-
limits every request, and writes a hash-chained audit log plus a JSON report.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from core import Engagement, RulesOfEngagement, ScopeViolation
from modules import DEFAULT_MODULES


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Authorized Kerberos engagement runner")
    ap.add_argument("--roe", required=True, help="Path to signed ROE JSON file")
    ap.add_argument("--target", required=True, help="KDC / domain controller host")
    ap.add_argument("--realm", required=True)
    ap.add_argument("--username", default="")
    ap.add_argument("--password", default="")
    ap.add_argument("--userlist", help="File of candidate principals, one per line")
    ap.add_argument("--spns", nargs="*", default=[], help="SPNs to kerberoast")
    ap.add_argument("--workdir", default="reports")
    args = ap.parse_args(argv)

    roe = RulesOfEngagement.from_file(args.roe)
    eng = Engagement(roe, workdir=args.workdir)

    for mod_cls in DEFAULT_MODULES:
        eng.register(mod_cls())

    userlist = []
    if args.userlist:
        userlist = [ln.strip() for ln in Path(args.userlist).read_text().splitlines()
                    if ln.strip() and not ln.startswith("#")]

    opts = dict(realm=args.realm, username=args.username, password=args.password,
                userlist=userlist, spns=args.spns)

    try:
        eng.scope.check(args.target)
    except ScopeViolation as exc:
        print(f"[REFUSED] {exc}", file=sys.stderr)
        return 2

    findings = eng.run_all(args.target, **opts)
    report_path = eng.export_report()

    print(f"[+] Engagement {roe.engagement_id} complete: {len(findings)} findings")
    print(f"[+] Audit chain valid: {eng.audit.verify()}")
    print(f"[+] Report: {report_path}")
    for f in sorted(findings, key=lambda x: x.severity):
        print(f"    [{f.severity:8}] {f.title}  ({f.technique_id})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
