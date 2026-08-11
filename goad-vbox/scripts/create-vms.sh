#!/usr/bin/env bash
# Create the lab VMs and attach both the Windows ISO and the per-VM unattend
# ISO, so that starting a VM performs a complete hands-off install.

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

VARIANT="full"
CONF=""
FORCE=false

usage() {
    cat <<'EOF'
usage: create-vms.sh [options]
  --variant full|light|nested   which VM set to create (default: full)
  --iso-<oskey> PATH            media for an OS key used by the variant,
                                e.g. --iso-win2019, --iso-win2022, --iso-win10
  --force                       recreate VMs that already exist
  --config FILE                 alternate lab.conf
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --variant) VARIANT="$2"; shift 2 ;;
        --force)   FORCE=true; shift ;;
        --config)  CONF="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        # --iso-<oskey> sets ISO_<oskey>, so new OS keys in lab.conf need no
        # matching change here.
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
require_cmd VBoxManage "install VirtualBox"

ifname="$(hostonly_require)"
log_dim "host-only interface: $ifname"

# Validate every ISO the chosen variant needs before creating anything, so a
# missing path fails immediately instead of halfway through.
declare -A needed_iso=()
while IFS= read -r record; do
    [ -n "$record" ] || continue
    oskey="$(vm_field "$record" 2)"
    path="$(iso_path "$oskey")"
    [ -f "$path" ] || die "ISO not found for '$oskey': $path (pass --iso-$oskey, set ISO_$oskey, or run scripts/fetch-isos.sh)"
    needed_iso[$oskey]="$path"
done <<EOF
$(lab_vms "$VARIANT")
EOF

for key in "${!needed_iso[@]}"; do
    log_dim "$key -> ${needed_iso[$key]}"
done

log_step "Creating VMs for GOAD-$VARIANT"

created=0 skipped=0

while IFS= read -r record; do
    [ -n "$record" ] || continue

    name="$(vm_name  "$record")"
    oskey="$(vm_field "$record" 2)"
    ram="$(vm_field   "$record" 3)"
    cpus="$(vm_field  "$record" 4)"
    disk="$(vm_field  "$record" 5)"
    ip="$(vm_ip       "$record")"
    role="$(vm_field  "$record" 7)"

    win_iso="${needed_iso[$oskey]}"
    unattend_iso="$LAB_BUILD_DIR/$name/unattend.iso"
    [ -f "$unattend_iso" ] || die "missing $unattend_iso — run scripts/build-unattend-iso.sh first"

    if vbox_vm_exists "$name"; then
        if [ "$FORCE" != true ]; then
            log_warn "$name already exists — skipping (use --force to recreate)"
            skipped=$((skipped + 1))
            continue
        fi
        vbox_vm_running "$name" && VBoxManage controlvm "$name" poweroff >/dev/null 2>&1 || true
        sleep 2
        VBoxManage unregistervm "$name" --delete >/dev/null
        log_dim "removed existing $name"
    fi

    case "$oskey" in
        win2016) ostype="Windows2016_64" ;;
        win2019) ostype="Windows2019_64" ;;
        win2022) ostype="$(vbox_ostype Windows2022_64 Windows2019_64)" ;;
        win10)   ostype="Windows10_64"   ;;
        *)       ostype="Windows2019_64" ;;
    esac

    VBoxManage createvm --name "$name" --ostype "$ostype" \
        --basefolder "$LAB_VM_BASEFOLDER" --register >/dev/null

    vm_dir="$LAB_VM_BASEFOLDER/$name"
    disk_path="$vm_dir/$name.vdi"
    VBoxManage createmedium disk --filename "$disk_path" \
        --size $((disk * 1024)) --format VDI >/dev/null

    VBoxManage storagectl "$name" --name SATA --add sata \
        --controller IntelAHCI --portcount 4 --bootable on >/dev/null

    VBoxManage storageattach "$name" --storagectl SATA \
        --port 0 --device 0 --type hdd --medium "$disk_path" >/dev/null

    # Port 1: Windows installation media. Port 2: the generated unattend
    # volume. Setup scans every volume root for autounattend.xml, which is why
    # the Windows ISO itself never has to be modified.
    VBoxManage storageattach "$name" --storagectl SATA \
        --port 1 --device 0 --type dvddrive --medium "$win_iso" >/dev/null
    VBoxManage storageattach "$name" --storagectl SATA \
        --port 2 --device 0 --type dvddrive --medium "$unattend_iso" >/dev/null

    # BIOS firmware to match the MBR layout in autounattend.xml.
    VBoxManage modifyvm "$name" \
        --memory "$ram" --cpus "$cpus" --vram 32 \
        --firmware "$LAB_FIRMWARE" \
        --nic1 hostonly --hostonlyadapter1 "$ifname" --nictype1 82540EM \
        --nic2 none --nic3 none --nic4 none \
        --audio none --usb off \
        --boot1 dvd --boot2 disk --boot3 none --boot4 none \
        --rtcuseutc on --clipboard bidirectional >/dev/null

    log_ok "$(printf '%-6s' "$name") ${cpus}cpu ${ram}MB ${disk}GB  $ip  $role"
    created=$((created + 1))

done <<EOF
$(lab_vms "$VARIANT")
EOF

log_info ""
log_ok "created $created VM(s), skipped $skipped"
[ "$created" -gt 0 ] && log_dim "next: scripts/deploy-all.sh continues automatically, or start them yourself with VBoxManage startvm <name> --type headless"
exit 0
