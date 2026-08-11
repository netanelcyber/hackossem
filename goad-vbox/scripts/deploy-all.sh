#!/usr/bin/env bash
# End-to-end, hands-off: network -> unattend media -> VMs -> boot -> wait ->
# provision -> verify. This is "Option B": after the ISOs are in place, one
# command produces a running, provisioned GOAD lab with no GUI interaction.

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

VARIANT="full"
CONF=""
ISO_ARGS=()
SKIP_PROVISION=false
ASSUME_YES="${ASSUME_YES:-false}"   # read by confirm() in lib/common.sh

usage() {
    cat <<'EOF'
usage: deploy-all.sh --variant full|light|nested [--iso-<oskey> PATH ...]
  --variant NAME       VM set to deploy (default: full)
  --iso-<oskey> PATH   Windows media, e.g. --iso-win2019 / --iso-win2022 / --iso-win10
  --skip-provision     build and boot the VMs but stop before Ansible
  --yes                do not prompt for confirmation
  --config FILE        alternate lab.conf

Runs: check -> network -> unattend ISOs -> create VMs -> boot ->
      wait for WinRM -> generate inventory -> provision -> health check.
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --variant)        VARIANT="$2"; shift 2 ;;
        --skip-provision) SKIP_PROVISION=true; shift ;;
        --yes)            ASSUME_YES=true; shift ;;
        --config)         CONF="$2"; shift 2 ;;
        --iso-*)          ISO_ARGS+=("$1" "$2"); shift 2 ;;
        -h|--help)        usage; exit 0 ;;
        *) die "unknown option: $1" ;;
    esac
done

load_config "${CONF:-}"
conf_flag=(); [ -n "$CONF" ] && conf_flag=(--config "$CONF")

vm_list="$(lab_vms "$VARIANT")"
count="$(printf '%s\n' "$vm_list" | grep -c .)"

log_step "GOAD-$VARIANT — full unattended deploy"
printf '%s\n' "$vm_list" | while IFS= read -r r; do
    [ -n "$r" ] || continue
    log_dim "  $(printf '%-6s' "$(vm_name "$r")") $(vm_ip "$r")  $(vm_field "$r" 7)"
done
log_info ""
confirm "Create and provision $count VM(s)?" || { log_info "aborted"; exit 0; }

# 1. host readiness (warnings ok, blocking failures stop us)
bash "$SCRIPTS_DIR/check-requirements.sh" --variant "$VARIANT" "${conf_flag[@]}" \
    "${ISO_ARGS[@]}" || die "requirements not met"

# 2. network
bash "$SCRIPTS_DIR/network-setup.sh" "${conf_flag[@]}"

# 3. unattend media
bash "$SCRIPTS_DIR/build-unattend-iso.sh" --variant "$VARIANT" "${conf_flag[@]}"

# 4. VMs
bash "$SCRIPTS_DIR/create-vms.sh" --variant "$VARIANT" "${conf_flag[@]}" "${ISO_ARGS[@]}"

# 5. boot every VM headless; the unattend media drives the install
log_step "Booting VMs (unattended install begins now)"
while IFS= read -r record; do
    [ -n "$record" ] || continue
    name="$(vm_name "$record")"
    if vbox_vm_running "$name"; then
        log_dim "$name already running"
    else
        VBoxManage startvm "$name" --type headless >/dev/null
        log_ok "started $name"
    fi
done <<EOF
$vm_list
EOF

if [ "$SKIP_PROVISION" = true ]; then
    log_info ""
    log_ok "VMs are installing. Stopping before provisioning as requested."
    log_dim "when they are up:  scripts/apply-provisioning.sh --variant $VARIANT"
    exit 0
fi

# 6. wait for all of them to finish installing and open WinRM
bash "$SCRIPTS_DIR/wait-for-winrm.sh" --variant "$VARIANT" "${conf_flag[@]}"

# 7 + 8. provision, then verify
bash "$SCRIPTS_DIR/apply-provisioning.sh" --variant "$VARIANT" "${conf_flag[@]}"
bash "$SCRIPTS_DIR/health-check.sh" --variant "$VARIANT" "${conf_flag[@]}"

log_info ""
log_ok "GOAD-$VARIANT is up and provisioned."
log_dim "RDP:  xfreerdp /u:$GOAD_NETBIOS\\\\Administrator /p:'$GOAD_ADMIN_PASSWORD' /v:$(lab_root_dc_ip "$VARIANT")"
