#!/usr/bin/env bash
# Verify a provisioned lab: connectivity, domain, membership, seeded content.

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

VARIANT="full"
CONF=""
INVENTORY=""

while [ $# -gt 0 ]; do
    case "$1" in
        --variant)   VARIANT="$2";   shift 2 ;;
        --inventory) INVENTORY="$2"; shift 2 ;;
        --config)    CONF="$2";      shift 2 ;;
        -h|--help)   echo "usage: health-check.sh [--variant full|light|nested] [--inventory FILE]"; exit 0 ;;
        *) die "unknown option: $1" ;;
    esac
done

load_config "${CONF:-}"
require_cmd ansible "install Ansible"
INVENTORY="${INVENTORY:-$REPO_DIR/inventory/hosts.ini}"
[ -f "$INVENTORY" ] || die "inventory not found: $INVENTORY (generate it or pass --inventory)"

export ANSIBLE_CONFIG="$REPO_DIR/ansible.cfg"
failed=0
check() { if eval "$2" >/dev/null 2>&1; then log_ok "$1"; else log_err "$1"; failed=$((failed + 1)); fi; }

root_dc="$(lab_root_dc_name "$VARIANT")"

log_step "Connectivity"
check "all hosts answer WinRM" \
    "ansible -i '$INVENTORY' windows -m ansible.windows.win_ping"

log_step "Active Directory on $root_dc"
check "forest root reports domain $GOAD_DOMAIN" \
    "ansible -i '$INVENTORY' $root_dc -m ansible.windows.win_shell \
        -a '(Get-ADDomain).DNSRoot' | grep -q '$GOAD_DOMAIN'"

check "seeded user jsnow exists" \
    "ansible -i '$INVENTORY' $root_dc -m ansible.windows.win_shell \
        -a 'Get-ADUser -Identity jsnow' "

check "kerberoastable SPN present on svc_sql" \
    "ansible -i '$INVENTORY' $root_dc -m ansible.windows.win_shell \
        -a 'setspn -L $GOAD_NETBIOS\\svc_sql' | grep -qi MSSQLSvc"

log_step "Domain membership"
# Only meaningful if the variant has members; light/full/nested all do.
if ansible -i "$INVENTORY" domain_members --list-hosts >/dev/null 2>&1; then
    check "all members report domain $GOAD_DOMAIN" \
        "ansible -i '$INVENTORY' domain_members -m ansible.windows.win_shell \
            -a '(Get-CimInstance Win32_ComputerSystem).Domain' | grep -q '$GOAD_DOMAIN'"
fi

log_info ""
if [ "$failed" -eq 0 ]; then
    log_ok "lab healthy"
    exit 0
fi
log_err "$failed check(s) failed"
exit 1
