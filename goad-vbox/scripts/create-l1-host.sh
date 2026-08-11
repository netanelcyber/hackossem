#!/usr/bin/env bash
# Create the L1 "lab in a box" VM: a Linux guest with nested hardware
# virtualisation enabled, which then runs VirtualBox itself to host the
# nested variant (Server 2022 DC + three Windows 10 endpoints).
#
#   physical host
#   └── L1  goad-l1        Debian/Ubuntu, nested-hw-virt on, runs VirtualBox
#       ├── dc01           Windows Server 2022, forest root
#       ├── ws01           Windows 10
#       ├── ws02           Windows 10
#       └── ws03           Windows 10
#
# Caveat, stated plainly: VirtualBox inside VirtualBox is not a configuration
# Oracle supports. It generally works on AMD-V and is more fragile on Intel
# VT-x, and the nested Windows guests run several times slower than they would
# flat. Everything here is tuned to give it the best chance, but if a nested
# guest refuses to boot, that is the known failure mode rather than a bug in
# this script — the flat 'full'/'light' variants remain the reliable path.

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

L1_NAME="goad-l1"
L1_CPUS=8
L1_RAM=14336            # 14 GB: 4 (DC) + 3x2 (endpoints) + headroom for L1
L1_DISK=250             # dynamically allocated, so this is a ceiling not a cost
L1_ISO=""
CONF=""
FORCE=false

usage() {
    cat <<'EOF'
usage: create-l1-host.sh --iso PATH [options]
  --iso PATH        Linux installer ISO for L1 (Debian 12 or Ubuntu 22.04+)
  --name NAME       L1 VM name (default: goad-l1)
  --cpus N          vCPUs for L1 (default: 8)
  --ram MB          memory for L1 (default: 14336)
  --disk GB         virtual disk ceiling for L1 (default: 250)
  --force           recreate L1 if it already exists
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --iso)   L1_ISO="$2";  shift 2 ;;
        --name)  L1_NAME="$2"; shift 2 ;;
        --cpus)  L1_CPUS="$2"; shift 2 ;;
        --ram)   L1_RAM="$2";  shift 2 ;;
        --disk)  L1_DISK="$2"; shift 2 ;;
        --force) FORCE=true;   shift ;;
        --config) CONF="$2";   shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) die "unknown option: $1" ;;
    esac
done

load_config "${CONF:-}"
require_cmd VBoxManage "install VirtualBox"

[ -n "$L1_ISO" ] || { usage; die "--iso is required"; }
[ -f "$L1_ISO" ] || die "ISO not found: $L1_ISO"

# --- can this host nest at all? -------------------------------------------
log_step "Nested virtualisation preflight"

if [ -r /proc/cpuinfo ]; then
    if grep -qw vmx /proc/cpuinfo; then
        log_ok "CPU exposes Intel VT-x"
        log_dim "  VBox-in-VBox is more fragile on Intel than on AMD; expect slow nested guests"
    elif grep -qw svm /proc/cpuinfo; then
        log_ok "CPU exposes AMD-V (the better case for nesting)"
    else
        die "CPU exposes neither vmx nor svm — this host cannot do nested virtualisation"
    fi

    # VirtualBox and KVM both want exclusive control of the virtualisation
    # extensions; whichever grabs them first wins and the other degrades.
    if lsmod 2>/dev/null | grep -qE '^kvm_(intel|amd)'; then
        log_warn "kvm_intel/kvm_amd is loaded and will contend with VirtualBox"
        log_dim "  free the extensions with: sudo modprobe -r kvm_intel kvm_amd"
    fi
fi

vbox_major="$(VBoxManage --version 2>/dev/null | cut -d. -f1)"
if [ "${vbox_major:-0}" -lt 6 ]; then
    die "VirtualBox $vbox_major is too old for nested virtualisation (need 6.1+)"
fi
log_ok "VirtualBox $(VBoxManage --version 2>/dev/null | head -1)"

total_ram_mb="$(free -m 2>/dev/null | awk '/^Mem:/ {print $2}')"
if [ -n "$total_ram_mb" ] && [ "$total_ram_mb" -lt $((L1_RAM + 4096)) ]; then
    log_warn "host has ${total_ram_mb}MB total; L1 alone wants ${L1_RAM}MB and the host still needs its own"
    log_dim "  lower with --ram, or trim guest memory in the LAB_VMS_nested table"
fi

ifname="$(hostonly_require)"

# --- create ----------------------------------------------------------------
if vbox_vm_exists "$L1_NAME"; then
    if [ "$FORCE" != true ]; then
        die "$L1_NAME already exists (use --force to recreate)"
    fi
    vbox_vm_running "$L1_NAME" && VBoxManage controlvm "$L1_NAME" poweroff >/dev/null 2>&1 || true
    sleep 2
    VBoxManage unregistervm "$L1_NAME" --delete >/dev/null
    log_dim "removed existing $L1_NAME"
fi

log_step "Creating L1 host $L1_NAME"

VBoxManage createvm --name "$L1_NAME" --ostype Debian_64 \
    --basefolder "$LAB_VM_BASEFOLDER" --register >/dev/null

disk_path="$LAB_VM_BASEFOLDER/$L1_NAME/$L1_NAME.vdi"
VBoxManage createmedium disk --filename "$disk_path" \
    --size $((L1_DISK * 1024)) --format VDI --variant Standard >/dev/null

VBoxManage storagectl "$L1_NAME" --name SATA --add sata \
    --controller IntelAHCI --portcount 2 --bootable on >/dev/null
VBoxManage storageattach "$L1_NAME" --storagectl SATA \
    --port 0 --device 0 --type hdd --medium "$disk_path" >/dev/null
VBoxManage storageattach "$L1_NAME" --storagectl SATA \
    --port 1 --device 0 --type dvddrive --medium "$L1_ISO" >/dev/null

# --nested-hw-virt is the flag that makes any of this possible: it exposes
# VT-x/AMD-V to the guest so a hypervisor can run inside it. It requires
# --nested-paging, and --ioapic is mandatory for more than one vCPU.
VBoxManage modifyvm "$L1_NAME" \
    --memory "$L1_RAM" --cpus "$L1_CPUS" --vram 64 \
    --nested-hw-virt on --nested-paging on --ioapic on --pae on \
    --paravirtprovider kvm \
    --graphicscontroller vmsvga \
    --nic1 nat \
    --nic2 hostonly --hostonlyadapter2 "$ifname" \
    --audio none \
    --boot1 dvd --boot2 disk --boot3 none --boot4 none \
    --rtcuseutc on >/dev/null

# SSH from the physical host into L1 without needing its address up front.
VBoxManage modifyvm "$L1_NAME" \
    --natpf1 "ssh,tcp,127.0.0.1,2222,,22" >/dev/null

log_ok "$L1_NAME  ${L1_CPUS}cpu ${L1_RAM}MB ${L1_DISK}GB  nested-hw-virt=on"

nested_ram=0
while IFS= read -r record; do
    [ -n "$record" ] || continue
    nested_ram=$((nested_ram + $(vm_field "$record" 3)))
done <<EOF
$(lab_vms nested)
EOF

log_info ""
log_info "Nested guests will ask for ${nested_ram}MB of L1's ${L1_RAM}MB, leaving $((L1_RAM - nested_ram))MB for Linux itself."
log_info ""
log_info "Next:"
log_info "  1. VBoxManage startvm $L1_NAME --type gui      # install Linux, enable OpenSSH"
log_info "  2. ssh -p 2222 <user>@127.0.0.1                # from this host"
log_info "  3. copy templates/l1-provision.sh into L1 and run it (installs VirtualBox)"
log_info "  4. copy this repo and your Windows ISOs into L1"
log_info "  5. inside L1:  bash scripts/deploy-all.sh --variant nested \\"
log_info "                   --iso-win2022 /isos/WinServer2022.iso \\"
log_info "                   --iso-win10  /isos/Win10.iso"
log_info ""
log_dim "Inside L1 the toolchain is identical — it is VirtualBox there too, so the"
log_dim "same scripts, unattend media and playbooks apply unchanged."
