#!/bin/bash

# Ubuntu xrdp + Xfce + Firefox Setup Script
# This script configures a remote desktop environment with GUI and web browser

set -e  # Exit on any error

echo "=========================================="
echo "Starting Ubuntu xrdp Setup"
echo "=========================================="

# Update package list
echo "Updating package list..."
sudo apt-get update

# Install Xfce desktop environment
echo "Installing Xfce desktop environment..."
sudo apt-get install -y xfce4 xfce4-goodies

# Install xrdp
echo "Installing xrdp..."
sudo apt-get install -y xrdp

# Configure xrdp to use Xfce
echo "Configuring xrdp to use Xfce..."
echo "startxfce4" > ~/.xsession

# Create and configure startwm.sh script
echo "Setting up xrdp window manager script..."
cat > /tmp/startwm.sh <<'EOT'
#!/bin/sh
# Start Xfce for xrdp sessions
if [ -r /etc/profile ]; then . /etc/profile; fi
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
startxfce4
EOT

sudo cp /etc/xrdp/startwm.sh /etc/xrdp/startwm.sh.bak || true
sudo mv /tmp/startwm.sh /etc/xrdp/startwm.sh
sudo chmod +x /etc/xrdp/startwm.sh

# Configure SSL certificate for xrdp
echo "Configuring SSL certificate access..."
sudo adduser xrdp ssl-cert || true

# Enable and start xrdp service
echo "Enabling and starting xrdp service..."
sudo systemctl enable --now xrdp
sudo systemctl restart xrdp

# Configure firewall for RDP access
echo "Configuring firewall for RDP (port 3389)..."
sudo ufw allow 3389/tcp || true

# Install Firefox
echo "Installing Firefox web browser..."
sudo apt-get install -y firefox

# Display setup summary
echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo "xrdp service status:"
sudo systemctl status xrdp --no-pager || true
echo ""
echo "Firewall status:"
sudo ufw status verbose || true
echo ""
echo "Firefox version:"
firefox --version || true
echo ""
echo "You can now connect via RDP on port 3389"
echo "=========================================="
