"""
User / principal enumeration via Kerberos pre-authentication responses.

ATT&CK: T1087.002 (Account Discovery: Domain Account) using the classic
AS-REQ oracle — the KDC answers differently for a valid principal that lacks
pre-auth (KRB5KDC_ERR_PREAUTH_REQUIRED) vs. an unknown one
(KRB5KDC_ERR_C_PRINCIPAL_UNKNOWN). No credentials required.
"""

from __future__ import annotations

from typing import Any

from core.module_base import Finding, Module

try:  # optional dependency, present in a real engagement environment
    from impacket.krb5.kerberosv5 import getKerberosTGT, KerberosError
    from impacket.krb5 import constants
    from impacket.krb5.types import Principal
    _HAVE_IMPACKET = True
except Exception:  # noqa: BLE001
    _HAVE_IMPACKET = False


class UserEnumModule(Module):
    name = "user_enum"
    tactic = "Discovery"
    technique_id = "T1087.002"
    description = "Enumerate valid domain principals via AS-REQ error oracle."

    def _probe(self, target: str, realm: str, user: str) -> str:
        """Return 'valid', 'valid-nopreauth', or 'unknown' for one principal."""
        if not _HAVE_IMPACKET:
            raise RuntimeError("impacket not installed; cannot probe KDC")
        principal = Principal(user, type=constants.PrincipalNameType.NT_PRINCIPAL.value)
        try:
            getKerberosTGT(principal, "", realm, None, None, None, kdcHost=target)
            return "valid-nopreauth"  # answered a TGT with no pre-auth => roastable
        except KerberosError as exc:
            name = exc.getErrorCode()
            if name == constants.ErrorCodes.KDC_ERR_PREAUTH_REQUIRED.value:
                return "valid"
            if name == constants.ErrorCodes.KDC_ERR_C_PRINCIPAL_UNKNOWN.value:
                return "unknown"
            return "unknown"

    def run(self, engagement, target: str, **opts: Any) -> list[Finding]:
        realm = opts["realm"]
        userlist: list[str] = opts.get("userlist", [])
        found: list[str] = []
        roastable: list[str] = []
        for user in userlist:
            status = engagement.guarded_action(
                "kerberos.as_req_probe", target,
                lambda u=user: self._probe(target, realm, u),
                realm=realm, principal=user,
            )
            if status == "valid":
                found.append(user)
            elif status == "valid-nopreauth":
                found.append(user)
                roastable.append(user)
        findings: list[Finding] = []
        if found:
            findings.append(self.finding(
                title=f"{len(found)} valid domain principals disclosed",
                severity="MEDIUM", target=target,
                description=("The KDC's AS-REQ error responses distinguish valid "
                             "principals from unknown ones, enabling unauthenticated "
                             "username enumeration."),
                evidence={"realm": realm, "valid_principals": found},
                remediation=("Cannot be fully eliminated in Kerberos, but reduce "
                             "signal by disabling unused accounts and monitoring for "
                             "high-volume AS-REQ patterns (Event ID 4768)."),
            ))
        if roastable:
            findings.append(self.finding(
                title=f"{len(roastable)} accounts do not require pre-authentication",
                severity="HIGH", target=target, technique_id="T1558.004",
                description=("Accounts with 'Do not require Kerberos preauthentication' "
                             "set allow AS-REP Roasting: an attacker obtains an AS-REP "
                             "encrypted with the account's key for offline cracking."),
                evidence={"realm": realm, "asrep_roastable": roastable},
                remediation="Remove DONT_REQUIRE_PREAUTH; enforce strong passwords / AES.",
            ))
        return findings
