#!/usr/bin/env bash
# Run this INSIDE the L1 VM, once, after installing Debian/Ubuntu.
# It installs VirtualBox plus the Ansible control tooling, so L1 can host and
# provision the nested variant on its own.

set -euo pipefail

[ "$(id -u)" -eq 0 ] || { echo "run with sudo"; exit 1; }
[ -r /etc/os-release ] || { echo "unsupported: no /etc/os-release"; exit 1; }
. /etc/os-release

echo "==> Verifying the L1 guest actually received nested virtualisation"
if grep -qwE 'vmx|svm' /proc/cpuinfo; then
    echo "    OK: virtualisation extensions visible inside L1"
else
    cat <<'MSG'
    FAIL: no vmx/svm inside this VM.

    The outer VM was not started with nested virtualisation. On the physical
    host, with L1 powered off:

        VBoxManage modifyvm goad-l1 --nested-hw-virt on --nested-paging on

    Without this, VirtualBox here can only run 32-bit guests in software
    emulation, and the Windows guests will not boot.
MSG
    exit 1
fi

echo "==> Installing packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq \
    virtualbox virtualbox-dkms \
    linux-headers-"$(uname -r)" dkms build-essential \
    ansible python3-pip python3-winrm \
    xorriso git curl openssh-server

# Debian ships VirtualBox in contrib; Ubuntu in multiverse. If the package was
# unavailable the command above already failed, so reaching here means it is in.
echo "==> VirtualBox: $(VBoxManage --version 2>/dev/null || echo 'NOT WORKING')"

echo "==> Loading kernel modules"
modprobe vboxdrv
modprobe vboxnetadp
lsmod | grep -q '^vboxdrv'    || { echo "vboxdrv failed to load"; exit 1; }
lsmod | grep -q '^vboxnetadp' || { echo "vboxnetadp failed to load"; exit 1; }
echo "    OK: vboxdrv and vboxnetadp loaded"

# Persist across reboots.
printf 'vboxdrv\nvboxnetadp\n' > /etc/modules-load.d/virtualbox.conf

echo "==> Ansible collections"
target_user="${SUDO_USER:-root}"
sudo -u "$target_user" ansible-galaxy collection install \
    ansible.windows microsoft.ad community.windows

usermod -aG vboxusers "$target_user" || true

cat <<MSG

==> L1 is ready.

    VirtualBox : $(VBoxManage --version 2>/dev/null)
    Ansible    : $(ansible --version 2>/dev/null | head -1)

    Log out and back in so the vboxusers group membership takes effect, then:

        bash scripts/deploy-all.sh --variant nested \\
            --iso-win2022 /isos/WinServer2022.iso \\
            --iso-win10   /isos/Win10.iso

    Nested guests will be slow. That is inherent to running VirtualBox inside
    VirtualBox, not a misconfiguration.
MSG
