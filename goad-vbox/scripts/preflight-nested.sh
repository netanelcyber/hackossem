#!/usr/bin/env bash
# Run this INSIDE the L1 VM, right before deploying the nested variant.
#
# It fails fast, with a clear message, on the ways a nested lab is broken before
# you've sunk 20 minutes into a Windows install that was never going to boot:
# nesting never reached L1, VirtualBox can't run 64-bit guests, the kernel
# modules aren't up, KVM is holding the virtualisation extensions, or L1 is too
# small for the guests it's about to start.
#
# deploy-all.sh runs this automatically for --variant nested; you can also run
# it by hand.

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

CONF=""
while [ $# -gt 0 ]; do
    case "$1" in
        --config)  CONF="$2"; shift 2 ;;
        -h|--help) echo "usage: preflight-nested.sh   (run inside the L1 VM)"; exit 0 ;;
        *) die "unknown option: $1" ;;
    esac
done
load_config "${CONF:-}"

failed=0
fail() { log_err "$*"; failed=$((failed + 1)); }

log_step "Nested preflight (run me inside L1)"

# 1. Nesting actually reached this VM. This is THE check — without vmx/svm here,
#    L1 received no nested virtualisation and Windows guests cannot boot.
if grep -qwE 'vmx|svm' /proc/cpuinfo; then
    ext="$(grep -qw vmx /proc/cpuinfo && echo 'VT-x (vmx)' || echo 'AMD-V (svm)')"
    log_ok "virtualisation extensions present in L1: $ext"
else
    fail "no vmx/svm in /proc/cpuinfo — nesting did NOT reach this VM"
    log_dim "  on the PHYSICAL host, with L1 powered off:"
    log_dim "    VBoxManage modifyvm goad-l1 --nested-hw-virt on --nested-paging on"
    log_dim "  then start L1 again and re-run this."
fi

# 2. VirtualBox present and able to enumerate 64-bit guest types.
if command -v VBoxManage >/dev/null 2>&1; then
    log_ok "VBoxManage $(VBoxManage --version 2>/dev/null | head -1)"
    if VBoxManage list ostypes 2>/dev/null | grep -q 'Windows2022_64\|Windows2019_64'; then
        log_ok "64-bit Windows guest types available"
    else
        fail "VirtualBox lists no 64-bit Windows guest types — VT-x/AMD-V not usable inside L1"
    fi
else
    fail "VBoxManage not found — run templates/l1-provision.sh first"
fi

# 3. Kernel modules up.
if lsmod 2>/dev/null | grep -q '^vboxdrv'; then
    log_ok "vboxdrv loaded"
else
    fail "vboxdrv not loaded — run: sudo modprobe vboxdrv (or sudo /sbin/vboxconfig)"
fi
if lsmod 2>/dev/null | grep -q '^vboxnetadp'; then
    log_ok "vboxnetadp loaded (needed for the host-only lab network)"
else
    fail "vboxnetadp not loaded — run: sudo modprobe vboxnetadp"
fi

# 4. KVM must not be holding the virtualisation extensions; whoever grabs them
#    first wins and the other silently degrades to emulation.
if lsmod 2>/dev/null | grep -qE '^kvm_(intel|amd)'; then
    fail "kvm_intel/kvm_amd is loaded and will contend with VirtualBox"
    log_dim "  free them: sudo modprobe -r kvm_intel kvm_amd"
fi

# 5. Enough memory for the guests L1 is about to start.
need_mb=0; guests=0
while IFS= read -r record; do
    [ -n "$record" ] || continue
    need_mb=$((need_mb + $(vm_field "$record" 3)))
    guests=$((guests + 1))
done <<EOF
$(lab_vms nested)
EOF
avail_mb="$(free -m 2>/dev/null | awk '/^Mem:/ {print $2}')"
if [ -n "$avail_mb" ]; then
    # Leave ~1.5GB for Xubuntu itself.
    if [ "$avail_mb" -ge $((need_mb + 1536)) ]; then
        log_ok "L1 memory ${avail_mb}MB covers ${guests} guests (${need_mb}MB) + headroom"
    else
        fail "L1 has ${avail_mb}MB; ${guests} nested guests need ${need_mb}MB plus headroom for Xubuntu"
        log_dim "  give L1 more RAM (physical host: VBoxManage modifyvm goad-l1 --memory NNNN)"
        log_dim "  or trim the LAB_VMS_nested table"
    fi
fi

log_info ""
if [ "$failed" -eq 0 ]; then
    log_ok "nested preflight passed — safe to deploy"
    exit 0
fi
log_err "$failed blocking problem(s) — fix the above before deploying the nested lab"
exit 1
