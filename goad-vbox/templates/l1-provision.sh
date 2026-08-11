#!/usr/bin/env bash
# Run this INSIDE the L1 VM, once, after installing Xubuntu 22.04+.
# It installs VirtualBox plus the Ansible control tooling, so L1 can host and
# provision the nested variant (all Windows Server 2022) on its own.

set -euo pipefail

[ "$(id -u)" -eq 0 ] || { echo "run with sudo"; exit 1; }
[ -r /etc/os-release ] || { echo "unsupported: no /etc/os-release"; exit 1; }
. /etc/os-release

# --- confirm this really is Xubuntu/Ubuntu 22.04 or newer ------------------
# The VirtualBox packaging path below (multiverse) is Ubuntu-specific, and the
# 22.04 floor is what ships a new enough VirtualBox to nest.
echo "==> Checking the L1 distribution"
# Xubuntu reports ID=ubuntu; other Ubuntu remixes set ID_LIKE=ubuntu. Use [[ ]]
# so the ID_LIKE glob actually matches.
if [ "${ID:-}" != "ubuntu" ] && [[ "${ID_LIKE:-}" != *ubuntu* ]]; then
    echo "    FAIL: expected Ubuntu/Xubuntu, found '${PRETTY_NAME:-unknown}'."
    echo "    Reinstall L1 from an official Xubuntu 22.04+ desktop ISO."
    exit 1
fi
ver_major="${VERSION_ID%%.*}"
if [ "${ver_major:-0}" -lt 22 ]; then
    echo "    FAIL: Ubuntu ${VERSION_ID:-?} is too old; need 22.04+."
    exit 1
fi
echo "    OK: ${PRETTY_NAME}"

# --- confirm L1 actually received nested virtualisation --------------------
echo "==> Verifying nested virtualisation reached this VM"
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

# --- packages --------------------------------------------------------------
# VirtualBox lives in Ubuntu's 'multiverse' component and the Ansible WinRM
# binding in 'universe'; enable both, then install from the distro repos so no
# third-party APT source is needed.
echo "==> Enabling universe + multiverse and installing packages"
export DEBIAN_FRONTEND=noninteractive
apt-get install -y -qq software-properties-common >/dev/null
add-apt-repository -y universe   >/dev/null 2>&1 || true
add-apt-repository -y multiverse >/dev/null 2>&1 || true
apt-get update -qq

apt-get install -y -qq \
    virtualbox virtualbox-dkms virtualbox-ext-pack \
    linux-headers-"$(uname -r)" dkms build-essential \
    ansible python3-pip python3-winrm \
    xorriso git curl openssh-server

if ! command -v VBoxManage >/dev/null 2>&1; then
    echo "    FAIL: VirtualBox did not install. Confirm multiverse is enabled:"
    echo "          grep -R multiverse /etc/apt/sources.list /etc/apt/sources.list.d/"
    exit 1
fi
echo "==> VirtualBox: $(VBoxManage --version)"

# --- kernel modules --------------------------------------------------------
echo "==> Loading kernel modules"
# The dkms build for the running kernel can lag a fresh install; make it
# explicit so a failure is obvious here rather than at first VM start.
if ! modprobe vboxdrv 2>/dev/null; then
    echo "    vboxdrv build not ready; running /sbin/vboxconfig"
    /sbin/vboxconfig || true
    modprobe vboxdrv
fi
modprobe vboxnetadp
lsmod | grep -q '^vboxdrv'    || { echo "vboxdrv failed to load"; exit 1; }
lsmod | grep -q '^vboxnetadp' || { echo "vboxnetadp failed to load"; exit 1; }
echo "    OK: vboxdrv and vboxnetadp loaded"

printf 'vboxdrv\nvboxnetadp\n' > /etc/modules-load.d/virtualbox.conf

# --- Ansible collections ---------------------------------------------------
echo "==> Ansible collections"
target_user="${SUDO_USER:-root}"
sudo -u "$target_user" ansible-galaxy collection install \
    ansible.windows microsoft.ad community.windows

usermod -aG vboxusers "$target_user" || true

cat <<MSG

==> L1 is ready.

    Distro     : ${PRETTY_NAME}
    VirtualBox : $(VBoxManage --version)
    Ansible    : $(ansible --version 2>/dev/null | head -1)

    Log out and back in so the vboxusers group membership takes effect, then
    from the repo directory (one Server 2022 ISO covers the whole nested lab):

        bash scripts/deploy-all.sh --variant nested \\
            --iso-win2022 /isos/WinServer2022.iso

    Nested guests will be slow. That is inherent to running VirtualBox inside
    VirtualBox, not a misconfiguration.
MSG
