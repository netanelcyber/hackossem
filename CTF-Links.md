# CTF & Practice Links — AD / Samba-SMB and Beyond

A curated link directory for hands-on practice. **🆓 = has a free tier**,
**🎯 = directly useful for the AD / Samba-SMB vector** in this repo.

> [!IMPORTANT]
> **Authorized labs only.** Use these platforms and self-hosted VMs for their
> intended, sanctioned practice — or against systems you own. Never point the
> tooling at anything you lack explicit permission to test.

---

## 1. Practice platforms (machines & guided labs)

| Platform | Notes | Link |
|----------|-------|------|
| **Hack The Box** 🎯 | Machines, Pro Labs, Starting Point. Retired boxes need VIP. | https://app.hackthebox.com |
| **HTB Academy** 🆓🎯 | Structured modules; some free, paths use "cubes". | https://academy.hackthebox.com |
| **TryHackMe** 🆓🎯 | Huge free tier; great AD/SMB rooms (see the room list below). | https://tryhackme.com |
| **VulnLab** 🎯 | Realistic **Active Directory** labs — standalone boxes + multi-host "Chains" (red-team style). Paid subscription; one of the strongest AD-focused platforms. | https://www.vulnlab.com |
| **VulnHub** 🆓🎯 | Free downloadable vulnerable VMs — run locally. | https://www.vulnhub.com |
| **OffSec Proving Grounds** 🆓 | *Play* tier is free (community VMs); *Practice* is paid. | https://www.offsec.com/labs/ |
| **PentesterLab** 🆓 | Web-focused exercises; some free. | https://pentesterlab.com |
| **PortSwigger Web Security Academy** 🆓 | Best free web-hacking labs (SQLi, SSRF, auth…). | https://portswigger.net/web-security |
| **pwn.college** 🆓 | Free university-grade binary exploitation / systems security. | https://pwn.college |
| **Hacker101 CTF** 🆓 | Free CTF by HackerOne, feeds bug-bounty skills. | https://ctf.hacker101.com |

### TryHackMe — key AD / SMB rooms 🎯

**Free rooms** (great starting point, no subscription):

| Room | Focus | Link |
|------|-------|------|
| **Attacktive Directory** | Full free AD chain: `enum4linux`, `kerbrute`, AS-REP roast, `secretsdump`, `evil-winrm`. | https://tryhackme.com/room/attacktivedirectory |
| **Network Services** | Dedicated **SMB** enumeration (`enum4linux`, `smbclient`) + Telnet/FTP. | https://tryhackme.com/room/networkservices |
| **Kenobi** | Samba share enumeration → foothold → privesc. | https://tryhackme.com/room/kenobi |
| **Post-Exploitation Basics** | Small AD: `mimikatz`, **BloodHound**, `evil-winrm`. | https://tryhackme.com/room/postexploit |

**Compromising Active Directory module** (subscriber path — the full AD story):
Active Directory Basics → Breaching AD → Enumerating AD → Lateral Movement &
Pivoting → Exploiting AD → Persisting AD → Credentials Harvesting.
→ https://tryhackme.com/module/compromising-active-directory  •  also **Attacking
Kerberos**: https://tryhackme.com/room/attackingkerberos

### VulnLab — realistic AD labs & chains 🎯

[**VulnLab**](https://www.vulnlab.com) (by *xct*) is a paid platform built around
**Active Directory** and modern enterprise attack paths. Two formats:

- **Boxes** — single machines (Easy → Insane), many Windows/AD with SMB, ADCS,
  Kerberos, delegation, and relay themes.
- **Chains** — multi-host networks that mimic a real internal engagement
  (pivoting, cross-trust, DA → EA) — the closest free-world equivalent to HTB
  Pro Labs / a real red-team assessment.

It's the natural step up once GOAD and the HTB Easy AD boxes feel comfortable.

---

## 2. Beginner-friendly wargames & jeopardy CTFs (all 🆓)

| Site | Focus | Link |
|------|-------|------|
| **OverTheWire** | Classic Linux/networking wargames (start with *Bandit*). | https://overthewire.org/wargames/ |
| **picoCTF** | Beginner jeopardy CTF + year-round practice gym. | https://picoctf.org |
| **Root-Me** | 400+ challenges across every category. | https://www.root-me.org |
| **CTFlearn** | Community beginner challenges. | https://ctflearn.com |
| **Hack This Site** | Old-school progressive missions. | https://www.hackthissite.org |

---

## 3. Live CTF competitions

| Resource | Notes | Link |
|----------|-------|------|
| **CTFtime** 🆓 | The calendar + archive of every competitive CTF; team rankings and past challenges. | https://ctftime.org |

---

## 4. Active Directory / Samba-SMB labs (self-hosted — 🆓🎯)

Build a Domain Controller you own and attack it legally, unlimited.

| Project | What it is | Link |
|---------|-----------|------|
| **GOAD** 🎯 | Ready-made vulnerable multi-DC AD forest. Best free AD range. | https://github.com/Orange-Cyberdefense/GOAD |
| **vulnerable-AD** 🎯 | Script that makes any DC vulnerable on demand. | https://github.com/WazeHell/vulnerable-AD |
| **Ludus** | Automated AD range deployment (incl. GOAD). | https://ludus.cloud |
| **DetectionLab** | AD + telemetry — see the blue-team side. | https://github.com/clong/DetectionLab |
| **Metasploitable 2** 🎯 | Samba 3.0.20 → **CVE-2007-2447** (same bug as HTB `Lame`). | https://sourceforge.net/projects/metasploitable/ |
| **Metasploitable 3** | Windows + Linux SMB targets. | https://github.com/rapid7/metasploitable3 |
| **Windows Server eval ISO** | Free 180-day Windows to host your DC. | https://www.microsoft.com/en-us/evalcenter |

---

## 5. Blue-team / DFIR practice (🆓🎯 for defenders)

| Platform | Focus | Link |
|----------|-------|------|
| **CyberDefenders** | Blue-team labs, DFIR challenges. | https://cyberdefenders.org |
| **LetsDefend** | SOC analyst simulation. | https://letsdefend.io |
| **Blue Team Labs Online** | Investigations & IR scenarios. | https://blueteamlabs.online |
| **HTB Sherlocks** | HTB's DFIR track. | https://app.hackthebox.com/sherlocks |

---

## 6. Core tools for the SMB/AD vector (🎯)

| Tool | Purpose | Link |
|------|---------|------|
| **Impacket** | `GetNPUsers`, `GetUserSPNs`, `secretsdump`, `psexec`, `ntlmrelayx`. | https://github.com/fortra/impacket |
| **NetExec (nxc)** | Maintained CrackMapExec successor — SMB/LDAP/WinRM. | https://github.com/Pennyw0rth/NetExec |
| **BloodHound CE** | Graph AD attack paths. | https://github.com/SpecterOps/BloodHound |
| **Responder** | LLMNR/NBT-NS poisoning, NetNTLM capture. | https://github.com/lgandx/Responder |
| **enum4linux-ng** | Automated null-session SMB enum. | https://github.com/cddmp/enum4linux-ng |
| **Kerbrute** | Kerberos user enum & spraying. | https://github.com/ropnop/kerbrute |
| **Certipy** | AD CS (certificate) attacks. | https://github.com/ly4k/Certipy |
| **smbmap** | Share permission mapping. | https://github.com/ShawnDEvans/smbmap |
| **evil-winrm** | WinRM shell. | https://github.com/Hackplayers/evil-winrm |
| **mimikatz** | Windows credential extraction. | https://github.com/gentilkiwi/mimikatz |

---

## 7. Writeups, references & cheat sheets (🆓)

| Resource | Notes | Link |
|----------|-------|------|
| **IppSec** 🎯 | Video walkthroughs of retired HTB machines. | https://www.youtube.com/c/ippsec |
| **ippsec.rocks** | Searchable index of IppSec videos by technique. | https://ippsec.rocks |
| **0xdf** 🎯 | Detailed retired-box writeups. | https://0xdf.gitlab.io |
| **HackTricks** 🎯 | The pentest encyclopedia (huge AD/SMB section). | https://book.hacktricks.xyz |
| **The Hacker Recipes** 🎯 | Clean AD attack reference (roasting, relay, delegation). | https://www.thehacker.recipes |
| **PayloadsAllTheThings** | Payloads & bypass cheat sheets. | https://github.com/swisskyrepo/PayloadsAllTheThings |
| **OCD AD mindmaps** 🎯 | Orange Cyberdefense's AD attack mind maps. | https://orange-cyberdefense.github.io/ocd-mindmaps/ |
| **ADSecurity** | Deep AD security articles (Sean Metcalf). | https://adsecurity.org |
| **SecLists** | The go-to wordlists (users, passwords, payloads). | https://github.com/danielmiessler/SecLists |

---

## Free "no-VIP" starter path 🆓🎯

1. **Metasploitable 2** — Samba `usermap_script` (the free `Lame`).
2. **TryHackMe → Network Services → Kenobi → Attacktive Directory** — SMB/AD chain.
3. **GOAD / vulnerable-AD** — your own forest; run the full workflow in
   [`HTB-AD-Samba-Vector.md`](./HTB-AD-Samba-Vector.md).
4. **IppSec / 0xdf / HackTricks** — learn retired HTB AD boxes for free.

See **[`FREE-AD-SMB-Practice.md`](./FREE-AD-SMB-Practice.md)** for the full free guide.

---

> [!NOTE]
> Free tiers, URLs, and platform features change over time — verify on each site.
> Authorized / self-hosted labs only.
