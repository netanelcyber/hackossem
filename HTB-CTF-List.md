# HTB CTF List — Machines & Labs for the AD / Samba-SMB Vector

A curated reference of **Hack The Box** content for practicing the techniques in
[`HTB-AD-Samba-Vector.md`](./HTB-AD-Samba-Vector.md). Grouped by attack surface so
you can pick a target that drills the exact skill you want.

> [!IMPORTANT]
> **Authorized labs only.** Everything here refers to Hack The Box's own
> intentionally vulnerable, retired lab targets. Only attack systems you own or
> are explicitly permitted to test.

> [!NOTE]
> **Links** point to the official HTB pages (`app.hackthebox.com`) and require an
> HTB account to open. Difficulty ratings and active/retired status change over
> time — treat the "Difficulty" column as a guide and confirm current status on
> the platform. "Primary vector" is the headline technique, not the full chain.

> [!WARNING]
> **Most machines below are retired, and retired HTB boxes require a paid VIP /
> VIP+ subscription.** Free-tier users only get the current *active* machines and
> Starting Point. Want to practice the exact same skills for **free, no VIP**?
> See **[`FREE-AD-SMB-Practice.md`](./FREE-AD-SMB-Practice.md)** — self-hosted AD
> labs, the free Samba-CVE target, and free TryHackMe rooms.

---

## How HTB content is organized

| Type | What it is |
|------|-----------|
| **Machines** | Full boxes — enumerate → foothold → privesc → `user.txt` + `root.txt`. The main event for AD/SMB practice. |
| **Challenges** | Bite-size category tasks (Web, Pwn, Crypto, Reversing, Forensics, Misc). |
| **Sherlocks** | Blue-team / DFIR investigations (log analysis, incident response). |
| **Fortresses** | Larger multi-flag vendor networks. |
| **Pro Labs** | Multi-machine enterprise networks — the closest thing to a real AD engagement. |
| **Seasonal CTF / HTB CTF** | Time-boxed competitive events (jeopardy-style + machines). |

For the **Samba/SMB vector**, you care mostly about **AD Machines** and the
**AD-heavy Pro Labs**.

---

## 1. Active Directory machines — Easy

Best starting points; the SMB/Samba workflow lands cleanly here.

| Machine | OS | Primary vector |
|---------|----|----------------|
| [**Active**](https://app.hackthebox.com/machines/Active) | Windows | Anonymous SMB `Replication` share → SYSVOL GPP `Groups.xml` → `gpp-decrypt` → Kerberoast → DA. **The canonical SMB box.** |
| [**Forest**](https://app.hackthebox.com/machines/Forest) | Windows | RID/LDAP user enum → AS-REP roast → BloodHound ACL (`WriteDacl`) → DCSync. |
| [**Sauna**](https://app.hackthebox.com/machines/Sauna) | Windows | User list → AS-REP roast → autologon creds → DCSync. |
| [**Return**](https://app.hackthebox.com/machines/Return) | Windows | SMB/LDAP enum → network-printer creds → `Server Operators` → SYSTEM. |
| [**Support**](https://app.hackthebox.com/machines/Support) | Windows | Info leak in a shared `.exe` → LDAP creds → RBCD (Resource-Based Constrained Delegation). |
| [**Timelapse**](https://app.hackthebox.com/machines/Timelapse) | Windows | SMB share → password-protected PFX cert → WinRM → LAPS read. |
| [**Cicada**](https://app.hackthebox.com/machines/Cicada) | Windows | SMB null/guest → password in a share → user enum → backup privilege. |

---

## 2. Active Directory machines — Medium

| Machine | OS | Primary vector |
|---------|----|----------------|
| [**Cascade**](https://app.hackthebox.com/machines/Cascade) | Windows | SMB/LDAP enum → config + deleted-object creds → recover DA. |
| [**Monteverde**](https://app.hackthebox.com/machines/Monteverde) | Windows | SMB user enum → password reuse → **Azure AD Connect** DB creds → DA. |
| [**Resolute**](https://app.hackthebox.com/machines/Resolute) | Windows | LDAP enum → password in description → `DnsAdmins` DLL injection. |
| [**Fuse**](https://app.hackthebox.com/machines/Fuse) | Windows | Print job usernames → password spray → `SeLoadDriverPrivilege`. |
| [**Intelligence**](https://app.hackthebox.com/machines/Intelligence) | Windows | Doc metadata → password spray → **gMSA** read → RBCD. |
| [**Search**](https://app.hackthebox.com/machines/Search) | Windows | LDAP + Kerberoast → **gMSA** → certificate abuse. |
| [**Escape**](https://app.hackthebox.com/machines/Escape) | Windows | MSSQL coerced auth → **AD CS ESC1** certificate template abuse. |
| [**Certified**](https://app.hackthebox.com/machines/Certified) | Windows | Shadow credentials → **AD CS ESC9** → DA. |
| [**Manager**](https://app.hackthebox.com/machines/Manager) | Windows | MSSQL → SMB backup → **AD CS ESC7** (Manage CA). |
| [**Scrambled**](https://app.hackthebox.com/machines/Scrambled) | Windows | NTLM disabled → Kerberos-only → silver ticket → MSSQL. |
| [**Jab**](https://app.hackthebox.com/machines/Jab) | Windows | XMPP directory enum → AS-REP roast → DCSync path. |

---

## 3. Active Directory machines — Hard / Insane

| Machine | OS | Difficulty | Primary vector |
|---------|----|-----------|----------------|
| [**Blackfield**](https://app.hackthebox.com/machines/Blackfield) | Windows | Hard | Anonymous SMB share → RID brute → AS-REP roast → `SeBackupPrivilege` → NTDS. |
| [**Sizzle**](https://app.hackthebox.com/machines/Sizzle) | Windows | Hard | SMB writable share → **SCF file** NetNTLM capture → certificate auth. |
| [**Object**](https://app.hackthebox.com/machines/Object) | Windows | Hard | Jenkins → AD creds → ACL abuse (`ForceChangePassword`/`GenericWrite`). |
| [**Reel**](https://app.hackthebox.com/machines/Reel) | Windows | Hard | Phishing (RTF) → AD enum → ACL path. |
| [**Mantis**](https://app.hackthebox.com/machines/Mantis) | Windows | Hard | MSSQL + Kerberos (MS14-068 era) → DA. |
| [**APT**](https://app.hackthebox.com/machines/APT) | Windows | Insane | IPv6 + RPC → NTLM relay → NTDS. |
| [**Multimaster**](https://app.hackthebox.com/machines/Multimaster) | Windows | Insane | SQLi → user enum → AS-REP → certificate/AV evasion chain. |
| [**Absolute**](https://app.hackthebox.com/machines/Absolute) | Windows | Insane | IPv6 DNS → Kerberos-only → shadow creds → KrbRelay. |

---

## 4. Samba / SMB-centric Linux machines

Where the SMB service is **Samba itself** — direct service exploitation rather
than AD.

| Machine | OS | Primary vector |
|---------|----|----------------|
| [**Lame**](https://app.hackthebox.com/machines/Lame) | Linux | **CVE-2007-2447** `usermap_script` command injection → root. The purest Samba-RCE box. |

> On any Linux box, fingerprint the Samba version (`smbclient -L`, nmap
> `smb-os-discovery`) against §10 of the main guide (CVE-2007-2447,
> CVE-2017-7494 SambaCry, CVE-2021-44142 `vfs_fruit`). Even when the foothold is
> elsewhere, always enumerate `445` for loot.

---

## 5. AD-heavy Pro Labs (multi-machine networks)

Closest to a real internal AD pentest — SMB enumeration, relaying, and lateral
movement across many hosts. Browse all at
[app.hackthebox.com/prolabs](https://app.hackthebox.com/prolabs).

| Pro Lab | Focus |
|---------|-------|
| [**Dante**](https://app.hackthebox.com/prolabs/overview/Dante) | Beginner-friendly network pivoting; mixed Linux/Windows. |
| [**Zephyr**](https://app.hackthebox.com/prolabs/overview/Zephyr) | Intermediate AD-focused enterprise network. |
| [**Offshore**](https://app.hackthebox.com/prolabs/overview/Offshore) | Classic Windows AD enterprise lab — the AD/SMB workhorse. |
| [**RastaLabs**](https://app.hackthebox.com/prolabs/overview/RastaLabs) | AD with an emphasis on persistence and evasion. |
| [**Cybernetics**](https://app.hackthebox.com/prolabs/overview/Cybernetics) | Large, hardened AD enterprise network. |
| [**APTLabs**](https://app.hackthebox.com/prolabs/overview/APTLabs) | Red-team style, red-forest / advanced AD. |

---

## 6. HTB Academy modules that teach this vector

Browse the catalog at
[academy.hackthebox.com/catalogue](https://academy.hackthebox.com/catalogue).

| Module | Why |
|--------|-----|
| **Active Directory Enumeration & Attacks** | The core SMB/LDAP/Kerberos workflow this repo documents. |
| **Password Attacks** | Spraying, roasting, hash cracking. |
| **Attacking Enterprise Networks** | End-to-end AD engagement. |
| **Kerberos Attacks** | AS-REP, Kerberoast, delegation, tickets. |
| **File Transfers / Pivoting, Tunneling & Port Forwarding** | Getting SMB tools to reach internal hosts. |

---

## 7. Suggested progression

```
Samba RCE        Active   ->  GPP/SMB        ->  Roasting + BloodHound  ->  Full chains
  Lame     ->    Active   ->  Return/Support ->  Forest / Sauna         ->  Blackfield / Cascade
                                                                            -> Pro Lab: Dante -> Offshore
```

1. [**Lame**](https://app.hackthebox.com/machines/Lame) — see the Samba service itself exploited (CVE-2007-2447).
2. [**Active**](https://app.hackthebox.com/machines/Active) — the textbook SMB→GPP→Kerberoast chain.
3. [**Forest**](https://app.hackthebox.com/machines/Forest) / [**Sauna**](https://app.hackthebox.com/machines/Sauna) — AS-REP roasting + BloodHound ACL paths + DCSync.
4. [**Return**](https://app.hackthebox.com/machines/Return) / [**Support**](https://app.hackthebox.com/machines/Support) / [**Timelapse**](https://app.hackthebox.com/machines/Timelapse) — varied Easy AD footholds over SMB/LDAP.
5. [**Blackfield**](https://app.hackthebox.com/machines/Blackfield) / [**Cascade**](https://app.hackthebox.com/machines/Cascade) — full, multi-step chains.
6. **Pro Labs** ([Dante](https://app.hackthebox.com/prolabs/overview/Dante) → [Offshore](https://app.hackthebox.com/prolabs/overview/Offshore)) — apply it across a real network.

---

## References

- Machine catalog & status — https://app.hackthebox.com/machines
- Pro Labs — https://app.hackthebox.com/prolabs
- HTB Academy — https://academy.hackthebox.com
- Companion methodology — [`HTB-AD-Samba-Vector.md`](./HTB-AD-Samba-Vector.md)

> [!IMPORTANT]
> Authorized Hack The Box / CTF lab targets only.
