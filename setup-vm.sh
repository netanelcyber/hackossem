#!/bin/bash
# VirtualBox setup script for VulnLab Hackossem
# This script sets up the application environment on a fresh Ubuntu VM

set -e

echo "=========================================="
echo "VulnLab Hackossem - VirtualBox Setup"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${YELLOW}➜${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root"
    exit 1
fi

# Step 1: Update system
print_step "Updating system packages..."
apt-get update
apt-get upgrade -y
print_success "System packages updated"

# Step 2: Install Python and dependencies
print_step "Installing Python and build tools..."
apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    build-essential \
    git \
    curl \
    wget \
    vim \
    nano \
    htop
print_success "Python and dependencies installed"

# Step 3: Create application directory
print_step "Setting up application directory..."
APP_DIR="/opt/hackossem"
if [ ! -d "$APP_DIR" ]; then
    mkdir -p "$APP_DIR"
    print_success "Created $APP_DIR"
else
    print_success "Application directory already exists"
fi

# Step 4: Clone or copy repository
if [ -d ".git" ]; then
    print_step "Copying application files..."
    cp -r . "$APP_DIR"
else
    print_step "Cloning repository..."
    cd /tmp
    git clone https://github.com/netanelcyber/hackossem.git "$APP_DIR"
fi
print_success "Application files ready"

# Step 5: Create virtual environment
print_step "Creating Python virtual environment..."
cd "$APP_DIR"
python3 -m venv venv
print_success "Virtual environment created"

# Step 6: Install Python dependencies
print_step "Installing Python dependencies..."
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
print_success "Python dependencies installed"

# Step 7: Create systemd service
print_step "Creating systemd service..."
cat > /etc/systemd/system/hackossem.service <<EOF
[Unit]
Description=VulnLab Hackossem Flask Application
After=network.target
Documentation=https://github.com/netanelcyber/hackossem

[Service]
Type=simple
User=www-data
WorkingDirectory=$APP_DIR
Environment="PATH=$APP_DIR/venv/bin"
ExecStart=$APP_DIR/venv/bin/python3 app.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

print_success "Systemd service created"

# Step 8: Set permissions
print_step "Setting permissions..."
chown -R www-data:www-data "$APP_DIR"
chmod -R 755 "$APP_DIR"
print_success "Permissions set"

# Step 9: Enable and start service
print_step "Starting service..."
systemctl daemon-reload
systemctl enable hackossem
systemctl start hackossem
print_success "Service started and enabled"

# Step 10: Verify installation
print_step "Verifying installation..."
sleep 2
if systemctl is-active --quiet hackossem; then
    print_success "Service is running"
else
    print_error "Service failed to start, checking logs..."
    journalctl -u hackossem -n 20
    exit 1
fi

# Print summary
echo ""
echo "=========================================="
echo -e "${GREEN}✅ Setup Complete!${NC}"
echo "=========================================="
echo ""
echo "📊 Application Information:"
echo "   - Location: $APP_DIR"
echo "   - Service: hackossem"
echo "   - Port: 5000"
echo ""
echo "🌐 Access the application:"
echo "   - Web UI: http://localhost:5000"
echo "   - VulnLab Labs: http://localhost:5000/vulnlab-ad-labs"
echo "   - API Endpoint: http://localhost:5000/api/vulnlab/ad-labs"
echo ""
echo "🔧 Useful commands:"
echo "   - Check status: sudo systemctl status hackossem"
echo "   - View logs: sudo journalctl -u hackossem -f"
echo "   - Restart: sudo systemctl restart hackossem"
echo "   - Stop: sudo systemctl stop hackossem"
echo "   - Start: sudo systemctl start hackossem"
echo ""
echo "📝 Configuration:"
echo "   - To use real VulnLab API: export VULNLAB_API_KEY='your-key'"
echo "   - Configuration file location: $APP_DIR"
echo ""
