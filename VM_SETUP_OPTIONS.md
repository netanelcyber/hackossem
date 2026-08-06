# 🖥️ VM Setup Options - Choose Your Approach

## Summary: 3 Ways to Create Labs

This project supports **3 different approaches** to create and manage VirtualBox VMs for the VulnLab AD labs:

### 1️⃣ Vagrant (Recommended for Most Users)
### 2️⃣ VBoxManage (Direct VirtualBox)
### 3️⃣ Docker (Containerized Alternative)

Choose based on your needs and experience level.

---

## Option 1: Vagrant ✅ RECOMMENDED

### What is Vagrant?
Vagrant is an automation tool that manages VirtualBox VMs using configuration files (Vagrantfile).

### Best For
- Beginners
- Rapid setup and iteration
- Reproducible environments
- Teams sharing same configuration

### Pros
✅ Automatic VM creation and provisioning  
✅ Configuration as code (Vagrantfile)  
✅ Automatic networking setup  
✅ Easy to share configurations  
✅ One command: `vagrant up`  
✅ Good documentation  

### Cons
❌ Requires Vagrant installation  
❌ Less control over VM details  
❌ Slower for advanced customization  

### Quick Start
```bash
cd lab-vms-vagrant
vagrant up                    # Creates all 5 VMs
vagrant ssh ad-lab-1          # SSH into Lab 1
vagrant halt                  # Stop all VMs
```

### Setup Time
⏱️ **10-15 minutes** (automated)

### Resource Usage
- RAM: 2GB per VM × 5 = 10GB total
- Disk: 20GB per VM × 5 = 100GB total
- CPU: 2 cores per VM × 5 = 10 cores needed

### Documentation
👉 See: `INDIVIDUAL_LABS_GUIDE.md`

---

## Option 2: VBoxManage (Direct VirtualBox)

### What is VBoxManage?
VBoxManage is VirtualBox's command-line tool for VM management with full control.

### Best For
- Advanced users
- Full VM customization
- Learning VirtualBox internals
- Integrating with CI/CD systems
- Users who don't want Vagrant

### Pros
✅ Full VirtualBox control  
✅ No Vagrant dependency  
✅ More granular configuration  
✅ Better for automation scripts  
✅ Direct visibility into VM setup  
✅ Great for advanced scenarios  

### Cons
❌ Manual OS installation required  
❌ More commands to learn  
❌ Steeper learning curve  
❌ Setup takes longer  
❌ Network configuration manual  

### Quick Start
```bash
./create-vms-vboxmanage.sh    # Create 5 empty VMs
# Install Ubuntu in each VM (interactive)
./manage-vms.sh               # Interactive VM management
```

### Setup Time
⏱️ **45-60 minutes** (includes manual Ubuntu installation)

### Resource Usage
- Same as Vagrant (2GB RAM, 20GB disk per VM)
- More flexibility to adjust

### Documentation
👉 See: `VBOXMANAGE_VM_GUIDE.md`

---

## Option 3: Docker (Containerized)

### What is Docker?
Docker provides lightweight containerized environments as alternative to full VMs.

### Best For
- Development and testing
- CI/CD pipelines
- Rapid iteration
- Users with limited disk space
- Cloud deployments

### Pros
✅ Minimal resource usage (100-500MB per container)  
✅ Very fast startup (~1 second)  
✅ Easier deployment to cloud  
✅ Better isolation than VMs  
✅ Easier sharing (Docker Hub)  
✅ Better for microservices  

### Cons
❌ Different from production VirtualBox VMs  
❌ Less realistic for AD lab scenarios  
❌ Requires Docker knowledge  
❌ No full Windows-like AD experience  
❌ Networking different from VMs  

### Quick Start
```bash
docker-compose up                    # Start containers
docker ps                            # List running
docker exec -it hackossem bash       # Shell access
```

### Setup Time
⏱️ **2-5 minutes**

### Resource Usage
- RAM: 256-512MB per container (much less than VMs)
- Disk: 500MB per container (much less than VMs)
- CPU: Shared/limited

### Documentation
👉 See: `DOCKER_SETUP.md` and `docker-compose.yml`

---

## Comparison Table

| Feature | Vagrant | VBoxManage | Docker |
|---------|---------|-----------|--------|
| **Setup Time** | 10-15 min | 45-60 min | 2-5 min |
| **Configuration** | Vagrantfile | Shell script | docker-compose.yml |
| **OS Installation** | Automatic | Manual | Pre-built image |
| **Disk Space** | 100GB (5 VMs) | 100GB (5 VMs) | 5-10GB (5 containers) |
| **RAM Usage** | 10GB (5 VMs) | 10GB (5 VMs) | 2-3GB (5 containers) |
| **Learning Curve** | Easy | Medium | Medium |
| **Realism** | High | High | Medium |
| **Customization** | Medium | High | Low-Medium |
| **Reproducibility** | Excellent | Good | Excellent |
| **Automation** | Good | Excellent | Excellent |
| **Cloud Ready** | Medium | Low | High |
| **Best For** | Teams/Beginners | Advanced/Custom | Dev/Testing |

---

## Decision Tree

```
Start Here: Which approach suits you?

Do you want automatic setup?
  ↓ YES → Use VAGRANT ✅
  ↓ NO  → Continue...

Do you need full VM realism?
  ↓ YES → Use VBOXMANAGE
  ↓ NO  → Use DOCKER

Do you need to learn VirtualBox?
  ↓ YES → Use VBOXMANAGE
  ↓ NO  → Use DOCKER
```

---

## Recommended Usage Scenarios

### Scenario 1: Learning Active Directory
**Use: Vagrant**
- Fastest setup
- Most realistic AD environment
- Easiest for beginners
- Good documentation

```bash
cd lab-vms-vagrant
vagrant up
vagrant ssh ad-lab-1
# Start learning!
```

---

### Scenario 2: Understanding VirtualBox Internals
**Use: VBoxManage**
- Full control and visibility
- Learn VirtualBox deeply
- Customize VM configuration
- Good for advanced users

```bash
./create-vms-vboxmanage.sh
# Manually install Ubuntu in each VM
./manage-vms.sh
```

---

### Scenario 3: Rapid Testing & Development
**Use: Docker**
- Fast iteration
- Minimal resources
- Easy version control
- Suitable for CI/CD

```bash
docker-compose up
curl http://localhost:5000
# Quick testing
```

---

### Scenario 4: Team Collaboration
**Use: Vagrant**
- Same configuration for everyone
- Easy to version control
- Reproducible environments
- Good for shared teams

```bash
git clone https://github.com/netanelcyber/hackossem.git
cd hackossem
vagrant up
# Same environment for all team members
```

---

### Scenario 5: Production-like Testing
**Use: VBoxManage + OVA Export**
- Export VMs as OVA files
- Share via Git LFS
- Identical to production
- Backup capability

```bash
# Export
VBoxManage export "VulnLab-ad-lab-1" -o lab-ad-lab-1.ova

# Share via Git LFS
git lfs push origin claude/vulnlab-list-ad-labs-pgchvl
```

---

### Scenario 6: CI/CD Pipeline Integration
**Use: Docker**
- Fast, reliable containers
- Easy to parallelize
- Minimal resource overhead
- Built for automation

```yaml
# In GitHub Actions or similar
- name: Test labs
  run: docker-compose up -d && npm test
```

---

## Migration Guide

### Vagrant → VBoxManage

```bash
# Export Vagrant VMs as OVA
cd lab-vms-vagrant
vagrant halt
vagrant global-status

# Then import to VBoxManage
VBoxManage import exported.ova --vsys 0 --vmname "VulnLab-ad-lab-1"
```

### VBoxManage → Vagrant

```bash
# Export VirtualBox VMs
VBoxManage export "VulnLab-ad-lab-1" -o lab-ad-lab-1.ova

# Create Vagrantfile that uses box
# Requires creating Vagrant box from OVA (complex)
```

### Vagrant/VBoxManage → Docker

```bash
# Create Dockerfile from VM configuration
# Install same packages in Docker
# Expose same ports
# Build and run

docker build -t hackossem-lab .
docker run -p 5001:5000 hackossem-lab
```

---

## Installation Instructions

### Vagrant Setup
```bash
# Install VirtualBox
sudo apt-get install virtualbox

# Install Vagrant
wget https://releases.hashicorp.com/vagrant/2.4.0/vagrant_2.4.0_linux_amd64.zip
unzip vagrant_2.4.0_linux_amd64.zip
sudo mv vagrant /usr/local/bin/

# Verify
vagrant --version
```

### VBoxManage Setup
```bash
# VirtualBox includes VBoxManage
sudo apt-get install virtualbox

# Verify
VBoxManage --version
```

### Docker Setup
```bash
# Install Docker
sudo apt-get install docker.io docker-compose

# Add user to docker group
sudo usermod -aG docker $USER

# Verify
docker --version
```

---

## Performance Tuning

### Vagrant
```bash
# Edit Vagrantfile
config.vm.provider "virtualbox" do |vb|
  vb.memory = 4096    # Increase RAM
  vb.cpus = 4         # Increase CPUs
end

vagrant reload
```

### VBoxManage
```bash
# Modify running VM (must be off)
VBoxManage modifyvm "VulnLab-ad-lab-1" --memory 4096 --cpus 4
```

### Docker
```bash
# Edit docker-compose.yml
services:
  hackossem:
    mem_limit: 1g
    cpus: '1.0'
    
docker-compose up
```

---

## Troubleshooting

### "Vagrant command not found"
→ Install Vagrant: `sudo apt-get install vagrant`

### "VBoxManage not in PATH"
→ Add to PATH or use full path: `/usr/lib/virtualbox/VBoxManage`

### "Docker daemon not running"
→ Start Docker: `sudo systemctl start docker`

### "VMs use too much disk"
→ Reduce disk per VM in Vagrantfile/VBoxManage config
→ Or use Docker (much smaller)

---

## References

- **Vagrant Documentation**: https://www.vagrantup.com/docs
- **VirtualBox Manual**: https://www.virtualbox.org/manual/
- **Docker Documentation**: https://docs.docker.com/
- **Ubuntu ISO**: https://releases.ubuntu.com/jammy/

---

## Getting Help

- **Vagrant issues**: See `INDIVIDUAL_LABS_GUIDE.md`
- **VBoxManage issues**: See `VBOXMANAGE_VM_GUIDE.md`
- **Docker issues**: See `DOCKER_SETUP.md`
- **General setup**: See `DEPLOYMENT_GUIDE.md`

---

**Version**: 1.0  
**Created**: 2026-08-06  
**Status**: ✅ Production Ready
