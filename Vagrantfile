# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.hostname = "vulnlab-hackossem"

  # Network configuration
  config.vm.network "private_network", ip: "192.168.56.10"
  config.vm.network "forwarded_port", guest: 5000, host: 5000

  # VirtualBox configuration
  config.vm.provider "virtualbox" do |vb|
    vb.name = "VulnLab-Hackossem"
    vb.memory = 2048
    vb.cpus = 2
    vb.gui = false

    # Enable clipboard and drag-and-drop for better UX
    vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
    vb.customize ["modifyvm", :id, "--draganddrop", "bidirectional"]
  end

  # Sync the project folder
  config.vm.synced_folder ".", "/home/vagrant/hackossem"

  # Provisioning script
  config.vm.provision "shell", inline: <<-SHELL
    set -e
    echo "=========================================="
    echo "Setting up VulnLab Hackossem Environment"
    echo "=========================================="

    # Update system packages
    echo "📦 Updating system packages..."
    apt-get update
    apt-get upgrade -y

    # Install Python and dependencies
    echo "🐍 Installing Python..."
    apt-get install -y python3 python3-pip python3-venv

    # Install git (if not already installed)
    apt-get install -y git

    # Create and activate virtual environment
    echo "🔧 Setting up Python virtual environment..."
    cd /home/vagrant/hackossem
    python3 -m venv venv
    source venv/bin/activate

    # Install Python dependencies
    echo "📚 Installing Python dependencies..."
    pip install --upgrade pip
    pip install -r requirements.txt

    # Create systemd service for the app
    echo "🚀 Creating systemd service..."
    sudo tee /etc/systemd/system/hackossem.service > /dev/null <<EOF
[Unit]
Description=VulnLab Hackossem Flask Application
After=network.target

[Service]
Type=simple
User=vagrant
WorkingDirectory=/home/vagrant/hackossem
Environment="PATH=/home/vagrant/hackossem/venv/bin"
ExecStart=/home/vagrant/hackossem/venv/bin/python3 app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    # Enable and start the service
    sudo systemctl daemon-reload
    sudo systemctl enable hackossem
    sudo systemctl start hackossem

    # Install useful development tools
    echo "🛠️  Installing development tools..."
    apt-get install -y curl wget vim nano htop

    echo ""
    echo "=========================================="
    echo "✅ Setup Complete!"
    echo "=========================================="
    echo ""
    echo "📊 Application Information:"
    echo "   - URL: http://192.168.56.10:5000"
    echo "   - Local forward: http://localhost:5000"
    echo "   - Project location: /home/vagrant/hackossem"
    echo ""
    echo "🔧 Useful commands:"
    echo "   - Check service: sudo systemctl status hackossem"
    echo "   - View logs: sudo journalctl -u hackossem -f"
    echo "   - Restart app: sudo systemctl restart hackossem"
    echo ""
  SHELL
end
