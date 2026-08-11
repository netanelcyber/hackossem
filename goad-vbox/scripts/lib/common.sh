# shellcheck shell=bash
# Shared helpers. Source this, do not execute it.
#
#   . "$(dirname "$0")/lib/common.sh"
#
# Note on arithmetic: never use ((x++)) in these scripts. Under `set -e` it
# terminates the shell whenever the pre-increment value is 0, because the
# expression evaluates to 0 and the builtin reports exit status 1. Use
# x=$((x + 1)) instead.

set -euo pipefail

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(dirname "$LIB_DIR")"
REPO_DIR="$(dirname "$SCRIPTS_DIR")"
LOG_DIR="$REPO_DIR/logs"
BUILD_DIR_DEFAULT="$REPO_DIR/build"

mkdir -p "$LOG_DIR"

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    C_RED=$'\033[0;31m'; C_GREEN=$'\033[0;32m'; C_YELLOW=$'\033[1;33m'
    C_BLUE=$'\033[0;34m'; C_DIM=$'\033[2m';     C_OFF=$'\033[0m'
else
    C_RED=''; C_GREEN=''; C_YELLOW=''; C_BLUE=''; C_DIM=''; C_OFF=''
fi

log_info()  { printf '%s\n' "$*"; }
log_ok()    { printf '%s✓%s %s\n'  "$C_GREEN"  "$C_OFF" "$*"; }
log_warn()  { printf '%s!%s %s\n'  "$C_YELLOW" "$C_OFF" "$*"; }
log_err()   { printf '%s✗%s %s\n'  "$C_RED"    "$C_OFF" "$*" >&2; }
log_step()  { printf '\n%s==>%s %s\n' "$C_BLUE" "$C_OFF" "$*"; }
log_dim()   { printf '%s%s%s\n' "$C_DIM" "$*" "$C_OFF"; }

die() { log_err "$*"; exit 1; }

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "required command not found: $1${2:+ ($2)}"
}

# --- configuration ---------------------------------------------------------

load_config() {
    local conf="${1:-$REPO_DIR/lab.conf}"
    [ -f "$conf" ] || die "config not found: $conf"
    # shellcheck disable=SC1090
    . "$conf"
    LAB_BUILD_DIR="${LAB_BUILD_DIR:-$BUILD_DIR_DEFAULT}"
    [ -n "$LAB_BUILD_DIR" ] || LAB_BUILD_DIR="$BUILD_DIR_DEFAULT"
    LAB_ISO_DIR="${LAB_ISO_DIR:-$REPO_DIR/isos}"
    [ -n "$LAB_ISO_DIR" ] || LAB_ISO_DIR="$REPO_DIR/isos"
}

# iso_path <oskey> -> the ISO to use for that OS key.
# An explicit ISO_<oskey> wins (from lab.conf or --iso-<oskey>); otherwise it
# defaults to the canonical download location, so fetch-isos.sh output is found
# automatically with no flags.
iso_path() {
    local oskey="$1" var="ISO_$1"
    local explicit="${!var:-}"
    if [ -n "$explicit" ]; then
        printf '%s' "$explicit"
    else
        printf '%s/%s.iso' "$LAB_ISO_DIR" "$oskey"
    fi
}

# lab_vms <variant> -> one "name:os:ram:cpu:disk:octet:role" record per line
lab_vms() {
    local variant="$1" var="LAB_VMS_$1"
    local value="${!var:-}"
    [ -n "$value" ] || die "unknown variant '$variant' (expected: full, light)"
    printf '%s\n' "$value" | sed '/^[[:space:]]*$/d'
}

vm_name()  { printf '%s' "${1%%:*}"; }
vm_field() { printf '%s' "$1" | cut -d: -f"$2"; }
vm_ip()    { printf '%s.%s' "$GOAD_SUBNET" "$(vm_field "$1" 6)"; }

# The forest root's address, derived from the table rather than hardcoded.
# Every other machine uses it as its DNS server, which is the single most
# common thing to get wrong in a hand-built AD lab.
lab_root_dc_ip() {
    local variant="$1" record
    while IFS= read -r record; do
        [ -n "$record" ] || continue
        if [ "$(vm_field "$record" 7)" = "dc_root" ]; then
            vm_ip "$record"; return 0
        fi
    done <<EOF
$(lab_vms "$variant")
EOF
    die "variant '$variant' defines no dc_root"
}

lab_root_dc_name() {
    local variant="$1" record
    while IFS= read -r record; do
        [ -n "$record" ] || continue
        if [ "$(vm_field "$record" 7)" = "dc_root" ]; then
            vm_name "$record"; return 0
        fi
    done <<EOF
$(lab_vms "$variant")
EOF
    die "variant '$variant' defines no dc_root"
}

# --- VirtualBox ------------------------------------------------------------

vbox_vm_exists()     { VBoxManage list vms         | grep -q "^\"$1\" "; }
vbox_vm_running()    { VBoxManage list runningvms  | grep -q "^\"$1\" "; }

# --- misc ------------------------------------------------------------------

confirm() {
    [ "${ASSUME_YES:-false}" = true ] && return 0
    local reply
    printf '%s [y/N] ' "$1"
    read -r reply || true
    case "$reply" in [yY]|[yY][eE][sS]) return 0 ;; *) return 1 ;; esac
}

# Render an @@PLACEHOLDER@@ template using pure bash substitution, so payload
# values containing / & ! \ (passwords, notably) need no escaping the way they
# would with sed.
render_template() {
    local src="$1" dst="$2"; shift 2
    local content pair key value
    content="$(cat "$src")"
    for pair in "$@"; do
        key="${pair%%=*}"
        value="${pair#*=}"
        content="${content//@@${key}@@/$value}"
    done
    if printf '%s' "$content" | grep -qo '@@[A-Z_]*@@'; then
        die "unsubstituted placeholder in $(basename "$src"): $(printf '%s' "$content" | grep -o '@@[A-Z_]*@@' | sort -u | tr '\n' ' ')"
    fi
    printf '%s\n' "$content" > "$dst"
}

# --- host-only networking --------------------------------------------------
# VirtualBox "internal" networks (intnet) are deliberately isolated from the
# host, so an Ansible controller running on the host could never reach the
# guests. Host-only gives host<->guest plus guest<->guest with no internet.
#
# Since 6.1.28 VirtualBox refuses host-only addresses outside 192.168.56.0/21
# unless /etc/vbox/networks.conf permits it, which is why lab.conf uses .56.

hostonly_find() {
    # Print the name of the host-only interface holding GOAD_HOSTONLY_HOST_IP.
    VBoxManage list hostonlyifs 2>/dev/null | awk -v want="$GOAD_HOSTONLY_HOST_IP" '
        /^Name:/        { name = $2 }
        /^IPAddress:/   { if ($2 == want) { print name; exit } }
    '
}

hostonly_require() {
    local ifname
    ifname="$(hostonly_find)"
    [ -n "$ifname" ] || die "no host-only interface on $GOAD_HOSTONLY_HOST_IP — run scripts/network-setup.sh first"
    printf '%s' "$ifname"
}

# Resolve a guest OS type, falling back when the running VirtualBox is older
# than the guest. Windows2022_64 only exists from VirtualBox 7.0; on 6.1 a
# Server 2022 guest installs perfectly well typed as Windows2019_64.
vbox_ostype() {
    local preferred="$1" fallback="$2"
    if VBoxManage list ostypes 2>/dev/null | grep -qE "^ID:[[:space:]]+${preferred}$"; then
        printf '%s' "$preferred"
    else
        printf '%s' "$fallback"
    fi
}
