# Practicing the AD / Samba-SMB Vector — 100% Free (No HTB VIP)

The machines in [`HTB-CTF-List.md`](./HTB-CTF-List.md) are mostly **retired**, and
retired HTB boxes require a **paid VIP / VIP+** subscription. This page is the
**free path**: the same skills — SMB enumeration, GPP/SYSVOL loot, roasting,
BloodHound, pass-the-hash, DCSync, and the Samba CVEs — with **zero cost**.

> [!IMPORTANT]
> **Authorized labs only.** The self-hosted labs below are ones **you build and
> own**, so you are fully authorized to attack them. Never point these tools at
> systems you do not own or have written permission to test.

> [!NOTE]
> Free tiers and room availability change. "Free" is accurate at time of
> writing — confirm on each platform before assuming access.

---

## What is actually free on Hack The Box

| Content | Free tier? |
|---------|-----------|
| **Active machines** (the current rotating set) | ✅ Yes — free users can play the currently *active* boxes. |
| **Starting Point** | ✅ Tier 0 is free; a great gentle intro (includes SMB basics). |
| **Retired machines** (Active, Forest, Lame, Blackfield…) | ❌ **VIP/VIP+ only.** |
| **Pro Labs** (Dante, Offshore…) | ❌ Paid. |
| **Challenges** (some) | ✅ Many are free. |

So the retired AD classics need VIP. **Everything below replaces them for free.**

---

## 1. Best free option — build your own AD lab (unlimited, legal, offline)

Self-hosted labs give you a **full Domain Controller you own**, so every
technique in the main guide works with no subscription and no scope worries.

| Project | What it gives you | Link |
|---------|-------------------|------|
| **GOAD — Game of Active Directory** | A ready-made, deliberately vulnerable **multi-DC AD forest** (Kerberoast, AS-REP, ACL abuse, delegation, ADCS, relay). The single best free AD range. | https://github.com/Orange-Cyberdefense/GOAD |
| **vulnerable-AD** | A PowerShell script that makes **any** Windows DC vulnerable on demand (misconfigured ACLs, roastable users, GPP, etc.). Pairs with a free Windows Server eval VM. | https://github.com/WazeHell/vulnerable-AD |
| **Ludus** | Automated deploy of AD ranges (incl. GOAD) if you have a hypervisor. | https://ludus.cloud |
| **DetectionLab** | AD + logging/telemetry — good for seeing the **blue-team** side of your attacks. | https://github.com/clong/DetectionLab |

**Windows Server + Windows 10 evaluation ISOs are free from Microsoft** (180-day
eval), so the whole GOAD/vulnerable-AD setup costs nothing:
- Windows Server eval: https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server
- Windows 10/11 enterprise eval: https://www.microsoft.com/en-us/evalcenter

> With GOAD running locally you can practice **exactly** the workflow in
> [`HTB-AD-Samba-Vector.md`](./HTB-AD-Samba-Vector.md): `nxc`, `enum4linux-ng`,
> `GetNPUsers`, `GetUserSPNs`, `bloodhound-python`, `secretsdump`, `psexec`.

---

## 2. Free Samba-vector target — the same CVE as HTB `Lame`

You don't need HTB's `Lame` to practice **CVE-2007-2447** (`usermap_script`):

| Target | Why | Link |
|--------|-----|------|
| **Metasploitable 2** | Ships **Samba 3.0.20**, vulnerable to the *exact* `usermap_script` command injection as `Lame` → root. Free download, runs in VirtualBox. | https://sourceforge.net/projects/metasploitable/ |
| **Metasploitable 3** | Windows + Linux targets with SMB and other services for lateral-movement practice. | https://github.com/rapid7/metasploitable3 |

```bash
# Against your own Metasploitable 2 VM — same drill as Lame:
smbclient -L //<msf2-ip> -N            # confirm Samba 3.0.20
nmap -p139,445 --script smb-vuln-cve2007-2447 <msf2-ip>
# then exploit usermap_script (metasploit: exploit/multi/samba/usermap_script)
```

---

## 3. Free TryHackMe rooms (SMB / AD focused)

TryHackMe has a large free tier. These rooms drill the SMB/AD vector directly:

| Room | Focus | Link |
|------|-------|------|
| **Attacktive Directory** | Full free AD chain: `enum4linux`, `kerbrute`, AS-REP roast, `secretsdump`, `evil-winrm`. The free equivalent of an Easy HTB AD box. | https://tryhackme.com/room/attacktivedirectory |
| **Network Services** | Dedicated **SMB enumeration** with `enum4linux` + `smbclient` (plus Telnet/FTP). | https://tryhackme.com/room/networkservices |
| **Kenobi** | Samba share enumeration → foothold → privesc. Great pure-SMB Linux practice. | https://tryhackme.com/room/kenobi |
| **Post-Exploitation Basics** | Small AD: `mimikatz`, **BloodHound**, `evil-winrm`. | https://tryhackme.com/room/postexploit |

---

## 4. Free VMs from VulnHub (download & run locally)

Free, downloadable, deliberately vulnerable VMs — many with SMB/Samba surfaces.
Filter for "Active Directory" or "SMB": https://www.vulnhub.com

---

## 5. Learn from retired HTB boxes without paying

Even if you can't *launch* a retired box, the writeups and videos are free — read
them alongside your GOAD/TryHackMe practice:

- **IppSec** (video walkthroughs of retired HTB machines) — https://www.youtube.com/c/ippsec  •  search index: https://ippsec.rocks
- **0xdf** (detailed retired-box writeups) — https://0xdf.gitlab.io
- **HTB Academy** — has **free introductory modules**; the full paths use "cubes". https://academy.hackthebox.com/catalogue

---

## Free progression (no VIP, no cost)

```
Metasploitable 2      TryHackMe (free)          GOAD / vulnerable-AD (self-host)
  Samba CVE      ->   Network Services ->        full AD forest, unlimited runs
 (== Lame)            Kenobi                     Kerberoast / AS-REP / BloodHound
                      Attacktive Directory  ->   / DCSync / pass-the-hash
```

1. **Metasploitable 2** — exploit Samba `usermap_script` (the free `Lame`).
2. **TryHackMe: Network Services → Kenobi** — SMB enumeration fundamentals.
3. **TryHackMe: Attacktive Directory** — a full free AD attack chain.
4. **GOAD / vulnerable-AD** — your own forest; run the entire main-guide workflow
   as many times as you want.
5. **IppSec / 0xdf** — watch retired HTB AD boxes to see the chains end-to-end.

---

> [!IMPORTANT]
> All targets here are self-hosted or platform-sanctioned free labs. Authorized
> practice only.
