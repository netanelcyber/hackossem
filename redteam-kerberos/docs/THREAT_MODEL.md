# Kerberos Engagement — Threat Model & Authorization

## Purpose & authorization

This toolkit performs **authorized** security assessment of a Kerberos KDC
(MIT krb5 or Active Directory). It is intended for use by defenders and
sanctioned red teams against systems they own or are explicitly contracted to
test. Every offensive module is gated by a signed Rules-of-Engagement file and
cannot act against a target that is not in scope.

## Enforcement-in-code controls

| Control | Where | What it guarantees |
|---|---|---|
| **Scope gate** | `core/safety.py::ScopeGate` | No action against a host outside the ROE `scope` (or inside `exclusions`), and only within the authorized time window. |
| **Rate limiting** | `core/safety.py::RateLimiter` | Per-target token bucket + hard request ceiling — an assessment cannot become a DoS. |
| **Audit log** | `core/safety.py::AuditLog` | Append-only, SHA-256 hash-chained record of every action; tampering with any past entry is detectable via `verify()`. |
| **Mediated I/O** | `core/engagement.py::guarded_action` | Modules never touch the network directly; all calls pass scope + rate + audit first. |

## Techniques exercised (MITRE ATT&CK)

| Module | Technique | Tactic |
|---|---|---|
| `user_enum` | T1087.002 Account Discovery | Discovery |
| `user_enum` (no-preauth) | T1558.004 AS-REP Roasting | Credential Access |
| `kerberoast` | T1558.003 Kerberoasting | Credential Access |
| `enc_downgrade` | T1558 Steal/Forge Tickets (weak enctype) | Credential Access |

## Out of scope by design

No ticket forging (Golden/Silver), no traffic interception, no credential
replay against production identities, and no exploitation of the crackable
material this toolkit collects — it grades exposure, it does not weaponize it.
