# VirtualBox VM Creation Guide (VBoxManage Deep Dive)

This document explains how to create GOAD VMs using `VBoxManage` commands directly.

## What is VBoxManage?

`VBoxManage` is VirtualBox's command-line interface. Instead of using the GUI, you create and configure VMs via shell commands.

**Advantages over Vagrant:**
- Direct control over VM parameters
- No abstraction layer (Vagrant → provider → VirtualBox)
- Can use any Windows ISO
- Easier to understand & debug
- Works with existing Windows installations

## Network Setup

Before creating VMs, create an isolated internal network:

```bash
VBoxManage list networks
# Find internal network named "goad-internal"

# If not present, create it:
VBoxManage dhcpserver add \
  --network=goad-internal \
  --server-ip=192.168.1.1 \
  --netmask=255.255.255.0 \
  --lower-ip=192.168.1.100 \
  --upper-ip=192.168.1.200 \
  --enable
```

## Creating a Single VM

Example: Create `dc01` (Domain Controller 1)

```bash
# Variables
VM_NAME="dc01"
VM_MEMORY="2048"      # 2 GB RAM
VM_CPUS="2"           # 2 vCPU
VM_DISK="60"          # 60 GB disk
DISK_PATH="/var/lib/vbox/disks/${VM_NAME}.vdi"
ISO_PATH="/opt/iso/WinServer2016.iso"

# 1. Create VM
VBoxManage createvm --name "$VM_NAME" --ostype Windows2016_64 --register

# 2. Create disk
VBoxManage createmedium disk --filename "$DISK_PATH" --size $(($VM_DISK * 1024))

# 3. Create storage controller
VBoxManage storagectl "$VM_NAME" --name "SATA" --add sata --controller IntelAHCI

# 4. Attach disk
VBoxManage storageattach "$VM_NAME" --storagectl "SATA" --port 0 --device 0 --type hdd --medium "$DISK_PATH"

# 5. Attach ISO
VBoxManage storageattach "$VM_NAME" --storagectl "SATA" --port 1 --device 0 --type dvddrive --medium "$ISO_PATH"

# 6. Configure VM
VBoxManage modifyvm "$VM_NAME" --memory "$VM_MEMORY" --cpus "$VM_CPUS"
VBoxManage modifyvm "$VM_NAME" --vram 32                    # Video RAM
VBoxManage modifyvm "$VM_NAME" --accelerate3d off          # No 3D acceleration
VBoxManage modifyvm "$VM_NAME" --clipboard bidirectional   # Clipboard sharing

# 7. Add network interface
VBoxManage modifyvm "$VM_NAME" --nic1 intnet --intnet1 goad-internal

# 8. Boot order (CD first, then disk)
VBoxManage modifyvm "$VM_NAME" --boot1 dvd --boot2 disk --boot3 none --boot4 none

# 9. Enable RDP (for remote desktop access)
VBoxManage modifyvm "$VM_NAME" --vrde on --vrdeport 3389
```

## Automated Script: `create-vms.sh`

Instead of running all these commands manually, use our script:

```bash
bash scripts/create-vms.sh \
  --variant full \
  --iso-2016 /opt/iso/WinServer2016.iso \
  --iso-2019 /opt/iso/WinServer2019.iso
```

**What the script does:**
1. Validates prerequisites (VirtualBox, disk space)
2. Creates network if needed
3. Creates all VMs with correct parameters
4. Attaches disks and ISOs
5. Prints VM list for verification

## Starting/Stopping VMs

```bash
# Start VM (headless—no GUI window)
VBoxManage startvm dc01 --type headless

# Start VM with GUI window
VBoxManage startvm dc01 --type gui

# List running VMs
VBoxManage list runningvms

# Shutdown VM gracefully
VBoxManage controlvm dc01 acpipowerbutton

# Force power off
VBoxManage controlvm dc01 poweroff

# Reboot
VBoxManage controlvm dc01 reset

# Get VM info
VBoxManage showvminfo dc01
```

## Cloning an Existing VM

If you want to quickly duplicate a VM:

```bash
# Clone dc01 to create dc02
VBoxManage clonemedium disk \
  /var/lib/vbox/disks/dc01.vdi \
  /var/lib/vbox/disks/dc02.vdi

# Register the clone
VBoxManage createvm --name dc02 --ostype Windows2016_64 --register
# ... (then attach disk, configure, etc.)
```

## VM Configuration Files

VirtualBox stores VM metadata in:
```
~/.VirtualBox/Machines/
  └── dc01/
      └── dc01.vbox          # VM configuration (XML)
      └── Logs/
          └── VBox.log       # Last VM session log
```

**Check logs for boot issues:**
```bash
cat ~/.VirtualBox/Machines/dc01/Logs/VBox.log | tail -100
```

## Troubleshooting VM Creation

| Problem | Solution |
|---------|----------|
| "SATA controller already exists" | Use different controller name or port |
| "Disk image not found" | Check ISO path; use absolute path |
| "Cannot create medium" | Insufficient disk space; check `df` |
| "VM with name already exists" | Delete old VM: `VBoxManage unregistervm --delete` |

---

**Next:** [`docs/03-WINDOWS-SETUP.md`](03-WINDOWS-SETUP.md) for installing Windows on created VMs.
