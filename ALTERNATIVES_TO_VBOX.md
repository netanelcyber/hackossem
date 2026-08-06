# 🔄 Alternatives to VirtualBox

Complete guide to alternatives for creating and running VulnLab AD labs without VirtualBox.

---

## Comparison Table

| Tool | Windows | Linux | Mac | Cloud | Ease | Performance | Cost |
|------|---------|-------|-----|-------|------|-------------|------|
| **VirtualBox** | ✅ | ✅ | ✅ | ❌ | Easy | Good | Free |
| **Hyper-V** | ✅ | ❌ | ❌ | ❌ | Medium | Excellent | Free |
| **VMware** | ✅ | ✅ | ✅ | ✅ | Medium | Excellent | Paid |
| **Docker** | ✅ | ✅ | ✅ | ✅ | Easy | Excellent | Free |
| **Proxmox** | N/A | ✅ | ❌ | ✅ | Hard | Excellent | Free |
| **KVM/QEMU** | ❌ | ✅ | ❌ | ✅ | Hard | Excellent | Free |
| **WSL 2** | ✅ | ❌ | ❌ | ❌ | Easy | Good | Free |

---

## 1️⃣ Docker (Recommended Alternative)

### Why Use Docker Instead?

✅ **Pros:**
- Lightweight (500MB per container vs 20GB per VM)
- Fast startup (1 second vs 30 seconds)
- Works in cloud environments
- Easy to share (Docker Hub)
- Better resource efficiency
- Simpler network management

❌ **Cons:**
- Less realistic than full VMs
- Limited to Linux containers
- Different networking model
- Reduced isolation

### Quick Start

```bash
# Build Docker image
docker build -t vulnlab-ad .

# Run container
docker run -p 5001:5000 vulnlab-ad

# Or use compose
docker-compose up
```

### For Windows Server 2022

```powershell
# Install Docker Desktop or Docker Server
choco install docker-desktop -y

# Or use Windows Containers
Install-WindowsFeature Containers

# Build and run
docker build -t vulnlab-ad .
docker run -p 5001:5000 vulnlab-ad

# Access
Start-Process "http://localhost:5001"
```

### Dockerfile Example

```dockerfile
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    python3 python3-pip python3-venv \
    git curl

WORKDIR /app

COPY . .

RUN python3 -m venv venv
RUN ./venv/bin/pip install -r requirements.txt

EXPOSE 5000

CMD ["./venv/bin/python3", "app.py"]
```

---

## 2️⃣ Hyper-V (Windows-Native)

### Why Use Hyper-V?

✅ **Pros:**
- Built into Windows Server 2022 Pro/Enterprise
- Excellent performance
- Deep Windows integration
- No additional license needed
- Can run Windows/Linux VMs

❌ **Cons:**
- Windows only
- Steeper learning curve
- More complex management
- GUI or PowerShell required

### Installation

```powershell
# Enable Hyper-V (requires restart)
Enable-WindowsOptionalFeature -FeatureName Hyper-V -Online -NoRestart

# Restart
Restart-Computer
```

### Import OVA to Hyper-V

```powershell
# Convert OVA to VHD format first
# Use: OVA Converter or manual conversion

# Import VHD into Hyper-V
Import-VM -Path "C:\VMs\lab-ad-lab-1" -VirtualMachinePath "C:\Hyper-V\VMs"

# Create VM from VHD
New-VM -Name "VulnLab-ad-lab-1" `
    -MemoryStartupBytes 2GB `
    -VHDPath "C:\path\to\disk.vhd" `
    -Generation 2

# Start VM
Start-VM -Name "VulnLab-ad-lab-1"
```

### Management

```powershell
# List VMs
Get-VM

# Start VM
Start-VM -Name "VulnLab-ad-lab-1"

# Stop VM
Stop-VM -Name "VulnLab-ad-lab-1"

# Check status
Get-VMStatus

# Modify resources
Set-VMMemory -VMName "VulnLab-ad-lab-1" -StartupBytes 4GB
```

### Hyper-V GUI

```powershell
# Open Hyper-V Manager
hyper-v.msc
```

---

## 3️⃣ VMware (Professional Grade)

### Why Use VMware?

✅ **Pros:**
- Excellent performance
- Works on Windows, Linux, Mac
- Can deploy to cloud (vSphere)
- Extensive features
- Good OVA support
- Professional support available

❌ **Cons:**
- Paid license (subscription)
- More complex
- Overkill for small labs
- Steeper learning curve

### Options

**VMware Workstation Pro** (Windows/Linux)
- Professional desktop virtualization
- OVA import support
- Snapshot management
- Pricing: ~$150-200/year

**VMware Fusion** (Mac)
- Similar to Workstation
- Mac optimization
- Good performance

**VMware Workstation Player** (Free)
- Free version with limitations
- OVA import support
- Limited to non-commercial use

### Import OVA

```bash
# Using Workstation Pro
vmware -open lab-ad-lab-1.ova

# Or via command line
vmplayer lab-ad-lab-1.ova

# Via GUI
File → Open → lab-ad-lab-1.ova
```

### Network Access

```bash
# SSH via NAT
ssh -p 22 ubuntu@<vm-ip>

# Web access
http://<vm-ip>:5000
```

---

## 4️⃣ Proxmox (Bare Metal Hypervisor)

### Why Use Proxmox?

✅ **Pros:**
- Bare metal hypervisor (not virtualization on top of OS)
- Excellent performance
- Free and open source
- Web GUI management
- Clustering support
- Can run VMs and containers

❌ **Cons:**
- Requires dedicated hardware
- Linux only
- Steeper learning curve
- Not for development machine
- Best for servers/data centers

### Installation

```bash
# Download ISO
wget https://www.proxmox.com/en/downloads/category/proxmox-virtual-environment

# Boot from ISO and follow installer
# Allocate entire disk to Proxmox

# Access web GUI
https://<proxmox-ip>:8006

# Login with root account
```

### Import OVA

```bash
# Via web GUI:
1. Datacenter → Create VM
2. Upload OVA as template
3. Create instances from template

# Via CLI:
qm importdisk <vm-id> lab-ad-lab-1.ova <storage>
```

---

## 5️⃣ KVM/QEMU (Linux Hypervisor)

### Why Use KVM/QEMU?

✅ **Pros:**
- Linux native
- Excellent performance
- Free and open source
- Can run on any Linux system
- Good OVA support

❌ **Cons:**
- Linux only
- Command-line heavy
- Steeper learning curve
- Requires Linux kernel features

### Installation (Ubuntu/Debian)

```bash
sudo apt-get install qemu-kvm libvirt-daemon-system \
    libvirt-clients bridge-utils virtinst virt-manager

# Enable user for libvirt
sudo usermod -aG libvirt $USER
```

### Import OVA

```bash
# Extract OVA (it's a TAR archive)
tar -xf lab-ad-lab-1.ova

# Convert disk to QEMU format
qemu-img convert disk-0.vmdk lab-ad-lab-1.qcow2

# Create VM
virt-install \
    --name vulnlab-ad-lab-1 \
    --memory 2048 \
    --vcpus 2 \
    --disk lab-ad-lab-1.qcow2 \
    --import \
    --os-variant ubuntu22.04

# Start VM
virsh start vulnlab-ad-lab-1
```

### Management

```bash
# List VMs
virsh list --all

# Start VM
virsh start vulnlab-ad-lab-1

# Stop VM
virsh destroy vulnlab-ad-lab-1

# GUI management
virt-manager
```

---

## 6️⃣ WSL 2 (Windows Subsystem for Linux)

### Why Use WSL 2?

✅ **Pros:**
- Built into Windows 10/11/Server 2022
- Very lightweight
- Fast
- Integrated with Windows
- Free

❌ **Cons:**
- Linux only (not full Windows VMs)
- No GUI by default
- Limited hardware access
- Different from traditional VMs

### Installation

```powershell
# Enable WSL 2
wsl --install

# Install Ubuntu distro
wsl --install -d Ubuntu-22.04

# List distros
wsl --list --verbose
```

### Run Labs in WSL 2

```bash
# Inside WSL terminal
git clone https://github.com/netanelcyber/hackossem.git
cd hackossem

python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python3 app.py

# Access from Windows
http://localhost:5000
```

---

## 7️⃣ Vagrant + Different Providers

### Use Vagrant with Different Backends

**Instead of VirtualBox, use:**

```ruby
# Vagrantfile with Hyper-V
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.provider "hyperv" do |h|
    h.memory = 2048
    h.cpus = 2
  end
end

# Vagrant with VMware
config.vm.provider "vmware_desktop" do |v|
  v.memory = 2048
  v.cpus = 2
end

# Vagrant with Docker
config.vm.provider "docker" do |d|
  d.image = "ubuntu:22.04"
  d.ports = ["5000:5000"]
end
```

### Usage

```bash
# Specify provider
vagrant up --provider=hyperv
vagrant up --provider=vmware_desktop
vagrant up --provider=docker
```

---

## 8️⃣ Cloud VMs (AWS, Azure, GCP)

### Why Cloud VMs?

✅ **Pros:**
- Accessible from anywhere
- Scalable
- No local hardware needed
- Professional infrastructure
- Pay per use

❌ **Cons:**
- Ongoing costs
- Network latency
- Internet dependency
- Account required

### AWS EC2 Example

```bash
# Launch Ubuntu Server
aws ec2 run-instances \
    --image-id ami-xxxxxxxx \
    --instance-type t3.medium \
    --key-name my-key \
    --security-groups allow-ssh-http

# SSH into instance
ssh -i my-key.pem ubuntu@<public-ip>

# Install dependencies
sudo apt-get update
sudo apt-get install -y python3-pip
git clone https://github.com/netanelcyber/hackossem.git
cd hackossem
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python3 app.py
```

---

## Recommendation Matrix

| Use Case | Recommendation | Reason |
|----------|---|---|
| **Learning AD (Local Windows)** | VirtualBox | Easy, free, good realism |
| **Learning AD (Cloud)** | Docker | Only option for cloud |
| **Professional Lab (Local)** | Hyper-V or VMware | Better performance |
| **Enterprise Deployment** | Proxmox or vSphere | Scalability and management |
| **Linux Server** | KVM/QEMU | Native, free, performant |
| **Mac Development** | Docker or VMware Fusion | Native performance |
| **Minimal Resources** | Docker or WSL 2 | Lightweight |
| **Full Realism** | VirtualBox or Hyper-V | Closest to production |

---

## Quick Decision Guide

```
Do you have VirtualBox already installed?
  ├─ YES → Keep using VirtualBox
  └─ NO  → Continue...

What's your operating system?
  ├─ Windows Server 2022
  │  ├─ Want native (Hyper-V)? → Use Hyper-V
  │  ├─ Want lightweight? → Use Docker
  │  └─ Want easiest? → Use Docker
  │
  ├─ Linux
  │  ├─ Want free & native? → Use KVM/QEMU
  │  ├─ Want easiest? → Use Docker
  │  └─ Want standalone? → Use Proxmox
  │
  └─ Mac
     ├─ Want native? → Use Docker or Fusion
     └─ Want lightweight? → Use Docker

Do you need it in the cloud?
  ├─ YES → Use Docker or Cloud VMs
  └─ NO  → Use local hypervisor above
```

---

## Migration Path

### From VirtualBox to Docker

```bash
# 1. Export VM as OVA (done)
VBoxManage export "VulnLab-ad-lab-1" -o lab-ad-lab-1.ova

# 2. Create Dockerfile
cat > Dockerfile << EOF
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y \
    python3 python3-pip python3-venv git
COPY . /app
WORKDIR /app
RUN python3 -m venv venv && \
    ./venv/bin/pip install -r requirements.txt
EXPOSE 5000
CMD ["./venv/bin/python3", "app.py"]
EOF

# 3. Build and run
docker build -t vulnlab-ad .
docker run -p 5001:5000 vulnlab-ad
```

### From VirtualBox to Hyper-V

```bash
# 1. Export as VHDX
# Use third-party converter or:
qemu-img convert -f vmdk -O vhdx disk.vmdk disk.vhdx

# 2. Create VM in Hyper-V
New-VM -Name "VulnLab-ad-lab-1" \
    -MemoryStartupBytes 2GB \
    -VHDPath C:\path\to\disk.vhdx

# 3. Start VM
Start-VM -Name "VulnLab-ad-lab-1"
```

---

## Support & Resources

- **Docker**: https://docs.docker.com/
- **Hyper-V**: https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/
- **VMware**: https://www.vmware.com/products/workstation-pro.html
- **Proxmox**: https://www.proxmox.com/en/
- **KVM/QEMU**: https://www.linux-kvm.org/
- **WSL 2**: https://learn.microsoft.com/en-us/windows/wsl/

---

**Version**: 1.0  
**Created**: 2026-08-06  
**Status**: ✅ Production Ready
