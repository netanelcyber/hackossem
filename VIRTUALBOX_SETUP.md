# VirtualBox Setup Guide - VulnLab Hackossem

This guide provides comprehensive instructions for setting up the VulnLab Hackossem application in a VirtualBox virtual machine.

## Table of Contents

1. [Quick Start (Vagrant)](#quick-start-vagrant)
2. [Manual Setup](#manual-setup)
3. [Configuration](#configuration)
4. [Access & Usage](#access--usage)
5. [Troubleshooting](#troubleshooting)
6. [Advanced Configuration](#advanced-configuration)

---

## Quick Start (Vagrant)

### Prerequisites

- **VirtualBox** (6.1 or newer)
- **Vagrant** (2.3 or newer)
- 2GB RAM available
- 10GB disk space

### Installation

1. **Install VirtualBox**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install virtualbox

   # macOS (using Homebrew)
   brew install virtualbox

   # Windows - Download from https://www.virtualbox.org/
   ```

2. **Install Vagrant**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install vagrant

   # macOS (using Homebrew)
   brew install vagrant

   # Windows - Download from https://www.vagrantup.com/
   ```

3. **Clone the Repository**
   ```bash
   git clone https://github.com/netanelcyber/hackossem.git
   cd hackossem
   ```

### Start the VM

```bash
# Create and start the VM
vagrant up

# This will:
# - Download Ubuntu 22.04 LTS base image
# - Create a new VirtualBox VM
# - Install all dependencies
# - Configure and start the Flask application
```

### Access the Application

Once Vagrant finishes provisioning:

- **Web Interface**: http://localhost:5000
- **VulnLab AD Labs**: http://localhost:5000/vulnlab-ad-labs
- **API Endpoint**: http://localhost:5000/api/vulnlab/ad-labs
- **VM IP Address**: 192.168.56.10

### Common Vagrant Commands

```bash
# SSH into the VM
vagrant ssh

# Stop the VM (without destroying)
vagrant halt

# Resume the VM
vagrant up

# Destroy the VM (frees disk space)
vagrant destroy

# Check VM status
vagrant status

# View provisioning output
vagrant provision

# Reload configuration
vagrant reload
```

---

## Manual Setup

For manual VirtualBox setup without Vagrant:

### Option 1: Using Setup Script (Recommended)

1. **Create a VirtualBox VM**
   - Download Ubuntu 22.04 LTS ISO
   - Create a new VM with:
     - 2GB+ RAM
     - 20GB+ disk space
     - Network bridge for internet access

2. **Boot and Install Ubuntu**
   - Follow standard Ubuntu installation
   - Update system after installation

3. **Download and Run Setup Script**
   ```bash
   # Clone or download the repository
   git clone https://github.com/netanelcyber/hackossem.git
   cd hackossem

   # Run the setup script (requires sudo)
   sudo bash setup-vm.sh
   ```

### Option 2: Manual Step-by-Step

1. **Update System**
   ```bash
   sudo apt-get update
   sudo apt-get upgrade -y
   ```

2. **Install Python and Dependencies**
   ```bash
   sudo apt-get install -y \
       python3 \
       python3-pip \
       python3-venv \
       python3-dev \
       build-essential \
       git
   ```

3. **Clone Repository**
   ```bash
   git clone https://github.com/netanelcyber/hackossem.git
   cd hackossem
   ```

4. **Create Virtual Environment**
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   ```

5. **Install Dependencies**
   ```bash
   pip install --upgrade pip
   pip install -r requirements.txt
   ```

6. **Run Application**
   ```bash
   python3 app.py
   ```
   The application will be available at `http://localhost:5000`

---

## Configuration

### Environment Variables

Set VulnLab API credentials for real lab data:

```bash
export VULNLAB_API_KEY="your-api-key-here"
python3 app.py
```

### Flask Configuration

Modify `app.py` to customize:

```python
# Port configuration
app.run(debug=True, port=5000, host='0.0.0.0')

# Debug mode (set to False in production)
app.run(debug=True)
```

### Systemd Service (Manual Setup)

Create `/etc/systemd/system/hackossem.service`:

```ini
[Unit]
Description=VulnLab Hackossem Flask Application
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/opt/hackossem
Environment="PATH=/opt/hackossem/venv/bin"
ExecStart=/opt/hackossem/venv/bin/python3 app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable hackossem
sudo systemctl start hackossem
```

---

## Access & Usage

### Web Interface

1. **Home Page** - http://localhost:5000
   - Navigation to all demos
   - Links to VulnLab AD Labs

2. **VulnLab AD Labs** - http://localhost:5000/vulnlab-ad-labs
   - Browse all Active Directory labs
   - Filter by difficulty
   - Search by name/description
   - View lab details

3. **LINQ Demo** - http://localhost:5000/linq
   - Test the LINQ query engine
   - Filter and sort data

4. **WASM Demo** - http://localhost:5000/wasm
   - WebAssembly/JIT compilation demo

### API Endpoints

#### List All Labs
```bash
curl http://localhost:5000/api/vulnlab/ad-labs
```

#### Filter by Difficulty
```bash
curl "http://localhost:5000/api/vulnlab/ad-labs?difficulty=Medium"
```

#### Search Labs
```bash
curl "http://localhost:5000/api/vulnlab/ad-labs?search=Kerberos"
```

#### Combined Filters
```bash
curl "http://localhost:5000/api/vulnlab/ad-labs?difficulty=Hard&search=Privilege"
```

### Response Format

```json
{
  "total": 2,
  "labs": [
    {
      "id": "ad-lab-4",
      "name": "Privilege Escalation in AD",
      "description": "Exploit common privilege escalation vectors in AD environments.",
      "difficulty": "Hard",
      "category": "active-directory",
      "machines": ["DC-1", "CLIENT-1", "CLIENT-2", "SERVER-1"],
      "tags": ["Privilege Escalation", "AD", "Post-Exploitation"],
      "url": "https://vulnlab.com/labs/ad-privesc"
    }
  ]
}
```

---

## Troubleshooting

### VM Won't Start

```bash
# Check VirtualBox installation
VBoxManage --version

# Reset Vagrant
vagrant destroy
vagrant up --force

# Check VM logs
VBoxManage showvminfo VulnLab-Hackossem
```

### Port Already in Use

If port 5000 is already in use:

**Vagrant**: Modify `Vagrantfile`:
```ruby
config.vm.network "forwarded_port", guest: 5000, host: 5001
```

**Manual Setup**: Change Flask port:
```bash
python3 -c "from app import app; app.run(port=8000)"
```

### Service Won't Start

Check logs:
```bash
sudo journalctl -u hackossem -n 50
sudo systemctl status hackossem
```

Verify dependencies:
```bash
source venv/bin/activate
python3 -c "from app import app; print('✅ App loads successfully')"
```

### Network Connectivity Issues

**Inside Vagrant VM**:
```bash
# Check VM network configuration
ip addr show
route -n

# Test connectivity
ping 8.8.8.8
curl http://localhost:5000
```

### Slow Performance

- Increase VM resources in `Vagrantfile`:
  ```ruby
  vb.memory = 4096  # 4GB
  vb.cpus = 4       # 4 cores
  ```

---

## Advanced Configuration

### Enable HTTPS

1. **Generate Self-Signed Certificate**
   ```bash
   openssl req -x509 -newkey rsa:4096 -nodes \
     -out cert.pem -keyout key.pem -days 365
   ```

2. **Modify app.py**
   ```python
   if __name__ == "__main__":
       app.run(ssl_context=('cert.pem', 'key.pem'), port=5443)
   ```

### Production Deployment

Replace Flask development server with production WSGI server:

```bash
pip install gunicorn

# Run with Gunicorn
gunicorn -w 4 -b 0.0.0.0:5000 app:app
```

### Database Integration

Add database support:

```bash
pip install flask-sqlalchemy
```

Update `app.py`:
```python
from flask_sqlalchemy import SQLAlchemy

app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///labs.db'
db = SQLAlchemy(app)
```

### Nginx Reverse Proxy

Install and configure Nginx:

```bash
sudo apt-get install nginx

# Create /etc/nginx/sites-available/hackossem
upstream hackossem {
    server localhost:5000;
}

server {
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://hackossem;
    }
}
```

Enable:
```bash
sudo ln -s /etc/nginx/sites-available/hackossem /etc/nginx/sites-enabled/
sudo systemctl restart nginx
```

---

## Maintenance

### Regular Updates

```bash
# Inside the VM or after vagrant ssh
cd /opt/hackossem (or ~/hackossem)
git pull origin main
source venv/bin/activate
pip install -r requirements.txt
sudo systemctl restart hackossem
```

### Backup VM

```bash
# Vagrant
vagrant package --output hackossem-backup.box

# VirtualBox
VBoxManage export VulnLab-Hackossem -o backup.ova
```

### Cleanup

```bash
# Remove old packages
sudo apt-get autoremove
sudo apt-get autoclean

# Clear pip cache
pip cache purge

# Vagrant cleanup
vagrant destroy
rm -rf .vagrant
```

---

## Resources

- **VirtualBox**: https://www.virtualbox.org/
- **Vagrant**: https://www.vagrantup.com/
- **Flask Documentation**: https://flask.palletsprojects.com/
- **VulnLab**: https://vulnlab.com/

---

## Support

For issues or questions:
1. Check this guide's troubleshooting section
2. Review VM logs: `sudo journalctl -u hackossem -f`
3. Visit the GitHub repository: https://github.com/netanelcyber/hackossem/issues
