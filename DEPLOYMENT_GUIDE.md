# VulnLab Hackossem - Complete Deployment Guide

This guide provides a complete overview of all available deployment options for the VulnLab Hackossem application.

## Quick Reference

### Choose Your Setup Method

| Method | Best For | Setup Time | Resources | Complexity |
|--------|----------|-----------|-----------|-----------|
| **Docker Compose** | Development, Quick Testing | 2 mins | Minimal (512MB) | ⭐ Very Easy |
| **Vagrant** | Full VM, Isolated Environment | 10 mins | Moderate (2GB) | ⭐⭐ Easy |
| **Manual Setup** | Learning, Customization | 15 mins | Depends | ⭐⭐⭐ Moderate |
| **VirtualBox VM** | Full Control, Advanced Setup | 20+ mins | Full OS (2GB+) | ⭐⭐⭐ Moderate |

---

## 🚀 Quick Start

### Option 1: Docker Compose (Fastest - 2 minutes)

```bash
# Prerequisites: Docker and Docker Compose installed

git clone https://github.com/netanelcyber/hackossem.git
cd hackossem
docker-compose up

# Access: http://localhost:5000
```

**Best for**: Quick testing, development, CI/CD pipelines

**Resources**: ~256MB RAM, ~100MB disk

[Full Docker Guide](DOCKER_SETUP.md)

---

### Option 2: Vagrant (Easiest - 10 minutes)

```bash
# Prerequisites: VirtualBox and Vagrant installed

git clone https://github.com/netanelcyber/hackossem.git
cd hackossem
vagrant up

# Access: http://localhost:5000
```

**Best for**: Complete VM, portable environment, team collaboration

**Resources**: ~2GB RAM (configurable), ~10GB disk

[Full Vagrant Guide](VIRTUALBOX_SETUP.md#quick-start-vagrant)

---

### Option 3: Manual Setup (Full Control - 15 minutes)

```bash
# Prerequisites: Ubuntu/Debian system

git clone https://github.com/netanelcyber/hackossem.git
cd hackossem
sudo bash setup-vm.sh

# Access: http://localhost:5000
```

**Best for**: Understanding the system, custom configurations, minimal dependencies

**Resources**: Varies (~1GB+ RAM), ~500MB disk

[Full Manual Setup Guide](VIRTUALBOX_SETUP.md#manual-setup)

---

## 📊 Feature Comparison

### Core Features (All Methods)

- ✅ VulnLab AD Labs listing
- ✅ Search and filtering
- ✅ LINQ query engine
- ✅ WASM compilation demo
- ✅ RESTful API endpoints
- ✅ Beautiful responsive UI
- ✅ Mock data demonstration

### Additional Features by Method

| Feature | Docker | Vagrant | Manual |
|---------|--------|---------|--------|
| Systemd service | ❌ | ✅ | ✅ |
| Health checks | ✅ | ❌ | ❌ |
| Volume mounts | ✅ | ✅ | ✅ |
| Environment isolation | ✅ | ✅ | ❌ |
| Full OS access | ❌ | ✅ | ✅ |
| Production-ready | ✅ | ⚠️ | ⚠️ |

---

## 🔧 Configuration

### Common Configuration Options

#### Set VulnLab API Key

**Docker Compose**:
```bash
export VULNLAB_API_KEY="your-key-here"
docker-compose up
```

**Vagrant**:
```bash
vagrant ssh
export VULNLAB_API_KEY="your-key-here"
python3 app.py
```

**Manual**:
```bash
export VULNLAB_API_KEY="your-key-here"
python3 app.py
```

#### Change Port

**Docker Compose** - Modify `docker-compose.yml`:
```yaml
ports:
  - "8000:5000"
```

**Vagrant** - Modify `Vagrantfile`:
```ruby
config.vm.network "forwarded_port", guest: 5000, host: 8000
```

**Manual** - Modify `app.py`:
```python
app.run(port=8000)
```

---

## 📚 Detailed Documentation

### For Docker Users
→ [Docker Setup Guide](DOCKER_SETUP.md)
- Docker Compose quick start
- Manual Docker commands
- Multi-container architecture
- Production deployment

### For Vagrant Users
→ [VirtualBox Setup Guide](VIRTUALBOX_SETUP.md)
- Vagrant quick start
- Manual VirtualBox setup
- Systemd configuration
- VM management

### For VulnLab Integration
→ [VulnLab Feature Documentation](VULNLAB_FEATURE.md)
- VulnLabClient API
- Mock data structure
- Usage examples
- Future enhancements

---

## 🎯 Use Cases & Recommendations

### I want to quickly test the app
**Recommended**: Docker Compose
```bash
docker-compose up
curl http://localhost:5000/api/vulnlab/ad-labs
```

### I'm developing a feature
**Recommended**: Docker Compose with volume mounts
```bash
docker run -d -v $(pwd):/app -p 5000:5000 hackossem:latest
```

### I need a complete isolated environment
**Recommended**: Vagrant
```bash
vagrant up
vagrant ssh
```

### I want to understand how everything works
**Recommended**: Manual setup
```bash
sudo bash setup-vm.sh
journalctl -u hackossem -f  # Watch logs
```

### I'm deploying to production
**Recommended**: Docker + Kubernetes or Gunicorn
- See [Docker Setup - Production Deployment](DOCKER_SETUP.md#production-deployment)

### I need to work without internet
**Recommended**: Manual setup or Vagrant (after initial setup)

---

## 🚨 Troubleshooting Quick Links

### Port Issues
- Docker: [Docker Troubleshooting - Port Already in Use](DOCKER_SETUP.md#port-already-in-use)
- Vagrant: [Vagrant Troubleshooting - Port Already in Use](VIRTUALBOX_SETUP.md#port-already-in-use)

### Service Won't Start
- Docker: [Docker Troubleshooting - Container Won't Start](DOCKER_SETUP.md#container-wont-start)
- Vagrant: [Vagrant Troubleshooting - Service Won't Start](VIRTUALBOX_SETUP.md#service-wont-start)
- Manual: [Manual Troubleshooting - Service Won't Start](VIRTUALBOX_SETUP.md#service-wont-start)

### Performance Issues
- All methods: See respective guides' "Slow Performance" section

---

## 🔄 Switching Between Setup Methods

### From Docker to Vagrant

```bash
# Stop Docker
docker-compose down

# Start Vagrant
vagrant up
```

### From Vagrant to Docker

```bash
# Stop Vagrant VM
vagrant halt

# Start Docker
docker-compose up
```

### From Docker/Vagrant to Manual

```bash
# Stop existing
# Docker: docker-compose down
# Vagrant: vagrant halt

# Install manually
sudo bash setup-vm.sh
```

---

## 📈 Scaling & Production

### Single Instance (Development)
- Docker Compose
- Vagrant VM
- Manual setup

### Multiple Instances (Testing)
```bash
# Docker Compose with scaling
docker-compose up --scale hackossem=3
```

### Production Deployment
1. Use Docker with:
   - Gunicorn or uWSGI WSGI server
   - Nginx reverse proxy
   - PostgreSQL database (optional)
   - Container orchestration (Kubernetes/Docker Swarm)

2. Or use Vagrant base image for:
   - VirtualBox enterprise deployments
   - Consistent environment across machines

See [DOCKER_SETUP.md](DOCKER_SETUP.md#advanced-setup) for detailed production setup.

---

## 📋 Pre-Deployment Checklist

### Before Deployment

- [ ] System requirements met (RAM, disk space)
- [ ] Docker/Vagrant/prerequisites installed
- [ ] Repository cloned
- [ ] Network connectivity verified
- [ ] Ports 5000 (or custom) available
- [ ] Environment variables configured (if needed)

### After Deployment

- [ ] Application loads at http://localhost:5000
- [ ] VulnLab AD Labs page accessible
- [ ] API endpoint working: `/api/vulnlab/ad-labs`
- [ ] Search functionality working
- [ ] Filters working correctly
- [ ] No error logs in output

### Verification Commands

```bash
# Test web interface
curl http://localhost:5000

# Test API endpoint
curl http://localhost:5000/api/vulnlab/ad-labs

# Test with filters
curl "http://localhost:5000/api/vulnlab/ad-labs?difficulty=Medium"

# Test search
curl "http://localhost:5000/api/vulnlab/ad-labs?search=Kerberos"
```

---

## 🤝 Contributing & Support

### Issues or Questions?

1. Check the appropriate guide:
   - Docker: [DOCKER_SETUP.md](DOCKER_SETUP.md)
   - Vagrant/VirtualBox: [VIRTUALBOX_SETUP.md](VIRTUALBOX_SETUP.md)
   - VulnLab Feature: [VULNLAB_FEATURE.md](VULNLAB_FEATURE.md)

2. Check troubleshooting sections

3. Review logs:
   ```bash
   # Docker
   docker logs hackossem
   
   # Vagrant
   vagrant ssh
   sudo journalctl -u hackossem -f
   
   # Manual
   sudo journalctl -u hackossem -f
   ```

4. Open GitHub issue with:
   - Setup method used
   - Error messages and logs
   - System information
   - Steps to reproduce

---

## 📝 Version Info

- **Application**: VulnLab Hackossem
- **Branch**: `claude/vulnlab-list-ad-labs-pgchvl`
- **Python**: 3.9+
- **Flask**: 2.3.3+
- **Docker**: 20.10+
- **Vagrant**: 2.3+
- **VirtualBox**: 6.1+

---

## 🎓 Learning Resources

- **Flask**: https://flask.palletsprojects.com/
- **Docker**: https://docs.docker.com/
- **Vagrant**: https://www.vagrantup.com/docs
- **VirtualBox**: https://www.virtualbox.org/manual/
- **VulnLab**: https://vulnlab.com/

---

## 📄 Related Documentation

- [VulnLab Feature Documentation](VULNLAB_FEATURE.md)
- [Docker Setup Guide](DOCKER_SETUP.md)
- [VirtualBox Setup Guide](VIRTUALBOX_SETUP.md)
- [Application README](readme.MD)

---

**Last Updated**: 2026-08-05
**Status**: ✅ Production Ready
