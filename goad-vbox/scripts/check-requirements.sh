#!/usr/bin/env bash
# Verify the host can build and drive the lab.

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

VARIANT="full"
CONF=""
while [ $# -gt 0 ]; do
    case "$1" in
        --variant) VARIANT="$2"; shift 2 ;;
        --config)  CONF="$2";    shift 2 ;;
        -h|--help) echo "usage: check-requirements.sh [--variant full|light|nested] [--iso-<oskey> PATH]"; exit 0 ;;
        # Accept the same --iso-<oskey> flags as create-vms/deploy-all, so the
        # media check validates exactly what the caller passed.
        --iso-*)
            oskey="${1#--iso-}"
            [ -n "${2:-}" ] || die "$1 needs a path"
            printf -v "ISO_$oskey" '%s' "$2"
            export "ISO_$oskey"
            shift 2 ;;
        *) die "unknown option: $1" ;;
    esac
done

load_config "${CONF:-}"

failed=0
warned=0
fail() { log_err  "$*"; failed=$((failed + 1)); }
warn() { log_warn "$*"; warned=$((warned + 1)); }

# Sum the resources the chosen variant actually asks for rather than quoting a
# fixed number that drifts out of step with lab.conf.
need_ram_mb=0
need_disk_gb=0
vm_count=0
while IFS= read -r record; do
    [ -n "$record" ] || continue
    need_ram_mb=$((need_ram_mb + $(vm_field "$record" 3)))
    need_disk_gb=$((need_disk_gb + $(vm_field "$record" 5)))
    vm_count=$((vm_count + 1))
done <<EOF
$(lab_vms "$VARIANT")
EOF
need_ram_gb=$(( (need_ram_mb + 1023) / 1024 ))

log_step "GOAD-$VARIANT needs $vm_count VMs: ${need_ram_gb}GB RAM, ${need_disk_gb}GB disk"

log_step "VirtualBox"
if command -v VBoxManage >/dev/null 2>&1; then
    log_ok "VBoxManage $(VBoxManage --version 2>/dev/null | head -1)"
    if [ "$(uname -s)" = "Linux" ]; then
        if lsmod 2>/dev/null | grep -q '^vboxdrv'; then
            log_ok "vboxdrv kernel module loaded"
        else
            fail "vboxdrv kernel module not loaded — run: sudo modprobe vboxdrv"
        fi
        if lsmod 2>/dev/null | grep -q '^vboxnetadp'; then
            log_ok "vboxnetadp kernel module loaded (needed for host-only)"
        else
            warn "vboxnetadp not loaded — host-only creation will fail; run: sudo modprobe vboxnetadp"
        fi
    fi
    if [ -n "$(hostonly_find 2>/dev/null)" ]; then
        log_ok "host-only interface present on $GOAD_HOSTONLY_HOST_IP"
    else
        log_dim "  host-only interface not created yet (network-setup.sh will make it)"
    fi
else
    fail "VBoxManage not found — install VirtualBox"
fi

log_step "Ansible control tooling"
if command -v ansible-playbook >/dev/null 2>&1; then
    log_ok "$(ansible --version 2>/dev/null | head -1)"

    if python3 -c 'import winrm' >/dev/null 2>&1; then
        log_ok "pywinrm importable"
    else
        fail "pywinrm missing — Ansible cannot speak WinRM; run: python3 -m pip install pywinrm"
    fi

    have_collection() {
        ansible-galaxy collection list "$1" >/dev/null 2>&1 &&
        ansible-galaxy collection list "$1" 2>/dev/null | grep -q "^$1 "
    }
    for coll in ansible.windows microsoft.ad community.windows; do
        if have_collection "$coll"; then
            log_ok "collection $coll"
        else
            fail "collection $coll missing — run: ansible-galaxy collection install $coll"
        fi
    done
else
    fail "ansible-playbook not found — install Ansible"
fi

log_step "ISO authoring"
writer=""
for tool in xorriso genisoimage mkisofs hdiutil; do
    if command -v "$tool" >/dev/null 2>&1; then writer="$tool"; break; fi
done
if [ -n "$writer" ]; then
    log_ok "native ISO writer: $writer"
elif command -v python3 >/dev/null 2>&1; then
    log_ok "no native ISO writer, will use bundled scripts/lib/mkiso.py"
else
    fail "no ISO writer and no python3 — install xorriso or genisoimage"
fi

log_step "Windows media"
while IFS= read -r oskey; do
    var="ISO_$oskey"
    path="${!var:-}"
    if [ -z "$path" ]; then
        warn "$var not set — pass --iso-$oskey to create-vms.sh or set it in lab.conf"
    elif [ -f "$path" ]; then
        log_ok "$oskey $(du -h "$path" 2>/dev/null | cut -f1) $path"
    else
        fail "$var points at a missing file: $path"
    fi
done <<EOF
$(lab_vms "$VARIANT" | cut -d: -f2 | sort -u)
EOF

log_step "Host resources"
if command -v free >/dev/null 2>&1; then
    avail_mb=$(free -m | awk '/^Mem:/ {print $7 ? $7 : $4}')
    if [ "${avail_mb:-0}" -ge "$need_ram_mb" ]; then
        log_ok "RAM available ${avail_mb}MB >= ${need_ram_mb}MB required"
    else
        warn "RAM available ${avail_mb}MB < ${need_ram_mb}MB required — VMs will swap"
    fi
fi

target="$LAB_VM_BASEFOLDER"
while [ ! -d "$target" ] && [ "$target" != "/" ]; do target="$(dirname "$target")"; done
if avail_gb=$(df -BG "$target" 2>/dev/null | awk 'NR==2 {gsub(/G/,"",$4); print $4}'); then
    if [ "${avail_gb:-0}" -ge "$need_disk_gb" ]; then
        log_ok "disk available ${avail_gb}GB >= ${need_disk_gb}GB required at $target"
    else
        warn "disk available ${avail_gb}GB < ${need_disk_gb}GB required at $target (VDIs grow on demand, so this may still fit)"
    fi
fi

log_info ""
if [ "$failed" -eq 0 ]; then
    [ "$warned" -eq 0 ] && log_ok "all checks passed" || log_ok "checks passed with $warned warning(s)"
    exit 0
fi
log_err "$failed blocking problem(s), $warned warning(s)"
exit 1
