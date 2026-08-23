# redteam-kerberos

A modular, **safety-gated** framework for authorized Kerberos security
engagements, plus a standalone dynamic (DAST) scanner and a static-analysis
(SAST) harness for MIT krb5 source.

> **Authorized use only.** Every offensive action is refused unless the target
> is covered by a signed Rules-of-Engagement file. See
> [`docs/THREAT_MODEL.md`](docs/THREAT_MODEL.md).

## Why this exists

Kerberos assessment tools are easy to point at the wrong host and easy to run
without a paper trail. This framework moves the guardrails **into the code**:
scope, rate limiting, and a tamper-evident audit log are owned by the
engagement context, and modules physically cannot bypass them.

## Layout

```
redteam-kerberos/
├── core/                  Enforcement-in-code safety layer
│   ├── safety.py            ScopeGate · RateLimiter · hash-chained AuditLog · ROE
│   ├── engagement.py        Orchestrator — the only object modules talk to
│   └── module_base.py       Module base class + Finding
├── modules/               MITRE ATT&CK-mapped capabilities
│   ├── user_enum.py         T1087.002 enum + T1558.004 AS-REP roast exposure
│   ├── kerberoast.py        T1558.003 Kerberoasting (enctype grading)
│   └── enc_downgrade.py     T1558 weak-enctype issuance probe
├── tools/
│   ├── kerberos_dast.py     Standalone dynamic KDC posture scanner
│   └── run_sast.sh          cppcheck + flawfinder harness for krb5 source
├── tests/test_safety.py   Offline proof the gates work (no KDC needed)
├── run_engagement.py      CLI entrypoint
└── roe.example.json       Sample Rules of Engagement
```

## Quick start

```bash
# 1. Prove the safety layer (no network, no deps):
python tests/test_safety.py

# 2. Dynamic posture check (standalone; impacket optional for live checks):
python tools/kerberos_dast.py --target dc01.corp.lab --realm CORP.LAB \
    --scope '*.corp.lab' --userlist users.txt

# 3. Full engagement (requires impacket + a real, in-scope KDC):
pip install -r requirements.txt
python run_engagement.py --roe roe.example.json --target dc01.corp.lab \
    --realm CORP.LAB --username svc_scan --password '***' \
    --userlist users.txt --spns 'MSSQLSvc/db01.corp.lab:1433'
```

The engagement writes two artifacts to `reports/`:
a **hash-chained audit log** (`audit-<id>.jsonl`) and a severity-sorted
**JSON report** (`report-<id>.json`) that includes `audit_chain_valid`.

## Safety guarantees (all covered by `tests/test_safety.py`)

- An out-of-scope target is **refused** (exit code 2), before any packet is sent.
- An ROE `exclusion` overrides an otherwise-matching scope entry.
- Every target is rate-limited with a hard request **ceiling**.
- Editing any past audit record breaks the chain and fails `verify()`.

## Scope of the modules

The modules *measure exposure* — valid principals, roastable accounts, weak
enctypes, crackable ticket material. They deliberately do **not** forge tickets,
crack the harvested material, or replay credentials. Grading, not weaponizing.

## License

MIT — for authorized security testing and educational use.
