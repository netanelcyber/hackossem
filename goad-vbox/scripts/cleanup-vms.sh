#!/usr/bin/env bash
# Power off and delete the VMs for a variant, and optionally the L1 host and
# generated build artifacts.

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

VARIANT="full"
CONF=""
DROP_L1=false
DROP_BUILD=false
ASSUME_YES="${ASSUME_YES:-false}"   # read by confirm() in lib/common.sh

usage() {
    cat <<'EOF'
usage: cleanup-vms.sh [--variant full|light|nested] [options]
  --l1        also delete the goad-l1 nested host
  --build     also delete generated build/ artifacts
  --yes       do not prompt
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --variant) VARIANT="$2"; shift 2 ;;
        --l1)      DROP_L1=true; shift ;;
        --build)   DROP_BUILD=true; shift ;;
        --yes)     ASSUME_YES=true; shift ;;
        --config)  CONF="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) die "unknown option: $1" ;;
    esac
done

load_config "${CONF:-}"
require_cmd VBoxManage

targets=()
while IFS= read -r record; do
    [ -n "$record" ] || continue
    targets+=("$(vm_name "$record")")
done <<EOF
$(lab_vms "$VARIANT")
EOF
[ "$DROP_L1" = true ] && targets+=("goad-l1")

log_step "Cleanup for GOAD-$VARIANT"
existing=()
for name in "${targets[@]}"; do
    vbox_vm_exists "$name" && existing+=("$name")
done

if [ "${#existing[@]}" -eq 0 ]; then
    log_info "no matching VMs registered"
else
    log_warn "will DELETE: ${existing[*]}"
    confirm "Destroy these VMs and their disks?" || { log_info "aborted"; exit 0; }
    for name in "${existing[@]}"; do
        vbox_vm_running "$name" && VBoxManage controlvm "$name" poweroff >/dev/null 2>&1 || true
    done
    sleep 2
    for name in "${existing[@]}"; do
        VBoxManage unregistervm "$name" --delete >/dev/null && log_ok "deleted $name"
    done
fi

if [ "$DROP_BUILD" = true ] && [ -d "$LAB_BUILD_DIR" ]; then
    rm -rf "$LAB_BUILD_DIR"
    log_ok "removed $LAB_BUILD_DIR"
fi

log_info ""
log_ok "cleanup complete"
