#!/usr/bin/env bash
# Block until every VM in the variant answers on WinRM.
#
# This is the join between the unattended install and the Ansible run: Windows
# Setup reboots several times and bootstrap.ps1 only opens 5985 at the very
# end, so a listening port is a reliable "this machine is finished installing"
# signal.

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

VARIANT="full"
CONF=""
TIMEOUT=3600          # generous: a cold Windows Server install can take a while
INTERVAL=15

while [ $# -gt 0 ]; do
    case "$1" in
        --variant)  VARIANT="$2";  shift 2 ;;
        --timeout)  TIMEOUT="$2";  shift 2 ;;
        --interval) INTERVAL="$2"; shift 2 ;;
        --config)   CONF="$2";     shift 2 ;;
        -h|--help)  echo "usage: wait-for-winrm.sh [--variant full|light] [--timeout SEC]"; exit 0 ;;
        *) die "unknown option: $1" ;;
    esac
done

load_config "${CONF:-}"

# bash's /dev/tcp avoids depending on nc, which is absent on many hosts.
port_open() {
    timeout 3 bash -c "exec 3<>/dev/tcp/$1/$2" 2>/dev/null
}

names=(); ips=()
while IFS= read -r record; do
    [ -n "$record" ] || continue
    names+=("$(vm_name "$record")")
    ips+=("$(vm_ip "$record")")
done <<EOF
$(lab_vms "$VARIANT")
EOF

total=${#names[@]}
log_step "Waiting for WinRM on $total machine(s), timeout ${TIMEOUT}s"
log_dim "Windows installs unattended, reboots a few times, then opens 5985."

start=$(date +%s)
declare -A ready=()

while :; do
    for i in "${!names[@]}"; do
        name="${names[$i]}"
        [ "${ready[$name]:-}" = yes ] && continue
        if port_open "${ips[$i]}" 5985; then
            ready[$name]=yes
            elapsed=$(( $(date +%s) - start ))
            log_ok "$(printf '%-6s' "$name") ${ips[$i]}:5985 open after ${elapsed}s"
        fi
    done

    count=0
    for name in "${names[@]}"; do
        [ "${ready[$name]:-}" = yes ] && count=$((count + 1))
    done
    [ "$count" -eq "$total" ] && break

    elapsed=$(( $(date +%s) - start ))
    if [ "$elapsed" -ge "$TIMEOUT" ]; then
        log_info ""
        log_err "timed out after ${elapsed}s with $count/$total ready"
        for i in "${!names[@]}"; do
            name="${names[$i]}"
            if [ "${ready[$name]:-}" != yes ]; then
                state="$(VBoxManage showvminfo "$name" --machinereadable 2>/dev/null | sed -n 's/^VMState="\(.*\)"$/\1/p')"
                log_err "  $name (${ips[$i]}) not ready — VM state: ${state:-unknown}"
            fi
        done
        log_info ""
        log_dim "Attach to a stuck VM to see where it is:"
        log_dim "  VBoxManage startvm <name> --type separate    # opens a console window"
        log_dim "  or read C:\\goad-bootstrap.log inside the guest"
        exit 1
    fi

    printf '\r%s  %d/%d ready, %ds elapsed%s' "$C_DIM" "$count" "$total" "$elapsed" "$C_OFF"
    sleep "$INTERVAL"
done

printf '\r%*s\r' 60 ''
log_info ""
log_ok "all $total machine(s) reachable on WinRM"
