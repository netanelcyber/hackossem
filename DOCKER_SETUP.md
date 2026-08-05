# Docker Setup Guide - VulnLab Hackossem

This guide covers Docker and Docker Compose setup options for running the VulnLab Hackossem application. Docker can run on VirtualBox, making it a lightweight alternative to full VM provisioning.

## Table of Contents

1. [Quick Start (Docker Compose)](#quick-start-docker-compose)
2. [Manual Docker Setup](#manual-docker-setup)
3. [Docker in VirtualBox](#docker-in-virtualbox)
4. [Configuration](#configuration)
5. [Troubleshooting](#troubleshooting)

---

## Quick Start (Docker Compose)

### Prerequisites

- **Docker** (20.10+)
- **Docker Compose** (2.0+)
- 1GB RAM available
- 2GB disk space

### Installation

#### Ubuntu/Debian

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

#### macOS (using Homebrew)

```bash
brew install docker docker-compose
# Start Docker Desktop from Applications
```

#### Windows

1. Download [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop)
2. Install and restart
3. Open PowerShell and verify: `docker --version`

### Quick Start

```bash
# Clone repository
git clone https://github.com/netanelcyber/hackossem.git
cd hackossem

# Start the application
docker-compose up

# Or run in background
docker-compose up -d
```

### Access the Application

- **Web Interface**: http://localhost:5000
- **VulnLab AD Labs**: http://localhost:5000/vulnlab-ad-labs
- **API Endpoint**: http://localhost:5000/api/vulnlab/ad-labs

### Docker Compose Commands

```bash
# Start services
docker-compose up

# Run in background
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Rebuild images
docker-compose build --no-cache

# View running services
docker-compose ps

# Execute command in container
docker-compose exec hackossem bash

# Restart service
docker-compose restart
```

---

## Manual Docker Setup

### Build Docker Image

```bash
# Build the image
docker build -t hackossem:latest .

# Verify image
docker images | grep hackossem
```

### Run Container

```bash
# Basic run
docker run -p 5000:5000 hackossem:latest

# Run in background
docker run -d -p 5000:5000 --name hackossem hackossem:latest

# Run with volume mount for development
docker run -d -p 5000:5000 \
  -v $(pwd):/app \
  --name hackossem \
  hackossem:latest

# Run with VulnLab API key
docker run -d -p 5000:5000 \
  -e VULNLAB_API_KEY="your-key-here" \
  --name hackossem \
  hackossem:latest
```

### Docker Commands

```bash
# View logs
docker logs -f hackossem

# Execute command
docker exec -it hackossem bash

# Stop container
docker stop hackossem

# Remove container
docker rm hackossem

# View container details
docker inspect hackossem

# Check resource usage
docker stats hackossem
```

---

## Docker in VirtualBox

### Option 1: Install Docker in VirtualBox VM

1. **Create Ubuntu VM in VirtualBox** (2GB RAM, 20GB disk)

2. **SSH into VM and install Docker**
   ```bash
   sudo apt-get update
   sudo apt-get install -y docker.io docker-compose
   ```

3. **Clone and run**
   ```bash
   git clone https://github.com/netanelcyber/hackossem.git
   cd hackossem
   sudo docker-compose up
   ```

4. **Access from host**
   - Set up port forwarding in VirtualBox: Guest 5000 → Host 5000
   - Access: http://localhost:5000

### Option 2: Use Docker Machine

Create VirtualBox VM with Docker automatically:

```bash
# Install Docker Machine
curl -L https://github.com/docker/machine/releases/download/v0.16.2/docker-machine-`uname -s`-`uname -m` \
  >/usr/local/bin/docker-machine && \
chmod +x /usr/local/bin/docker-machine

# Create VM
docker-machine create -d virtualbox hackossem-vm

# Activate environment
eval $(docker-machine env hackossem-vm)

# Clone and run
git clone https://github.com/netanelcyber/hackossem.git
cd hackossem
docker-compose up

# Get VM IP
docker-machine ip hackossem-vm
```

---

## Configuration

### Environment Variables

Create `.env` file:

```bash
VULNLAB_API_KEY=your-api-key-here
FLASK_ENV=development
FLASK_DEBUG=1
```

Use with docker-compose:

```bash
docker-compose --env-file .env up
```

Or pass via command line:

```bash
docker run -e VULNLAB_API_KEY=your-key hackossem:latest
```

### Custom Port

Modify `docker-compose.yml`:

```yaml
services:
  hackossem:
    ports:
      - "8000:5000"  # Host:Container
```

Or run with:

```bash
docker run -p 8000:5000 hackossem:latest
```

### Volume Mounts

For live code editing:

```bash
docker-compose exec hackossem bash
# or
docker run -d -v $(pwd):/app -p 5000:5000 hackossem:latest
```

### Network Modes

```yaml
# Host network (Linux only)
network_mode: host

# Custom bridge
networks:
  hackossem-net:
    driver: bridge
```

---

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker logs hackossem

# Inspect container
docker inspect hackossem

# Check resource limits
docker stats hackossem
```

### Port Already in Use

```bash
# Find process using port 5000
lsof -i :5000

# Kill process (Linux/macOS)
kill -9 <PID>

# Or use different port
docker run -p 8000:5000 hackossem:latest
```

### Permission Denied

```bash
# Add user to docker group (Linux)
sudo usermod -aG docker $USER
newgrp docker

# Or use sudo
sudo docker-compose up
```

### Out of Disk Space

```bash
# Clean up Docker
docker system prune -a

# Remove unused volumes
docker volume prune

# Check disk usage
docker system df
```

### Slow Performance

```bash
# Increase Docker resources
# Docker Desktop → Settings → Resources → CPUs/Memory

# Or in VirtualBox VM:
# Increase VM memory and CPU allocation
```

### API Key Not Working

```bash
# Verify environment variable
docker-compose exec hackossem env | grep VULNLAB

# Check logs
docker logs hackossem
```

---

## Advanced Setup

### Multi-Container Architecture

Extend `docker-compose.yml`:

```yaml
version: '3.8'

services:
  hackossem:
    build: .
    ports:
      - "5000:5000"
    environment:
      DATABASE_URL: postgresql://user:password@db:5432/hackossem
    depends_on:
      - db

  db:
    image: postgres:15
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
      POSTGRES_DB: hackossem
    volumes:
      - db_data:/var/lib/postgresql/data

  nginx:
    image: nginx:latest
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - hackossem

volumes:
  db_data:
```

### Production Deployment

Use Gunicorn:

Modify Dockerfile:

```dockerfile
# ... existing content ...

# Install Gunicorn
RUN . venv/bin/activate && pip install gunicorn

# Change CMD
CMD ["venv/bin/gunicorn", "-w", "4", "-b", "0.0.0.0:5000", "app:app"]
```

### Health Checks

Docker will automatically check container health:

```bash
# View health status
docker ps

# Manual health check
docker exec hackossem curl http://localhost:5000/
```

### Logging

```yaml
services:
  hackossem:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

### Resource Limits

```yaml
services:
  hackossem:
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
```

---

## Comparison: Vagrant vs Docker Compose

| Feature | Vagrant | Docker Compose |
|---------|---------|----------------|
| Setup Time | 5-10 minutes | 1-2 minutes |
| Resource Usage | ~1GB RAM | ~256MB RAM |
| File Size | ~1GB | ~100MB |
| Portability | VM-specific | Universal |
| Development | Full OS access | Container isolation |
| Learning Curve | Moderate | Low |
| Production Ready | With nginx/proxy | Yes, readily |

---

## Resources

- **Docker Documentation**: https://docs.docker.com/
- **Docker Hub**: https://hub.docker.com/
- **Docker Compose**: https://docs.docker.com/compose/
- **VulnLab**: https://vulnlab.com/

---

## Support

For issues:
1. Check Docker logs: `docker logs hackossem`
2. Verify Docker installation: `docker --version`
3. Check Docker Compose: `docker-compose --version`
4. Visit GitHub issues: https://github.com/netanelcyber/hackossem/issues
