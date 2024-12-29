#!/bin/bash

set -e

# Function to check if a package is already installed
is_installed() {
  dpkg -l | grep -qw "$1"
}

# Check if the Webmin GPG key is already added
if ! apt-key list | grep -q "Webmin"; then
  echo "Adding Webmin GPG key..."
  wget -qO - http://www.webmin.com/jcameron-key.asc | sudo apt-key add -
else
  echo "Webmin GPG key already added, skipping..."
fi

# Add Webmin repository if not already present
if ! grep -q "deb http://download.webmin.com/download/repository sarge contrib" /etc/apt/sources.list; then
  echo "Adding Webmin repository..."
  echo "deb http://download.webmin.com/download/repository sarge contrib" >> /etc/apt/sources.list
fi

# Add main, updates, and security repositories
if ! grep -q "deb http://kartolo.sby.datautama.net.id/debian bookworm main" /etc/apt/sources.list; then
  echo "Adding main repository..."
  echo "deb http://kartolo.sby.datautama.net.id/debian bookworm main" >> /etc/apt/sources.list
fi

if ! grep -q "deb http://kartolo.sby.datautama.net.id/debian bookworm-updates main" /etc/apt/sources.list; then
  echo "Adding updates repository..."
  echo "deb http://kartolo.sby.datautama.net.id/debian bookworm-updates main" >> /etc/apt/sources.list
fi

if ! grep -q "deb http://kartolo.sby.datautama.net.id/debian-security bookworm-security main" /etc/apt/sources.list; then
  echo "Adding security repository..."
  echo "deb http://kartolo.sby.datautama.net.id/debian-security bookworm-security main" >> /etc/apt/sources.list
fi

# Update and upgrade the system
apt update && apt upgrade -y

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
    apt install -y "$package"
  fi
done

# Install ZeroTier if not already installed
if is_installed "zerotier-one"; then
  echo "ZeroTier is already installed, skipping..."
else
  echo "Installing ZeroTier..."
  curl -s https://install.zerotier.com | bash
fi

# Prompt for ZeroTier Network ID
echo "Enter ZeroTier Network ID: "
read ZT_NETWORK_ID
zerotier-cli join "$ZT_NETWORK_ID"

# Ensure ZeroTier starts on boot
systemctl enable zerotier-one

# Check if CasaOS is installed
if [ -d "/usr/lib/casaOS" ] || [ -f "/usr/bin/casaos" ]; then
  echo "CasaOS is already installed, skipping..."
else
  echo "Installing CasaOS..."
  curl -fsSL https://get.casaos.io | bash
fi

# Enable IP forwarding for router functionality
if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf; then
  echo "Enabling IP forwarding..."
  echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
  sysctl -p
else
  echo "IP forwarding is already enabled, skipping..."
fi

# Configure iptables NAT
if ! iptables -t nat -C POSTROUTING -o eth0 -j MASQUERADE 2>/dev/null; then
  echo "Adding iptables NAT rule..."
  iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
  iptables-save > /etc/iptables/rules.v4
else
  echo "iptables NAT rule already exists, skipping..."
fi

# Display available network interfaces
echo "Available network interfaces:"
ip link show | grep -E "^[0-9]+: " | awk -F: '{print $2}' | sed 's/^ //g'

# Prompt for number of interfaces to configure
echo "Enter the number of interfaces to configure: "
read NUM_INTERFACES

# Loop through the interfaces for configuration
for ((i=1; i<=NUM_INTERFACES; i++)); do
  echo "Enter the name of interface #$i: "
  read INTERFACE_NAME
  echo "Enter the static IP address for $INTERFACE_NAME (e.g., 192.168.1.1/24): "
  read IP_ADDRESS

  # Configure the interface with the static IP
  ip addr add $IP_ADDRESS dev $INTERFACE_NAME
  ip link set $INTERFACE_NAME up
done

# Ask if DHCP should be enabled for each interface
echo "Do you want to enable DHCP for the interfaces configured above? (yes/no)"
read ENABLE_DHCP

if [ "$ENABLE_DHCP" == "yes" ]; then
  # Configure DHCP for each interface
  for ((i=1; i<=NUM_INTERFACES; i++)); do
    echo "Configuring DHCP for interface #$i..."
    echo "subnet ${IP_ADDRESS%.*}.0 netmask 255.255.255.0 {" >> /etc/dhcp/dhcpd.conf
    echo "  range ${IP_ADDRESS%.*}.10 ${IP_ADDRESS%.*}.100;" >> /etc/dhcp/dhcpd.conf
    echo "  option routers $IP_ADDRESS;" >> /etc/dhcp/dhcpd.conf
    echo "}" >> /etc/dhcp/dhcpd.conf
  done

  # Restart DHCP server to apply the configuration
  systemctl restart isc-dhcp-server
  echo "DHCP server enabled and configured."
else
  echo "DHCP server will not be enabled."
fi

# Restart other services to ensure they are running
systemctl restart zerotier-one
systemctl restart webmin

echo "\n--- Setup complete! ---"
echo "Router, ZeroTier, CasaOS, and Webmin have been installed and configured."
echo "Ensure ZeroTier has joined the network and configure the DHCP server as needed."
echo "Access the web GUI using your browser at https://<your-server-ip>:10000."
