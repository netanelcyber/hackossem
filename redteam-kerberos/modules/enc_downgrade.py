"""
Encryption downgrade probe — determine whether the KDC will still issue tickets
under weak/legacy encryption types (RC4-HMAC, single-DES, 3DES).

ATT&CK: T1558 (Steal or Forge Kerberos Tickets) — a KDC that honours RC4 in
the AS-REQ etype list lets an attacker force weak crypto for roasting/cracking.
No downgrade attack is performed against traffic; this only asks the KDC which
enctypes it is willing to grant, which is a configuration-disclosure test.
"""

from __future__ import annotations

from typing import Any

from core.module_base import Finding, Module

try:
    from impacket.krb5.kerberosv5 import getKerberosTGT, KerberosError
    from impacket.krb5 import constants
    from impacket.krb5.types import Principal
    _HAVE_IMPACKET = True
except Exception:  # noqa: BLE001
    _HAVE_IMPACKET = False

_WEAK = {23: "RC4-HMAC", 16: "DES3-CBC-SHA1", 3: "DES-CBC-MD5", 1: "DES-CBC-CRC"}


class EncryptionDowngradeModule(Module):
    name = "enc_downgrade"
    tactic = "Credential Access"
    technique_id = "T1558"
    description = "Detect KDC willingness to issue tickets under weak enctypes."

    def _try_etype(self, target: str, realm: str, user: str, pw: str, etype: int):
        principal = Principal(user, type=constants.PrincipalNameType.NT_PRINCIPAL.value)
        try:
            tgt, cipher, _ok, _sk = getKerberosTGT(
                principal, pw, realm, None, None, None,
                kdcHost=target, requestPAC=True)
            return int(cipher.enctype) == etype
        except KerberosError:
            return False

    def run(self, engagement, target: str, **opts: Any) -> list[Finding]:
        realm = opts["realm"]
        username = opts["username"]
        password = opts.get("password", "")
        if not _HAVE_IMPACKET:
            return [self.finding(
                title="Encryption-downgrade module requires impacket",
                severity="INFO", target=target,
                description="impacket not installed in this environment.")]
        granted_weak: list[str] = []
        for etype, label in _WEAK.items():
            ok = engagement.guarded_action(
                "kerberos.etype_probe", target,
                lambda e=etype: self._try_etype(target, realm, username, password, e),
                realm=realm, etype=etype)
            if ok:
                granted_weak.append(label)
        if not granted_weak:
            return [self.finding(
                title="KDC rejects weak encryption types", severity="INFO",
                target=target, description="No legacy enctype (RC4/DES/3DES) was granted.",
                remediation="No action required; maintain AES-only policy.")]
        return [self.finding(
            title=f"KDC issues tickets under weak encryption: {', '.join(granted_weak)}",
            severity="HIGH", target=target,
            description=("The KDC honoured one or more legacy encryption types. "
                         "RC4-HMAC and DES-family tickets are cheap to crack offline "
                         "and enable efficient Kerberoasting / AS-REP roasting."),
            evidence={"realm": realm, "weak_enctypes_granted": granted_weak},
            remediation=("Set msDS-SupportedEncryptionTypes to AES-only (0x18); "
                         "remove RC4 and DES; audit accounts pinned to legacy crypto."),
        )]
