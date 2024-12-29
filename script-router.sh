#!/bin/bash

set -e

# Function to check if a package is already installed
is_installed() {
  dpkg -l | grep -qw "$1"
}

# Function to check if a line exists in a file
line_exists() {
  grep -qxF "$1" "$2"
}

# Checking if Webmin repository and GPG key are added
echo "Checking Webmin repository and GPG key..."

# Webmin GPG Key and Repository
WEBMIN_REPO="deb http://download.webmin.com/download/repository sarge contrib"
if ! apt-key list | grep -q "Webmin"; then
  echo "Adding Webmin GPG key..."
  wget -qO - http://www.webmin.com/jcameron-key.asc | sudo apt-key add -
else
  echo "Webmin GPG key already added, skipping..."
fi

if ! line_exists "$WEBMIN_REPO" /etc/apt/sources.list; then
  echo "Adding Webmin repository..."
  echo "$WEBMIN_REPO" | sudo tee -a /etc/apt/sources.list
else
  echo "Webmin repository already exists, skipping..."
fi

# Main, updates, and security repositories
DEBIAN_REPO="deb http://kartolo.sby.datautama.net.id/debian bookworm main"
DEBIAN_UPDATES_REPO="deb http://kartolo.sby.datautama.net.id/debian bookworm-updates main"
DEBIAN_SECURITY_REPO="deb http://kartolo.sby.datautama.net.id/debian-security bookworm-security main"

if ! line_exists "$DEBIAN_REPO" /etc/apt/sources.list; then
  echo "Adding main repository..."
  echo "$DEBIAN_REPO" | sudo tee -a /etc/apt/sources.list
else
  echo "Main repository already exists, skipping..."
fi

if ! line_exists "$DEBIAN_UPDATES_REPO" /etc/apt/sources.list; then
  echo "Adding updates repository..."
  echo "$DEBIAN_UPDATES_REPO" | sudo tee -a /etc/apt/sources.list
else
  echo "Updates repository already exists, skipping..."
fi

if ! line_exists "$DEBIAN_SECURITY_REPO" /etc/apt/sources.list; then
  echo "Adding security repository..."
  echo "$DEBIAN_SECURITY_REPO" | sudo tee -a /etc/apt/sources.list
else
  echo "Security repository already exists, skipping..."
fi

# Update and upgrade the system
echo "Updating and upgrading system..."
sudo apt update && sudo apt upgrade -y

# Install required packages
REQUIRED_PACKAGES=(
  net-tools iproute2 iptables iptables-persistent dnsutils curl wget unzip \
  bridge-utils hostapd isc-dhcp-server sudo vim git build-essential webmin
)

for package in "${REQUIRED_PACKAGES[@]}"; do
  if is_installed "$package"; then
    echo "Package $package is already installed, skipping..."
  else
    echo "Installing package $package..."
    sudo apt install -y "$package"
  fi
done

# Install ZeroTier if not already installed
if is_installed "zerotier-one"; then
  echo "ZeroTier is already installed, skipping..."
else
  echo "Installing ZeroTier..."
  curl -s https://install.zerotier.com | sudo bash

  # Prompt for ZeroTier Network ID
  echo "Enter your ZeroTier Network ID: "
  read ZT_NETWORK_ID
  sudo zerotier-cli join "$ZT_NETWORK_ID"
  echo "Joined ZeroTier network $ZT_NETWORK_ID."
fi


# Ensure ZeroTier starts on boot
if sudo systemctl is-enabled zerotier-one; then
  echo "ZeroTier is already enabled to start on boot, skipping..."
else
  echo "Enabling ZeroTier to start on boot..."
  sudo systemctl enable zerotier-one
fi

# Check if CasaOS is installed
if [ -d "/usr/lib/casaOS" ] || [ -f "/usr/bin/casaos" ]; then
  echo "CasaOS is already installed, skipping..."
else
  echo "Installing CasaOS..."
  curl -fsSL https://get.casaos.io | sudo bash
fi

# Enable IP forwarding for router functionality if not already done
if grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf; then
  echo "IP forwarding already enabled, skipping..."
else
  echo "Enabling IP forwarding..."
  echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
  sudo sysctl -p
fi

# Configure iptables NAT if not already configured
if sudo iptables -t nat -C POSTROUTING -o eth0 -j MASQUERADE 2>/dev/null; then
  echo "iptables NAT rule already exists, skipping..."
else
  echo "Adding iptables NAT rule..."
  sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
  sudo iptables-save | sudo tee /etc/iptables/rules.v4
fi

# Restart other services to ensure they are running
sudo systemctl restart zerotier-one
sudo systemctl restart webmin

echo "\n--- Setup complete! ---"
echo "Router, ZeroTier, CasaOS, and Webmin have been installed and configured."
echo "Ensure ZeroTier has joined the network and configure the DHCP server as needed."
echo "Access the web GUI using your browser at https://<your-server-ip>:10000."
