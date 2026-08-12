#!/usr/bin/env bash
#
# smb_ad_enum.sh — SMB / Samba enumeration helper for HTB Active Directory labs
# ---------------------------------------------------------------------------
# Companion to HTB-AD-Samba-Vector.md. Wraps the standard, unauthenticated
# SMB reconnaissance workflow (Phases 1–3 of the guide) into one reproducible
# run and drops all output into a per-target folder for note-taking.
#
#  AUTHORIZED USE ONLY. Run this against Hack The Box targets or systems you
#  are explicitly permitted to test. Enumerating hosts without permission is
#  illegal. Stay in scope.
#
# Usage:
#   ./smb_ad_enum.sh <target-ip> [domain] [user] [pass]
#
# Examples:
#   ./smb_ad_enum.sh 10.10.10.100                 # anonymous / null session
#   ./smb_ad_enum.sh 10.10.10.100 active.htb      # set domain for Kerberos-aware steps
#   ./smb_ad_enum.sh 10.10.10.100 htb.local svc-user 'P@ssw0rd'   # authenticated
#
# The script is defensive about missing tools: each step is skipped (not fatal)
# if the underlying binary is not installed, and tells you what to install.
# ---------------------------------------------------------------------------

set -uo pipefail

# ---- args -----------------------------------------------------------------
IP="${1:-}"
DOMAIN="${2:-}"
USER="${3:-}"
PASS="${4:-}"

if [[ -z "$IP" ]]; then
    echo "Usage: $0 <target-ip> [domain] [user] [pass]" >&2
    exit 1
fi

# ---- pretty output --------------------------------------------------------
c_reset=$'\033[0m'; c_blue=$'\033[1;34m'; c_green=$'\033[1;32m'
c_yellow=$'\033[1;33m'; c_red=$'\033[1;31m'

banner() { printf '\n%s========================================================%s\n' "$c_blue" "$c_reset"
           printf '%s>> %s%s\n'   "$c_blue" "$1" "$c_reset"
           printf '%s========================================================%s\n' "$c_blue" "$c_reset"; }
info()   { printf '%s[*]%s %s\n' "$c_green"  "$c_reset" "$1"; }
warn()   { printf '%s[!]%s %s\n' "$c_yellow" "$c_reset" "$1"; }
err()    { printf '%s[x]%s %s\n' "$c_red"    "$c_reset" "$1"; }

have() { command -v "$1" >/dev/null 2>&1; }

# NetExec is 'nxc'; fall back to legacy 'crackmapexec' if that is all that exists.
CME=""
if have nxc; then CME="nxc"; elif have crackmapexec; then CME="crackmapexec"; fi

# Credential fragment shared by NetExec calls.
if [[ -n "$USER" ]]; then
    AUTH_DESC="authenticated as '$USER'"
    CRED=(-u "$USER" -p "$PASS")
else
    AUTH_DESC="anonymous / null session"
    CRED=(-u '' -p '')
fi

# ---- output dir -----------------------------------------------------------
OUTDIR="enum_${IP//[.:]/_}"
mkdir -p "$OUTDIR"
info "Target ......: $IP"
[[ -n "$DOMAIN" ]] && info "Domain ......: $DOMAIN"
info "Auth mode ...: $AUTH_DESC"
info "Output dir ..: $OUTDIR/"

# run <logfile> <command...> : tee output to file + screen, never abort the script
run() {
    local log="$OUTDIR/$1"; shift
    info "\$ $*"
    { "$@"; } 2>&1 | tee "$log"
    echo
}

# =========================================================================
# Phase 1 — Discovery
# =========================================================================
banner "PHASE 1  Discovery & service fingerprint"

if have nmap; then
    run "nmap_ad.txt" nmap -Pn -sV \
        -p 88,135,139,389,445,464,593,636,3268,3269,5985 \
        --script "smb-os-discovery,smb-security-mode,smb2-security-mode,smb-protocols" \
        "$IP"
else
    warn "nmap not found — skipping port scan. Install: sudo apt install nmap"
fi

if [[ -n "$CME" ]]; then
    # Bare NetExec smb call prints OS, domain, and — crucially — signing status.
    run "nxc_hostinfo.txt" "$CME" smb "$IP"
else
    warn "NetExec/crackmapexec not found. Install: pipx install netexec"
fi

# =========================================================================
# Phase 2 — Unauthenticated / credentialed SMB enumeration
# =========================================================================
banner "PHASE 2  SMB session enumeration ($AUTH_DESC)"

if [[ -n "$CME" ]]; then
    run "nxc_shares.txt"  "$CME" smb "$IP" "${CRED[@]}" --shares
    run "nxc_users.txt"   "$CME" smb "$IP" "${CRED[@]}" --users
    run "nxc_groups.txt"  "$CME" smb "$IP" "${CRED[@]}" --groups
    run "nxc_passpol.txt" "$CME" smb "$IP" "${CRED[@]}" --pass-pol

    # RID cycling only makes sense unauthenticated / with guest.
    if [[ -z "$USER" ]]; then
        info "Attempting RID brute force (guest) to recover account names…"
        "$CME" smb "$IP" -u 'guest' -p '' --rid-brute 4000 2>&1 \
            | tee "$OUTDIR/nxc_ridbrute.txt" \
            | grep -i 'SidTypeUser' \
            | sed -E 's/.*\\([^ ]+) .*/\1/' \
            | sort -u > "$OUTDIR/users.txt"
        if [[ -s "$OUTDIR/users.txt" ]]; then
            info "Recovered $(wc -l < "$OUTDIR/users.txt") usernames -> $OUTDIR/users.txt"
        else
            warn "RID brute returned no users (likely RestrictAnonymous). Try kerbrute userenum."
        fi
    fi
fi

if have enum4linux-ng; then
    run "enum4linux-ng.txt" enum4linux-ng -A "$IP"
elif have enum4linux; then
    run "enum4linux.txt" enum4linux -a "$IP"
else
    warn "enum4linux(-ng) not found. Install: pipx install enum4linux-ng"
fi

if have rpcclient; then
    info "rpcclient null-session queries…"
    rpcclient -U "" -N "$IP" \
        -c 'srvinfo;enumdomusers;enumdomgroups;querydominfo;getdompwinfo' \
        2>&1 | tee "$OUTDIR/rpcclient.txt"
    echo
else
    warn "rpcclient not found. Install: sudo apt install samba-common-bin (or smbclient)"
fi

# =========================================================================
# Phase 3 — Share access & loot hints
# =========================================================================
banner "PHASE 3  Share permission map & loot hints"

if have smbmap; then
    run "smbmap.txt" smbmap -H "$IP" ${USER:+-u "$USER"} ${PASS:+-p "$PASS"} ${USER:+-d "$DOMAIN"}
else
    warn "smbmap not found. Install: pipx install smbmap"
fi

if have smbclient; then
    run "smbclient_shares.txt" smbclient -L "//$IP" ${USER:+-U "$USER%$PASS"} ${USER:+} $( [[ -z "$USER" ]] && echo "-N" )
fi

# GPP password hunt — the classic HTB "Active" find — when we have some access.
if [[ -n "$CME" ]]; then
    info "Scanning for Group Policy Preferences (GPP) passwords…"
    "$CME" smb "$IP" "${CRED[@]}" -M gpp_password 2>&1 | tee "$OUTDIR/gpp_password.txt"
    "$CME" smb "$IP" "${CRED[@]}" -M gpp_autologin 2>&1 | tee "$OUTDIR/gpp_autologin.txt"
    echo
fi

# =========================================================================
# Wrap-up — next-step suggestions
# =========================================================================
banner "SUMMARY  Suggested next steps"

cat <<EOF
Artifacts saved under: $OUTDIR/

Follow-ups (see HTB-AD-Samba-Vector.md for full commands):

  • Users found?         -> AS-REP roast:
        impacket-GetNPUsers ${DOMAIN:-DOMAIN}/ -no-pass -usersfile $OUTDIR/users.txt -dc-ip $IP -format hashcat

  • Have a credential?   -> Kerberoast + BloodHound:
        impacket-GetUserSPNs ${DOMAIN:-DOMAIN}/${USER:-USER}:${PASS:-PASS} -dc-ip $IP -request
        bloodhound-python -u ${USER:-USER} -p ${PASS:-PASS} -d ${DOMAIN:-DOMAIN} -ns $IP -c All --zip

  • Signing NOT required? -> Relay is viable (Responder + impacket-ntlmrelayx).

  • Linux Samba service?  -> Check the version banner against §10 CVEs
        (CVE-2007-2447 usermap_script, CVE-2017-7494 SambaCry).

Reminder: authorized lab targets only.
EOF
