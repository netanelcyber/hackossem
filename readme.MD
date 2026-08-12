# hackossem — HTB Active Directory: The Samba / SMB Vector

Educational security notes and tooling for practicing **Active Directory
attacks on Hack The Box** through the **SMB (Samba)** surface — the protocol on
ports `139/445` that every Domain Controller exposes and that Linux HTB targets
implement with Samba.

> [!IMPORTANT]
> **Authorized labs only.** This material is for Hack The Box, other CTF
> platforms, and systems you are explicitly permitted to test. Using it against
> anything you do not own or have written permission to assess is illegal.

## Contents

| File | What it is |
|------|-----------|
| **[`HTB-AD-Samba-Vector.md`](./HTB-AD-Samba-Vector.md)** | The main field guide — a six-phase methodology (discover → enumerate → get creds → escalate → DCSync), Samba CVE notes, a machine-by-machine map, blue-team detections, and a copy-paste cheat sheet. |
| **[`HTB-CTF-List.md`](./HTB-CTF-List.md)** | A curated list of HTB machines and Pro Labs for practicing the AD/Samba-SMB vector, grouped by attack surface and difficulty, with direct lab links and a suggested progression. |
| **[`FREE-AD-SMB-Practice.md`](./FREE-AD-SMB-Practice.md)** | The **free / no-VIP** path — self-hosted AD labs (GOAD, vulnerable-AD), the free Samba-CVE target (Metasploitable 2 = the same bug as `Lame`), and free TryHackMe rooms. |
| **[`smb_ad_enum.sh`](./smb_ad_enum.sh)** | A companion Bash helper that runs the unauthenticated SMB recon workflow (Phases 1–3) in one shot and saves all output per target. |
| `app.py` | An unrelated Flask/LINQ/WASM demo kept from earlier work; not part of the HTB material. |

## Quick start

Read the guide first, then run the enumerator against a lab target:

```bash
# Anonymous / null-session recon
./smb_ad_enum.sh 10.10.10.100

# With a domain (Kerberos-aware) and/or a credential you have obtained
./smb_ad_enum.sh 10.10.10.100 active.htb
./smb_ad_enum.sh 10.10.10.100 htb.local svc-user 'P@ssw0rd'
```

All artifacts land in an `enum_<ip>/` folder for note-taking. The script skips —
rather than fails on — any tool that is not installed and tells you how to get it.

## The vector in one paragraph

SMB is the front door to AD: it leaks the domain, users, groups, and password
policy over null sessions; SYSVOL routinely hands out passwords (the classic
GPP `Groups.xml` → `gpp-decrypt`); and once you hold any credential or NTLM hash
it becomes the channel for Kerberoasting, BloodHound collection, pass-the-hash,
`psexec`/`wmiexec`, and ultimately DCSync to Domain Admin. On Linux boxes the
same service is *Samba itself*, which adds direct RCE bugs like CVE-2007-2447
(`usermap_script`, the `Lame` box) and CVE-2017-7494 (SambaCry). The guide walks
each phase with real commands and maps them to specific HTB machines.

## Recommended HTB progression

`Lame` (pure Samba RCE) → `Active` (GPP over SMB) → `Forest` / `Sauna`
(AS-REP roasting + BloodHound) → `Blackfield` / `Cascade` (full chains).

## License

Educational content, distributed under the MIT License.
